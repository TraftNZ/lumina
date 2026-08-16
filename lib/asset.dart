import 'dart:async';
import 'dart:ui' as ui;

import 'package:lumina/proto/lumina.pbgrpc.dart';
import 'package:lumina/storage/storage.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:exif/exif.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:lumina/global.dart';

class Asset extends ImageProvider<Asset> {
  static final DateTime _minimumReliableDate = DateTime(1990, 1, 1);
  static const Duration _recentDateWindow = Duration(days: 30);
  static const Duration _significantDateDifference = Duration(days: 1);
  static const int _maxCachedImageBytes = 10 * 1024 * 1024;

  bool hasLocal = false;
  bool hasRemote = false;
  AssetEntity? local;
  RemoteImage? remote;
  Completer<Uint8List>? _thumbnailDataCompleter;
  Uint8List? _thumbnailData;
  Completer<Uint8List>? _dataAsyncCompleter;
  Uint8List? _data;
  MemoryImage? _cachedThumbnailProvider;
  Uint8List? _cachedThumbnailDataRef;

  String? make;
  String? model;
  int? imageWidth;
  int? imageHeight;
  double imageSize = 0;
  String? date;
  String? iSO;
  String? exposureTime;
  String? fNumber;
  String? focalLength;

  File? localFile;
  String? localTitle;

  Asset({this.local, this.remote}) {
    if (local != null) {
      // getLocalFile();
      hasLocal = true;
    }
    if (remote != null) {
      hasRemote = true;
    }
  }

  bool isLocal() {
    return hasLocal;
  }

  bool get isCloudOnly => hasRemote && !hasLocal;

  static final _timestampPrefixRe = RegExp(r'^\d{14}_([a-f0-9]{16}_)?');

  /// Returns the original filename, stripping the server-added timestamp prefix
  /// (and optional content-hash segment) from remote filenames.
  /// e.g. `20260213090431_IMG.jpg` → `IMG.jpg`
  /// e.g. `20260213090431_abcdef0123456789_IMG.jpg` → `IMG.jpg`
  String? get originalName {
    if (hasLocal) return name();
    if (hasRemote) {
      final remoteName = basename(remote!.path);
      return remoteName.replaceFirst(_timestampPrefixRe, '');
    }
    return null;
  }

  /// Number of leading hex characters of the SHA-256 the server writes into
  /// uploaded filenames (see `encodeName` in server/api/http.go).
  static const int remoteHashLength = 16;

  static final _hashPrefixRe = RegExp(r'^\d{14}_([a-f0-9]{16})_');

  /// The content hash the server embedded in an uploaded filename, or null for
  /// uploads that predate the hash prefix.
  ///
  /// This is the only part of a remote path that identifies the photo itself:
  /// the directory and timestamp prefix are derived from a date the server may
  /// rewrite from EXIF or the original filename, so they cannot be matched
  /// against the local creation date.
  String? get remoteContentHash {
    if (!hasRemote || remote == null) return null;
    return _hashPrefixRe.firstMatch(basename(remote!.path))?.group(1);
  }

  /// Filename normalized for matching, scoped by the date the file is filed
  /// under so two photos sharing a name on different days stay distinct. Case
  /// is folded because the same photo has been observed stored remotely as both
  /// `.3GP` and `.3gp`.
  String? get matchName {
    final n = originalName;
    if (n == null || n.isEmpty) return null;
    final d = _dedupDate(n);
    return "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}_${n.toLowerCase()}";
  }

  static final List<RegExp> _filenameDatePatterns = [
    RegExp(
      r'(?:VID|IMG|PXL|Screenshot|MVIMG|PANO)_(\d{4})(\d{2})(\d{2})[_-](\d{2})(\d{2})(\d{2})',
    ),
    RegExp(r'(\d{4})(\d{2})(\d{2})[_-](\d{2})(\d{2})(\d{2})'),
  ];

  DateTime _dedupDate(String name) {
    final assetDate = dateCreated();
    if (!hasLocal) return assetDate;
    final filenameDate = _dateFromFilename(name);
    if (filenameDate == null) return assetDate;
    if (_dateLooksSuspicious(assetDate) ||
        (local?.type == AssetType.video &&
            _dateDiffSignificant(assetDate, filenameDate))) {
      return filenameDate;
    }
    return assetDate;
  }

  DateTime? _dateFromFilename(String name) {
    for (final pattern in _filenameDatePatterns) {
      final match = pattern.firstMatch(name);
      if (match == null) continue;
      final year = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      final day = int.tryParse(match.group(3) ?? '');
      final hour = int.tryParse(match.group(4) ?? '');
      final minute = int.tryParse(match.group(5) ?? '');
      final second = int.tryParse(match.group(6) ?? '');
      if (year == null ||
          month == null ||
          day == null ||
          hour == null ||
          minute == null ||
          second == null) {
        continue;
      }
      final date = DateTime(year, month, day, hour, minute, second);
      if (date.year == year &&
          date.month == month &&
          date.day == day &&
          date.hour == hour &&
          date.minute == minute &&
          date.second == second &&
          !date.isBefore(_minimumReliableDate)) {
        return date;
      }
    }
    return null;
  }

