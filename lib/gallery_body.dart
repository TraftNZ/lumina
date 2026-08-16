import 'dart:io';
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
import 'package:lumina/prefix_extent_sliver.dart';
import 'package:lumina/setting_body.dart';
import 'package:lumina/theme.dart';
import 'package:lumina/timeline_scrollbar.dart';
import 'package:lumina/year_detail_body.dart';
import 'package:lumina/month_detail_body.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:vibration/vibration.dart';
import 'package:local_auth/local_auth.dart';

enum GalleryViewMode { years, months, all }

const int _autoSyncBatchLimit = 20;

/// Gap between photo tiles, both axes.
const double _gridSpacing = 2;

/// Badges sit directly on the photo, which can be any colour; without a shadow
/// a white icon disappears over a bright thumbnail.
const List<Shadow> _badgeShadows = [
  Shadow(blurRadius: 4, color: Colors.black87),
];

/// Fills a tile that has no image to show — still loading, or a file the
/// backend cannot render a thumbnail for at all. Videos in particular keep the
/// play badge drawn over this, so an empty tile still reads as a video rather
/// than as a failure.
Widget _tilePlaceholder(ColorScheme colorScheme) => Container(
  key: const ValueKey('ph'),
  color: colorScheme.surfaceContainerHighest,
);

/// One rendered row of the "all" view: either a day header or a run of photos.
class _GalleryRow {
  /// Non-null when this row is a day header.
  final DateTime? header;

  /// Range into [_GalleryLayout.visible] when this row holds photos.
  final int start;
  final int count;

  /// Content-derived identity, so a keyed child can be relocated after the
  /// underlying list shifts.
  final String key;

  _GalleryRow.header(DateTime date)
    : header = date,
      start = 0,
      count = 0,
      key = 'h:${date.year}-${date.month}-${date.day}';

  _GalleryRow.photos(this.start, this.count, String firstId)
    : header = null,
      key = 'p:$firstId';
}

/// Flat row model backing the "all" view.
///
/// The gallery used to emit a header sliver plus a grid sliver per day and
/// spread them all into [CustomScrollView.slivers]. A sliver in that list is
/// laid out no matter where the viewport is, so only the tiles *inside* each
/// grid were lazy: a multi-year library kept tens of thousands of render
/// objects and semantics nodes resident and pushed the process past the iOS
/// memory limit. Flattening days into row descriptors lets a single
/// [SliverList] build only the rows on screen.
class _GalleryLayout {
  final List<Asset> assets;
  final int columns;

  /// Indices into [assets] that are renderable, in display order.
  final List<int> visible;
  final List<_GalleryRow> rows;
  final Map<String, int> rowIndexByKey;

  _GalleryLayout._(
    this.assets,
    this.columns,
    this.visible,
    this.rows,
    this.rowIndexByKey,
  );

  factory _GalleryLayout.build(List<Asset> assets, int columns) {
    final visible = <int>[];
    final rows = <_GalleryRow>[];
    int cursor = 0;
    while (cursor < assets.length) {
      if (assets[cursor].name() == null) {
        cursor++;
        continue;
      }
      final dayDate = assets[cursor].dateCreated();
      final dayStart = visible.length;
      while (cursor < assets.length) {
        if (assets[cursor].name() == null) {
          cursor++;
          continue;
        }
        final d = assets[cursor].dateCreated();
        if (d.year != dayDate.year ||
            d.month != dayDate.month ||
            d.day != dayDate.day) {
          break;
        }
        visible.add(cursor);
        cursor++;
      }
      if (visible.length == dayStart) continue;

      rows.add(_GalleryRow.header(dayDate));
      for (int off = dayStart; off < visible.length; off += columns) {
        final remaining = visible.length - off;
        rows.add(
          _GalleryRow.photos(
            off,
            remaining < columns ? remaining : columns,
            assets[visible[off]].stableId(),
          ),
        );
      }
    }

    final rowIndexByKey = <String, int>{};
    for (int i = 0; i < rows.length; i++) {
      rowIndexByKey[rows[i].key] = i;
    }
    return _GalleryLayout._(assets, columns, visible, rows, rowIndexByKey);
  }
}

class GalleryBody extends StatefulWidget {
  final GalleryViewMode viewMode;

