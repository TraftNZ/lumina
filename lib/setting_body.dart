import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:img_syncer/choose_album_route.dart';
import 'package:img_syncer/setting_storage_route.dart';
import 'package:img_syncer/background_sync_route.dart';
import 'package:img_syncer/theme.dart';
import 'package:img_syncer/global.dart';
import 'package:img_syncer/proto/img_syncer.pbgrpc.dart';
import 'package:img_syncer/storage/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingBody extends StatefulWidget {
  const SettingBody({Key? key}) : super(key: key);

  @override
  State<SettingBody> createState() => _SettingBodyState();
}

class _SettingBodyState extends State<SettingBody> {
  bool _hasPinSet = false;
  String _cacheSizeStr = '...';
  bool _isRebuilding = false;

  @override
  void initState() {
    super.initState();
    _checkPin();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    if (!isServerReady) return;
    try {
      final stats = await storage.cli.getIndexStats(GetIndexStatsRequest());
      if (stats.success && mounted) {
        setState(() {
          _cacheSizeStr = _formatBytes(stats.cacheSizeBytes.toInt());
        });
      }
    } catch (_) {}
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _clearCache() async {
    try {
      final rsp =
          await storage.cli.clearThumbnailCache(ClearThumbnailCacheRequest());
      if (rsp.success) {
        SnackBarManager.showSnackBar(
            l10n.cacheCleared(_formatBytes(rsp.freedBytes.toInt())));
        _loadCacheStats();
      }
    } catch (e) {
      SnackBarManager.showSnackBar(e.toString());
    }
  }

  Future<void> _rebuildIndex() async {
    if (_isRebuilding) return;
    setState(() => _isRebuilding = true);
    try {
      final responses = storage.cli.rebuildIndex(RebuildIndexRequest());
      int count = 0;
      await for (final rsp in responses) {
        count = rsp.totalFound;
        if (rsp.isFinished) break;
      }
      SnackBarManager.showSnackBar(l10n.indexRebuilt(count));
    } catch (e) {
      SnackBarManager.showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isRebuilding = false);
    }
  }

  Future<void> _checkPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('locked_folder_pin');
    if (mounted) setState(() => _hasPinSet = pin != null && pin.isNotEmpty);
  }

  void _showSetPinDialog() {
    String firstPin = '';
    final controller1 = TextEditingController();
    final controller2 = TextEditingController();
    bool isConfirmStep = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isConfirmStep ? l10n.confirmPin : l10n.enterNewPin),
          content: TextField(
            controller: isConfirmStep ? controller2 : controller1,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: isConfirmStep ? l10n.confirmPin : l10n.enterNewPin,
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                if (!isConfirmStep) {
                  final pin = controller1.text;
                  if (pin.length < 4) return;
                  firstPin = pin;
                  controller2.clear();
                  setDialogState(() => isConfirmStep = true);
                } else {
                  final confirmPin = controller2.text;
                  if (confirmPin != firstPin) {
                    SnackBarManager.showSnackBar(l10n.pinMismatch);
                    return;
                  }
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('locked_folder_pin', firstPin);
                  if (mounted) {
                    Navigator.pop(ctx);
                    SnackBarManager.showSnackBar(l10n.pinSet);
                    _checkPin();
                  }
                }
              },
              child: Text(l10n.yes),
            ),
          ],
        ),
      ),
    );
  }

  void _removePin() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removePin),
        content: Text('${l10n.removePin}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('locked_folder_pin');
              Navigator.pop(ctx);
              SnackBarManager.showSnackBar(l10n.pinRemoved);
              _checkPin();
            },
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          l10n.settings,
          style: textTheme.headlineMedium,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.md, bottom: AppSpacing.xs),
            child: Text(
              l10n.storageSetting,
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.folder_outlined, color: colorScheme.primary),
                  title: Text(l10n.localFolder),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChooseAlbumRoute()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading:
                      Icon(Icons.cloud_outlined, color: colorScheme.primary),
                  title: Text(l10n.cloudStorage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingStorageRoute(),
                        ));
                  },
                ),
              ],
            ),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.md, bottom: AppSpacing.xs),
              child: Text(
                l10n.sync,
                style:
                    textTheme.titleSmall?.copyWith(color: colorScheme.primary),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.cloud_sync_outlined,
                    color: colorScheme.primary),
                title: Text(l10n.backgroundSync),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const BackgroundSyncSettingRoute()),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.md, bottom: AppSpacing.xs),
            child: Text(
              l10n.security,
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.lock_outline, color: colorScheme.primary),
                  title: Text(l10n.lockedFolderPin),
                  subtitle: Text(
                    _hasPinSet ? l10n.changePin : l10n.lockedFolderPinDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _hasPinSet
                      ? IconButton(
                          icon: Icon(Icons.delete_outline, color: colorScheme.error),
                          onPressed: _removePin,
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _showSetPinDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.md, bottom: AppSpacing.xs),
            child: Text(
              l10n.cacheManagement,
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.photo_size_select_large_outlined,
                      color: colorScheme.primary),
                  title: Text(l10n.thumbnailCache),
                  subtitle: Text(_cacheSizeStr),
                  trailing: TextButton(
                    onPressed: _clearCache,
                    child: Text(l10n.clearCache),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.refresh_outlined,
                      color: colorScheme.primary),
                  title: Text(l10n.rebuildIndex),
                  subtitle: _isRebuilding
                      ? Text(l10n.rebuildingIndex)
                      : null,
                  trailing: _isRebuilding
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isRebuilding ? null : _rebuildIndex,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.md, bottom: AppSpacing.xs),
            child: Text(
              l10n.about,
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.info_outline, color: colorScheme.primary),
                  title: const Text('Lumina'),
                  subtitle: Text('${l10n.version} 1.0.0'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
