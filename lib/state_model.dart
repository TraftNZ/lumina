import 'dart:io';
import 'package:flutter/material.dart';
import 'event_bus.dart';
import 'package:lumina/asset.dart';
import 'dart:async';
import 'package:photo_manager/photo_manager.dart';
import 'package:lumina/storage/storage.dart';
import 'package:lumina/sync_engine.dart';
import 'package:lumina/sync_state_persistence.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:lumina/global.dart';

const Duration _kIndexSyncThrottle = Duration(minutes: 10);
const Duration _kUnsyncedRefreshThrottle = Duration(minutes: 10);

SettingModel settingModel = SettingModel();
AssetModel assetModel = AssetModel();
StateModel stateModel = StateModel();

enum Drive { smb, webDav, nfs, s3, cloudreve }

Map<Drive, String> driveName = {
  Drive.smb: 'SMB',
  Drive.webDav: 'WebDAV',
  Drive.nfs: 'NFS',
  Drive.s3: 'S3',
  Drive.cloudreve: 'Cloudreve',
};

class SettingModel extends ChangeNotifier {
  String localFolder = "";
  String? localFolderAbsPath;
  bool isRemoteStorageSetted = false;

  void setLocalFolder(String folder) {
    if (localFolder == folder) return;
    localFolder = folder;
    localFolderAbsPath = null;
    eventBus.fire(LocalRefreshEvent());
    notifyListeners();
  }

  void setRemoteStorageSetted(bool setted) {
    if (isRemoteStorageSetted == setted) return;
    isRemoteStorageSetted = setted;
    eventBus.fire(RemoteRefreshEvent());
    notifyListeners();
  }
}

class transmitState {
  int transmitted = 0;
  int total = 0;
}

class StateModel extends ChangeNotifier {
  bool _isSelectionMode = false;
  bool refreshingUnsynchronized = false;
  List<String> notSyncedIDs = [];

  Map<String, transmitState> uploadProgress = {};
  Map<String, transmitState> downloadProgress = {};

  bool get isSelectionMode => _isSelectionMode;

  void updateUploadProgress(String id, int transmitted, int total) {
    if (!uploadProgress.containsKey(id)) {
      uploadProgress[id] = transmitState();
    }
    uploadProgress[id]!.transmitted = transmitted;
    uploadProgress[id]!.total = total;
    notifyListeners();
  }

  void finishUpload(String id, bool success) {
    uploadProgress.remove(id);
    if (success) {
      notSyncedIDs.remove(id);
    }
    notifyListeners();
  }

  void updateDownloadProgress(String id, int transmitted, int total) {
    if (!downloadProgress.containsKey(id)) {
      downloadProgress[id] = transmitState();
    }
    downloadProgress[id]!.transmitted = transmitted;
    downloadProgress[id]!.total = total;
    notifyListeners();
  }

  void finishDownload(String id, bool success) {
    downloadProgress.remove(id);
    notifyListeners();
  }

  double getUploadPercent(String id) {
    if (!uploadProgress.containsKey(id)) {
      return 0;
    }
    final state = uploadProgress[id]!;
    return state.transmitted / state.total;
  }

  double getDownloadPercent(String id) {
    if (!downloadProgress.containsKey(id)) {
      return 0;
    }
    final state = downloadProgress[id]!;
    return state.transmitted / state.total;
  }

  bool isUploading() {
    return uploadProgress.isNotEmpty;
  }

  bool isDownloading() {
    return downloadProgress.isNotEmpty;
  }

  void setSelectionMode(bool mode) {
    if (_isSelectionMode == mode) return;
    _isSelectionMode = mode;
    notifyListeners();
  }

  void setNotSyncedPhotos(List<String> ids) {
    notSyncedIDs = ids;
    notifyListeners();
  }

  void setRefreshingUnsynchronized(bool refreshing) {
    if (refreshingUnsynchronized == refreshing) return;
    refreshingUnsynchronized = refreshing;
    notifyListeners();
  }

