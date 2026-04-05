import 'dart:io';
import 'package:flutter/services.dart';

class BackgroundSyncService {
  static const _channel = MethodChannel('com.traftai.lumina/BackgroundSync');

  static Future<void> scheduleSync({
    required int intervalMinutes,
    required bool wifiOnly,
  }) async {
    await _channel.invokeMethod('scheduleSync', {
      'intervalMinutes': intervalMinutes,
      'wifiOnly': wifiOnly,
    });
  }

  static Future<void> cancelScheduledSync() async {
    await _channel.invokeMethod('cancelScheduledSync');
  }

  static Future<void> startImmediateSync() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod('startBackgroundSync');
    }
  }

  static Future<bool> isSyncRunning() async {
    final result = await _channel.invokeMethod<bool>('isSyncRunning');
    return result ?? false;
  }
}
