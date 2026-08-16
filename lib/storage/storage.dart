import 'dart:io';
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
import 'package:lumina/util.dart';

RemoteStorage storage = RemoteStorage("127.0.0.1", 10000);

class RemoteStorage {
  int bufferSize = 1024 * 1024;
  LuminaClient cli = LuminaClient(
    ClientChannel(
      "127.0.0.1",
      port: 50051,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    ),
  );
  RemoteStorage(String addr, int port) {
    final channel = ClientChannel(
      addr,
      port: port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    cli = LuminaClient(channel);
  }

  Future<void> uploadXFile(XFile file) async {
    await checkServer();
    final name = basename(file.path);
    final date = await file.lastModified();
    final dateStr = formatDate(date, [
      yyyy,
      ':',
      mm,
      ':',
      dd,
      ' ',
      HH,
      ':',
      nn,
      ':',
      ss,
    ]);
    // Stream through the digest instead of readAsBytes(): a picked video can
    // be gigabytes, and buffering it whole exhausts the memory limit.
    final contentHash = (await sha256.bind(file.openRead()).first).toString();
    var req = http.StreamedRequest("POST", Uri.parse("$httpBaseUrl/$name"));
    req.headers['Image-Date'] = dateStr;
    req.headers['Content-Hash'] = contentHash;
    req.contentLength = await file.length();
    file.openRead().listen(
      (chunk) => req.sink.add(chunk),
      onDone: () => req.sink.close(),
      onError: (Object e, StackTrace st) {
        req.sink.addError(e, st);
        req.sink.close();
      },
      cancelOnError: true,
    );
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
    final dateStr = formatDate(date, [
      yyyy,
      ':',
      mm,
      ':',
      dd,
      ' ',
      HH,
      ':',
      nn,
      ':',
      ss,
    ]);
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
        var req = http.StreamedRequest("POST", Uri.parse("$httpBaseUrl/$name"));
        req.headers['Image-Date'] = dateStr;
        req.headers['Content-Hash'] = contentHash;
        req.contentLength = await retryFile.length();
        retryFile.openRead().listen(
          (chunk) {
            uploaded += chunk.length;
            stateModel.updateUploadProgress(asset.id, uploaded, imgLen);
            req.sink.add(chunk);
          },
          onDone: () => req.sink.close(),
          // Surface read failures through send() rather than letting them
          // escape as unhandled async errors.
          onError: (Object e, StackTrace st) {
            req.sink.addError(e, st);
            req.sink.close();
          },
          cancelOnError: true,
        );
        final response = await req.send();
        final remotePath = await response.stream.bytesToString();
        if (response.statusCode != 200) {
          throw Exception("upload failed: [${response.statusCode}] $remotePath");
        }
        stateModel.finishUpload(asset.id, true);
        // The server cannot decode video frames, so the only thumbnail a video
        // will ever have is the one the OS already made for us. It is stored
        // under the path the server just reported, which is where the viewer
        // looks — the server may have filed the video under a different date
        // than the one we sent.
        if (asset.type == AssetType.video && remotePath.isNotEmpty) {
          try {
            final thumb = await asset.thumbnailDataWithSize(
              const ThumbnailSize.square(500),
              quality: 75,
            );
            if (thumb != null && thumb.isNotEmpty) {
              final thumbUrl = Uri.encodeFull(
                '$httpBaseUrl/thumbnail/$remotePath',
              );
              final thumbReq = http.Request("POST", Uri.parse(thumbUrl));
              thumbReq.bodyBytes = thumb;
              await thumbReq.send();
            }
          } catch (_) {}
        }
        return;
      } catch (e) {
        final errStr = e.toString();
        final isAuthError =
            errStr.contains('auth failed') ||
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
    if (!rsp.success) {
      throw Exception("full resync index failed: ${rsp.message}");
    }
    return rsp.totalFiles;
  }
}

class RemoteImage {
  LuminaClient cli;
  String path;

  RemoteImage(this.cli, this.path);

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

  /// Returns empty when the backend has no thumbnail for this file. Video
  /// formats it cannot decode never get one, and substituting a broken-image
  /// bitmap here would make that bitmap the asset's thumbnail forever — the
  /// caller can only draw a proper placeholder if it can tell the two apart.
  Future<Uint8List> thumbnail() async {
    var urlPath = path;
    if (urlPath.isNotEmpty && urlPath[0] == '/') {
      urlPath = urlPath.substring(1);
    }
    try {
      final response = await http.get(
        Uri.parse('$httpBaseUrl/thumbnail/$urlPath'),
      );
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (e) {
      print("get $path thumbnail failed: $e");
    }
    return Uint8List(0);
  }

  Stream<Uint8List> dataStream() async* {
    var urlPath = path;
    if (urlPath.isNotEmpty && urlPath[0] == '/') {
      urlPath = urlPath.substring(1);
    }
    final url = '$httpBaseUrl/$urlPath';
    final client = http.Client();
    try {
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
            basename(path),
            downloaded,
            totalLength,
          );
        }
        yield data is Uint8List ? data : Uint8List.fromList(data);
      }
      stateModel.finishDownload(basename(path), true);
    } catch (_) {
      stateModel.finishDownload(basename(path), false);
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> downloadToFile(String filePath) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    final partialFile = File('$filePath.part');
    final sink = partialFile.openWrite();
    try {
      await for (final chunk in dataStream()) {
        sink.add(chunk);
      }
      await sink.close();
      if (await file.exists()) {
        await file.delete();
      }
      await partialFile.rename(filePath);
    } catch (_) {
      await sink.close();
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      rethrow;
    }
  }

  Future<Uint8List> imageData() async {
    final currentData = BytesBuilder();
    await for (final d in dataStream()) {
      currentData.add(d);
    }
    return currentData.takeBytes();
  }
}