  int syncTotal = 0;
  int syncDone = 0;
  String? syncCurrentFile;
  bool syncCancelled = false;

  bool get isSyncing => syncTotal > 0 && syncDone < syncTotal;

  void startSync(int total) {
    syncDone = 0;
    syncTotal = total;
    syncCurrentFile = null;
    syncCancelled = false;
    notifyListeners();
  }

  void advanceSync(String? fileName) {
    syncDone++;
    syncCurrentFile = fileName;
    notifyListeners();
  }

  void finishSync() {
    syncTotal = 0;
    syncDone = 0;
    syncCurrentFile = null;
    syncCancelled = false;
    notifyListeners();
  }

  void cancelSync() {
    syncCancelled = true;
    notifyListeners();
  }

  bool indexSyncing = false;
  String? indexSyncMessage;
  int? indexSyncResult;

  void startIndexSync(String message) {
    indexSyncing = true;
    indexSyncMessage = message;
    indexSyncResult = null;
    notifyListeners();
  }

  void finishIndexSync(int totalFiles) {
    indexSyncing = false;
    indexSyncResult = totalFiles;
    notifyListeners();
  }
}

class AssetModel extends ChangeNotifier {
  AssetModel() {
    eventBus.on<LocalRefreshEvent>().listen((event) => refreshLocal());
    // Event-bus fires (cold start initDrive, post-upload, post-delete, timer)
    // go through the throttled path — the backend DB already reflects the
    // change, so a full syncIndex within _kIndexSyncThrottle is skipped.
    eventBus.on<RemoteRefreshEvent>().listen((event) => refreshRemote());
  }
  List<Asset> localAssets = [];
  List<Asset> remoteAssets = [];
  List<Asset> _unifiedAssets = [];
  List<Asset>? _searchResults;
  bool _unifiedDirty = true;
  int columCount = 4;
  int pageSize = 500;
  bool localHasMore = true;
  bool remoteHasMore = true;
  Completer<bool>? localGetting;
  Completer<bool>? remoteGetting;

  String? remoteLastError;
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool get hasMore => localHasMore || remoteHasMore;

  List<Asset> getUnifiedAssets() {
    if (_searchResults != null) return _searchResults!;
    if (_unifiedDirty) _rebuildUnifiedList();
    return _unifiedAssets;
  }

  void _rebuildUnifiedList() {
    // Index remote assets by dedup key
    final remoteByKey = <String, Asset>{};
    for (final a in remoteAssets) {
      final key = a.dedupKey;
      if (key != null) remoteByKey[key] = a;
    }

    // Merge: local assets gain remote info when a match exists
    final matchedRemoteKeys = <String>{};
    for (final a in localAssets) {
      final key = a.dedupKey;
      if (key != null && remoteByKey.containsKey(key)) {
        a.hasRemote = true;
        a.remote = remoteByKey[key]!.remote;
        matchedRemoteKeys.add(key);
      } else {
        a.hasRemote = false;
        a.remote = null;
      }
    }

    // Cloud-only: remote assets with no local match
    final cloudOnly = remoteAssets.where((a) {
      final key = a.dedupKey;
      return key == null || !matchedRemoteKeys.contains(key);
    });

    _unifiedAssets = [...localAssets, ...cloudOnly];
    _unifiedAssets.sort((a, b) => b.dateCreated().compareTo(a.dateCreated()));
    _unifiedDirty = false;
  }

  void removeAssets(List<Asset> assets) {
    final toRemove = assets.toSet();
    localAssets.removeWhere((a) => toRemove.contains(a));
    remoteAssets.removeWhere((a) => toRemove.contains(a));
    _unifiedAssets.removeWhere((a) => toRemove.contains(a));
    _searchResults?.removeWhere((a) => toRemove.contains(a));
    notifyListeners();
  }

  void setSearchResults(List<Asset> results) {
    _searchResults = results;
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = null;
    notifyListeners();
  }

