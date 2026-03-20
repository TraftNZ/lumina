import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:grpc/grpc.dart';
import 'package:lumina/proto/lumina.pbgrpc.dart';
import 'package:date_format/date_format.dart';
import 'package:lumina/state_model.dart';
import 'package:lumina/storage/hash_cache.dart';
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:lumina/global.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:lumina/util.dart';

RemoteStorage storage = RemoteStorage("127.0.0.1", 10000);

class RemoteStorage {
  int bufferSize = 1024 * 1024;
  LuminaClient cli = LuminaClient(ClientChannel(
    "127.0.0.1",
    port: 50051,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(),
    ),
  ));
  RemoteStorage(String addr, int port) {
    final channel = ClientChannel(
      addr,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    cli = LuminaClient(channel);
  }

  Future<void> uploadXFile(XFile file) async {
    await checkServer();
    final name = basename(file.path);
    final date = await file.lastModified();
    final dateStr =
        formatDate(date, [yyyy, ':', mm, ':', dd, ' ', HH, ':', nn, ':', ss]);
    final fileBytes = await file.readAsBytes();
    final contentHash = sha256.convert(fileBytes).toString();
    var req = http.StreamedRequest("POST", Uri.parse("$httpBaseUrl/$name"));
    req.headers['Image-Date'] = dateStr;
    req.headers['Content-Hash'] = contentHash;
    req.contentLength = fileBytes.length;
    file.openRead().listen((chunk) {
      req.sink.add(chunk);
    }, onDone: () {
      req.sink.close();
    });
    final response = await req.send();
    if (response.statusCode != 200) {
      throw Exception("upload failed: ${response.statusCode}");
    }
  }

  Future<void> uploadAssetEntity(AssetEntity asset) async {
    await checkServer();
    final file = await asset.originFile;
    if (file == null) {
      throw Exception("asset file is null");
    }
    final name = await asset.titleAsync;
    var date = asset.createDateTime;
    if (date.isBefore(DateTime(1990, 1, 1))) {
      date = asset.modifiedDateTime;
    }
    final dateStr =
        formatDate(date, [yyyy, ':', mm, ':', dd, ' ', HH, ':', nn, ':', ss]);
    final contentHash = await HashCache.instance.getHash(asset);
    final imgLen = await file.length();
    stateModel.updateUploadProgress(asset.id, 0, imgLen);

    const maxUploadRetries = 3;
    for (int attempt = 0; attempt < maxUploadRetries; attempt++) {
      try {
        final retryFile = await asset.originFile;
        if (retryFile == null) {
          throw Exception("asset file is null on retry");
        }
        int uploaded = 0;
        var req =
            http.StreamedRequest("POST", Uri.parse("$httpBaseUrl/$name"));
        req.headers['Image-Date'] = dateStr;
        req.headers['Content-Hash'] = contentHash;
        req.contentLength = await retryFile.length();
        retryFile.openRead().listen((chunk) {
          uploaded += chunk.length;
          stateModel.updateUploadProgress(asset.id, uploaded, imgLen);
          req.sink.add(chunk);
        }, onDone: () {
          req.sink.close();
        });
        final response = await req.send();
        if (response.statusCode != 200) {
          final body = await response.stream.bytesToString();
          throw Exception("upload failed: [${response.statusCode}] $body");
        }
        stateModel.finishUpload(asset.id, true);
        // Upload video thumbnail from device (OS-generated frame)
        if (asset.type == AssetType.video) {
          try {
            final thumb = await asset.thumbnailDataWithSize(
                const ThumbnailSize.square(500),
                quality: 75);
            if (thumb != null && thumb.isNotEmpty) {
              final thumbUrl =
                  Uri.encodeFull('$httpBaseUrl/thumbnail/$name');
              final thumbReq =
                  http.Request("POST", Uri.parse(thumbUrl));
              thumbReq.headers['Image-Date'] = dateStr;
              thumbReq.bodyBytes = thumb;
              await thumbReq.send();
            }
          } catch (_) {}
        }
        return;
      } catch (e) {
        final errStr = e.toString();
        final isAuthError = errStr.contains('auth failed') ||
            errStr.contains('session expired') ||
            errStr.contains('re-authenticate');
        if (isAuthError || attempt >= maxUploadRetries - 1) {
          stateModel.finishUpload(asset.id, false);
          rethrow;
        }
        final backoff = Duration(seconds: (attempt + 1) * 2);
        await Future.delayed(backoff);
        continue;
      }
    }
  }

  Future<List<RemoteImage>> listImages(String date) async {
    final rsp = await cli.listByDate(ListByDateRequest(date: date));
    if (!rsp.success) throw Exception("list images failed: ${rsp.message}");
    return rsp.paths.map((e) => RemoteImage(cli, e)).toList();
  }

  Future<int> syncIndex() async {
    final rsp = await cli.syncIndex(SyncIndexRequest());
    if (!rsp.success) throw Exception("sync index failed: ${rsp.message}");
    return rsp.totalFiles;
  }

  Future<int> fullResyncIndex() async {
    final rsp = await cli.fullResyncIndex(FullResyncIndexRequest());
    if (!rsp.success) throw Exception("full resync index failed: ${rsp.message}");
    return rsp.totalFiles;
  }
}

class RemoteImage {
  LuminaClient cli;
  String path;
  Uint8List? data;
  Uint8List? thumbnailData;

  RemoteImage(
    this.cli,
    this.path, {
    this.data,
    this.thumbnailData,
  });

  bool isVideo() {
    return isVideoByPath(path);
  }

  String thumbnailUrl() {
    var urlPath = path;
    if (urlPath.isNotEmpty && urlPath[0] == '/') {
      urlPath = urlPath.substring(1);
    }
    return Uri.encodeFull('$httpBaseUrl/thumbnail/$urlPath');
  }

  Future<Uint8List> thumbnail() async {
    if (thumbnailData != null) {
      return thumbnailData!;
    }
    var urlPath = path;
    if (urlPath[0] == '/') {
      urlPath = urlPath.substring(1);
    }
    try {
      final response =
          await http.get(Uri.parse('$httpBaseUrl/thumbnail/$urlPath'));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        thumbnailData = response.bodyBytes;
        return thumbnailData!;
      }
    } catch (e) {
      print("get $path thumbnail failed: $e");
    }
    final data = await rootBundle.load("assets/images/broken.png");
    return data.buffer.asUint8List();
  }

  Stream<Uint8List> dataStream() async* {
    var urlPath = path;
    if (urlPath[0] == '/') {
      urlPath = urlPath.substring(1);
    }
    final url = '$httpBaseUrl/$urlPath';
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception("get image failed: [${response.statusCode}] $body");
    }
    final totalLength = response.contentLength ?? 0;
    if (totalLength > 0) {
      stateModel.updateDownloadProgress(basename(path), 0, totalLength);
    }
    int downloaded = 0;
    await for (var data in response.stream) {
      downloaded += data.length;
      if (totalLength > 0) {
        stateModel.updateDownloadProgress(
            basename(path), downloaded, totalLength);
      }
      yield data as Uint8List;
    }
    stateModel.finishDownload(basename(path), true);
  }

  Future<Uint8List> imageData() async {
    if (data != null && data!.isNotEmpty) {
      return data!;
    }
    var currentData = BytesBuilder();
    var stream = dataStream();
    await for (var d in stream) {
      currentData.add(d);
    }
    final result = currentData.takeBytes();
    if (result.isNotEmpty) {
      data = result;
    }
    return result;
  }
}
