import 'dart:async';

import 'package:lumina/state_model.dart';
import 'package:lumina/sync_engine.dart';
import 'package:lumina/sync_state_persistence.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/event_bus.dart';
import 'package:lumina/global.dart';

Timer? autoSyncTimer;

Future<void> reloadAutoSyncTimer() async {
  if (autoSyncTimer != null) {
    autoSyncTimer!.cancel();
  }
  final prefs = await SharedPreferences.getInstance();
  final backgroundSyncEnable = prefs.getBool('backgroundSyncEnabled') ?? false;
  if (!backgroundSyncEnable) return;
  final backgroundSyncInterval =
      Duration(minutes: prefs.getInt('backgroundSyncInterval') ?? 60 * 12);
  print("backgroundSyncInterval: $backgroundSyncInterval");
  autoSyncTimer = Timer.periodic(backgroundSyncInterval, (timer) async {
    print("start auto sync");
    if (settingModel.localFolder == "" || !settingModel.isRemoteStorageSetted) {
      return;
    }
    if (stateModel.isUploading() || stateModel.isDownloading()) return;

    final persistence = SyncStatePersistence(prefs);
    if (persistence.isSyncInProgress) return;

    final wifiOnly = prefs.getBool('backgroundSyncWifiOnly') ?? true;
    final engine = SyncEngine(
      grpcPort: grpcPort,
      httpPort: httpPort,
      localFolder: settingModel.localFolder,
      wifiOnly: wifiOnly,
      onProgress: (progress) {
        if (progress.total > 0) {
          stateModel.startSync(progress.total);
          stateModel.advanceSync(progress.currentFile);
        }
      },
    );

    await persistence.setSyncInProgress(true);
    try {
      final pendingIds = persistence.pendingSyncQueue;
      final result = await engine.syncPhotos(
        pendingIds: pendingIds.isNotEmpty ? pendingIds : null,
      );
      await persistence.clearPendingSyncQueue();
      await persistence
          .setLastSyncTimestamp(DateTime.now().millisecondsSinceEpoch);
      print(
          "auto sync done: uploaded=${result.uploaded}, failed=${result.failed}");
    } catch (e) {
      print("auto sync error: $e");
    } finally {
      await persistence.setSyncInProgress(false);
      stateModel.finishSync();
      eventBus.fire(RemoteRefreshEvent());
    }
  });
}
