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
  double scrollOffset = 0;

  final Map<int, bool> _selectedIndices = {};

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
        .listen((scrollPosition) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 4000) {
        getPhotos();
      }
      setState(() {
        scrollOffset = scrollPosition;
      });
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

  bool _isRefreshing = false;
  Future<void> refresh() async {
    if (stateModel.isDownloading() || stateModel.isUploading()) {
      return;
    }
    if (_isRefreshing) {
      return;
    }
    _isRefreshing = true;
    await assetModel.refreshAll();
    _isRefreshing = false;
  }

  void getPhotos() {
    assetModel.getMorePhotos();
  }

  void toggleSelection(int index) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator!) {
      Vibration.vibrate(duration: 10);
    }
    if (_selectedIndices[index] == null) {
      _selectedIndices[index] = true;
    } else {
      _selectedIndices[index] = !_selectedIndices[index]!;
    }
    var hasSelected = false;
    _selectedIndices.forEach((key, value) {
      if (value) {
        hasSelected = true;
      }
    });
    stateModel.setSelectionMode(hasSelected);
    if (!hasSelected) {
      _selectedIndices.clear();
    }
    setState(() {});
  }

  void clearSelection() {
    _selectedIndices.clear();
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

  void _runAutoSync(List<Asset> toSync) async {
    stateModel.startSync(toSync.length);
    for (final asset in toSync) {
      if (stateModel.syncCancelled) break;
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
    }
    stateModel.finishSync();
    eventBus.fire(RemoteRefreshEvent());
  }

  void _toggleSyncPanel() {
    setState(() {
      _syncPanelExpanded = !_syncPanelExpanded;
    });
  }

  void _deleteSelected() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    var toDelete = <Asset>[];
    try {
      final all = assetModel.getUnifiedAssets();
      _selectedIndices.forEach((key, value) {
        if (value) {
          toDelete.add(all[key]);
        }
      });
      clearSelection();
      final localToDelete = toDelete.where((e) => e.hasLocal).toList();
      final remoteToDelete = toDelete.where((e) => e.hasRemote).toList();
      if (localToDelete.isNotEmpty) {
        await PhotoManager.editor
            .deleteWithIds(localToDelete.map((e) => e.local!.id).toList());
        await assetModel.refreshLocal();
      }
      if (remoteToDelete.isNotEmpty) {
        await storage.cli.moveToTrash(MoveToTrashRequest(
          paths: remoteToDelete.map((e) => e.remote!.path).toList(),
        ));
        await assetModel.refreshRemote();
      }
      SnackBarManager.showSnackBar(l10n.movedToTrash);
    } catch (e) {
      SnackBarManager.showSnackBar(e.toString());
    }
    if (mounted) setState(() => _isDeleting = false);
  }

  void _shareAsset() async {
    if (!stateModel.isSelectionMode) {
      return;
    }
    final all = assetModel.getUnifiedAssets();
    final assets = <Asset>[];
    _selectedIndices.forEach((key, isSelected) {
      if (isSelected) {
        assets.add(all[key]);
      }
    });
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
    final assets = <Asset>[];
    _selectedIndices.forEach((key, isSelected) {
      if (isSelected && all[key].isCloudOnly) {
        assets.add(all[key]);
      }
    });
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
    final assets = <Asset>[];
    _selectedIndices.forEach((key, isSelected) {
      if (isSelected && all[key].hasLocal) {
        assets.add(all[key]);
      }
    });
    for (var asset in assets) {
      final entity = asset.local!;
      try {
        await storage.uploadAssetEntity(entity);
      } catch (e) {
        SnackBarManager.showSnackBar("${l10n.uploadFailed}: $e");
      }
    }
    SnackBarManager.showSnackBar(
        "${l10n.successfullyUpload} ${assets.length} ${l10n.photos}");
    eventBus.fire(RemoteRefreshEvent());

    clearSelection();
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
    final assets = <Asset>[];

    _selectedIndices.forEach((key, isSelected) {
      if (isSelected) {
        assets.add(all[key]);
      }
    });

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
                if (model.isSyncing)
                  GestureDetector(
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
                  )
                else
                  Icon(
                    Icons.cloud_done,
                    size: 20,
                    color: colorScheme.primary,
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
            child: _syncPanelExpanded && model.isSyncing
                ? Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                    ),
                  )
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget contentBuilder(BuildContext context, AssetModel model, Widget? child) {
    final all = model.getUnifiedAssets();
    var children = <Widget>[];
    final totalwidth = MediaQuery.of(context).size.width - (columCount - 1) * 2;
    final totalHeight = MediaQuery.of(context).size.height;
    final imgWidth = totalwidth / columCount;
    final imgHeight = imgWidth;
    final colorScheme = Theme.of(context).colorScheme;

    var currentChildren = <Widget>[];
    DateTime? currentDateTime;
    double currentScrollOffset = 0;
    for (int i = 0; i < all.length; i++) {
      if (all[i].name() == null) {
        continue;
      }
      final date = all[i].dateCreated();
      if (currentDateTime == null ||
          date.year != currentDateTime.year ||
          date.month != currentDateTime.month ||
          date.day != currentDateTime.day) {
        children.add(Wrap(
          spacing: 2,
          runSpacing: 2.0,
          alignment: WrapAlignment.start,
          children: currentChildren,
        ));
        currentScrollOffset -= 2;
        currentChildren = <Widget>[];
        DateFormat format = DateFormat('yyyy MMMM d${l10n.chineseday}  EEEEE',
            Localizations.localeOf(context).languageCode);
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            format.format(date),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ));
        currentScrollOffset += 40;
      }
      bool needLoadThumbnail = false;
      if (currentScrollOffset > scrollOffset - (2 * totalHeight) &&
          currentScrollOffset < scrollOffset + (3 * totalHeight)) {
        needLoadThumbnail = true;
        if (!all[i].loadThumbnailFinished()) {
          all[i].thumbnailDataAsync().then((value) => setState(() {}));
        }
      }
      var child = GestureDetector(
          onTap: () async {
            if (stateModel.isSelectionMode) {
              toggleSelection(i);
            } else {
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  transitionDuration: const Duration(milliseconds: 300),
                  reverseTransitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder: (BuildContext context,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                      Widget child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  pageBuilder: (BuildContext context, _, __) =>
                      GalleryViewerRoute(
                    originIndex: i,
                  ),
                ),
              );
            }
          },
          onLongPress: () {
            if (!stateModel.isSelectionMode) {
              toggleSelection(i);
            }
          },
          child: Stack(
            children: [
              SizedBox(
                    width: imgWidth,
                    height: imgHeight,
                    child: Hero(
                      tag:
                          "asset_${all[i].dedupKey ?? all[i].path()}",
                      child:
                          needLoadThumbnail && all[i].loadThumbnailFinished()
                              ? Image(
                                  image: all[i].thumbnailProvider(),
                                  fit: BoxFit.cover)
                              : Container(
                                  color: colorScheme.surfaceContainerHighest),
                      flightShuttleBuilder: (BuildContext flightContext,
                          Animation<double> animation,
                          HeroFlightDirection flightDirection,
                          BuildContext fromHeroContext,
                          BuildContext toHeroContext) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (BuildContext context, Widget? child) {
                            return Opacity(
                                opacity: animation.value,
                                child: all[i].loadThumbnailFinished()
                                    ? Image(
                                        image: all[i].thumbnailProvider(),
                                        fit: BoxFit.contain,
                                      )
                                    : Container(
                                        color: colorScheme
                                            .surfaceContainerHighest));
                          },
                        );
                      },
                    )),
              Consumer<StateModel>(builder: (context, stateModel, child) {
                final asset = all[i];
                // Active upload progress
                if (asset.hasLocal) {
                  final uploadPercent = stateModel.getUploadPercent(asset.local!.id);
                  if (uploadPercent > 0) {
                    return Positioned(
                      bottom: 4,
                      right: 4,
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                        value: uploadPercent,
                      ),
                    );
                  }
                }
                // Active download progress
                if (asset.isCloudOnly) {
                  final downloadPercent = stateModel.getDownloadPercent(asset.name()!);
                  if (downloadPercent > 0) {
                    return Positioned(
                      bottom: 4,
                      right: 4,
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                        value: downloadPercent,
                      ),
                    );
                  }
                }
                // Synced: subtle cloud-done icon
                if (asset.hasLocal && asset.hasRemote) {
                  return const Positioned(
                    bottom: 4,
                    right: 4,
                    child: Icon(
                      Icons.cloud_done_outlined,
                      color: Colors.white,
                      size: 16,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  );
                }
                // Local only: not yet uploaded
                if (asset.hasLocal && !asset.hasRemote) {
                  return const Positioned(
                    bottom: 4,
                    right: 4,
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.white,
                      size: 16,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  );
                }
                // Cloud only: not on device
                if (asset.isCloudOnly) {
                  return const Positioned(
                    bottom: 4,
                    right: 4,
                    child: Icon(
                      Icons.cloud_outlined,
                      color: Colors.white,
                      size: 16,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              if (all[i].isVideo())
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              if (stateModel.isSelectionMode)
                Positioned(
                  top: 2,
                  left: 2,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _selectedIndices[i] ?? false,
                      onChanged: (value) {
                        toggleSelection(i);
                      },
                      fillColor: WidgetStateProperty.all(
                          colorScheme.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ));
      currentChildren.add(child);
      if (currentChildren.length % columCount == 1) {
        currentScrollOffset += imgHeight + 2;
      }
      currentDateTime = all[i].dateCreated();

      if (i == all.length - 1) {
        children.add(Wrap(
          spacing: 2,
          runSpacing: 2.0,
          alignment: WrapAlignment.start,
          children: currentChildren,
        ));
      }
    }
    children.add(const SizedBox(height: 80));
    return SliverList.list(
      children: children,
    );
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
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
    return Stack(
      children: [
        RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: refresh,
          child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildToolbar(),
                _buildSyncPanel(),
                Consumer<AssetModel>(
                  builder: (context, model, child) {
                    switch (widget.viewMode) {
                      case GalleryViewMode.years:
                        return _buildYearsGrid(context, model);
                      case GalleryViewMode.months:
                        return _buildMonthsGrid(context, model);
                      case GalleryViewMode.all:
                        return contentBuilder(context, model, child);
                    }
                  },
                ),
              ]),
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
    );
  }
}

class _GroupInfo {
  final Asset asset;
  int count = 0;

  _GroupInfo({required this.asset});
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
