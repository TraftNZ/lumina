import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef StartServerNative = Pointer<Utf8> Function(
    Pointer<Utf8> dataDir, Pointer<Utf8> cacheDir);
typedef StartServerDart = Pointer<Utf8> Function(
    Pointer<Utf8> dataDir, Pointer<Utf8> cacheDir);

typedef FreeStringNative = Void Function(Pointer<Utf8> s);
typedef FreeStringDart = void Function(Pointer<Utf8> s);

class ServerBindings {
  late final DynamicLibrary _lib;
  late final StartServerDart _startServer;
  late final FreeStringDart _freeString;

  ServerBindings() {
    _lib = DynamicLibrary.open(_libraryPath());
    _startServer =
        _lib.lookupFunction<StartServerNative, StartServerDart>('StartServer');
    _freeString =
        _lib.lookupFunction<FreeStringNative, FreeStringDart>('FreeString');
  }

  String startServer(String dataDir, String cacheDir) {
    final dataDirPtr = dataDir.toNativeUtf8();
    final cacheDirPtr = cacheDir.toNativeUtf8();
    final resultPtr = _startServer(dataDirPtr, cacheDirPtr);
    final result = resultPtr.toDartString();
    _freeString(resultPtr);
    calloc.free(dataDirPtr);
    calloc.free(cacheDirPtr);
    return result;
  }

  static String _libraryPath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    if (Platform.isMacOS) {
      return '$exeDir/../Frameworks/liblumina_server.dylib';
    } else if (Platform.isLinux) {
      return '$exeDir/lib/liblumina_server.so';
    } else if (Platform.isWindows) {
      return '$exeDir/lumina_server.dll';
    }
    throw UnsupportedError('Unsupported platform for FFI server bindings');
  }
}
