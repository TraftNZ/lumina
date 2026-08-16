import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:synchronized/synchronized.dart';

/// Caches SHA-256 hashes of asset file content to avoid re-computing on every
/// sync check. Invalidates when the asset's modifiedDateTime changes.
///
/// Backed by an append-only log file rather than SharedPreferences. The cache
/// holds two entries per photo, and SharedPreferences is a whole-store
/// abstraction: every write re-serializes the entire backing store (full XML
/// rewrite on Android, plist flush on iOS) and the first read loads every key
/// into memory. A library-sized cache therefore made writes quadratic and
/// slowed every cold start, since `SharedPreferences.getInstance()` has to
/// materialize the whole store before it returns.
class HashCache {
  HashCache._();
  static final HashCache instance = HashCache._();

  static const _fileName = 'hash_cache.log';

  /// Keys written by the previous SharedPreferences-backed implementation.
  /// Prefixed with `flutter.`, the namespace the plugin stores under, because
  /// the purge goes through the platform store rather than the Dart wrapper.
  static const _legacyHashPrefix = 'flutter.hash_cache_';
  static const _legacyModPrefix = 'flutter.hash_mod_';
  static const _legacyPurgedKey = 'hashCacheLegacyPurged';

  /// Rewrite the log once superseded lines outnumber live entries by this
  /// much. Keeps the file from growing without bound as photos are edited.
  static const _compactSlack = 512;

  final Lock _lock = Lock();
  final Map<String, _HashEntry> _entries = <String, _HashEntry>{};
  final Map<String, Future<String>> _inFlight = <String, Future<String>>{};

  File? _file;
  int _lineCount = 0;
  bool _loaded = false;

  /// Loads the on-disk cache if it has not been read yet, so synchronous
  /// lookups through [cachedHash] can see previously computed hashes.
  Future<void> warmUp() => _ensureLoaded();

  /// Returns the already-known hash for [asset] without touching the file
  /// system, or null when it has never been hashed or has changed since.
  ///
  /// Gallery dedup runs synchronously during a rebuild and must not block on
  /// I/O; an absent hash simply falls back to filename matching.
  String? cachedHash(AssetEntity asset) {
    final cached = _entries[asset.id];
    if (cached == null) return null;
    if (cached.modMs != asset.modifiedDateTime.millisecondsSinceEpoch.toString()) {
      return null;
    }
    return cached.hash;
  }

  /// Returns the cached SHA-256 hex string for the asset, computing and caching
  /// it if not present or if the asset has been modified since last computation.
  Future<String> getHash(AssetEntity asset) async {
    await _ensureLoaded();

    final modMs = asset.modifiedDateTime.millisecondsSinceEpoch.toString();
    final cached = _entries[asset.id];
    if (cached != null && cached.modMs == modMs) {
      return cached.hash;
    }

    // Collapse concurrent requests for the same asset so a page containing
    // duplicates only reads the file once.
    final pending = _inFlight[asset.id];
    if (pending != null) return pending;

    final future = _computeAndStore(asset, modMs);
    _inFlight[asset.id] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(asset.id);
    }
  }

  Future<String> _computeAndStore(AssetEntity asset, String modMs) async {
    final file = await asset.originFile;
    if (file == null) {
      throw Exception('Cannot read asset file for hashing');
    }
    // Stream the file through the digest rather than readAsBytes(): originals
    // are routinely hundreds of megabytes (a 4K video far more), and buffering
    // whole files is what pushed the sync past the platform memory limit.
    final digest = await sha256.bind(file.openRead()).first;
    final hash = digest.toString();
    await _append(asset.id, modMs, hash);
    return hash;
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await _lock.synchronized(() async {
      if (_loaded) return;
      try {
        final dir = Directory(
            p.join((await getApplicationSupportDirectory()).path, 'lumina'));
        await dir.create(recursive: true);
        final file = File(p.join(dir.path, _fileName));
        _file = file;
        if (await file.exists()) {
          await for (final line in file
              .openRead()
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
            _parseLine(line);
          }
        }
      } catch (e) {
        // The log is a cache, not a source of truth. A truncated or unreadable
        // file just means we re-hash; it must never fail the sync.
        _entries.clear();
        _lineCount = 0;
      }
      _loaded = true;
    });
  }

  void _parseLine(String line) {
    if (line.isEmpty) return;
    final firstTab = line.indexOf('\t');
    if (firstTab < 0) return;
    final secondTab = line.indexOf('\t', firstTab + 1);
    if (secondTab < 0) return;
    // id goes last: it is the only field that may contain a separator.
    final id = line.substring(secondTab + 1);
    final hash = line.substring(firstTab + 1, secondTab);
    if (id.isEmpty || hash.isEmpty) return;
    _entries[id] = _HashEntry(line.substring(0, firstTab), hash);
    _lineCount++;
  }

  Future<void> _append(String id, String modMs, String hash) async {
    _entries[id] = _HashEntry(modMs, hash);
    await _lock.synchronized(() async {
      final file = _file;
      if (file == null) return;
      try {
        await file.writeAsString('$modMs\t$hash\t$id\n',
            mode: FileMode.append, flush: false);
        _lineCount++;
        if (_lineCount > _entries.length * 2 + _compactSlack) {
          await _compact(file);
        }
      } catch (e) {
        // Best-effort: a failed cache write only costs us a re-hash later.
      }
    });
  }

  Future<void> _compact(File file) async {
    final buffer = StringBuffer();
    _entries.forEach((id, entry) {
      buffer.write('${entry.modMs}\t${entry.hash}\t$id\n');
    });
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(buffer.toString(), flush: true);
    await tmp.rename(file.path);
    _lineCount = _entries.length;
  }

  /// One-time removal of the SharedPreferences-backed cache this class used to
  /// write. Left in place those keys make every unrelated preference write
  /// re-serialize a multi-megabyte store and slow every launch.
  ///
  /// Clears by prefix through the platform store, which is a single native
  /// call — removing the keys one at a time through [SharedPreferences] would
  /// rewrite the whole store once per key.
  static Future<void> purgeLegacyPrefsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_legacyPurgedKey) ?? false) return;

      final store = SharedPreferencesStorePlatform.instance;
      for (final prefix in const [_legacyHashPrefix, _legacyModPrefix]) {
        await store.clearWithParameters(
          ClearParameters(filter: PreferencesFilter(prefix: prefix)),
        );
      }
      // The wrapper caches the whole store in memory; drop the removed keys.
      await prefs.reload();
      await prefs.setBool(_legacyPurgedKey, true);
    } catch (e) {
      // Purging is opportunistic — it retries on the next launch.
    }
  }
}

class _HashEntry {
  final String modMs;
  final String hash;

  const _HashEntry(this.modMs, this.hash);
}
