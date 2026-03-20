import 'dart:io';
import 'package:event_bus/event_bus.dart';

EventBus _innerBus = EventBus();

class _DebugEventBus {
  IOSink? _sink;

  void _log(String msg) {
    try {
      _sink ??= File('/Users/pzhu/Library/Containers/B0A88356-59CC-40D9-B21C-24CF195D3681/Data/Documents/lumina_debug.log').openWrite(mode: FileMode.append);
      _sink!.writeln('[${DateTime.now().toIso8601String()}] $msg');
      _sink!.flush();
    } catch (_) {}
  }

  void fire(dynamic event) {
    if (event is RemoteRefreshEvent) {
      _log('EVENT RemoteRefreshEvent fired from: ${StackTrace.current.toString().split('\n').take(4).join(' <- ')}');
    }
    _innerBus.fire(event);
  }

  Stream<T> on<T>() => _innerBus.on<T>();
}

_DebugEventBus eventBus = _DebugEventBus();

class LocalRefreshEvent {
  LocalRefreshEvent();
}

class RemoteRefreshEvent {
  RemoteRefreshEvent();
}
