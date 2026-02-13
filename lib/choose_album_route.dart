import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'state_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:img_syncer/global.dart';
import 'package:flutter/services.dart';

class ChooseAlbumRoute extends StatefulWidget {
  const ChooseAlbumRoute({Key? key}) : super(key: key);
  @override
  ChooseAlbumRouteState createState() => ChooseAlbumRouteState();
}

class ChooseAlbumRouteState extends State<ChooseAlbumRoute> {
  List<AssetPathEntity> albums = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getAlbums().then((value) {
        setState(() {
          albums = value;
        });
      });
    });
  }

  Future<List<AssetPathEntity>> getAlbums() async {
    final re = await requestPermission();
    if (!re) return [];
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common, hasAll: true);
    final Map<AssetPathEntity, int> assetCountMap = {};
    await Future.wait(paths.map((path) async {
      int assetCount = await path.assetCountAsync;
      assetCountMap[path] = assetCount;
    }));

    paths.sort((a, b) {
      int countA = assetCountMap[a] ?? 0;
      int countB = assetCountMap[b] ?? 0;
      return countB.compareTo(countA);
    });
    return paths;
  }

  Future<Uint8List?> getFirstPhotoThumbnail(AssetPathEntity path) async {
    final List<AssetEntity> entities =
        await path.getAssetListPaged(page: 0, size: 1);
    if (entities.isNotEmpty) {
      final entity = entities[0];
      final data = await entity.thumbnailData;
      return data!;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];
    for (var path in albums) {
      children.add(
        FutureBuilder(
          future: getFirstPhotoThumbnail(path),
          builder: (context, snapshot) {
            return AlbumCard(
              path: path,
              thumbnail: snapshot.data,
            );
          },
        ),
      );
    }
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(l10n.chooseAlbum,
              style: Theme.of(context).textTheme.titleLarge),
        ),
        body: CustomScrollView(
          primary: false,
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid.count(
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                children: children,
              ),
            ),
          ],
        ));
  }
}

class AlbumCard extends StatelessWidget {
  final AssetPathEntity path;
  final Uint8List? thumbnail;
  const AlbumCard({
    Key? key,
    required this.path,
    required this.thumbnail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight - 80,
                  child: thumbnail != null
                      ? Image.memory(thumbnail!, fit: BoxFit.cover)
                      : Image.asset("assets/images/gray.jpg")),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(path.name,
                        style: textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  )),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: FutureBuilder(
                          future: path.assetCountAsync,
                          builder: (context, snapshot) => Text(
                              snapshot.hasData
                                  ? "${snapshot.data} ${l10n.pics}"
                                  : '',
                              style: textTheme.bodySmall),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: FilledButton.tonal(
                        onPressed: () {
                          settingModel.setLocalFolder(path.name);
                          SharedPreferences.getInstance().then((prefs) {
                            prefs.setString("localFolder", path.name);
                          });
                          Navigator.pop(context);
                        },
                        child: Text(l10n.choose),
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
