import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:photo_manager/photo_manager.dart';
import 'package:img_syncer/global.dart';
import 'package:img_syncer/trash_body.dart';
import 'package:img_syncer/locked_folder_body.dart';
import 'package:img_syncer/album_detail_body.dart';
import 'package:img_syncer/places_body.dart';
import 'package:img_syncer/year_detail_body.dart';

class _YearData {
  final int year;
  final int count;
  final Uint8List? thumbnail;

  _YearData({required this.year, required this.count, this.thumbnail});
}

class CollectionsBody extends StatefulWidget {
  const CollectionsBody({Key? key}) : super(key: key);

  @override
  State<CollectionsBody> createState() => _CollectionsBodyState();
}

class _CollectionsBodyState extends State<CollectionsBody> {
  List<AssetPathEntity> _albums = [];
  List<_YearData> _years = [];

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _loadYears();
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

  Future<void> _loadYears() async {
    final re = await requestPermission();
    if (!re) return;

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );
    if (paths.isEmpty) return;

    final allPath = paths.firstWhere((p) => p.isAll, orElse: () => paths.first);
    final totalCount = await allPath.assetCountAsync;
    if (totalCount == 0) return;

    final Map<int, List<AssetEntity>> yearMap = {};

    const batchSize = 500;
    for (int page = 0; page * batchSize < totalCount; page++) {
      final assets = await allPath.getAssetListPaged(page: page, size: batchSize);
      for (final asset in assets) {
        final year = asset.createDateTime.year;
        yearMap.putIfAbsent(year, () => []);
        if (yearMap[year]!.isEmpty) {
          yearMap[year]!.add(asset);
        }
      }
    }

    final years = <_YearData>[];
    for (final entry in yearMap.entries) {
      final filterOption = FilterOptionGroup(
        createTimeCond: DateTimeCond(
          min: DateTime(entry.key),
          max: DateTime(entry.key + 1),
        ),
      );
      final yearPaths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
        filterOption: filterOption,
      );
      int count = 0;
      if (yearPaths.isNotEmpty) {
        final yp = yearPaths.firstWhere((p) => p.isAll, orElse: () => yearPaths.first);
        count = await yp.assetCountAsync;
      }

      Uint8List? thumb;
      if (entry.value.isNotEmpty) {
        thumb = await entry.value.first.thumbnailDataWithSize(
          const ThumbnailSize.square(200),
          quality: 80,
        );
      }

      years.add(_YearData(year: entry.key, count: count, thumbnail: thumb));
    }

    years.sort((a, b) => b.year.compareTo(a.year));

    if (mounted) {
      setState(() => _years = years);
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
        // Places card — full width
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 120,
              child: _PlacesCard(
                label: l10n.places,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlacesBody()),
                  );
                },
              ),
            ),
          ),
        ),
        // Year in Review section
        if (_years.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                l10n.yearInReview,
                style: textTheme.titleLarge,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _years.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final yearData = _years[index];
                  return _YearCard(
                    yearData: yearData,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => YearDetailBody(year: yearData.year),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
        // Device Albums section
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
        // Trash & Locked Folder — bottom list tiles
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              children: [
                _BottomListTile(
                  icon: Icons.delete_outline,
                  label: l10n.trash,
                  iconColor: colorScheme.error,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TrashBody()),
                    );
                  },
                ),
                Divider(height: 1, color: colorScheme.outlineVariant),
                _BottomListTile(
                  icon: Icons.lock_outline,
                  label: l10n.lockedFolder,
                  iconColor: colorScheme.tertiary,
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
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _YearCard extends StatelessWidget {
  final _YearData yearData;
  final VoidCallback onTap;

  const _YearCard({required this.yearData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 120,
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (yearData.thumbnail != null)
                Image.memory(yearData.thumbnail!, fit: BoxFit.cover)
              else
                Container(color: colorScheme.surfaceContainerHighest),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${yearData.year}',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${yearData.count} ${l10n.pics}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _BottomListTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: textTheme.bodyLarge),
      trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _PlacesCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PlacesCard({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const ll.LatLng(30, 10),
                  initialZoom: 1.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
                        : 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    retinaMode: true,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_outlined, size: 32,
                          color: isDark ? Colors.white : Colors.black87),
                      const Spacer(),
                      Text(
                        label,
                        style: textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
