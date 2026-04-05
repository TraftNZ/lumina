import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:date_format/date_format.dart';
import 'package:grpc/grpc.dart';
import 'package:lumina/proto/lumina.pbgrpc.dart';
import 'package:lumina/storage/hash_cache.dart';
import 'package:lumina/state_model.dart' show Drive;
import 'package:lumina/sync_state_persistence.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;
import 'package:lumina/setting_storage_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncProgress {
  final int total;
  final int completed;
  final String? currentFile;
  final double? currentFilePercent;

  SyncProgress({
    required this.total,
    required this.completed,
    this.currentFile,
    this.currentFilePercent,
  });
}

class SyncResult {
  final int uploaded;
  final int failed;
  final int skipped;
  final List<String> errors;

  SyncResult({
    required this.uploaded,
    required this.failed,
    required this.skipped,
    required this.errors,
  });
}

class CancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class SyncEngine {
  final String grpcHost;
  final int grpcPort;
  final int httpPort;
  final String localFolder;
  final bool wifiOnly;
  final CancellationToken? cancellationToken;
  final void Function(SyncProgress progress)? onProgress;

  late final LuminaClient _cli;
  late final String _httpBaseUrl;

  SyncEngine({
    this.grpcHost = '127.0.0.1',
    required this.grpcPort,
    required this.httpPort,
    required this.localFolder,
    this.wifiOnly = true,
    this.cancellationToken,
    this.onProgress,
  }) {
    final channel = ClientChannel(
      grpcHost,
      port: grpcPort,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _cli = LuminaClient(channel);
    _httpBaseUrl = 'http://$grpcHost:$httpPort';
  }

  Future<bool> initDriveFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    var drive = prefs.getString("drive");
    drive ??= "SMB";
    switch (getDrive(drive)) {
      case Drive.smb:
        final addr = prefs.getString("addr");
        final username = prefs.getString("username");
        final password = prefs.getString("password");
        final share = prefs.getString("share");
        final root = prefs.getString("rootPath");
        if (addr != null &&
            username != null &&
            password != null &&
            share != null &&
            root != null) {
          final rsp = await _cli.setDriveSMB(SetDriveSMBRequest(
            addr: addr,
            username: username,
            password: password,
            share: share,
            root: root,
          ));
          return rsp.success;
        }
        return false;
      case Drive.webDav:
        final url = prefs.getString('webdav_url');
        final username = prefs.getString('webdav_username');
        final password = prefs.getString('webdav_password');
        final root = prefs.getString('webdav_root_path');
        if (url != null && root != null) {
          final rsp = await _cli.setDriveWebdav(SetDriveWebdavRequest(
            addr: url,
            username: username,
            password: password,
            root: root,
          ));
          return rsp.success;
        }
        return false;
      case Drive.nfs:
        final addr = prefs.getString('nfs_url');
        final root = prefs.getString('nfs_root_path');
        if (addr != null && root != null) {
          final rsp = await _cli.setDriveNFS(SetDriveNFSRequest(
            addr: addr,
            root: root,
          ));
          return rsp.success;
        }
        return false;
      case Drive.s3:
        final endpoint = prefs.getString('s3_endpoint');
        final region = prefs.getString('s3_region');
        final accessKeyId = prefs.getString('s3_access_key_id');
        final secretAccessKey = prefs.getString('s3_secret_access_key');
        final bucket = prefs.getString('s3_bucket');
        final root = prefs.getString('s3_root_path');
        if (accessKeyId != null && secretAccessKey != null && bucket != null) {
          final rsp = await _cli.setDriveS3(SetDriveS3Request(
            endpoint: endpoint ?? '',
            region: region ?? '',
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            bucket: bucket,
            root: root ?? '',
          ));
          return rsp.success;
        }
        return false;
    }
  }

  Future<List<String>> findNotUploadedIds() async {
    final List<String> notUploadedIds = [];
    final re = await _requestPermission();
    if (!re) return notUploadedIds;

    final requests = StreamController<FilterNotUploadedRequest>();
    final responses = _cli.filterNotUploaded(requests.stream);

    await Future.wait([
      _sendFilterRequests(requests),
      _receiveResponses(responses, notUploadedIds),
    ]);

    return notUploadedIds;
  }

  Future<SyncResult> syncPhotos({List<String>? pendingIds}) async {
    if (wifiOnly) {
      final result = await Connectivity().checkConnectivity();
      if (!result.contains(ConnectivityResult.wifi)) {
        return SyncResult(uploaded: 0, failed: 0, skipped: 0, errors: ['No WiFi']);
      }
    }

    final driveOk = await initDriveFromPrefs();
    if (!driveOk) {
      return SyncResult(
          uploaded: 0, failed: 0, skipped: 0, errors: ['Drive init failed']);
    }

    List<String> idsToSync;
    if (pendingIds != null && pendingIds.isNotEmpty) {
      idsToSync = pendingIds;
    } else {
      idsToSync = await findNotUploadedIds();
    }

    if (idsToSync.isEmpty) {
      return SyncResult(uploaded: 0, failed: 0, skipped: 0, errors: []);
    }

    final idSet = <String>{...idsToSync};
    final assets = await _getPhotosFromFolder();
    final toUpload =
        assets.where((a) => idSet.contains(a.id)).toList();

    int uploaded = 0;
    int failed = 0;
    int skipped = 0;
    final errors = <String>[];
    final persistence = await SyncStatePersistence.create();

    onProgress?.call(SyncProgress(
      total: toUpload.length,
      completed: 0,
    ));

    for (int i = 0; i < toUpload.length; i++) {
      if (cancellationToken?.isCancelled ?? false) {
        final remaining = toUpload.sublist(i).map((a) => a.id).toList();
        await persistence.setPendingSyncQueue(remaining);
        break;
      }

      if (wifiOnly) {
        final result = await Connectivity().checkConnectivity();
        if (!result.contains(ConnectivityResult.wifi)) {
          final remaining = toUpload.sublist(i).map((a) => a.id).toList();
          await persistence.setPendingSyncQueue(remaining);
          break;
        }
      }

      final asset = toUpload[i];
      try {
        await _uploadAsset(asset, (percent) {
          onProgress?.call(SyncProgress(
            total: toUpload.length,
            completed: uploaded,
            currentFile: asset.id,
            currentFilePercent: percent,
          ));
        });
        uploaded++;
      } catch (e) {
        failed++;
        errors.add('${asset.id}: $e');
      }

      onProgress?.call(SyncProgress(
        total: toUpload.length,
        completed: uploaded + failed + skipped,
        currentFile: null,
      ));
    }

    return SyncResult(
      uploaded: uploaded,
      failed: failed,
      skipped: skipped,
      errors: errors,
    );
  }

