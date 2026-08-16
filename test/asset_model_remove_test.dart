import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/asset.dart';
import 'package:lumina/state_model.dart';
import 'package:lumina/storage/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('removeAssets matches distinct remote objects by path', () {
    final model = AssetModel();
    const path = '2020/05/10/photo.jpg';
    final stored = Asset(remote: RemoteImage(storage.cli, path));
    final selected = Asset(remote: RemoteImage(storage.cli, path));
    model.remoteAssets = [stored];

    expect(model.getUnifiedAssets(), [stored]);

    model.removeAssets([selected]);

    expect(model.remoteAssets, isEmpty);
    expect(model.getUnifiedAssets(), isEmpty);
  });
}
