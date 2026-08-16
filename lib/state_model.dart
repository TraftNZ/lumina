import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'event_bus.dart';
import 'package:lumina/asset.dart';
import 'dart:async';
import 'dart:convert';
import 'package:photo_manager/photo_manager.dart';
import 'package:lumina/storage/storage.dart';
import 'package:lumina/storage/hash_cache.dart';
import 'package:lumina/sync_engine.dart';
import 'package:lumina/sync_state_persistence.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:lumina/global.dart';
import 'package:lumina/setting_storage_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Duration _kIndexSyncThrottle = Duration(minutes: 10);
const Duration _kUnsyncedRefreshThrottle = Duration(minutes: 10);

String _driveSyncKey(SharedPreferences prefs) {
  final drive = prefs.getString("drive") ?? "SMB";
  String raw;
  switch (getDrive(drive)) {
    case Drive.smb:
      raw =
          'smb://${prefs.getString("username") ?? ""}@'
          '${prefs.getString("addr") ?? ""}/'
          '${prefs.getString("share") ?? ""}/'
          '${prefs.getString("rootPath") ?? ""}';
      break;
    case Drive.webDav:
      raw =
          'webdav://${prefs.getString("webdav_username") ?? ""}@'
          '${prefs.getString("webdav_url") ?? ""}/'
          '${prefs.getString("webdav_root_path") ?? ""}';
      break;
    case Drive.nfs:
      raw =
          'nfs://${prefs.getString("nfs_url") ?? ""}/'
          '${prefs.getString("nfs_root_path") ?? ""}';
      break;
    case Drive.s3:
      raw =
          's3://${prefs.getString("s3_access_key_id") ?? ""}@'
          '${prefs.getString("s3_endpoint") ?? ""}/'
          '${prefs.getString("s3_bucket") ?? ""}/'
          '${prefs.getString("s3_root_path") ?? ""}';
      break;
    case Drive.cloudreve:
      raw =
          'cloudreve://${prefs.getString("cloudreve_email") ?? ""}@'
          '${prefs.getString("cloudreve_server") ?? ""}/'
          '${prefs.getString("cloudreve_root_path") ?? ""}';
      break;
  }
  return sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
}

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
    setRemoteStorageReady(setted);
  }

  void setRemoteStorageReady(bool setted, {bool forceRefresh = false}) {
    final changed = isRemoteStorageSetted != setted;
    if (!changed && !forceRefresh) return;
    isRemoteStorageSetted = setted;
    eventBus.fire(RemoteRefreshEvent(force: forceRefresh));
    if (changed) notifyListeners();
  }
}

