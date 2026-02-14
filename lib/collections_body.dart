import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:img_syncer/global.dart';
import 'package:img_syncer/trash_body.dart';
import 'package:img_syncer/locked_folder_body.dart';
import 'package:img_syncer/album_detail_body.dart';

class CollectionsBody extends StatefulWidget {
  const CollectionsBody({Key? key}) : super(key: key);

  @override
  State<CollectionsBody> createState() => _CollectionsBodyState();
}

class _CollectionsBodyState extends State<CollectionsBody> {
  List<AssetPathEntity> _albums = [];

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final re = await requestPermission();
    if (!re) return;
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );
    final Map<AssetPathEntity, int> countMap = {};
    await Future.wait(paths.map((p) async {
      countMap[p] = await p.assetCountAsync;
    }));
    paths.sort((a, b) => (countMap[b] ?? 0).compareTo(countMap[a] ?? 0));
    if (mounted) {
      setState(() => _albums = paths);
    }
  }

  Future<Uint8List?> _getAlbumThumbnail(AssetPathEntity path) async {
    final entities = await path.getAssetListPaged(page: 0, size: 1);
    if (entities.isNotEmpty) {
      return await entities[0].thumbnailDataWithSize(
        const ThumbnailSize.square(200),
        quality: 80,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset('assets/icon/lumina_icon_transparent.png', width: 36, height: 36),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              l10n.collections,
              style: textTheme.headlineMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _CollectionCard(
                icon: Icons.delete_outline,
                label: l10n.trash,
                color: colorScheme.errorContainer,
                iconColor: colorScheme.onErrorContainer,
                textColor: colorScheme.onErrorContainer,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TrashBody()),
                  );
                },
              ),
              _CollectionCard(
                icon: Icons.lock_outline,
                label: l10n.lockedFolder,
                color: colorScheme.tertiaryContainer,
                iconColor: colorScheme.onTertiaryContainer,
                textColor: colorScheme.onTertiaryContainer,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LockedFolderBody()),
                  );
                },
              ),
            ],
          ),
        ),
        if (_albums.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                l10n.deviceAlbums,
                style: textTheme.titleLarge,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: _albums.map((album) {
                return _AlbumCard(
                  album: album,
                  thumbnailFuture: _getAlbumThumbnail(album),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlbumDetailBody(album: album),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: iconColor),
              const Spacer(),
              Text(
                label,
                style: textTheme.titleMedium?.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final AssetPathEntity album;
  final Future<Uint8List?> thumbnailFuture;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    required this.thumbnailFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FutureBuilder<Uint8List?>(
                future: thumbnailFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }
                  return Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.photo_library_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                album.name,
                style: textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: FutureBuilder<int>(
                future: album.assetCountAsync,
                builder: (context, snapshot) {
                  return Text(
                    snapshot.hasData ? '${snapshot.data} ${l10n.pics}' : '',
                    style: textTheme.bodySmall,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