  const GalleryBody({super.key, this.viewMode = GalleryViewMode.all});

  @override
  GalleryBodyState createState() => GalleryBodyState();
}

class GalleryBodyState extends State<GalleryBody>
    with AutomaticKeepAliveClientMixin {
  bool _showToTopBtn = false;
  bool _syncPanelExpanded = false;
  bool _isDeleting = false;
  bool _isTimelineScrubbing = false;
  final ValueNotifier<int> _thumbnailResumeSignal = ValueNotifier(0);
  double _galleryCrossAxisExtent = -1;
  @override
  bool get wantKeepAlive => true;
  final ScrollController _scrollController = ScrollController();
  final _scrollSubject = PublishSubject<double>();
  int columCount = 3;

  // Keyed by Asset.stableId() so selection survives list reorders/refreshes.
  final Set<String> _selectedIds = {};

  _GalleryLayout? _galleryLayout;
  _GalleryLayout? _timelineGeometryLayout;
  double _timelineGeometryWidth = -1;
  double _timelineGeometryScaledFontSize = -1;
  TextStyle? _timelineGeometryTextStyle;
  String _timelineGeometryLocale = '';
  List<double> _timelineRowExtents = const [];
  List<double> _timelineRowEnds = const [];
  Map<int, double> _timelineYearOffsets = const {};
  double _timelineMarkerScrollableExtent = -1;
  double _timelineMarkerLeadingExtent = -1;
  double _timelineMarkerMinExtent = -1;
  List<TimelineMarker> _timelineMarkers = const [];

  final GlobalKey _syncPanelKey = GlobalKey();
  final GlobalKey _scrollViewKey = GlobalKey();

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
    if (oldWidget.viewMode != GalleryViewMode.all &&
        widget.viewMode == GalleryViewMode.all) {
      getPhotos();
    }
  }

  @override
  void dispose() {
    assetModel.removeListener(_scheduleAutoSync);
    _autoSyncTimer?.cancel();
    _thumbnailResumeSignal.dispose();
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
    if (_isDeleting) return;
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
    unawaited(() async {
      try {
        final initialLoad = assetModel.getMorePhotos();
        if (mounted && widget.viewMode == GalleryViewMode.all) {
          unawaited(() async {
            try {
              await assetModel.loadLocalTimeline();
            } catch (_) {}
          }());
        }
        await initialLoad;
      } catch (_) {}
    }());
  }

  void _setTimelineScrubbing(bool scrubbing) {
    if (_isTimelineScrubbing == scrubbing || !mounted) return;
    _isTimelineScrubbing = scrubbing;
    if (scrubbing) {
      _autoSyncTimer?.cancel();
    } else {
      _thumbnailResumeSignal.value++;
      _scheduleAutoSync();
    }
  }

  bool _canLoadTimelineThumbnails() => !_isTimelineScrubbing;

  List<String> _selectionKeys(Asset asset) => [
    if (asset.local != null) 'l:${asset.local!.id}',
    if (asset.remote != null) 'r:${asset.remote!.path}',
    if (asset.local == null && asset.remote == null) asset.stableId(),
  ];

  bool _isAssetSelected(Asset asset) {
    final local = asset.local;
    if (local != null && _selectedIds.contains('l:${local.id}')) return true;
    final remote = asset.remote;
    if (remote != null && _selectedIds.contains('r:${remote.path}')) {
      return true;
    }
    return local == null &&
        remote == null &&
        _selectedIds.contains(asset.stableId());
  }

  void toggleSelection(Asset asset) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 10);
      }
    }
    final keys = _selectionKeys(asset);
    if (keys.any(_selectedIds.contains)) {
      _selectedIds.removeWhere(keys.contains);
    } else {
      _selectedIds.addAll(keys);
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
      if (!mounted || _isTimelineScrubbing) return;
      if (stateModel.isSyncing) return;
      if (!settingModel.isRemoteStorageSetted) return;
      if (!isServerReady) return;
      if (assetModel.localGetting != null) return;
      if (assetModel.remoteGetting != null) return;
      // Wait until remote photos have been fetched at least once
      if (assetModel.remoteAssets.isEmpty && assetModel.remoteHasMore) return;
      final unsynced = assetModel
          .getUnifiedAssets()
          .where((a) => a.hasLocal && !a.hasRemote)
          .take(_autoSyncBatchLimit)
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
      if (!mounted || stateModel.syncCancelled || _isTimelineScrubbing) break;
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
    if (_isTimelineScrubbing) return;
    eventBus.fire(RemoteRefreshEvent());
  }

  void _toggleSyncPanel() {
    setState(() {
      _syncPanelExpanded = !_syncPanelExpanded;
    });
  }

  Future<void> _deleteSelected() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    final all = assetModel.getUnifiedAssets();
    final toDelete = all.where(_isAssetSelected).toList();
    clearSelection();
    if (toDelete.isEmpty) {
      setState(() => _isDeleting = false);
      return;
    }
    final localToDelete = toDelete.where((asset) => asset.hasLocal).toList();

    try {
      final confirmed = <Asset>[];
      if (localToDelete.isNotEmpty) {
        await assetModel.loadLocalTimeline();
        final requestedLocalIds = localToDelete
            .map((asset) => asset.local!.id)
            .toSet();
        final deletedLocalIds = (await PhotoManager.editor.deleteWithIds(
          requestedLocalIds.toList(),
        )).toSet();
        confirmed.addAll(
          localToDelete.where(
            (asset) => deletedLocalIds.contains(asset.local!.id),
          ),
        );
      }
      confirmed.addAll(toDelete.where((asset) => !asset.hasLocal));

      final remoteToDelete = confirmed
          .where((asset) => asset.hasRemote)
          .toList();
      if (remoteToDelete.isNotEmpty) {
        final response = await storage.cli.moveToTrash(
          MoveToTrashRequest(
            paths: remoteToDelete.map((asset) => asset.remote!.path).toList(),
          ),
        );
        if (!response.success) throw Exception(response.message);
      }
      assetModel.removeAssets(confirmed);
      if (confirmed.length != toDelete.length) {
        throw Exception('Some selected photos were not deleted');
      }
      SnackBarManager.showSnackBar(l10n.movedToTrash);
    } catch (error) {
      eventBus.fire(LocalRefreshEvent());
      eventBus.fire(RemoteRefreshEvent());
      SnackBarManager.showSnackBar(error.toString());
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _shareAsset() async {
    if (!stateModel.isSelectionMode) {
      return;
    }
    final all = assetModel.getUnifiedAssets();
    final assets = all.where(_isAssetSelected).toList();
    List<XFile> xfiles = [];
    for (var asset in assets) {
      final name = asset.name();
      if (name == null || name.isEmpty) continue;
      if (asset.isCloudOnly && asset.remote != null) {
        final tempDir = await getTemporaryDirectory();
        final savePath = '${tempDir.path}/$name';
        await asset.remote!.downloadToFile(savePath);
        xfiles.add(XFile(savePath, name: name, mimeType: asset.mimeType()));
      } else {
        final file = await asset.getLocalFile();
        if (file != null) {
          xfiles.add(XFile(file.path, name: name, mimeType: asset.mimeType()));
        } else {
          final data = await asset.imageDataAsync();
          xfiles.add(
            XFile.fromData(data, name: name, mimeType: asset.mimeType()),
          );
        }
      }
    }
    if (xfiles.isNotEmpty) {
      SharePlus.instance.share(ShareParams(files: xfiles));
    }
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
        .where((asset) => _isAssetSelected(asset) && asset.isCloudOnly)
        .toList();
    int count = 0;
    try {
      for (var asset in assets) {
        if (asset.name() == null) {
          continue;
        }
        if (Platform.isAndroid) {
          final absPath = '${settingModel.localFolderAbsPath}/${asset.name()}';
          await asset.remote!.downloadToFile(absPath);
          final file = File(absPath);
          await file.setLastModified(asset.dateCreated());
          await scanFile(absPath);
        } else if (Platform.isIOS) {
          var appDocDir = await getTemporaryDirectory();
          String savePath = "${appDocDir.path}/${asset.name()}";
          await asset.remote!.downloadToFile(savePath);
          final file = File(savePath);
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
        .where((asset) => _isAssetSelected(asset) && asset.hasLocal)
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
      "${l10n.successfullyUpload} $uploaded ${l10n.photos}",
    );
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
                _selectionBarButton(Icons.close, l10n.cancel, clearSelection),
                _selectionBarButton(
                  Icons.share_outlined,
                  l10n.share,
                  _shareAsset,
                ),
                _selectionBarButton(
                  Icons.delete_outline,
                  l10n.delete,
                  () => _deleteSelected(),
                ),
                _selectionBarButton(
                  Icons.lock_outline,
                  l10n.moveToLockedFolder,
                  _moveToLockedFolder,
                ),
                _selectionBarButton(
                  Icons.cloud_upload_outlined,
                  l10n.upload,
                  uploadSelected,
                  isEnable: !model.isDownloading() && !model.isUploading(),
                ),
                _selectionBarButton(
                  Icons.cloud_download_outlined,
                  l10n.download,
                  downloadSelected,
                  isEnable: !model.isDownloading() && !model.isUploading(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _selectionBarButton(
    IconData icon,
    String text,
    Function()? onTap, {
    bool isEnable = true,
  }) {
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
            Text(
              text,
              style: TextStyle(
                color: isEnable
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withAlpha(97),
                fontSize: 12,
              ),
            ),
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
                '${l10n.delete} ${uploaded.length} ${l10n.photos}.',
              );
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
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return false;
    }
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text == correctPin),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _moveToLockedFolder() async {
    print(
      "_moveToLockedFolder called, isSelectionMode: ${stateModel.isSelectionMode}",
    );
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
    final assets = all.where(_isAssetSelected).toList();

    if (assets.isEmpty) {
      SnackBarManager.showSnackBar(l10n.noPhotosSelected);
      clearSelection();
      return;
    }

    // Delete local copies
    final localIds = assets
        .where((e) => e.hasLocal)
        .map((e) => e.local!.id)
        .toList();
    if (localIds.isNotEmpty) {
      try {
        await PhotoManager.editor.deleteWithIds(localIds);
      } catch (e) {
        print("Failed to delete local photos: $e");
      }
    }

    // Move remote copies to locked folder on server
    final remotePaths = assets
        .where((e) => e.hasRemote)
        .map((e) => e.remote!.path)
        .toList();
    if (remotePaths.isNotEmpty) {
      try {
        final rsp = await storage.cli.moveToLocked(
          MoveToLockedRequest(paths: remotePaths),
        );
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
    SnackBarManager.showSnackBar(
      '${assets.length} ${l10n.photos} ${l10n.moveToLockedFolder}',
    );
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
                Image.asset(
                  'assets/icon/lumina_icon_transparent.png',
                  width: 36,
                  height: 36,
                ),
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
                              Icon(
                                Icons.cloud_sync,
                                size: 18,
                                color: colorScheme.primary,
                              ),
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
                              Icon(
                                Icons.cloud_sync,
                                size: 18,
                                color: colorScheme.primary,
                              ),
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
                  icon: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    if (value == 'delete_uploaded') {
                      _showDeleteUploadedDialog(context);
                    } else if (value == 'settings') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingBody(),
                        ),
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
            key: _syncPanelKey,
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
    final dateFormat = DateFormat(
      'yyyy MMMM d${l10n.chineseday}  EEEEE',
      locale,
    );
    final layout = _layoutFor(all, columCount);
    final width = _galleryCrossAxisExtent > 0
        ? _galleryCrossAxisExtent
        : MediaQuery.sizeOf(context).width;
    _ensureTimelineGeometry(layout, width);

    return [
      SliverPrefixExtentList.builder(
        itemCount: layout.rows.length,
        itemExtents: _timelineRowExtents,
        cumulativeExtents: _timelineRowEnds,
        itemBuilder: (context, index) {
          final row = layout.rows[index];
          return KeyedSubtree(
            key: ValueKey(row.key),
            child: _buildGalleryRow(
              context,
              layout,
              row,
              dateFormat,
              colorScheme,
            ),
          );
        },
        findChildIndexCallback: (key) {
          if (key is! ValueKey<String>) return null;
          return layout.rowIndexByKey[key.value];
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 80)),
    ];
  }

  Widget _buildGalleryRow(
    BuildContext context,
    _GalleryLayout layout,
    _GalleryRow row,
    DateFormat dateFormat,
    ColorScheme colorScheme,
  ) {
    TimelineScrubDiagnostics.recordRowBuild();
    final header = row.header;
    if (header != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          dateFormat.format(header),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize =
            (constraints.maxWidth - _gridSpacing * (layout.columns - 1)) /
            layout.columns;
        final children = <Widget>[];
        for (int slot = 0; slot < row.count; slot++) {
          if (slot > 0) {
            children.add(const SizedBox(width: _gridSpacing));
          }
          children.add(
            SizedBox(
              width: tileSize,
              child: _buildPhotoTile(
                context,
                layout.assets,
                layout.visible[row.start + slot],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: _gridSpacing),
          child: SizedBox(
            height: tileSize,
            child: Row(children: children),
          ),
        );
      },
    );
  }

  Widget _buildPhotoTile(
    BuildContext context,
    List<Asset> all,
    int globalIndex,
  ) {
    TimelineScrubDiagnostics.recordTileBuild();
    final asset = all[globalIndex];
    final id = asset.stableId();
    return _PhotoTile(
      key: ValueKey(id),
      asset: asset,
      thumbnailResumeSignal: _thumbnailResumeSignal,
      canLoadThumbnail: _canLoadTimelineThumbnails,
      isSelected: _isAssetSelected(asset),
      onTap: () {
        if (stateModel.isSelectionMode) {
          toggleSelection(asset);
        } else {
          Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (_, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
              pageBuilder: (_, _, _) =>
                  GalleryViewerRoute(originIndex: globalIndex),
            ),
          );
        }
      },
      onLongPress: () {
        if (!stateModel.isSelectionMode) toggleSelection(asset);
      },
    );
  }

  /// Row layout for the "all" view, rebuilt only when the asset list instance
  /// or the column count changes.
  _GalleryLayout _layoutFor(List<Asset> all, int columns) {
    final cached = _galleryLayout;
    if (cached != null &&
        identical(cached.assets, all) &&
        cached.columns == columns) {
      return cached;
    }
    final layout = _GalleryLayout.build(all, columns);
    _galleryLayout = layout;
    return layout;
  }

  void _ensureTimelineGeometry(_GalleryLayout layout, double width) {
    final stopwatch = Stopwatch()..start();
    final textScaler = MediaQuery.textScalerOf(context);
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final fontSize = textStyle?.fontSize ?? 14;
    final scaledFontSize = textScaler.scale(fontSize);
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (identical(_timelineGeometryLayout, layout) &&
        _timelineGeometryWidth == width &&
        _timelineGeometryScaledFontSize == scaledFontSize &&
        _timelineGeometryTextStyle == textStyle &&
        _timelineGeometryLocale == locale) {
      TimelineScrubDiagnostics.recordGeometry(
        cacheHit: true,
        microseconds: stopwatch.elapsedMicroseconds,
      );
      return;
    }

    final tileExtent =
        (width - _gridSpacing * (layout.columns - 1)) / layout.columns +
        _gridSpacing;
    final dateFormat = DateFormat(
      'yyyy MMMM d${l10n.chineseday}  EEEEE',
      Localizations.localeOf(context).languageCode,
    );
    final rowExtents = <double>[];
    final rowEnds = <double>[];
    final yearOffsets = <int, double>{};
    var cumulativeExtent = 0.0;
    for (final row in layout.rows) {
      final header = row.header;
      final double rowExtent;
      if (header == null) {
        rowExtent = tileExtent;
      } else {
        yearOffsets.putIfAbsent(header.year, () => cumulativeExtent);
        final painter = TextPainter(
          text: TextSpan(text: dateFormat.format(header), style: textStyle),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
        )..layout(maxWidth: width - 32);
        rowExtent = 28 + painter.height;
        painter.dispose();
      }
      rowExtents.add(rowExtent);
      cumulativeExtent += rowExtent;
      rowEnds.add(cumulativeExtent);
    }

    _timelineGeometryLayout = layout;
    _timelineGeometryWidth = width;
    _timelineGeometryScaledFontSize = scaledFontSize;
    _timelineGeometryTextStyle = textStyle;
    _timelineGeometryLocale = locale;
    _timelineRowExtents = rowExtents;
    _timelineRowEnds = rowEnds;
    _timelineYearOffsets = yearOffsets;
    _timelineMarkerScrollableExtent = -1;
    TimelineScrubDiagnostics.recordGeometry(
      cacheHit: false,
      microseconds: stopwatch.elapsedMicroseconds,
    );
  }

  DateTime? _timelineDateAt(ScrollMetrics metrics) {
    return _timelineDateAtPixels(metrics.pixels);
  }

  DateTime? _timelineDateForFraction(double fraction) {
    if (!_scrollController.hasClients) return null;
    final position = _scrollController.position;
    final scrollableExtent =
        position.maxScrollExtent - position.minScrollExtent;
    return _timelineDateAtPixels(
      position.minScrollExtent + scrollableExtent * fraction,
    );
  }

  DateTime? _timelineDateAtPixels(double pixels) {
    final layout = _galleryLayout;
    if (layout == null || layout.rows.isEmpty) return null;
    final width =
        _scrollViewKey.currentContext?.size?.width ??
        MediaQuery.sizeOf(context).width;
    _ensureTimelineGeometry(layout, width);

    final syncPanelExtent = _syncPanelKey.currentContext?.size?.height ?? 0;
    final contentOffset = pixels - 56 - syncPanelExtent;
    final target = contentOffset.clamp(0.0, _timelineRowEnds.last);
    var low = 0;
    var high = _timelineRowEnds.length - 1;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_timelineRowEnds[middle] <= target) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }

    final row = layout.rows[low];
    if (row.header != null) return row.header;
    if (row.start >= layout.visible.length) return null;
    return layout.assets[layout.visible[row.start]].dateCreated();
  }

  List<TimelineMarker> _timelineMarkersAt(ScrollMetrics metrics) {
    final layout = _galleryLayout;
    if (layout == null || layout.rows.isEmpty) return const [];
    final width =
        _scrollViewKey.currentContext?.size?.width ??
        MediaQuery.sizeOf(context).width;
    _ensureTimelineGeometry(layout, width);

    final scrollableExtent = metrics.maxScrollExtent - metrics.minScrollExtent;
    if (scrollableExtent <= 0) return const [];
    final leadingExtent =
        56.0 + (_syncPanelKey.currentContext?.size?.height ?? 0);
    if (_timelineMarkerScrollableExtent == scrollableExtent &&
        _timelineMarkerLeadingExtent == leadingExtent &&
        _timelineMarkerMinExtent == metrics.minScrollExtent) {
      return _timelineMarkers;
    }

    _timelineMarkers = _timelineYearOffsets.entries
        .map(
          (entry) => TimelineMarker(
            year: entry.key,
            scrollFraction:
                ((leadingExtent + entry.value - metrics.minScrollExtent) /
                        scrollableExtent)
                    .clamp(0.0, 1.0)
                    .toDouble(),
          ),
        )
        .toList(growable: false);
    _timelineMarkerScrollableExtent = scrollableExtent;
    _timelineMarkerLeadingExtent = leadingExtent;
    _timelineMarkerMinExtent = metrics.minScrollExtent;
    return _timelineMarkers;
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
        delegate: SliverChildBuilderDelegate((context, index) {
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
                MaterialPageRoute(builder: (_) => YearDetailBody(year: year)),
              );
            },
          );
        }, childCount: years.length),
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
        delegate: SliverChildBuilderDelegate((context, index) {
          final key = keys[index];
          final year = key ~/ 100;
          final month = key % 100;
          final info = monthMap[key]!;
          final label = DateFormat(
            'MMMM yyyy',
            locale,
          ).format(DateTime(year, month));
          return _TimeGroupTile(
            asset: info.asset,
            label: label,
            count: info.count,
            colorScheme: colorScheme,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MonthDetailBody(year: year, month: month),
                ),
              );
            },
          );
        }, childCount: keys.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    TimelineScrubDiagnostics.recordGalleryBuild();
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                _galleryCrossAxisExtent = constraints.maxWidth;
                return Consumer<AssetModel>(
                  builder: (context, model, child) {
                    TimelineScrubDiagnostics.recordAssetConsumerBuild();
                    return TimelineScrollbar(
                      controller: _scrollController,
                      dateForMetrics: _timelineDateAt,
                      dateForFraction: _timelineDateForFraction,
                      markersForMetrics: _timelineMarkersAt,
                      onScrubStateChanged: _setTimelineScrubbing,
                      interactive:
                          widget.viewMode != GalleryViewMode.all ||
                          model.localTimelineReady,
                      showDatePreview: widget.viewMode == GalleryViewMode.all,
                      child: CustomScrollView(
                        key: _scrollViewKey,
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        cacheExtent: 500,
                        slivers: [
                          _buildToolbar(),
                          _buildSyncPanel(),
                          ..._buildContentSlivers(context, model),
                        ],
                      ),
                    );
                  },
                );
              },
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
          Positioned(left: 0, right: 0, bottom: 0, child: _buildSelectionBar()),
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
  final ValueNotifier<int> thumbnailResumeSignal;
  final bool Function() canLoadThumbnail;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoTile({
    required Key key,
    required this.asset,
    required this.thumbnailResumeSignal,
    required this.canLoadThumbnail,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  bool _loaded = false;
  bool _imageMounted = false;

  @override
  void initState() {
    super.initState();
    widget.thumbnailResumeSignal.addListener(_resumeThumbnail);
    _loaded = widget.canLoadThumbnail() && widget.asset.loadThumbnailFinished();
    _kickOffThumbnail();
  }

  @override
  void didUpdateWidget(covariant _PhotoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnailResumeSignal != widget.thumbnailResumeSignal) {
      oldWidget.thumbnailResumeSignal.removeListener(_resumeThumbnail);
      widget.thumbnailResumeSignal.addListener(_resumeThumbnail);
    }
    if (oldWidget.asset != widget.asset) {
      _imageMounted = false;
      _loaded =
          widget.canLoadThumbnail() && widget.asset.loadThumbnailFinished();
      _kickOffThumbnail();
    }
  }

  @override
  void dispose() {
    widget.thumbnailResumeSignal.removeListener(_resumeThumbnail);
    super.dispose();
  }

  void _resumeThumbnail() {
    if (!mounted || !widget.canLoadThumbnail()) return;
    if (widget.asset.loadThumbnailFinished()) {
      if (!_loaded) setState(() => _loaded = true);
      return;
    }
    _kickOffThumbnail();
  }

  void _kickOffThumbnail() {
    if (!widget.canLoadThumbnail()) return;
    if (widget.asset.loadThumbnailFinished()) {
      _loaded = true;
      return;
    }
    TimelineScrubDiagnostics.recordThumbnailStart();
    widget.asset
        .thumbnailDataAsync()
        .then((_) {
          if (mounted && widget.canLoadThumbnail()) {
            setState(() => _loaded = true);
          }
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showImage =
        _loaded &&
        widget.asset.loadThumbnailFinished() &&
        (_imageMounted || widget.canLoadThumbnail());
    if (showImage && !_imageMounted) {
      TimelineScrubDiagnostics.recordImageMount();
      _imageMounted = true;
    }
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
              child: showImage
                  ? Image(
                      key: const ValueKey('img'),
                      image: widget.asset.thumbnailProvider(),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      // Cloud-only assets render straight from the network, so
                      // a backend that cannot thumbnail the file fails here
                      // rather than at load time.
                      errorBuilder: (context, error, stackTrace) =>
                          _tilePlaceholder(colorScheme),
                    )
                  : _tilePlaceholder(colorScheme),
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
                if (a.hasLocal &&
                    a.local != null &&
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
                  return const Icon(
                    Icons.cloud_outlined,
                    size: 14,
                    color: Colors.white,
                    shadows: _badgeShadows,
                  );
                }
                // A local photo that also exists remotely is backed up. Without
                // this the grid looks identical whether a photo is safe or has
                // never left the phone.
                if (a.hasLocal && a.hasRemote) {
                  return const Icon(
                    Icons.cloud_done,
                    size: 14,
                    color: Colors.white,
                    shadows: _badgeShadows,
                  );
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
                    errorBuilder: (context, error, stackTrace) =>
                        _tilePlaceholder(widget.colorScheme),
                  )
                : _tilePlaceholder(widget.colorScheme),
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
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                  Text(
                    '${widget.count} ${l10n.photos}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black54),
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
