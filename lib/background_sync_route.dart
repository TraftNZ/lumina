import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumina/background_sync_service.dart';
import 'package:lumina/sync_state_persistence.dart';
import 'package:lumina/sync_timer.dart';
import 'package:lumina/global.dart';
import 'package:lumina/theme.dart';
import 'package:permission_handler/permission_handler.dart';

class BackgroundSyncSettingRoute extends StatefulWidget {
  const BackgroundSyncSettingRoute({Key? key}) : super(key: key);

  @override
  _BackgroundSyncSettingRouteState createState() =>
      _BackgroundSyncSettingRouteState();
}

class _BackgroundSyncSettingRouteState
    extends State<BackgroundSyncSettingRoute> {
  bool _backgroundSyncEnabled = false;
  bool _backgroundSyncWifiOnly = true;
  Duration _backgroundSyncInterval = const Duration(minutes: 60);
  List<AssetPathEntity> albums = [];
  String? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final persistence = SyncStatePersistence(prefs);
    final lastTs = persistence.lastSyncTimestamp;
    setState(() {
      _backgroundSyncEnabled = prefs.getBool('backgroundSyncEnabled') ?? false;
      _backgroundSyncWifiOnly = prefs.getBool('backgroundSyncWifiOnly') ?? true;
      _backgroundSyncInterval =
          Duration(minutes: prefs.getInt('backgroundSyncInterval') ?? 60);
      if (lastTs != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(lastTs);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 1) {
          _lastSyncTime = 'Just now';
        } else if (diff.inHours < 1) {
          _lastSyncTime = '${diff.inMinutes}m ago';
        } else if (diff.inDays < 1) {
          _lastSyncTime = '${diff.inHours}h ago';
        } else {
          _lastSyncTime = '${diff.inDays}d ago';
        }
      }
    });
    final re = await requestPermission();
    if (!re) return;
    albums = await PhotoManager.getAssetPathList(type: RequestType.common);
    for (var path in albums) {
      if (path.name == 'Recent') {
        albums.remove(path);
        break;
      }
    }
    setState(() {});
  }

  Future<void> _onToggleBackgroundSync(bool value) async {
    if (value && Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backgroundSyncEnabled', value);
    setState(() {
      _backgroundSyncEnabled = value;
    });

    if (value) {
      await BackgroundSyncService.scheduleSync(
        intervalMinutes: _backgroundSyncInterval.inMinutes,
        wifiOnly: _backgroundSyncWifiOnly,
      );
    } else {
      await BackgroundSyncService.cancelScheduledSync();
    }

    reloadAutoSyncTimer();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(l10n.backgroundSync,
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary:
                      Icon(Icons.sync_outlined, color: colorScheme.primary),
                  title: Text(l10n.enableBackgroundSync),
                  subtitle: _lastSyncTime != null
                      ? Text('Last sync: $_lastSyncTime')
                      : null,
                  value: _backgroundSyncEnabled,
                  onChanged: _onToggleBackgroundSync,
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary:
                      Icon(Icons.wifi_outlined, color: colorScheme.primary),
                  title: Text(l10n.syncOnlyOnWifi),
                  value: _backgroundSyncWifiOnly,
                  onChanged: (value) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('backgroundSyncWifiOnly', value);
                    setState(() {
                      _backgroundSyncWifiOnly = value;
                    });
                    if (_backgroundSyncEnabled) {
                      await BackgroundSyncService.scheduleSync(
                        intervalMinutes: _backgroundSyncInterval.inMinutes,
                        wifiOnly: value,
                      );
                    }
                    reloadAutoSyncTimer();
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.timer_outlined,
                      color: colorScheme.primary),
                  title: Text(l10n.syncInterval),
                  trailing: DropdownButton<Duration>(
                    value: _backgroundSyncInterval,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(
                        value: const Duration(minutes: 10),
                        child: Text('10 ${l10n.minite}'),
                      ),
                      DropdownMenuItem(
                        value: const Duration(hours: 1),
                        child: Text('1 ${l10n.hour}'),
                      ),
                      DropdownMenuItem(
                        value: const Duration(hours: 3),
                        child: Text('3 ${l10n.hour}'),
                      ),
                      DropdownMenuItem(
                        value: const Duration(hours: 6),
                        child: Text('6 ${l10n.hour}'),
                      ),
                      DropdownMenuItem(
                        value: const Duration(hours: 12),
                        child: Text('12 ${l10n.hour}'),
                      ),
                      DropdownMenuItem(
                        value: const Duration(days: 1),
                        child: Text('1 ${l10n.day}'),
                      ),
                      DropdownMenuItem(
                        value: const Duration(days: 3),
                        child: Text('3 ${l10n.day}'),
                      ),
                      DropdownMenuItem(
                        value: const Duration(days: 7),
                        child: Text('1 ${l10n.week}'),
                      ),
                    ],
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt(
                          'backgroundSyncInterval', value!.inMinutes);
                      setState(() {
                        _backgroundSyncInterval = value;
                      });
                      if (_backgroundSyncEnabled) {
                        await BackgroundSyncService.scheduleSync(
                          intervalMinutes: value.inMinutes,
                          wifiOnly: _backgroundSyncWifiOnly,
                        );
                      }
                      reloadAutoSyncTimer();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              child: ListTile(
                leading: Icon(Icons.play_arrow_outlined,
                    color: colorScheme.primary),
                title: const Text('Sync Now'),
                subtitle: const Text('Start an immediate background sync'),
                onTap: () async {
                  await BackgroundSyncService.startImmediateSync();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Background sync started')),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
