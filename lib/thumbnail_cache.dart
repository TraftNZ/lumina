import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class ThumbnailCache {
  static ThumbnailCache? _instance;
  Directory? _cacheDir;

  ThumbnailCache._();

  static ThumbnailCache get instance {
    _instance ??= ThumbnailCache._();
    return _instance!;
  }

  Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final tempDir = await getTemporaryDirectory();
    _cacheDir = Directory('${tempDir.path}/thumb_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  String _cacheKey(String path) {
    // Simple hash using hashCode — sufficient for cache file names
    final hash = path.hashCode.toUnsigned(64).toRadixString(16);
    return hash;
  }

  Future<Uint8List?> get(String path) async {
    try {
      final dir = await _getCacheDir();
      final file = File('${dir.path}/${_cacheKey(path)}');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  Future<void> put(String path, Uint8List data) async {
    try {
      final dir = await _getCacheDir();
      final file = File('${dir.path}/${_cacheKey(path)}');
      await file.writeAsBytes(data, flush: true);
    } catch (_) {}
  }
}
