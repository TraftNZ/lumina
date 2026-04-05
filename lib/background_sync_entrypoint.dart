import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/sync_engine.dart';
import 'package:lumina/sync_state_persistence.dart';

@pragma('vm:entry-point')
void backgroundSyncEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.traftai.lumina/BackgroundSync');

  final prefs = await SharedPreferences.getInstance();
  final persistence = SyncStatePersistence(prefs);

  if (persistence.isSyncInProgress) {
    await channel.invokeMethod('syncComplete', {'success': true, 'message': 'Already running'});
    return;
  }

  final localFolder = prefs.getString('localFolder') ?? '';
  if (localFolder.isEmpty) {
    await channel.invokeMethod('syncComplete', {'success': false, 'message': 'No local folder'});
    return;
  }

  final wifiOnly = prefs.getBool('backgroundSyncWifiOnly') ?? true;
  if (wifiOnly) {
    final connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.wifi)) {
      await channel.invokeMethod('syncComplete', {'success': false, 'message': 'No WiFi'});
      return;
    }
  }

  int? grpcPort;
  int? httpPort;

  final savedGrpc = persistence.activeGrpcPort;
  final savedHttp = persistence.activeHttpPort;

  if (savedGrpc != null && savedHttp != null) {
    try {
      final socket = await Socket.connect('127.0.0.1', savedGrpc,
          timeout: const Duration(seconds: 3));
      socket.destroy();
      grpcPort = savedGrpc;
      httpPort = savedHttp;
    } catch (_) {}
  }

  if (grpcPort == null || httpPort == null) {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final appCacheDir = await getApplicationCacheDirectory();
      final portsStr = await channel.invokeMethod('RunGrpcServer', {
        'dataDir': appDocDir.path,
        'cacheDir': appCacheDir.path,
      }) as String;
      final ports = portsStr.split(',');
      if (ports.length != 2) {
        await channel.invokeMethod('syncComplete', {
          'success': false,
          'message': 'Server start failed',
        });
        return;
      }
      grpcPort = int.parse(ports[0]);
      httpPort = int.parse(ports[1]);
      await persistence.setActivePorts(grpcPort, httpPort);
    } catch (e) {
      await channel.invokeMethod('syncComplete', {
        'success': false,
        'message': 'Server start error: $e',
      });
      return;
    }
  }

  final cancellationToken = CancellationToken();

  channel.setMethodCallHandler((call) async {
    if (call.method == 'cancelSync') {
      cancellationToken.cancel();
    }
  });

  final engine = SyncEngine(
    grpcPort: grpcPort,
    httpPort: httpPort,
    localFolder: localFolder,
    wifiOnly: wifiOnly,
    cancellationToken: cancellationToken,
    onProgress: (progress) {
      channel.invokeMethod('updateNotification', {
        'total': progress.total,
        'completed': progress.completed,
        'currentFile': progress.currentFile,
      });
    },
  );

  await persistence.setSyncInProgress(true);
  try {
    final pendingIds = persistence.pendingSyncQueue;
    final result = await engine.syncPhotos(
      pendingIds: pendingIds.isNotEmpty ? pendingIds : null,
    );
    await persistence.clearPendingSyncQueue();
    await persistence.setLastSyncTimestamp(DateTime.now().millisecondsSinceEpoch);
    await channel.invokeMethod('syncComplete', {
      'success': true,
      'uploaded': result.uploaded,
      'failed': result.failed,
      'message': 'Sync complete: ${result.uploaded} uploaded, ${result.failed} failed',
    });
  } catch (e) {
    await channel.invokeMethod('syncComplete', {
      'success': false,
      'message': 'Sync error: $e',
    });
  } finally {
    await persistence.setSyncInProgress(false);
  }
}
