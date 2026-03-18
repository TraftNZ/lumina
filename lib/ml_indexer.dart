import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lumina/proto/lumina.pbgrpc.dart';
import 'package:lumina/storage/storage.dart';
import 'package:lumina/global.dart';
import 'package:lumina/logger.dart';
import 'package:lumina/util.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MLIndexer extends ChangeNotifier {
  final ImageLabeler _labeler;
  final FaceDetector _faceDetector;
  final TextRecognizer _textRecognizer;

  bool _running = false;
  bool _paused = false;
  int _indexed = 0;
  int _total = 0;
  String? _currentPath;

  /// Reusable temp file path to avoid create/delete per photo
  String? _tempFilePath;

  /// Throttle UI updates to avoid excessive rebuilds
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
  static const _notifyInterval = Duration(milliseconds: 500);

  bool get isRunning => _running;
  bool get isPaused => _paused;
  int get indexed => _indexed;
  int get total => _total;
  String? get currentPath => _currentPath;

  MLIndexer()
      : _labeler = ImageLabeler(
          options: ImageLabelerOptions(confidenceThreshold: 0.4),
        ),
        _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableTracking: true,
            performanceMode: FaceDetectorMode.fast,
          ),
        ),
        _textRecognizer = TextRecognizer();

  /// Throttled notify — only fires if >= 500ms since last notify.
  /// Use [force] for state transitions (start/stop/pause) that must update immediately.
  void _throttledNotify({bool force = false}) {
    final now = DateTime.now();
    if (force || now.difference(_lastNotify) >= _notifyInterval) {
      _lastNotify = now;
      notifyListeners();
    }
  }

  Future<void> startBatchIndexing() async {
    if (_running) return;
    _running = true;
    _indexed = 0;
    _throttledNotify(force: true);

    try {
      final tempDir = await getTemporaryDirectory();
      _tempFilePath = '${tempDir.path}/ml_indexer_temp.jpg';
      await _runBatchLoop();
    } finally {
      _running = false;
      _throttledNotify(force: true);
      // Clean up temp file
      if (_tempFilePath != null) {
        try {
          await File(_tempFilePath!).delete();
        } catch (_) {}
        _tempFilePath = null;
      }
    }
  }

  Future<void> pause() async {
    _paused = true;
    _throttledNotify(force: true);
  }

  Future<void> resume() async {
    _paused = false;
    _throttledNotify(force: true);
    if (!_running) {
      await startBatchIndexing();
    }
  }

  Future<void> stop() async {
    _paused = false;
    _running = false;
    _throttledNotify(force: true);
  }

  Future<void> _runBatchLoop() async {
    const batchSize = 20;

    while (_running) {
      if (_paused) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      try {
        final response = await storage.cli
            .getUnlabeledPhotos(GetUnlabeledPhotosRequest(limit: batchSize))
            .timeout(const Duration(seconds: 30));

        if (!response.success || response.paths.isEmpty) {
          logger.i("MLIndexer: No more unlabeled photos");
          break;
        }

        _total = _indexed + response.paths.length;
        _throttledNotify(force: true);

        for (final path in response.paths) {
          if (!_running || _paused) break;

          _currentPath = path;
          _throttledNotify();

          try {
            await _processPhoto(path);
            _indexed++;
            _throttledNotify();
          } catch (e) {
            logger.w("MLIndexer: Failed to process $path: $e");
          }

          // Always yield to UI between photos with a real delay.
          // This prevents a tight loop when many photos fail fast (no thumbnail/video).
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        logger.e("MLIndexer: Batch error: $e");
        await Future.delayed(const Duration(seconds: 5));
      }
    }

    _currentPath = null;
    _throttledNotify(force: true);
  }

  Future<void> _processPhoto(String path) async {
    // Skip videos — ML Kit image models don't apply
    if (isVideoByPath(path)) {
      await storage.cli.updatePhotoLabels(
        UpdatePhotoLabelsRequest(path: path, labels: ['_video']),
      );
      return;
    }

    // Always use thumbnail for ML — fast and consistent across local/remote
    final imageData = await _downloadThumbnail(path);
    if (imageData == null) {
      logger.w("MLIndexer: Could not get thumbnail for $path, marking as processed");
      await storage.cli.updatePhotoLabels(
        UpdatePhotoLabelsRequest(path: path, labels: ['_no_thumbnail']),
      );
      return;
    }

    // Reuse a single temp file
    final tempFile = File(_tempFilePath!);
    await tempFile.writeAsBytes(imageData);
    final inputImage = InputImage.fromFilePath(tempFile.path);

    // Run ML models sequentially to avoid saturating the main thread.
    // Each model does heavy native work via platform channels;
    // running them one at a time keeps UI responsive between calls.
    final labels = await _labeler.processImage(inputImage);
    final faces = await _faceDetector.processImage(inputImage);
    final text = await _textRecognizer.processImage(inputImage);

    // Extract data
    final labelList = labels.map((l) => l.label).toList();
    final faceIDs = faces.map((f) => f.trackingId?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    final textContent = text.text;

    // Ensure at least one label so photo isn't returned as "unlabeled" again
    if (labelList.isEmpty) {
      labelList.add('_processed');
    }

    // Send results to server
    final response = await storage.cli.updatePhotoLabels(
      UpdatePhotoLabelsRequest(
        path: path,
        labels: labelList,
        faceIDs: faceIDs,
        text: textContent,
      ),
    );

    if (!response.success) {
      throw Exception("Failed to update labels: ${response.message}");
    }
  }

  Future<Uint8List?> _downloadThumbnail(String path) async {
    var urlPath = path;
    if (urlPath.startsWith('/')) {
      urlPath = urlPath.substring(1);
    }
    // Encode each path segment individually to handle spaces and special chars
    final encodedPath = urlPath.split('/').map(Uri.encodeComponent).join('/');
    final url = '$httpBaseUrl/thumbnail/$encodedPath';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      logger.w("MLIndexer: Failed to download thumbnail for $path: $e");
    }
    return null;
  }

  @override
  void dispose() {
    _labeler.close();
    _faceDetector.close();
    _textRecognizer.close();
    super.dispose();
  }
}

MLIndexer? mlIndexer;

void initMLIndexer() {
  mlIndexer ??= MLIndexer();
}

Future<void> startMLIndexingIfNeeded() async {
  if (mlIndexer == null) {
    initMLIndexer();
  }

  if (!mlIndexer!.isRunning) {
    mlIndexer!.startBatchIndexing().catchError((e) {
      logger.e("MLIndexer error: $e");
    });
  }
}
