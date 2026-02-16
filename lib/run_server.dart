import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<String> runServer() async {
  late String ports;
  WidgetsFlutterBinding.ensureInitialized();

  final appDocDir = await getApplicationDocumentsDirectory();
  final appCacheDir = await getApplicationCacheDirectory();

  if (Platform.isAndroid) {
    ports = await const MethodChannel('com.traftai.lumina/RunGrpcServer')
        .invokeMethod('RunGrpcServer', {
      'dataDir': appDocDir.path,
      'cacheDir': appCacheDir.path,
    });
  } else if (Platform.isIOS) {
    ports = await const MethodChannel('com.traftai.lumina/RunGrpcServer')
        .invokeMethod('RunGrpcServer', {
      'dataDir': appDocDir.path,
      'cacheDir': appCacheDir.path,
    });
  }

  return ports;
}
