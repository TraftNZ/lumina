import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/event_bus.dart';
import 'package:lumina/state_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settingModel.isRemoteStorageSetted = false;
    assetModel.remoteLastError = 'previous error';
  });

  test(
    'persists the selected drive before requesting a forced refresh',
    () async {
      final snapshotFuture = eventBus.on<RemoteRefreshEvent>().first.then((
        event,
      ) async {
        final prefs = await SharedPreferences.getInstance();
        return <String, Object?>{
          'force': event.force,
          'drive': prefs.getString('drive'),
          'server': prefs.getString('cloudreve_server'),
          'root': prefs.getString('cloudreve_root_path'),
        };
      });

      await saveRemoteStorageConfiguration(
        drive: Drive.cloudreve,
        settings: const {
          'cloudreve_server': 'https://cloud.example.test',
          'cloudreve_email': 'user@example.test',
          'cloudreve_password': 'secret',
          'cloudreve_root_path': '/photos',
        },
      );

      final snapshot = await snapshotFuture;
      expect(snapshot, {
        'force': true,
        'drive': 'Cloudreve',
        'server': 'https://cloud.example.test',
        'root': '/photos',
      });
      expect(settingModel.isRemoteStorageSetted, isTrue);
      expect(assetModel.remoteLastError, isNull);
    },
  );

  test('reconfiguring an already-ready drive still forces a refresh', () async {
    settingModel.isRemoteStorageSetted = true;
    final eventFuture = eventBus.on<RemoteRefreshEvent>().first;

    await saveRemoteStorageConfiguration(
      drive: Drive.cloudreve,
      settings: const {'cloudreve_server': 'https://new-cloud.example.test'},
    );

    final event = await eventFuture;
    final prefs = await SharedPreferences.getInstance();
    expect(event.force, isTrue);
    expect(
      prefs.getString('cloudreve_server'),
      'https://new-cloud.example.test',
    );
    expect(prefs.getString('drive'), 'Cloudreve');
  });
}