  bool _dateLooksSuspicious(DateTime date) {
    if (date.isBefore(_minimumReliableDate)) return true;
    final now = DateTime.now();
    if (date.isAfter(now)) return true;
    return date.year == now.year &&
        date.isAfter(now.subtract(_recentDateWindow));
  }

  bool _dateDiffSignificant(DateTime a, DateTime b) {
    return a.difference(b).abs() > _significantDateDifference;
  }

  String stableId() {
    if (hasLocal && local != null) return 'l:${local!.id}';
    if (hasRemote && remote != null) return 'r:${remote!.path}';
    final n = matchName;
    if (n != null) return 'k:$n';
    return 'o:${identityHashCode(this)}';
  }

  bool hasGotTitle() {
    return localTitle != null;
  }

  Future<File?> getLocalFile() async {
    if (localFile != null) {
      return localFile;
    }
    if (hasLocal) {
      try {
        localFile = await local!.originFile;
      } catch (_) {
        // originFile may fail on macOS; continue without the file path.
      }
      localTitle = await local!.titleAsync;
    }
    return localFile;
  }

  String? name() {
    if (hasLocal) {
      if (localTitle != null && localTitle != "") {
        return localTitle;
      }
      if (local!.title != null && local!.title != "") {
        return local!.title;
      }
      if (localFile != null) {
        return basename(localFile!.path);
      }
      return local!.title;
    }
    if (hasRemote) {
      return basename(remote!.path);
    }
    return "";
  }

