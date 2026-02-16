import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:photo_manager/photo_manager.dart';
import 'package:lumina/global.dart';
import 'package:lumina/trash_body.dart';
import 'package:lumina/locked_folder_body.dart';
import 'package:lumina/album_detail_body.dart';
import 'package:lumina/places_body.dart';
import 'package:lumina/year_detail_body.dart';
import 'package:lumina/smart_album_body.dart';
import 'package:lumina/proto/lumina.pbgrpc.dart';
import 'package:lumina/storage/storage.dart';
import 'package:lumina/state_model.dart';
import 'package:lumina/search_body.dart';

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

class _SmartAlbumData {
  final String label;
  final String query;
  final int count;
  final String samplePath;
  final IconData? icon;

  _SmartAlbumData({
    required this.label,
    required this.query,
    required this.count,
    required this.samplePath,
    this.icon,
  });
}

const _petLabels = {'Dog', 'Cat', 'Bird', 'Fish', 'Horse', 'Rabbit'};

class _CollectionsBodyState extends State<CollectionsBody> {
  List<AssetPathEntity> _albums = [];
  List<_YearData> _years = [];
  List<_SmartAlbumData> _peoplePets = [];
  List<_SmartAlbumData> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _loadYears();
    _loadSmartAlbums();
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

  Future<void> _loadSmartAlbums() async {
    // Wait for server and drive to be ready before calling gRPC
    while (!isServerReady || !settingModel.isRemoteStorageSetted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
    }
    try {
      final response = await storage.cli
          .getLabelSummary(GetLabelSummaryRequest())
          .timeout(const Duration(seconds: 10));
      if (!response.success || !mounted) return;

      final peoplePets = <_SmartAlbumData>[];
      final categories = <_SmartAlbumData>[];

      if (response.faceCount > 0) {
        peoplePets.add(_SmartAlbumData(
          label: l10n.people,
          query: '_faces',
          count: response.faceCount,
          samplePath: response.faceSamplePath,
          icon: Icons.people,
        ));
      }

      final sortedLabels = response.labels.toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      for (final item in sortedLabels) {
        if (_petLabels.contains(item.label)) {
          peoplePets.add(_SmartAlbumData(
            label: item.label,
            query: item.label.toLowerCase(),
            count: item.count,
            samplePath: item.samplePath,
            icon: Icons.pets,
          ));
        } else {
          categories.add(_SmartAlbumData(
            label: item.label,
            query: item.label.toLowerCase(),
            count: item.count,
            samplePath: item.samplePath,
          ));
        }
      }

      setState(() {
        _peoplePets = peoplePets;
        _categories = categories.take(20).toList();
      });
    } catch (e) {
      // Smart albums are optional, ignore errors
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
        // People & Pets section
        if (_peoplePets.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                l10n.peoplePets,
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
                itemCount: _peoplePets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final album = _peoplePets[index];
                  return _SmartAlbumCard(
                    album: album,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SmartAlbumBody(
                            query: album.query,
                            title: album.label,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
        // Categories section
        if (_categories.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                l10n.categories,
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
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final album = _categories[index];
                  return _SmartAlbumCard(
                    album: album,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SmartAlbumBody(
                            query: album.query,
                            title: album.label,
                          ),
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

class _SmartAlbumCard extends StatefulWidget {
  final _SmartAlbumData album;
  final VoidCallback onTap;

  const _SmartAlbumCard({required this.album, required this.onTap});

  @override
  State<_SmartAlbumCard> createState() => _SmartAlbumCardState();
}

class _SmartAlbumCardState extends State<_SmartAlbumCard> {
  Uint8List? _thumbData;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    if (widget.album.samplePath.isEmpty) return;
    var urlPath = widget.album.samplePath;
    if (urlPath.startsWith('/')) {
      urlPath = urlPath.substring(1);
    }
    final url = '$httpBaseUrl/thumbnail/$urlPath';
    try {
      final response = await httpGetWithTimeout(url);
      if (response != null && mounted) {
        setState(() => _thumbData = response);
      }
    } catch (e) {
      // Ignore thumbnail load errors
    }
  }

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
          onTap: widget.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_thumbData != null)
                Image.memory(_thumbData!, fit: BoxFit.cover)
              else
                Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    widget.album.icon ?? Icons.photo_library_outlined,
                    size: 40,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
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
                      widget.album.label,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.album.count} ${l10n.pics}',
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
