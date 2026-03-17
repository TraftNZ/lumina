import 'package:crypto/crypto.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches SHA-256 hashes of asset file content to avoid re-computing on every
/// sync check. Invalidates when the asset's modifiedDateTime changes.
class HashCache {
  HashCache._();
  static final HashCache instance = HashCache._();

  static const _prefix = 'hash_cache_';
  static const _modPrefix = 'hash_mod_';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Returns the cached SHA-256 hex string for the asset, computing and caching
  /// it if not present or if the asset has been modified since last computation.
  Future<String> getHash(AssetEntity asset) async {
    final prefs = await _getPrefs();
    final key = '$_prefix${asset.id}';
    final modKey = '$_modPrefix${asset.id}';
    final modMs = asset.modifiedDateTime.millisecondsSinceEpoch.toString();

    final cachedMod = prefs.getString(modKey);
    if (cachedMod == modMs) {
      final cached = prefs.getString(key);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    // Compute hash from file content
    final file = await asset.originFile;
    if (file == null) {
      throw Exception('Cannot read asset file for hashing');
    }
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString();

    // Persist to cache
    await prefs.setString(key, hash);
    await prefs.setString(modKey, modMs);

    return hash;
  }
}