  String? mimeType() {
    if (name() == null) {
      return null;
    }
    final RegExp regex = RegExp(r'\.([a-zA-Z0-9]+)$');
    final Match? match = regex.firstMatch(name()!);

    if (match != null && match.groupCount > 0) {
      final String extension = match.group(1)?.toLowerCase() ?? '';

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          return 'image/jpeg';
        case 'png':
          return 'image/png';
        case 'gif':
          return 'image/gif';
        case 'bmp':
          return 'image/bmp';
        case 'webp':
          return 'image/webp';
        case 'heic':
          return 'image/heic';
        case 'heif':
          return 'image/heif';
        case 'dng':
          return 'image/x-adobe-dng';
        case 'tif':
        case 'tiff':
          return 'image/tiff';
        case 'cr2':
          return 'image/x-canon-cr2';
        case 'nef':
          return 'image/x-nikon-nef';
        case 'arw':
          return 'image/x-sony-arw';
        case 'rw2':
          return 'image/x-panasonic-rw2';
        case 'orf':
          return 'image/x-olympus-orf';
        case 'pef':
          return 'image/x-pentax-pef';
        case 'raf':
          return 'image/x-fuji-raf';
        case 'x3f':
          return 'image/x-sigma-x3f';
        case 'srw':
          return 'image/x-samsung-srw';
        default:
          return null;
      }
    } else {
      return null;
    }
  }

  DateTime dateCreated() {
    if (hasLocal) {
      return local!.createDateTime;
    }
    if (hasRemote) {
      RegExp datePattern = RegExp(r'(\d{4})/(\d{2})/(\d{2})');
      Match? match = datePattern.firstMatch(remote!.path);

      if (match != null) {
        if (match.groupCount != 3) {
          return DateTime.now();
        }
        int year = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int day = int.parse(match.group(3)!);

        return DateTime(year, month, day);
      } else {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Uint8List thumbnailData() {
  //   if (_thumbnailData != null) {
  //     return _thumbnailData!;
  //   }
  //   return Uint8List(0);
  // }

  bool isVideo() {
    if (hasLocal) {
      return local!.type == AssetType.video;
    }
    if (hasRemote) {
      return remote!.isVideo();
    }
    return false;
  }

  bool loadThumbnailFinished() {
    // Remote-only assets use ExtendedNetworkImageProvider which handles its own loading
    if (isCloudOnly && remote != null && isServerReady) {
      return true;
    }
    return _thumbnailData != null;
  }

  ImageProvider thumbnailProvider() {
    // For remote-only assets, use cached network image (disk cache + auto retry)
    // ResizeImage caps the decoded pixel dimensions so 500px server thumbnails
    // don't each consume ~1MB RGBA in the image cache.
    if (isCloudOnly && remote != null && isServerReady) {
      return ResizeImage(
        ExtendedNetworkImageProvider(
          remote!.thumbnailUrl(),
          cache: true,
          cacheKey: remote!.path.replaceAll('/', '_'),
        ),
        width: 200,
        height: 200,
        policy: ResizeImagePolicy.fit,
      );
    }
    try {
      if (_thumbnailData != null && _thumbnailData!.isNotEmpty) {
        if (_cachedThumbnailProvider != null &&
            identical(_thumbnailData, _cachedThumbnailDataRef)) {
          return _cachedThumbnailProvider!;
        }
        _cachedThumbnailDataRef = _thumbnailData;
        _cachedThumbnailProvider = MemoryImage(_thumbnailData!);
        return _cachedThumbnailProvider!;
      }
    } catch (e) {
      print(e);
    }
    return const AssetImage("assets/images/gray.jpg");
  }

  Future<Uint8List> thumbnailDataAsync() async {
    if (_thumbnailData != null) {
      return _thumbnailData!;
    }
    if (_thumbnailDataCompleter != null) {
      return _thumbnailDataCompleter!.future;
    }
    _thumbnailDataCompleter = Completer<Uint8List>();
    Uint8List? data;
    if (hasLocal && local != null) {
      data = await local!.thumbnailDataWithSize(
        const ThumbnailSize.square(200),
        quality: 80,
      );
    }
    if (hasRemote && remote != null) {
      data = await remote!.thumbnail();
    }
    if (data == null || data.isEmpty || !await isValidImage(data)) {
      final brokenData = await rootBundle.load("assets/images/gray.jpg");
      _thumbnailDataCompleter!.complete(brokenData.buffer.asUint8List());
      // Reset so next call retries the download instead of returning fallback forever
      _thumbnailDataCompleter = null;
      return brokenData.buffer.asUint8List();
    } else {
      _thumbnailDataCompleter!.complete(data);
      _thumbnailData = data;
      return data;
    }
  }

  Future<Uint8List> imageDataAsync() async {
    if (_data != null) {
      return _data!;
    }
    if (_dataAsyncCompleter != null) {
      return _dataAsyncCompleter!.future;
    }
    _dataAsyncCompleter = Completer<Uint8List>();
    Uint8List? data;
    try {
      if (hasLocal) {
        if (local!.type == AssetType.image) {
          data = await local!.originBytes;
        } else if (local!.type == AssetType.video) {
          data = await local!.thumbnailDataWithSize(
            const ThumbnailSize.square(800),
          );
        }
      }
      if (hasRemote) {
        if (!remote!.isVideo()) {
          data = await remote!.imageData();
        } else {
          data = await remote!.thumbnail();
        }
      }
    } catch (e) {
      print("Get image data failed: $e");
    }
    if (data == null || data.isEmpty) {
      final brokenData = await rootBundle.load("assets/images/broken.png");
      _dataAsyncCompleter!.complete(brokenData.buffer.asUint8List());
      _dataAsyncCompleter = null;
      return brokenData.buffer.asUint8List();
    } else {
      _dataAsyncCompleter!.complete(data);
      if (data.lengthInBytes <= _maxCachedImageBytes) {
        _data = data;
      } else {
        _dataAsyncCompleter = null;
      }
      return data;
    }
  }

  String path() {
    if (hasLocal) {
      if (localFile != null) {
        return localFile!.path;
      }
      if (local!.relativePath == null) {
        return "unknown";
      }
      return "${local!.relativePath!}${local!.title}";
    }
    if (hasRemote) {
      return remote!.path;
    }
    return "";
  }

  Future<void> delete() async {
    if (hasLocal && (Platform.isAndroid || Platform.isIOS)) {
      await PhotoManager.editor.deleteWithIds([local!.id]);
    }
    if (hasRemote) {
      final rsp = await storage.cli.moveToTrash(
        MoveToTrashRequest(paths: [remote!.path]),
      );
      if (!rsp.success) {
        throw Exception("move to trash failed: ${rsp.message}");
      }
    }
  }

  AssetEntity? getLocal() {
    return local;
  }

  bool _isInfoReaded = false;
  bool _isSizeInfoReadedFinished = false;
  bool _isExifInfoReadedFinished = false;

  bool isInfoReady() {
    return _isSizeInfoReadedFinished && _isExifInfoReadedFinished;
  }

  Future<void> readInfoFromData() async {
    if (_isInfoReaded) {
      return;
    }
    _isInfoReaded = true;
    final data = await imageDataAsync();
    final pending = <Future<void>>[];
    if (isLocal()) {
      imageWidth = getLocal()!.width;
      imageHeight = getLocal()!.height;
      imageSize = data.length / 1024 / 1024;
      _isSizeInfoReadedFinished = true;
    } else {
      pending.add(compute(img.decodeImage, data).then((image) {
        if (image != null) {
          imageWidth = image.width;
          imageHeight = image.height;
          imageSize = data.length / 1024 / 1024;
        }
        _isSizeInfoReadedFinished = true;
      }));
      _isSizeInfoReadedFinished = true;
    }
    pending.add(compute(readExifFromBytes, data).then((exifData) {
      if (exifData.isEmpty) {
        print("No Exif data found");
      } else {
        for (String key in exifData.keys) {
          // print("$key: ${exifData[key]!.printable}");
          switch (key) {
            case 'Image Make':
              make = exifData[key]!.toString();
              break;
            case 'Image Model':
              model = exifData[key]!.toString();
              break;
            case 'Image DateTime':
              final v = exifData[key]!.toString();
              if (v != "") {
                try {
                  DateTime dateTime = DateTime.parse(
                    v.replaceAll(':', '').replaceAll(' ', 'T'),
                  );
                  DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
                  date = dateFormat.format(dateTime);
                } catch (e) {
                  print(e);
                }
              }
              break;
            case 'EXIF ISOSpeedRatings':
              iSO = exifData[key]!.toString();
              break;
            case 'EXIF ExposureTime':
              exposureTime = exifData[key]!.toString();
              break;
            case 'EXIF FNumber':
              try {
                final v = exifData[key]!.toString();
                List<String> parts = v.split('/');

                int numerator = int.parse(parts[0]);
                int denominator = int.parse(parts[1]);

                double value = numerator / denominator;
                fNumber = value.toStringAsFixed(1);
              } catch (e) {
                print(e);
              }
              break;
            case "EXIF FocalLength":
              try {
                final v = exifData[key]!.toString();
                List<String> parts = v.split('/');

                int numerator = int.parse(parts[0]);
                int denominator = int.parse(parts[1]);
                double value = numerator / denominator;
                focalLength = value.toStringAsFixed(2);
              } catch (e) {
                print(e);
              }
              break;
            default:
              break;
          }
        }
      }
      _isExifInfoReadedFinished = true;
    }));
    Future.wait(pending).whenComplete(() => _releaseFullImageBytes(data));
  }

  @override
  Future<Asset> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<Asset>(this);
  }

  @override
  ImageStreamCompleter loadImage(Asset key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _resolveCodec(key, decode),
      scale: 1,
      informationCollector: () sync* {
        yield ErrorDescription('Image provider: ${describeIdentity(key)}');
      },
    );
  }

  Future<ui.Codec> _resolveCodec(Asset key, ImageDecoderCallback decode) async {
    Uint8List data = await imageDataAsync();
    if (data.isEmpty) {
      data = await thumbnailDataAsync();
    }
    if (data.isEmpty) {
      data = await _loadFallbackImageData();
    }
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(data);
      _releaseFullImageBytes(data);
      // Going through `decode` (instead of `ui.instantiateImageCodec`) lets
      // Flutter honor cacheWidth/cacheHeight on the consuming Image widget,
      // capping decoded pixel buffers (e.g. a 12MP HEIC otherwise allocates
      // ~48MB RGBA per frame and overruns the iOS memory watermark).
      return await decode(buffer);
    } catch (e) {
      print(e);
    }
    final fallback = await _loadFallbackImageData();
    final fallbackBuffer = await ui.ImmutableBuffer.fromUint8List(fallback);
    return await decode(fallbackBuffer);
  }

  // Drops the cached original-image byte buffer once a consumer is done with
  // it. The decoded ui.Image lives in Flutter's image cache (capped via
  // PaintingBinding.imageCache); keeping the raw HEIC/JPEG bytes around as
  // well meant every viewed photo retained its full payload, exhausting the
  // iOS 3GB memory watermark after scrolling through enough photos.
  void _releaseFullImageBytes(Uint8List consumed) {
    if (identical(_data, consumed)) {
      _data = null;
    }
  }

  Future<Uint8List> _loadFallbackImageData() async {
    ByteData data = await rootBundle.load("assets/images/gray.jpg");
    return data.buffer.asUint8List();
  }

  @override
  String toString() => 'Asset(local: $local, remote: $remote)';
}

Future<ImageInfo> loadFallbackImage(String path) async {
  final Completer<ImageInfo> completer = Completer();
  final ImageProvider provider = AssetImage(path);
  final ImageStream stream = provider.resolve(ImageConfiguration.empty);
  final listener = ImageStreamListener((ImageInfo info, bool _) {
    if (!completer.isCompleted) {
      completer.complete(info);
    }
  });

  stream.addListener(listener);
  completer.future.then((_) => stream.removeListener(listener));

  return completer.future;
}

Future<bool> isValidImage(Uint8List imageData) async {
  try {
    final codec = await ui.instantiateImageCodec(imageData);
    codec.dispose();
    return true;
  } catch (e) {
    return false;
  }
}
