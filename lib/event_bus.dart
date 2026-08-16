import 'package:event_bus/event_bus.dart';

EventBus eventBus = EventBus();

class LocalRefreshEvent {
  LocalRefreshEvent();
}

class RemoteRefreshEvent {
  const RemoteRefreshEvent({this.force = false});

  final bool force;
}