  Future<void> getMorePhotos() async {
    final futures = <Future>[];
    if (localHasMore) futures.add(getLocalPhotos());
    if (remoteHasMore) futures.add(getRemotePhotos());
    await Future.wait(futures);
  }

  Future<void> refreshAll() async {
    _isRefreshing = true;
    notifyListeners();
    try {
      await Future.wait([refreshLocal(), refreshRemote(force: true)]);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshLocal() async {
    if (localGetting != null) {
      await localGetting!.future;
    }
    final isFirstLoad = localAssets.isEmpty;
    final reuseMap = <String, Asset>{};
    for (final a in localAssets) {
      if (a.hasLocal) {
        reuseMap[a.local!.id] = a;
      }
    }
    localHasMore = true;
    if (isFirstLoad) {
      // Cold start: preserve incremental notify for fast first-paint.
      localAssets = [];
      _unifiedDirty = true;
      stateModel.setNotSyncedPhotos([]);
      await getLocalPhotos(reuseMap: reuseMap);
    } else {
      // True refresh: build the next snapshot into a buffer and swap atomically
      // so the grid never renders a half-empty intermediate state.
      final buffer = <Asset>[];
      await getLocalPhotos(reuseMap: reuseMap, targetList: buffer);
      localAssets = buffer;
      _unifiedDirty = true;
      stateModel.setNotSyncedPhotos([]);
      notifyListeners();
      if (!stateModel.refreshingUnsynchronized) {
        refreshUnsynchronizedPhotos(force: true);
      }
    }
  }

  Future<void> refreshRemote({bool force = false}) async {
    if (remoteGetting != null) {
      await remoteGetting!.future;
    }
    // Keep old data visible while fetching new data in background
    remoteHasMore = true;
    remoteGetting = null;
    await _fetchRemotePhotos(force: force);
  }

  Future<void> _fetchRemotePhotos({bool force = false}) async {
    if (!isServerReady) return;
    if (!settingModel.isRemoteStorageSetted) return;
    await checkServer();
    if (remoteGetting != null) {
      await remoteGetting!.future;
      return;
    }
    remoteGetting = Completer<bool>();
    final reuseMap = <String, Asset>{};
    for (final a in remoteAssets) {
      if (a.hasRemote) {
        reuseMap[a.remote!.path] = a;
      }
    }
    try {
      // Show cached data immediately (from local DB)
      final cachedImages = await storage.listImages("");
      if (cachedImages.isNotEmpty) {
        final List<Asset> cachedAssets = [];
        for (var image in cachedImages) {
          final existing = reuseMap[image.path];
          if (existing != null) {
            existing.remote = image;
            cachedAssets.add(existing);
          } else {
            cachedAssets.add(Asset(remote: image));
          }
        }
        remoteAssets = cachedAssets;
        _unifiedDirty = true;
        notifyListeners();
        _persistRemotePaths(cachedAssets);
      }

      // Sync index in background (slow for Cloudreve) — don't block UI.
      // Throttled so cold starts within _kIndexSyncThrottle skip the scan.
      _syncIndexInBackground(force: force);
    } catch (e) {
      remoteLastError = e.toString();
    }
    remoteHasMore = false;
    _unifiedDirty = true;
    notifyListeners();
    remoteGetting?.complete(true);
    remoteGetting = null;
  }

  void _syncIndexInBackground({bool force = false}) async {
    final persistence = await SyncStatePersistence.create();
    if (!force) {
      final last = persistence.lastIndexSyncAt;
      if (last != null) {
        final age = DateTime.now().millisecondsSinceEpoch - last;
        if (age >= 0 && age < _kIndexSyncThrottle.inMilliseconds) {
          return;
        }
      }
    }
    storage.syncIndex().then((_) async {
      final images = await storage.listImages("");
      final reuseMap = <String, Asset>{};
      for (final a in remoteAssets) {
        if (a.hasRemote) {
          reuseMap[a.remote!.path] = a;
        }
      }
      final List<Asset> newRemoteAssets = [];
      for (var image in images) {
        final existing = reuseMap[image.path];
        if (existing != null) {
          existing.remote = image;
          newRemoteAssets.add(existing);
        } else {
          newRemoteAssets.add(Asset(remote: image));
        }
      }
      remoteAssets = newRemoteAssets;
      _unifiedDirty = true;
      notifyListeners();
      await persistence
          .setLastIndexSyncAt(DateTime.now().millisecondsSinceEpoch);
      _persistRemotePaths(newRemoteAssets);
    }).catchError((e) {
      print("[AssetModel] Background sync error: $e");
    });
  }

  Future<void> _persistRemotePaths(List<Asset> assets) async {
    try {
      final persistence = await SyncStatePersistence.create();
      final paths = <String>[];
      for (final a in assets) {
        if (a.hasRemote && a.remote != null) paths.add(a.remote!.path);
      }
      await persistence.setCachedRemotePaths(paths);
    } catch (_) {}
  }

  /// Hydrate remoteAssets + notSyncedIDs from SharedPreferences so the grid
  /// paints yesterday's data instantly on cold start, before the gRPC server
  /// has finished starting. Safe to call before isServerReady.
  Future<void> hydrateFromCache() async {
    try {
      final persistence = await SyncStatePersistence.create();
      final paths = persistence.cachedRemotePaths
          .where((p) => p.isNotEmpty)
          .toList();
      if (paths.isNotEmpty && remoteAssets.isEmpty) {
        remoteAssets = paths
            .map((p) => Asset(remote: RemoteImage(storage.cli, p)))
            .toList();
        // Prevent scroll-triggered getMorePhotos from repeatedly hitting the
        // !isServerReady early-return before the real fetch runs. The
        // eventBus-driven refreshRemote() after initDrive resets this to true.
        remoteHasMore = false;
        _unifiedDirty = true;
      }
      final cachedIDs = persistence.cachedNotSyncedIDs;
      if (cachedIDs.isNotEmpty && stateModel.notSyncedIDs.isEmpty) {
        stateModel.notSyncedIDs = cachedIDs;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> getLocalPhotos({
    Map<String, Asset>? reuseMap,
    List<Asset>? targetList,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      localHasMore = false;
      return;
    }
    if (localGetting != null) {
      await localGetting?.future;
      return;
    }
    localGetting = Completer<bool>();
    // When targetList is non-null we're populating a detached buffer (used by
    // refreshLocal's atomic-swap path); skip incremental notifyListeners and
    // post-load hooks so the live list isn't touched until the final swap.
    final list = targetList ?? localAssets;
    final atomic = targetList != null;
    final offset = list.length;
    final re = await requestPermission();
    if (!re) {
      localGetting?.complete(true);
      localGetting = null;
      return;
    }
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );

    // Use the "all" path to show all photos on the device
    AssetPathEntity? allPath;
    for (var path in paths) {
      if (path.isAll) {
        allPath = path;
        break;
      }
    }
    if (allPath == null) {
      localGetting?.complete(true);
      localGetting = null;
      return;
    }

    final newpath = await allPath.fetchPathProperties(
        filterOptionGroup: FilterOptionGroup(
      orders: [
        const OrderOption(
          type: OrderOptionType.createDate,
          asc: false,
        ),
      ],
    ));
    final List<AssetEntity> entities = await newpath!
        .getAssetListRange(start: offset, end: offset + pageSize);
    if (entities.length < pageSize) {
      localHasMore = false;
    }
    for (var i = 0; i < entities.length; i++) {
      final existing = reuseMap?[entities[i].id];
      final Asset asset;
      if (existing != null) {
        existing.local = entities[i];
        asset = existing;
      } else {
        asset = Asset(local: entities[i]);
      }
      list.add(asset);
      if (!atomic) {
        // Notify immediately for the first batch so the grid appears fast,
        // then batch every 100 assets to avoid excessive rebuilds.
        if (i == 0 && offset == 0) {
          _unifiedDirty = true;
          notifyListeners();
        } else if (i % 100 == 0) {
          notifyListeners();
        }
      }
      // Do NOT await asset.getLocalFile() here: on iOS it triggers an iCloud
      // download per photo, serializing the whole page. Asset.name() falls
      // back to local!.title when localTitle is null, and thumbnails use
      // thumbnailDataWithSize which doesn't need originFile. The detail
      // viewer still lazy-loads the origin file on demand.
    }
    if (!atomic) {
      _unifiedDirty = true;
      notifyListeners();
      // Only trigger unsync check on initial load (offset == 0), not pagination,
      // and only if we haven't already fetched the list.
      if (offset == 0 &&
          stateModel.notSyncedIDs.isEmpty &&
          !stateModel.refreshingUnsynchronized) {
        refreshUnsynchronizedPhotos();
      }
    }

    localGetting?.complete(true);
    localGetting = null;
  }

  Future<void> getRemotePhotos() async {
    if (!isServerReady) return;
    if (remoteGetting != null) {
      await remoteGetting!.future;
      return;
    }
    await _fetchRemotePhotos();
  }
}

Future<void> resolveLocalFolderAbsPath() async {
  if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) return;
  if (settingModel.localFolder.isEmpty) return;
  if (settingModel.localFolderAbsPath != null) return;
  final re = await requestPermission();
  if (!re) return;
  final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
    type: RequestType.common,
  );
  for (var path in paths) {
    if (path.name == settingModel.localFolder) {
      final assets = await path.getAssetListRange(start: 0, end: 1);
      if (assets.isNotEmpty) {
        final file = await assets[0].originFile;
        if (file != null) {
          settingModel.localFolderAbsPath = file.parent.path;
        }
      }
      break;
    }
  }
}

Future<void> scanFile(String filePath) async {
  if (Platform.isAndroid) {
    try {
      final directory = await getExternalStorageDirectory();
      final path = directory?.path ?? '';
      final mimeType = lookupMimeType(filePath);
      final Map<String, dynamic> params = {
        'path': filePath,
        'volumeName': 'external_primary',
        'relativePath': filePath.replaceFirst('$path/', ''),
        'mimeType': mimeType,
      };

      await const MethodChannel('com.traftai.lumina/RunGrpcServer')
          .invokeMethod('scanFile', params);
    } on PlatformException catch (e) {
      print('Failed to scan file $filePath: ${e.message}');
    }
  }
}

Future<void> refreshUnsynchronizedPhotos({bool force = false}) async {
  if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) return;
  if (!isServerReady) return;
  await checkServer();
  if (!settingModel.isRemoteStorageSetted) {
    stateModel.setNotSyncedPhotos([]);
    return;
  }
  final persistence = await SyncStatePersistence.create();
  if (!force) {
    final last = persistence.lastUnsyncedRefreshAt;
    if (last != null) {
      final age = DateTime.now().millisecondsSinceEpoch - last;
      if (age >= 0 && age < _kUnsyncedRefreshThrottle.inMilliseconds) {
        return;
      }
    }
  }
  final re = await requestPermission();
  if (!re) return;
  stateModel.setRefreshingUnsynchronized(true);
  stateModel.setNotSyncedPhotos([]);

  final engine = SyncEngine(
    grpcPort: grpcPort,
    httpPort: httpPort,
    localFolder: settingModel.localFolder,
  );
  try {
    final ids = await engine.findNotUploadedIds();
    stateModel.setNotSyncedPhotos(ids);
    await persistence
        .setLastUnsyncedRefreshAt(DateTime.now().millisecondsSinceEpoch);
    await persistence.setCachedNotSyncedIDs(ids);
  } catch (e) {
    print('Error: $e');
    SnackBarManager.showSnackBar("Error: $e");
  }

  stateModel.setRefreshingUnsynchronized(false);
}
