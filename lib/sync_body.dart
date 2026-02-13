import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:img_syncer/asset.dart';
import 'package:img_syncer/background_sync_route.dart';
import 'package:img_syncer/event_bus.dart';
import 'package:img_syncer/storage/storage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:img_syncer/state_model.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:img_syncer/choose_album_route.dart';
import 'package:img_syncer/setting_storage_route.dart';
import 'package:img_syncer/global.dart';
import 'package:img_syncer/theme.dart';

class SyncBody extends StatefulWidget {
  const SyncBody({
    Key? key,
    required this.localFolder,
  }) : super(key: key);

  final String localFolder;

  @override
  SyncBodyState createState() => SyncBodyState();
}

class SyncBodyState extends State<SyncBody> {
  final ScrollController _scrollController = ScrollController();
  final _scrollSubject = PublishSubject<double>();

  @protected
  int pageSize = 20;
  List<Asset> all = [];
  bool syncing = false;
  bool _needStopSync = false;

  double scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    getPhotos();
    _scrollSubject.stream
        .debounceTime(const Duration(milliseconds: 150))
        .listen((scrollPosition) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 1500) {}
      setState(() {
        scrollOffset = scrollPosition;
      });
    });
    _scrollController.addListener(() {
      _scrollSubject.add(_scrollController.position.pixels);
    });
  }

  @override
  void didUpdateWidget(SyncBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (all.isEmpty) {
      getPhotos();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _scrollSubject.close();
  }

  Completer<bool>? _isGettingPhotos;
  Future<void> getPhotos() async {
    if (_isGettingPhotos != null) {
      await _isGettingPhotos!.future;
      return;
    }
    _isGettingPhotos = Completer();
    all.clear();
    final re = await requestPermission();
    if (!re) return;
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common, hasAll: true);
    for (var path in paths) {
      if (path.name == settingModel.localFolder) {
        final newpath = await path.fetchPathProperties(
            filterOptionGroup: FilterOptionGroup(
          orders: [
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: false,
            ),
          ],
        ));
        int assetOffset = 0;
        int assetPageSize = 300;
        while (true) {
          final List<AssetEntity> assets = await newpath!.getAssetListRange(
              start: assetOffset, end: assetOffset + assetPageSize);
          if (assets.isEmpty) {
            break;
          }
          for (var i = 0; i < assets.length; i++) {
            all.add(Asset(local: assets[i]));
          }
          assetOffset += assetPageSize;
        }
        break;
      }
    }
    setState(() {});
    _isGettingPhotos!.complete(true);
    _isGettingPhotos = null;
  }

  Widget settingRows() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.folder_outlined, color: colorScheme.primary),
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
            leading: Icon(Icons.cloud_outlined, color: colorScheme.primary),
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
          if (Platform.isAndroid) ...[
            const Divider(height: 1, indent: 56),
            ListTile(
              leading:
                  Icon(Icons.cloud_sync_outlined, color: colorScheme.primary),
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
          ],
        ],
      ),
    );
  }

  void syncPhotos() async {
    _needStopSync = false;
    if (syncing) {
      return;
    }
    setState(() {
      syncing = true;
    });
    Map ids = {};
    for (final id in stateModel.notSyncedIDs) {
      ids[id] = true;
    }
    for (var asset in all) {
      if (_needStopSync) {
        break;
      }
      final id = asset.local!.id;
      if (ids[id] != true) {
        continue;
      }
      try {
        await storage.uploadAssetEntity(asset.local!);
      } catch (e) {
        print(e);
        SnackBarManager.showSnackBar("${l10n.uploadFailed}: $e");
        continue;
      }
    }
    setState(() {
      syncing = false;
    });
    eventBus.fire(RemoteRefreshEvent());
  }

  void stopSync() {
    _needStopSync = true;
  }

  Widget _buildSyncProgressIndicator() {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.onPrimaryContainer),
        strokeWidth: 2,
      ),
    );
  }

  Widget columnBuilder(BuildContext context, StateModel model, Widget? child) {
    final colorScheme = Theme.of(context).colorScheme;
    Map notUploadedIds = {};
    for (final id in stateModel.notSyncedIDs) {
      notUploadedIds[id] = true;
    }
    List<Widget> listChildren = [];
    double currentScrollOffset = 0;
    for (var asset in all) {
      final id = asset.local!.id;
      if (notUploadedIds[id] != true) {
        continue;
      }
      final totalHeight = MediaQuery.of(context).size.height;
      bool needLoadThumbnail = false;
      if (currentScrollOffset > scrollOffset - (2 * totalHeight) &&
          currentScrollOffset < scrollOffset + (3 * totalHeight)) {
        needLoadThumbnail = true;
        if (!asset.loadThumbnailFinished()) {
          asset.thumbnailDataAsync().then((value) => setState(() {}));
        }
        if (!asset.hasGotTitle()) {
          asset.getLocalFile().then((value) => setState(() {}));
        }
      }
      Widget child = Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: needLoadThumbnail && asset.loadThumbnailFinished()
                  ? Image(image: asset.thumbnailProvider(), fit: BoxFit.cover)
                  : Container(color: colorScheme.surfaceContainerHighest),
            ),
          ),
          title: Text(
            asset.name()!,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: needLoadThumbnail
              ? Consumer<StateModel>(
                  builder: (context, stateModel, child) {
                    final percent =
                        stateModel.getUploadPercent(asset.local!.id);
                    if (percent > 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: LinearProgressIndicator(
                          value: percent,
                          color: colorScheme.primary,
                        ),
                      );
                    }
                    if (stateModel.notSyncedIDs.contains(asset.local!.id)) {
                      return Text(l10n.notUploaded,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant));
                    }
                    return Text(
                      l10n.uploaded,
                      style: TextStyle(color: colorScheme.primary),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
      );
      listChildren.add(child);
      currentScrollOffset += 80;
    }

    final bool isBusy = syncing ||
        model.refreshingUnsynchronized ||
        model.isDownloading() ||
        model.isUploading();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          l10n.cloudSync,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: model.refreshingUnsynchronized
                ? _buildSyncProgressIndicator()
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: isBusy ? null : () => refreshUnsynchronized(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "sync",
        onPressed: () {
          if (!settingModel.isRemoteStorageSetted) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingStorageRoute(),
                ));
            return;
          }
          if (syncing) {
            stopSync();
          } else if (!isBusy) {
            syncPhotos();
          }
        },
        icon: syncing
            ? _buildSyncProgressIndicator()
            : Icon(syncing ? Icons.stop : Icons.sync),
        label: Text(syncing ? l10n.stop : l10n.sync),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          settingRows(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Text(
                  l10n.unsynchronizedPhotos,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  "(${listChildren.length})",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!settingModel.isRemoteStorageSetted)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.setRemoteStroage,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            )
          else if (model.refreshingUnsynchronized && listChildren.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.refreshingPleaseWait,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            )
          else if (listChildren.isEmpty && settingModel.isRemoteStorageSetted)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done_outlined,
                        size: 48, color: colorScheme.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.allSynced,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            )
          else
            Flexible(
                child: ListView(
              controller: _scrollController,
              children: listChildren,
            )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<SettingModel>(context, listen: true).addListener(() {
      getPhotos();
    });
    return Consumer<StateModel>(
      builder: columnBuilder,
    );
  }

  Future<void> refreshUnsynchronized() async {
    if (!settingModel.isRemoteStorageSetted) {
      stateModel.setNotSyncedPhotos([]);
      return;
    }
    await Future.wait([
      refreshUnsynchronizedPhotos(),
      getPhotos(),
    ]);
  }
}
