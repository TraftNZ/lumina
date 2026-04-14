import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:lumina/proto/lumina.pb.dart';
import 'package:lumina/state_model.dart';
import 'package:lumina/storage/storage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:lumina/gallery_viewer_route.dart';
import 'package:lumina/asset.dart';
import 'package:lumina/event_bus.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/global.dart';
import 'package:lumina/setting_body.dart';
import 'package:lumina/theme.dart';
import 'package:lumina/year_detail_body.dart';
import 'package:lumina/month_detail_body.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:vibration/vibration.dart';
import 'package:local_auth/local_auth.dart';

enum GalleryViewMode { years, months, all }

class GalleryBody extends StatefulWidget {
  final GalleryViewMode viewMode;

  const GalleryBody({Key? key, this.viewMode = GalleryViewMode.all})
      : super(key: key);

  @override
  GalleryBodyState createState() => GalleryBodyState();
}

class GalleryBodyState extends State<GalleryBody>
    with AutomaticKeepAliveClientMixin {
  bool _showToTopBtn = false;
  bool _syncPanelExpanded = false;
  bool _isDeleting = false;
  @override
  bool get wantKeepAlive => true;
  final ScrollController _scrollController = ScrollController();
  final _scrollSubject = PublishSubject<double>();
  int columCount = 3;

  // Keyed by Asset.stableId() so selection survives list reorders/refreshes.
  final Set<String> _selectedIds = {};

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getPhotos();
    });
    assetModel.addListener(_scheduleAutoSync);
    _scrollSubject.stream
        .debounceTime(const Duration(milliseconds: 150))
        .listen((_) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 4000) {
        getPhotos();
      }
    });
    _scrollController.addListener(() {
      _scrollSubject.add(_scrollController.position.pixels);
      if (_scrollController.offset > 1000 && !_showToTopBtn) {
        setState(() {
          _showToTopBtn = true;
        });
      } else if (_scrollController.offset <= 1000 && _showToTopBtn) {
        setState(() {
          _showToTopBtn = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(GalleryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    assetModel.removeListener(_scheduleAutoSync);
    _autoSyncTimer?.cancel();
    _scrollController.dispose();
    _scrollSubject.close();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void refresh() {
    if (stateModel.isDownloading() || stateModel.isUploading()) {
      return;
    }
    if (assetModel.isRefreshing) {
      return;
    }
    // Fire-and-forget: refresh in background, no blocking spinner
    assetModel.refreshAll();
  }

  void getPhotos() {
    assetModel.getMorePhotos();
  }

  void toggleSelection(String id) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator!) {
        Vibration.vibrate(duration: 10);
      }
    }
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    stateModel.setSelectionMode(_selectedIds.isNotEmpty);
    setState(() {});
  }

  void clearSelection() {
    _selectedIds.clear();
    stateModel.setSelectionMode(false);
    setState(() {});
  }

  void _scheduleAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (stateModel.isSyncing) return;
      if (!settingModel.isRemoteStorageSetted) return;
      if (!isServerReady) return;
      if (assetModel.localGetting != null) return;
      if (assetModel.remoteGetting != null) return;
      // Wait until remote photos have been fetched at least once
      if (assetModel.remoteAssets.isEmpty && assetModel.remoteHasMore) return;
      final unsynced = assetModel.getUnifiedAssets()
          .where((a) => a.hasLocal && !a.hasRemote)
          .toList();
      if (unsynced.isEmpty) return;
      _runAutoSync(unsynced);
    });
  }

  bool _autoSyncing = false;

  void _runAutoSync(List<Asset> toSync) async {
    if (_autoSyncing) return;
    _autoSyncing = true;
    _autoSyncTimer?.cancel();
    stateModel.startSync(toSync.length);
    for (final asset in toSync) {
      if (!mounted || stateModel.syncCancelled) break;
      if (!asset.hasLocal || asset.hasRemote) {
        stateModel.advanceSync(asset.name());
        continue;
      }
      stateModel.syncCurrentFile = asset.name();
      stateModel.notifyListeners();
      try {
        await storage.uploadAssetEntity(asset.local!);
        asset.hasRemote = true;
        stateModel.advanceSync(asset.name());
      } catch (e) {
        stateModel.advanceSync(asset.name());
        continue;
      }
      // Yield to UI event loop between uploads
      await Future.delayed(Duration.zero);
    }
    _autoSyncing = false;
    stateModel.finishSync();
    eventBus.fire(RemoteRefreshEvent());
  }

  void _toggleSyncPanel() {
    setState(() {
      _syncPanelExpanded = !_syncPanelExpanded;
    });
  }

  void _deleteSelected() {
    if (_isDeleting) return;
    _isDeleting = true;
    final all = assetModel.getUnifiedAssets();
    final toDelete =
        all.where((a) => _selectedIds.contains(a.stableId())).toList();
    clearSelection();
    final localToDelete = toDelete.where((e) => e.hasLocal).toList();
    final remoteToDelete = toDelete.where((e) => e.hasRemote).toList();

    // Optimistically remove from UI
    assetModel.removeAssets(toDelete);
    SnackBarManager.showSnackBar(l10n.movedToTrash);
    _isDeleting = false;

    // Perform actual deletion in background (no refresh — optimistic removal is sufficient)
    () async {
      try {
        if (localToDelete.isNotEmpty) {
          await PhotoManager.editor
              .deleteWithIds(localToDelete.map((e) => e.local!.id).toList());
        }
        if (remoteToDelete.isNotEmpty) {
          await storage.cli.moveToTrash(MoveToTrashRequest(
            paths: remoteToDelete.map((e) => e.remote!.path).toList(),
          ));
        }
      } catch (e) {
        SnackBarManager.showSnackBar(e.toString());
      }
    }();
  }

  void _shareAsset() async {
    if (!stateModel.isSelectionMode) {
      return;
    }
    final all = assetModel.getUnifiedAssets();
    final assets =
        all.where((a) => _selectedIds.contains(a.stableId())).toList();
    List<XFile> xfiles = [];
    for (var asset in assets) {
      final data = await asset.imageDataAsync();
      xfiles.add(XFile.fromData(
        data,
        name: asset.name(),
        mimeType: asset.mimeType(),
      ));
    }
    SharePlus.instance.share(ShareParams(files: xfiles));
  }

  void downloadSelected() async {
    if (!stateModel.isSelectionMode) {
      return;
    }
    if (settingModel.localFolderAbsPath == null) {
      SnackBarManager.showSnackBar(l10n.setLocalFirst);
      return;
    }
    final all = assetModel.getUnifiedAssets();
    final assets = all
        .where((a) => _selectedIds.contains(a.stableId()) && a.isCloudOnly)
        .toList();
    int count = 0;
    try {
      for (var asset in assets) {
        if (asset.name() == null) {
          continue;
        }
        Uint8List data;
        if (!asset.isVideo()) {
          data = await asset.imageDataAsync();
        } else {
          data = await asset.remote!.imageData();
        }
        if (Platform.isAndroid) {
          final absPath = '${settingModel.localFolderAbsPath}/${asset.name()}';
          final file = File(absPath);
          await file.writeAsBytes(data);
          await file.setLastModified(asset.dateCreated());
          await scanFile(absPath);
        } else if (Platform.isIOS) {
          var appDocDir = await getTemporaryDirectory();
          String savePath = "${appDocDir.path}/${asset.name()}";
          final file = File(savePath);
          await file.writeAsBytes(data);
          await file.setLastModified(asset.dateCreated());
          await Gal.putImage(savePath);
        }

        count++;
      }
    } catch (e) {
      SnackBarManager.showSnackBar("${l10n.downloadFailed}: $e");
    }
    SnackBarManager.showSnackBar("${l10n.download} $count ${l10n.photos}");
    eventBus.fire(LocalRefreshEvent());
    clearSelection();
  }

  void uploadSelected() async {
    if (!stateModel.isSelectionMode) {
      return;
    }
    if (!settingModel.isRemoteStorageSetted) {
      SnackBarManager.showSnackBar(l10n.storageNotSetted);
      return;
    }
    final all = assetModel.getUnifiedAssets();
    final assets = all
        .where((a) => _selectedIds.contains(a.stableId()) && a.hasLocal)
        .toList();
    clearSelection();
    int uploaded = 0;
    for (var asset in assets) {
      if (!mounted) break;
      final entity = asset.local!;
      try {
        await storage.uploadAssetEntity(entity);
        uploaded++;
      } catch (e) {
        SnackBarManager.showSnackBar("${l10n.uploadFailed}: $e");
      }
      // Yield to UI event loop between uploads
      await Future.delayed(Duration.zero);
    }
    SnackBarManager.showSnackBar(
        "${l10n.successfullyUpload} $uploaded ${l10n.photos}");
    eventBus.fire(RemoteRefreshEvent());
  }

  Widget _buildSelectionBar() {
    return Consumer<StateModel>(
      builder: (context, model, child) {
        if (!model.isSelectionMode) return const SizedBox.shrink();
        return GlassContainer(
          borderRadius: BorderRadius.zero,
          child: SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _selectionBarButton(
                    Icons.close, l10n.cancel, clearSelection),
                _selectionBarButton(
                    Icons.share_outlined, l10n.share, _shareAsset),
                _selectionBarButton(Icons.delete_outline, l10n.delete,
                    () => _deleteSelected()),
                _selectionBarButton(
                    Icons.lock_outline,
                    l10n.moveToLockedFolder,
                    _moveToLockedFolder),
                _selectionBarButton(
                    Icons.cloud_upload_outlined,
                    l10n.upload,
                    uploadSelected,
                    isEnable: !model.isDownloading() &&
                        !model.isUploading()),
                _selectionBarButton(
                    Icons.cloud_download_outlined,
                    l10n.download,
                    downloadSelected,
                    isEnable: !model.isDownloading() &&
                        !model.isUploading()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _selectionBarButton(
      IconData icon, String text, Function()? onTap,
      {bool isEnable = true}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkResponse(
      containedInkWell: true,
      radius: 40,
      onTap: isEnable ? onTap : null,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isEnable
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withAlpha(97),
            ),
            const SizedBox(height: 4),
            Text(text,
                style: TextStyle(
                    color: isEnable
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withAlpha(97),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showDeleteUploadedDialog(BuildContext context) {
    final all = assetModel.getUnifiedAssets();
    final uploaded = all.where((a) => a.hasLocal && a.hasRemote).toList();
    if (uploaded.isEmpty) {
      SnackBarManager.showSnackBar(l10n.noUploadedPhotosToDelete);
      return;
    }
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.deleteUploadedPhotos),
        content: Text(l10n.deleteUploadedPhotosConfirm(uploaded.length)),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              final ids = uploaded.map((e) => e.local!.id).toList();
              PhotoManager.editor.deleteWithIds(ids).then((_) {
                eventBus.fire(LocalRefreshEvent());
              });
              Navigator.of(context).pop();
              SnackBarManager.showSnackBar(
                  '${l10n.delete} ${uploaded.length} ${l10n.photos}.');
            },
            child: Text(l10n.yes),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<bool> _tryBiometricAuth() async {
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) return false;
    final localAuth = LocalAuthentication();
    try {
      final canCheck = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();
      print("canCheckBiometrics: $canCheck, isDeviceSupported: $isSupported");
      final canAuth = canCheck || isSupported;
      if (!canAuth) return false;
      final result = await localAuth.authenticate(
        localizedReason: l10n.authenticate,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      print("Authenticate result: $result");
      return result;
    } catch (e) {
      print("Biometric auth error: $e");
      return false;
    }
  }

  Future<bool> _showPinDialog(String correctPin) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enterPin),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: InputDecoration(hintText: l10n.enterPin),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text == correctPin), child: Text(l10n.yes)),
        ],
      ),
    );
    return result ?? false;
  }

  void _moveToLockedFolder() async {
    print("_moveToLockedFolder called, isSelectionMode: ${stateModel.isSelectionMode}");
    if (!stateModel.isSelectionMode) return;

    // Try biometric auth first
    final biometricOk = await _tryBiometricAuth();
    print("Biometric auth result: $biometricOk");
    if (biometricOk) {
      _performMoveToLockedFolder();
      return;
    }

    if (!mounted) return;

    // Fallback to PIN
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('locked_folder_pin');
    print("Stored PIN: ${storedPin != null ? 'exists' : 'null'}");

    if (storedPin != null && storedPin.isNotEmpty) {
      final pinOk = await _showPinDialog(storedPin);
      if (!mounted) return;
      if (pinOk) {
        _performMoveToLockedFolder();
      } else {
        SnackBarManager.showSnackBar(l10n.incorrectPin);
      }
      return;
    }

    // No biometric and no PIN configured
    print("No biometric and no PIN - showing pinRequired");
    SnackBarManager.showSnackBar(l10n.pinRequired);
  }

  void _performMoveToLockedFolder() async {
    final all = assetModel.getUnifiedAssets();
    final assets =
        all.where((a) => _selectedIds.contains(a.stableId())).toList();

    if (assets.isEmpty) {
      SnackBarManager.showSnackBar(l10n.noPhotosSelected);
      clearSelection();
      return;
    }

    // Delete local copies
    final localIds = assets.where((e) => e.hasLocal).map((e) => e.local!.id).toList();
    if (localIds.isNotEmpty) {
      try {
        await PhotoManager.editor.deleteWithIds(localIds);
      } catch (e) {
        print("Failed to delete local photos: $e");
      }
    }

    // Move remote copies to locked folder on server
    final remotePaths = assets.where((e) => e.hasRemote).map((e) => e.remote!.path).toList();
    if (remotePaths.isNotEmpty) {
      try {
        final rsp = await storage.cli.moveToLocked(MoveToLockedRequest(paths: remotePaths));
        if (!rsp.success) {
          print("Move to locked failed: ${rsp.message}");
        }
      } catch (e) {
        print("Failed to move remote photos to locked: $e");
      }
    }

    clearSelection();
    eventBus.fire(LocalRefreshEvent());
    eventBus.fire(RemoteRefreshEvent());
    SnackBarManager.showSnackBar('${assets.length} ${l10n.photos} ${l10n.moveToLockedFolder}');
  }

  Widget _buildToolbar() {
    return SliverToBoxAdapter(
      child: Consumer<StateModel>(
        builder: (context, model, child) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset('assets/icon/lumina_icon_transparent.png', width: 36, height: 36),
                const Spacer(),
                Consumer<AssetModel>(
                  builder: (context, assetModel, child) {
                    if (model.indexSyncing) {
                      return GestureDetector(
                        onTap: _toggleSyncPanel,
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Icon(Icons.cloud_sync, size: 18, color: colorScheme.primary),
                            ],
                          ),
                        ),
                      );
                    }
                    if (model.isSyncing) {
                      return GestureDetector(
                        onTap: _toggleSyncPanel,
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  value: model.syncTotal > 0
                                      ? model.syncDone / model.syncTotal
                                      : null,
                                  strokeWidth: 3,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Icon(Icons.cloud_sync, size: 18, color: colorScheme.primary),
                            ],
                          ),
                        ),
                      );
                    }
                    if (assetModel.isRefreshing) {
                      return SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: refresh,
                      child: Icon(
                        Icons.cloud_done,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'delete_uploaded') {
                      _showDeleteUploadedDialog(context);
                    } else if (value == 'settings') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingBody()),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete_uploaded',
                      child: Text(l10n.deleteUploadedPhotos),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Text(l10n.settings),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncPanel() {
    return SliverToBoxAdapter(
      child: Consumer<StateModel>(
        builder: (context, model, child) {
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;
          final remaining = model.syncTotal - model.syncDone;
          final progress = model.syncTotal > 0
              ? model.syncDone / model.syncTotal
              : 0.0;
          return AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _syncPanelExpanded && (model.isSyncing || model.indexSyncing)
                ? Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (model.indexSyncing) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      model.indexSyncMessage ?? '',
                                      style: textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (model.isSyncing) ...[
                          Text(
                            l10n.backingUpPhotos(remaining),
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 3,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    l10n.nRemaining(remaining),
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                stateModel.cancelSync();
                              },
                              child: Text(l10n.stop),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  List<Widget> _buildContentSlivers(BuildContext context, AssetModel model) {
    switch (widget.viewMode) {
      case GalleryViewMode.years:
        return [_buildYearsGrid(context, model)];
      case GalleryViewMode.months:
        return [_buildMonthsGrid(context, model)];
      case GalleryViewMode.all:
        return _buildAllSlivers(context, model);
    }
  }

  List<Widget> _buildAllSlivers(BuildContext context, AssetModel model) {
    columCount = responsiveColumns(context, base: 3);
    final all = model.getUnifiedAssets();
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat =
        DateFormat('yyyy MMMM d${l10n.chineseday}  EEEEE', locale);

    final slivers = <Widget>[];
    int cursor = 0;
    while (cursor < all.length) {
      while (cursor < all.length && all[cursor].name() == null) {
        cursor++;
      }
      if (cursor >= all.length) break;
      final dayDate = all[cursor].dateCreated();
      final dayItems = <int>[];
      int scan = cursor;
      while (scan < all.length) {
        if (all[scan].name() == null) {
          scan++;
          continue;
        }
        final d = all[scan].dateCreated();
        if (d.year != dayDate.year ||
            d.month != dayDate.month ||
            d.day != dayDate.day) {
          break;
        }
        dayItems.add(scan);
        scan++;
      }
      cursor = scan;

      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            dateFormat.format(dayDate),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ));

      slivers.add(SliverPadding(
        padding: EdgeInsets.zero,
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columCount,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, localIndex) {
              final globalIndex = dayItems[localIndex];
              final asset = all[globalIndex];
              final id = asset.stableId();
              return _PhotoTile(
                key: ValueKey(id),
                asset: asset,
                isSelected: _selectedIds.contains(id),
                onTap: () {
                  if (stateModel.isSelectionMode) {
                    toggleSelection(id);
                  } else {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        transitionDuration:
                            const Duration(milliseconds: 300),
                        reverseTransitionDuration:
                            const Duration(milliseconds: 300),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                        pageBuilder: (_, __, ___) => GalleryViewerRoute(
                          originIndex: globalIndex,
                        ),
                      ),
                    );
                  }
                },
                onLongPress: () {
                  if (!stateModel.isSelectionMode) toggleSelection(id);
                },
              );
            },
            childCount: dayItems.length,
            findChildIndexCallback: (key) {
              final id = (key as ValueKey<String>).value;
              for (int i = 0; i < dayItems.length; i++) {
                if (all[dayItems[i]].stableId() == id) return i;
              }
              return null;
            },
          ),
        ),
      ));
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 80)));
    return slivers;
  }

  Widget _buildYearsGrid(BuildContext context, AssetModel model) {
    final all = model.getUnifiedAssets();
    if (all.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final Map<int, _GroupInfo> yearMap = {};
    for (final asset in all) {
      if (asset.name() == null) continue;
      final year = asset.dateCreated().year;
      if (!yearMap.containsKey(year)) {
        yearMap[year] = _GroupInfo(asset: asset);
      }
      yearMap[year]!.count++;
    }

    final years = yearMap.keys.toList()..sort((a, b) => b.compareTo(a));
    final colorScheme = Theme.of(context).colorScheme;

    return SliverPadding(
      padding: const EdgeInsets.all(4),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: responsiveColumns(context, base: 2),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final year = years[index];
            final info = yearMap[year]!;
            return _TimeGroupTile(
              asset: info.asset,
              label: '$year',
              count: info.count,
              colorScheme: colorScheme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => YearDetailBody(year: year),
                  ),
                );
              },
            );
          },
          childCount: years.length,
        ),
      ),
    );
  }

  Widget _buildMonthsGrid(BuildContext context, AssetModel model) {
    final all = model.getUnifiedAssets();
    if (all.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final Map<int, _GroupInfo> monthMap = {};
    for (final asset in all) {
      if (asset.name() == null) continue;
      final date = asset.dateCreated();
      final key = date.year * 100 + date.month;
      if (!monthMap.containsKey(key)) {
        monthMap[key] = _GroupInfo(asset: asset);
      }
      monthMap[key]!.count++;
    }

    final keys = monthMap.keys.toList()..sort((a, b) => b.compareTo(a));
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;

    return SliverPadding(
      padding: const EdgeInsets.all(4),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: responsiveColumns(context, base: 2),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final key = keys[index];
            final year = key ~/ 100;
            final month = key % 100;
            final info = monthMap[key]!;
            final label = DateFormat('MMMM yyyy', locale)
                .format(DateTime(year, month));
            return _TimeGroupTile(
              asset: info.asset,
              label: label,
              count: info.count,
              colorScheme: colorScheme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MonthDetailBody(year: year, month: month),
                  ),
                );
              },
            );
          },
          childCount: keys.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: !stateModel.isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && stateModel.isSelectionMode) {
          clearSelection();
        }
      },
      child: Stack(
      children: [
        RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () async {
            refresh(); // Fire-and-forget, returns immediately
          },
          child: Consumer<AssetModel>(
            builder: (context, model, child) => CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              cacheExtent: 1000,
              slivers: [
                _buildToolbar(),
                _buildSyncPanel(),
                ..._buildContentSlivers(context, model),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          right: 20,
          child: Offstage(
            offstage: !_showToTopBtn,
            child: FloatingActionButton.small(
              onPressed: _scrollToTop,
              heroTag: 'gallery_body_toTop',
              child: const Icon(Icons.arrow_upward),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildSelectionBar(),
        ),
        if (_isDeleting)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    ),
    );
  }
}

class _GroupInfo {
  final Asset asset;
  int count = 0;

  _GroupInfo({required this.asset});
}

class _PhotoTile extends StatefulWidget {
  final Asset asset;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoTile({
    required Key key,
    required this.asset,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _kickOffThumbnail();
  }

  @override
  void didUpdateWidget(covariant _PhotoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _loaded = widget.asset.loadThumbnailFinished();
      _kickOffThumbnail();
    }
  }

  void _kickOffThumbnail() {
    if (widget.asset.loadThumbnailFinished()) {
      _loaded = true;
      return;
    }
    widget.asset.thumbnailDataAsync().then((_) {
      if (mounted) setState(() => _loaded = true);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: "asset_${widget.asset.stableId()}",
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _loaded && widget.asset.loadThumbnailFinished()
                  ? Image(
                      key: const ValueKey('img'),
                      image: widget.asset.thumbnailProvider(),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : Container(
                      key: const ValueKey('ph'),
                      color: colorScheme.surfaceContainerHighest,
                    ),
            ),
          ),
          if (widget.asset.isVideo())
            const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 36,
              ),
            ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Consumer<StateModel>(
              builder: (context, model, child) {
                final a = widget.asset;
                if (a.hasLocal && a.local != null &&
                    model.uploadProgress.containsKey(a.local!.id)) {
                  return SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: model.getUploadPercent(a.local!.id),
                      color: Colors.white,
                    ),
                  );
                }
                if (a.name() != null &&
                    model.downloadProgress.containsKey(a.name()!)) {
                  return SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: model.getDownloadPercent(a.name()!),
                      color: Colors.white,
                    ),
                  );
                }
                if (a.isCloudOnly) {
                  return const Icon(Icons.cloud_outlined,
                      size: 14, color: Colors.white);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          Consumer<StateModel>(
            builder: (context, model, child) {
              if (!model.isSelectionMode) return const SizedBox.shrink();
              return Positioned(
                left: 4,
                top: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? colorScheme.primary
                        : Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    widget.isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          if (widget.isSelected)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 3),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeGroupTile extends StatefulWidget {
  final Asset asset;
  final String label;
  final int count;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _TimeGroupTile({
    required this.asset,
    required this.label,
    required this.count,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  State<_TimeGroupTile> createState() => _TimeGroupTileState();
}

class _TimeGroupTileState extends State<_TimeGroupTile> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.asset.loadThumbnailFinished()) {
      widget.asset.thumbnailDataAsync().then((_) {
        if (mounted) setState(() => _loaded = true);
      });
    } else {
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _loaded && widget.asset.loadThumbnailFinished()
                ? Image(
                    image: widget.asset.thumbnailProvider(),
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: widget.colorScheme.surfaceContainerHighest),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black54)
                      ],
                    ),
                  ),
                  Text(
                    '${widget.count} ${l10n.photos}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black54)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