  Future<void> _sendFilterRequests(
      StreamController<FilterNotUploadedRequest> requests) async {
    final List<AssetPathEntity> paths =
        await PhotoManager.getAssetPathList(type: RequestType.common);
    for (var path in paths) {
      if (path.name == localFolder) {
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
        const pageSize = 50;

        while (true) {
          final req = FilterNotUploadedRequest(
              photos:
                  List<FilterNotUploadedRequestInfo>.empty(growable: true));
          final List<AssetEntity> assets = await newpath!
              .getAssetListRange(start: offset, end: offset + pageSize);
          if (assets.isEmpty) {
            req.isFinished = true;
            break;
          }
          final futures = <Future<FilterNotUploadedRequestInfo>>[];
          for (var asset in assets) {
            futures.add(_createFilterInfo(asset));
          }
          req.photos.addAll(await Future.wait(futures));
          offset += pageSize;
          requests.add(req);
        }
      }
    }
    await requests.close();
  }

  Future<void> _receiveResponses(
      ResponseStream<FilterNotUploadedResponse> responses,
      List<String> notUploadedIds) async {
    await for (var response in responses) {
      if (!response.success) {
        print('SyncEngine error: ${response.message}');
        continue;
      }
      notUploadedIds.addAll(response.notUploaedIDs);
    }
  }

  Future<FilterNotUploadedRequestInfo> _createFilterInfo(
      AssetEntity asset) async {
    var date = asset.createDateTime;
    if (date.isBefore(DateTime(1990, 1, 1))) {
      date = asset.modifiedDateTime;
    }
    final dateStr =
        formatDate(date, [yyyy, ':', mm, ':', dd, ' ', HH, ':', nn, ':', ss]);
    final name = await asset.titleAsync;
    String contentHash = '';
    try {
      contentHash = await HashCache.instance.getHash(asset);
    } catch (_) {}
    return FilterNotUploadedRequestInfo(
      id: asset.id,
      name: name,
      date: dateStr,
      contentHash: contentHash,
    );
  }

  Future<List<AssetEntity>> _getPhotosFromFolder() async {
    final List<AssetEntity> all = [];
    final re = await _requestPermission();
    if (!re) return all;
    final List<AssetPathEntity> paths =
        await PhotoManager.getAssetPathList(type: RequestType.common);
    for (var path in paths) {
      if (path.name == localFolder) {
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
        const assetPageSize = 100;
        while (true) {
          final List<AssetEntity> assets = await newpath!.getAssetListRange(
              start: assetOffset, end: assetOffset + assetPageSize);
          if (assets.isEmpty) break;
          all.addAll(assets);
          assetOffset += assetPageSize;
        }
        break;
      }
    }
    return all;
  }

  Future<void> _uploadAsset(
      AssetEntity asset, void Function(double percent) onFileProgress) async {
    final file = await asset.originFile;
    if (file == null) throw Exception("asset file is null");

    final name = await asset.titleAsync;
    var date = asset.createDateTime;
    if (date.isBefore(DateTime(1990, 1, 1))) {
      date = asset.modifiedDateTime;
    }
    final dateStr =
        formatDate(date, [yyyy, ':', mm, ':', dd, ' ', HH, ':', nn, ':', ss]);
    final contentHash = await HashCache.instance.getHash(asset);
    final imgLen = await file.length();

    const maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final retryFile = await asset.originFile;
        if (retryFile == null) throw Exception("asset file is null on retry");

        int uploaded = 0;
        final req =
            http.StreamedRequest("POST", Uri.parse("$_httpBaseUrl/$name"));
        req.headers['Image-Date'] = dateStr;
        req.headers['Content-Hash'] = contentHash;
        req.contentLength = await retryFile.length();
        retryFile.openRead().listen((chunk) {
          uploaded += chunk.length;
          onFileProgress(uploaded / imgLen);
          req.sink.add(chunk);
        }, onDone: () {
          req.sink.close();
        });
        final response = await req.send();
        if (response.statusCode != 200) {
          final body = await response.stream.bytesToString();
          throw Exception("upload failed: [${response.statusCode}] $body");
        }
        return;
      } catch (e) {
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
        rethrow;
      }
    }
  }

  Future<bool> _requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps == PermissionState.authorized;
  }

  Future<bool> checkServerAlive() async {
    try {
      final socket = await Socket.connect(grpcHost, grpcPort,
          timeout: const Duration(seconds: 5));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
