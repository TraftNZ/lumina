import 'dart:io';
import 'package:date_format/date_format.dart';
import 'package:grpc/grpc.dart';
import 'package:flutter/material.dart';
import 'event_bus.dart';
import 'package:img_syncer/asset.dart';
import 'dart:async';
import 'package:photo_manager/photo_manager.dart';
import 'package:img_syncer/storage/storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:img_syncer/proto/img_syncer.pbgrpc.dart';
import 'package:img_syncer/global.dart';

SettingModel settingModel = SettingModel();
AssetModel assetModel = AssetModel();
StateModel stateModel = StateModel();

enum Drive { smb, webDav, nfs, s3 }

Map<Drive, String> driveName = {
  Drive.smb: 'SMB',
  Drive.webDav: 'WebDAV',
  Drive.nfs: 'NFS',
  Drive.s3: 'S3',
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
}

class AssetModel extends ChangeNotifier {
  AssetModel() {
    eventBus.on<LocalRefreshEvent>().listen((event) => refreshLocal());
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
    await Future.wait([refreshLocal(), refreshRemote()]);
  }

  Future<void> refreshLocal() async {
    if (localGetting != null) {
      await localGetting!.future;
    }
    localHasMore = true;
    localAssets = [];
    _unifiedDirty = true;
    notifyListeners();
    stateModel.setNotSyncedPhotos([]);
    await getLocalPhotos();
  }

  Future<void> refreshRemote() async {
    if (remoteGetting != null) {
      await remoteGetting!.future;
    }
    remoteHasMore = true;
    remoteAssets = [];
    _unifiedDirty = true;
    notifyListeners();
    remoteGetting = null;
    stateModel.setNotSyncedPhotos([]);
    await getRemotePhotos();
  }

  Future<void> getLocalPhotos() async {
    if (localGetting != null) {
      await localGetting?.future;
      return;
    }
    localGetting = Completer<bool>();
    final offset = localAssets.length;
    final re = await requestPermission();
    if (!re) return;
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
      final asset = Asset(local: entities[i]);
      await asset.getLocalFile();
      localAssets.add(asset);
      if (i % 100 == 0) {
        notifyListeners();
      }
    }
    _unifiedDirty = true;
    notifyListeners();
    if (stateModel.notSyncedIDs.isEmpty) {
      refreshUnsynchronizedPhotos();
    }

    localGetting?.complete(true);
    localGetting = null;
  }

  Future<void> getRemotePhotos() async {
    if (!isServerReady) return;
    await checkServer();
    if (remoteGetting != null) {
      await remoteGetting!.future;
      return;
    }
    remoteGetting = Completer<bool>();
    final offset = remoteAssets.length;
    try {
      final List<RemoteImage> images =
          await storage.listImages("9999:12:31", offset, pageSize);
      if (images.length < pageSize) {
        remoteHasMore = false;
      }
      for (var image in images) {
        try {
          final asset = Asset(remote: image);
          remoteAssets.add(asset);
          // asset.thumbnailDataAsync().then((value) => notifyListeners());
        } catch (e) {
          print(e);
        }
      }
      _unifiedDirty = true;
      notifyListeners();
    } catch (e) {
      remoteLastError = e.toString();
    }

    remoteGetting?.complete(true);
    remoteGetting = null;
  }
}

Future<void> resolveLocalFolderAbsPath() async {
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

      await const MethodChannel('com.example.img_syncer/RunGrpcServer')
          .invokeMethod('scanFile', params);
    } on PlatformException catch (e) {
      print('Failed to scan file $filePath: ${e.message}');
    }
  }
}

Future<void> refreshUnsynchronizedPhotos() async {
  if (!isServerReady) return;
  await checkServer();
  if (!settingModel.isRemoteStorageSetted) {
    stateModel.setNotSyncedPhotos([]);
    return;
  }
  final re = await requestPermission();
  if (!re) return;
  stateModel.setRefreshingUnsynchronized(true);
  stateModel.setNotSyncedPhotos([]);
  final requests = StreamController<FilterNotUploadedRequest>();
  final responses = storage.cli.filterNotUploaded(requests.stream);
  await Future.wait([
    sendFilterNotUploadedRequests(requests),
    receiveResponses(responses),
  ]);

  stateModel.setRefreshingUnsynchronized(false);
}

Future<void> sendFilterNotUploadedRequests(
    StreamController<FilterNotUploadedRequest> requests) async {
  final localFloder = settingModel.localFolder;
  final List<AssetPathEntity> paths =
      await PhotoManager.getAssetPathList(type: RequestType.common);
  for (var path in paths) {
    if (path.name == localFloder) {
      final newpath = await path.fetchPathProperties(
          filterOptionGroup: FilterOptionGroup(
        orders: [
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        ],
      ));
      int offset = 0;
      int pageSize = 50;

      while (true) {
        FilterNotUploadedRequest req = FilterNotUploadedRequest(
            photos: List<FilterNotUploadedRequestInfo>.empty(growable: true));
        final List<AssetEntity> assets = await newpath!
            .getAssetListRange(start: offset, end: offset + pageSize);
        if (assets.isEmpty) {
          req.isFinished = true;
          break;
        }
        var futures = <Future<FilterNotUploadedRequestInfo>>[];
        for (var asset in assets) {
          futures.add(_createFilterNotUploadedRequestInfo(asset));
        }
        req.photos.addAll(await Future.wait(futures));
        offset += pageSize;
        requests.add(req);
      }
      // final rsp = await storage.cli.filterNotUploaded(req);
      // if (rsp.success) {
      //   stateModel.setNotSyncedPhotos(rsp.notUploaedIDs);
      // } else {
      //   throw Exception("Refresh unsynchronized photos failed: ${rsp.message}");
      // }
    }
  }
  await requests.close();
}

Future<void> receiveResponses(
    ResponseStream<FilterNotUploadedResponse> responses) async {
  await for (var response in responses) {
    if (!response.success) {
      print('Error: ${response.message}');
      SnackBarManager.showSnackBar("Error: ${response.message}");
      continue;
    }
    stateModel
        .setNotSyncedPhotos(stateModel.notSyncedIDs + response.notUploaedIDs);
  }
}

Future<FilterNotUploadedRequestInfo> _createFilterNotUploadedRequestInfo(
    asset) async {
  var date = asset.createDateTime;
  if (date.isBefore(DateTime(1990, 1, 1))) {
    date = asset.modifiedDateTime;
  }
  final dateStr =
      formatDate(date, [yyyy, ':', mm, ':', dd, ' ', HH, ':', nn, ':', ss]);
  var name = await asset.titleAsync;
  return FilterNotUploadedRequestInfo(
    id: asset.id,
    name: name,
    date: dateStr,
  );
}
