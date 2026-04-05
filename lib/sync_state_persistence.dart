import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SyncStatePersistence {
  static const _lastSyncTimestampKey = 'lastSyncTimestamp';
  static const _pendingSyncQueueKey = 'pendingSyncQueue';
  static const _syncInProgressKey = 'syncInProgress';
  static const _syncInProgressTimestampKey = 'syncInProgressTimestamp';
  static const _activeGrpcPortKey = 'activeGrpcPort';
  static const _activeHttpPortKey = 'activeHttpPort';
  static const _staleThreshold = Duration(hours: 1);

  final SharedPreferences _prefs;

  SyncStatePersistence(this._prefs);

  static Future<SyncStatePersistence> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SyncStatePersistence(prefs);
  }

  int? get lastSyncTimestamp => _prefs.getInt(_lastSyncTimestampKey);

  Future<void> setLastSyncTimestamp(int epochMs) =>
      _prefs.setInt(_lastSyncTimestampKey, epochMs);

  List<String> get pendingSyncQueue {
    final json = _prefs.getString(_pendingSyncQueueKey);
    if (json == null) return [];
    return List<String>.from(jsonDecode(json));
  }

  Future<void> setPendingSyncQueue(List<String> ids) =>
      _prefs.setString(_pendingSyncQueueKey, jsonEncode(ids));

  Future<void> clearPendingSyncQueue() => _prefs.remove(_pendingSyncQueueKey);

  bool get isSyncInProgress {
    final inProgress = _prefs.getBool(_syncInProgressKey) ?? false;
    if (!inProgress) return false;
    final timestamp = _prefs.getInt(_syncInProgressTimestampKey) ?? 0;
    final age =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    if (age > _staleThreshold) {
      _prefs.setBool(_syncInProgressKey, false);
      return false;
    }
    return true;
  }

  Future<void> setSyncInProgress(bool value) async {
    await _prefs.setBool(_syncInProgressKey, value);
    if (value) {
      await _prefs.setInt(
          _syncInProgressTimestampKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  int? get activeGrpcPort => _prefs.getInt(_activeGrpcPortKey);
  int? get activeHttpPort => _prefs.getInt(_activeHttpPortKey);

  Future<void> setActivePorts(int grpcPort, int httpPort) async {
    await _prefs.setInt(_activeGrpcPortKey, grpcPort);
    await _prefs.setInt(_activeHttpPortKey, httpPort);
  }

  Future<void> clearActivePorts() async {
    await _prefs.remove(_activeGrpcPortKey);
    await _prefs.remove(_activeHttpPortKey);
  }
}
