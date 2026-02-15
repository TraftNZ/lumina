import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:img_syncer/proto/img_syncer.pbgrpc.dart';
import 'package:img_syncer/storage/storage.dart';
import 'package:img_syncer/global.dart';
import 'package:img_syncer/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
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

  Future<void> startBatchIndexing() async {
    if (_running) return;
    _running = true;
    _indexed = 0;
    notifyListeners();

    try {
      await _runBatchLoop();
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    _paused = true;
    notifyListeners();
  }

  Future<void> resume() async {
    _paused = false;
    notifyListeners();
    if (!_running) {
      await startBatchIndexing();
    }
  }

  Future<void> stop() async {
    _paused = false;
    _running = false;
    notifyListeners();
  }

  Future<void> _runBatchLoop() async {
    const batchSize = 50;

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
        notifyListeners();

        for (final path in response.paths) {
          if (!_running || _paused) break;

          _currentPath = path;
          notifyListeners();

          try {
            await _processPhoto(path);
            _indexed++;
            notifyListeners();
          } catch (e) {
            logger.w("MLIndexer: Failed to process $path: $e");
          }
        }
      } catch (e) {
        logger.e("MLIndexer: Batch error: $e");
        await Future.delayed(const Duration(seconds: 5));
      }
    }

    _currentPath = null;
    notifyListeners();
  }

  Future<void> _processPhoto(String path) async {
    File? tempFile;
    InputImage inputImage;

    try {
      // Always use thumbnail for ML — fast and consistent across local/remote
      final imageData = await _downloadThumbnail(path);
      if (imageData == null) {
        logger.w("MLIndexer: Could not get thumbnail for $path, marking as processed");
        await storage.cli.updatePhotoLabels(
          UpdatePhotoLabelsRequest(path: path, labels: ['_no_thumbnail']),
        );
        return;
      }
      // Save to temp file since InputImage.fromBytes doesn't support JPEG
      final tempDir = await getTemporaryDirectory();
      final filename = p.basename(path);
      tempFile = File('${tempDir.path}/ml_$filename');
      await tempFile.writeAsBytes(imageData);
      inputImage = InputImage.fromFilePath(tempFile.path);

      // Run ML inference
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
    } finally {
      // Clean up temp file
      if (tempFile != null) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<Uint8List?> _downloadThumbnail(String path) async {
    var urlPath = path;
    if (urlPath.startsWith('/')) {
      urlPath = urlPath.substring(1);
    }
    final url = '$httpBaseUrl/thumbnail/$urlPath';

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
    // Start indexing in the background
    mlIndexer!.startBatchIndexing().catchError((e) {
      logger.e("MLIndexer error: $e");
    });
  }
}