Future<void> saveRemoteStorageConfiguration({
  required Drive drive,
  required Map<String, String> settings,
}) async {
  final prefs = await SharedPreferences.getInstance();
  for (final entry in settings.entries) {
    await prefs.setString(entry.key, entry.value);
  }
  await prefs.setString('drive', driveName[drive]!);

  assetModel.remoteLastError = null;
  settingModel.setRemoteStorageReady(true, forceRefresh: true);
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
    eventBus
        .on<RemoteRefreshEvent>()
        .listen((event) => refreshRemote(force: event.force));
    // Hashes pair a local photo with its upload; load them before the first
    // merge so matching does not silently fall back to filenames on cold start.
    HashCache.instance.warmUp().then((_) {
      _unifiedDirty = true;
      notifyListeners();
    });
  }
  List<Asset> localAssets = [];
  List<Asset> remoteAssets = [];
  List<Asset> _unifiedAssets = [];
  List<Asset>? _searchResults;
  bool _unifiedDirty = true;
  int columCount = 4;
  int pageSize = 200;
  bool localHasMore = true;
  bool remoteHasMore = true;
  Completer<bool>? localGetting;
  Completer<bool>? remoteGetting;
  Future<void>? _localTimelineLoadFuture;
  Future<void>? _localRefreshFuture;
  bool _localTimelineComplete = false;
  Future<void>? _remoteRefreshFuture;
  bool _remoteRefreshPending = false;
  bool _forceRemoteRefreshPending = false;
  final Set<String> _removedRemotePaths = {};

  String? remoteLastError;
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool get hasMore => localHasMore || remoteHasMore;
  bool get localTimelineReady =>
      _localTimelineComplete && localGetting == null;

  List<Asset> getUnifiedAssets() {
    if (_searchResults != null) return _searchResults!;
    if (_unifiedDirty) _rebuildUnifiedList();
    return _unifiedAssets;
  }

  /// Pairs local photos with their uploaded copies.
  ///
  /// Identity is the file content, never the date. The server rewrites an
  /// upload's date from EXIF or the original filename when the client-supplied
  /// one looks wrong, so a photo taken in 2017 but added to the library in 2026
  /// lands under `2017/12/16/` while the local asset still reports 2026 — a
  /// date-keyed match can never pair those, and the photo renders twice.
  /// Matching prefers the content hash the server embeds in the filename and
  /// falls back to the filename itself for uploads that predate the hash.
  void _rebuildUnifiedList() {
    final remoteByHash = <String, Asset>{};
    final remoteByName = <String, List<Asset>>{};
    for (final a in remoteAssets) {
      final hash = a.remoteContentHash;
      if (hash != null) remoteByHash[hash] = a;
      final n = a.matchName;
      if (n != null) remoteByName.putIfAbsent(n, () => []).add(a);
    }

    final matchedRemotes = <String>{};
    for (final a in localAssets) {
      final match = _findRemoteFor(a, remoteByHash, remoteByName);
      if (match?.remote != null) {
        a.hasRemote = true;
        a.remote = match!.remote;
        matchedRemotes.add(match.remote!.path);
      } else {
        a.hasRemote = false;
        a.remote = null;
      }
    }

    final cloudOnly = remoteAssets.where(
        (a) => a.remote == null || !matchedRemotes.contains(a.remote!.path));

    _unifiedAssets = [...localAssets, ...cloudOnly];
    _unifiedAssets.sort((a, b) => b.dateCreated().compareTo(a.dateCreated()));
    _unifiedDirty = false;
  }

  /// Resolves the uploaded copy of [local], by content hash when both sides
  /// know it, otherwise by filename. When several uploads share a filename the
  /// one created nearest the local date wins, since that is the only signal
  /// left to separate genuinely different photos that reuse a name.
  Asset? _findRemoteFor(
    Asset local,
    Map<String, Asset> remoteByHash,
    Map<String, List<Asset>> remoteByName,
  ) {
    final entity = local.local;
    if (entity != null) {
      final hash = HashCache.instance.cachedHash(entity);
      if (hash != null && hash.length >= Asset.remoteHashLength) {
        final byHash = remoteByHash[hash.substring(0, Asset.remoteHashLength)];
        if (byHash != null) return byHash;
      }
    }

    final n = local.matchName;
    if (n == null) return null;
    final candidates = remoteByName[n];
    if (candidates == null || candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    final localDate = local.dateCreated();
    return candidates.reduce((a, b) =>
        a.dateCreated().difference(localDate).abs() <=
                b.dateCreated().difference(localDate).abs()
            ? a
            : b);
  }

  void removeAssets(List<Asset> assets) {
    final toRemove = assets.toSet();
    final localIds = assets
        .map((asset) => asset.local?.id)
        .whereType<String>()
        .toSet();
    final remotePaths = assets
        .map((asset) => asset.remote?.path)
        .whereType<String>()
        .toSet();
    _removedRemotePaths.addAll(remotePaths);
    bool shouldRemove(Asset asset) =>
        toRemove.contains(asset) ||
        asset.local != null && localIds.contains(asset.local!.id) ||
        asset.remote != null && remotePaths.contains(asset.remote!.path);

    localAssets = localAssets.where((asset) => !shouldRemove(asset)).toList();
    remoteAssets = remoteAssets.where((asset) => !shouldRemove(asset)).toList();
    final searchResults = _searchResults;
    if (searchResults != null) {
      _searchResults = searchResults
          .where((asset) => !shouldRemove(asset))
          .toList();
    }
    _unifiedDirty = true;
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

  Future<void> loadLocalTimeline() {
    final activeRefresh = _localRefreshFuture;
    if (activeRefresh != null) return activeRefresh;
    final active = _localTimelineLoadFuture;
    if (active != null) return active;

    final wasComplete = _localTimelineComplete;
    _localTimelineComplete = false;
    notifyListeners();
    var succeeded = false;
    late final Future<void> operation;
    operation = Future<void>.sync(_loadRemainingLocalPhotos)
        .then<void>((_) => succeeded = true)
        .whenComplete(() {
      if (identical(_localTimelineLoadFuture, operation)) {
        _localTimelineLoadFuture = null;
      }
      _localTimelineComplete = succeeded || wasComplete;
      notifyListeners();
    });
    _localTimelineLoadFuture = operation;
    return operation;
  }

  Future<void> _loadRemainingLocalPhotos() async {
    while (localHasMore) {
      final previousCount = localAssets.length;
      await getLocalPhotos(
        batchSize: 1000,
        incrementalNotifications: false,
      );
      await Future<void>.delayed(Duration.zero);
      if (localAssets.length == previousCount) break;
    }
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

  Future<void> refreshLocal() {
    final active = _localRefreshFuture;
    if (active != null) return active;

    late final Future<void> operation;
    operation = Future<void>.sync(_refreshLocal).whenComplete(() {
      if (identical(_localRefreshFuture, operation)) {
        _localRefreshFuture = null;
      }
    });
    _localRefreshFuture = operation;
    return operation;
  }

  Future<void> _refreshLocal() async {
    if (localGetting != null) {
      await localGetting!.future;
    }
    final activeTimelineLoad = _localTimelineLoadFuture;
    if (activeTimelineLoad != null) {
      await activeTimelineLoad;
    }
    final wasTimelineComplete = _localTimelineComplete;
    final wasLocalHasMore = localHasMore;
    _localTimelineComplete = false;
    notifyListeners();

    final isFirstLoad = localAssets.isEmpty;
    final reuseMap = <String, Asset>{};
    for (final a in localAssets) {
      if (a.hasLocal) {
        reuseMap[a.local!.id] = a;
      }
    }
    localHasMore = true;
    try {
      if (isFirstLoad) {
        // Cold start: preserve incremental notify for fast first-paint, then
        // complete the timeline so the scrubber has a stable extent.
        localAssets = [];
        _unifiedDirty = true;
        stateModel.setNotSyncedPhotos([]);
        await getLocalPhotos(reuseMap: reuseMap);
        await _loadRemainingLocalPhotos();
        _localTimelineComplete = true;
        notifyListeners();
      } else {
        // Build the complete next snapshot off-screen and swap atomically so
        // refresh never truncates the visible timeline to its first page.
        final buffer = <Asset>[];
        while (localHasMore) {
          final previousCount = buffer.length;
          await getLocalPhotos(
            reuseMap: reuseMap,
            targetList: buffer,
            batchSize: 1000,
            incrementalNotifications: false,
          );
          if (buffer.length == previousCount) break;
        }
        localAssets = buffer;
        _localTimelineComplete = true;
        _unifiedDirty = true;
        stateModel.setNotSyncedPhotos([]);
        notifyListeners();
        if (!stateModel.refreshingUnsynchronized) {
          refreshUnsynchronizedPhotos(force: true);
        }
      }
    } catch (_) {
      // The old complete snapshot remains visible when a buffered refresh
      // fails, so restore its scrubber readiness before propagating the error.
      _localTimelineComplete = wasTimelineComplete;
      localHasMore = wasLocalHasMore;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshRemote({bool force = false}) async {
    _remoteRefreshPending = true;
    _forceRemoteRefreshPending |= force;
    final active = _remoteRefreshFuture;
    if (active != null) return active;

    final operation = _drainRemoteRefreshes();
    _remoteRefreshFuture = operation;
    return operation;
  }

  Future<void> _drainRemoteRefreshes() async {
    try {
      while (_remoteRefreshPending) {
        final force = _forceRemoteRefreshPending;
        _remoteRefreshPending = false;
        _forceRemoteRefreshPending = false;
        await _fetchRemotePhotos(force: force);
      }
    } finally {
      _remoteRefreshFuture = null;
    }
  }

  Future<void> _fetchRemotePhotos({bool force = false}) async {
    if (!isServerReady) return;
    if (!settingModel.isRemoteStorageSetted) return;
    await checkServer();
    // Keep existing local and remote assets visible while the remote index is
    // refreshed. Only remote fetches are serialized by refreshRemote().
    remoteHasMore = true;
    remoteGetting = Completer<bool>();
    final reuseMap = <String, Asset>{};
    for (final a in remoteAssets) {
      if (a.hasRemote) {
        reuseMap[a.remote!.path] = a;
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final driveSyncKey = _driveSyncKey(prefs);
      final persistence = await SyncStatePersistence.create();
      final lastIndexSyncAt = persistence.lastIndexSyncAtForDrive(driveSyncKey);
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
        final visibleCachedAssets = cachedAssets
            .where(
              (asset) =>
                  !_removedRemotePaths.contains(asset.remote?.path),
            )
            .toList();
        remoteAssets = visibleCachedAssets;
        _unifiedDirty = true;
        notifyListeners();
        _persistRemotePaths(visibleCachedAssets);
      }

      if (force || cachedImages.isEmpty && lastIndexSyncAt == null) {
        await _syncIndexAndRefreshRemote(force: true);
        await persistence.setLastIndexSyncAtForDrive(
          driveSyncKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        // Cached rows have already been published above. Awaiting here keeps
        // remote index operations ordered without blocking the local gallery.
        await _syncIndexIfNeeded();
      }
    } catch (e) {
      remoteLastError = e.toString();
    } finally {
      remoteHasMore = false;
      _unifiedDirty = true;
      notifyListeners();
      remoteGetting?.complete(true);
      remoteGetting = null;
    }
  }

  Future<void> _syncIndexIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final driveSyncKey = _driveSyncKey(prefs);
    final persistence = await SyncStatePersistence.create();
    final last = persistence.lastIndexSyncAtForDrive(driveSyncKey);
    if (last != null) {
      final age = DateTime.now().millisecondsSinceEpoch - last;
      if (age >= 0 && age < _kIndexSyncThrottle.inMilliseconds) {
        return;
      }
    }
    await _syncIndexAndRefreshRemote(force: false);
    await persistence.setLastIndexSyncAtForDrive(
      driveSyncKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _syncIndexAndRefreshRemote({required bool force}) async {
    if (force) {
      await storage.fullResyncIndex();
    } else {
      await storage.syncIndex();
    }
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
    final visibleRemoteAssets = newRemoteAssets
        .where(
          (asset) => !_removedRemotePaths.contains(asset.remote?.path),
        )
        .toList();
    remoteAssets = visibleRemoteAssets;
    _unifiedDirty = true;
    notifyListeners();
    await _persistRemotePaths(visibleRemoteAssets);
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
          .where(
            (path) =>
                path.isNotEmpty && !_removedRemotePaths.contains(path),
          )
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
    int? batchSize,
    bool incrementalNotifications = true,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      localHasMore = false;
      return;
    }
    if (localGetting != null) {
      await localGetting?.future;
      return;
    }
    final operation = Completer<bool>();
    localGetting = operation;
    Object? loadError;
    StackTrace? loadStackTrace;
    try {
      await _loadLocalPhotoBatch(
        reuseMap: reuseMap,
        targetList: targetList,
        batchSize: batchSize,
        incrementalNotifications: incrementalNotifications,
      );
    } catch (error, stackTrace) {
      loadError = error;
      loadStackTrace = stackTrace;
    }
    if (loadError == null) {
      operation.complete(true);
    } else {
      operation.completeError(loadError, loadStackTrace!);
    }
    try {
      await operation.future;
    } finally {
      if (identical(localGetting, operation)) localGetting = null;
    }
  }

  Future<void> _loadLocalPhotoBatch({
    Map<String, Asset>? reuseMap,
    List<Asset>? targetList,
    int? batchSize,
    required bool incrementalNotifications,
  }) async {
    // When targetList is non-null we're populating a detached buffer (used by
    // refreshLocal's atomic-swap path); skip incremental notifyListeners and
    // post-load hooks so the live list isn't touched until the final swap.
    final list = targetList ?? localAssets;
    final atomic = targetList != null;
    final offset = list.length;
    final re = await requestPermission();
    if (!re) {
      localHasMore = false;
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
      localHasMore = false;
      return;
    }

    final newpath = await allPath.fetchPathProperties(
      filterOptionGroup: FilterOptionGroup(
        // Titles must come back with the query. On iOS AssetEntity.title is null
        // unless needTitle is set, and the filename is what pairs a local photo
        // with an upload the content hash cannot reach: without it those photos
        // render twice, once local and once cloud-only.
        imageOption: const FilterOption(needTitle: true),
        videoOption: const FilterOption(needTitle: true),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
    if (newpath == null) {
      localHasMore = false;
      return;
    }
    final requestedBatchSize = batchSize ?? pageSize;
    final List<AssetEntity> entities = await newpath.getAssetListRange(
      start: offset,
      end: offset + requestedBatchSize,
    );
    if (entities.length < requestedBatchSize) {
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
      if (!atomic && incrementalNotifications) {
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
  }

  Future<void> getRemotePhotos() async {
    await refreshRemote();
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

      await const MethodChannel(
        'com.traftai.lumina/RunGrpcServer',
      ).invokeMethod('scanFile', params);
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

  // Stamp the attempt before scanning, not after it succeeds. The scan reads
  // every original off disk to hash it; if that gets the process killed, a
  // timestamp written only on success would leave the throttle unarmed and the
  // next cold start would repeat the identical scan — a boot loop the app
  // could never escape on its own.
  await persistence
      .setLastUnsyncedRefreshAt(DateTime.now().millisecondsSinceEpoch);

  final engine = SyncEngine(
    grpcPort: grpcPort,
    httpPort: httpPort,
    localFolder: settingModel.localFolder,
  );
  try {
    final ids = await engine.findNotUploadedIds();
    stateModel.setNotSyncedPhotos(ids);
    await persistence.setCachedNotSyncedIDs(ids);
  } catch (e) {
    print('Error: $e');
    SnackBarManager.showSnackBar("Error: $e");
  }

  stateModel.setRefreshingUnsynchronized(false);
}
