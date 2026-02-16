import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lumina/global.dart';
import 'package:lumina/places_service.dart';
import 'package:lumina/place_city_body.dart';

class PlacesBody extends StatefulWidget {
  const PlacesBody({Key? key}) : super(key: key);

  @override
  State<PlacesBody> createState() => _PlacesBodyState();
}

class _PlacesBodyState extends State<PlacesBody> {
  List<CityGroup>? _groups;
  bool _loading = true;


  int _scanned = 0;
  int _total = 0;
  int _withLocation = 0;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    final groups = await PlacesService.instance.scanPhotosForLocations(
      onProgress: (scanned, total, withLocation) {
        if (mounted) {
          setState(() {
            _scanned = scanned;
            _total = total;
            _withLocation = withLocation;
          });
        }
      },
    );
    if (mounted) {
      setState(() {
        _groups = groups;
        _loading = false;
      });
    }
  }

  LatLngBounds? _computeBounds(List<CityGroup> groups) {
    if (groups.isEmpty) return null;
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final g in groups) {
      if (g.lat < minLat) minLat = g.lat;
      if (g.lat > maxLat) maxLat = g.lat;
      if (g.lng < minLng) minLng = g.lng;
      if (g.lng > maxLng) maxLng = g.lng;
    }
    const padding = 1.0;
    return LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );
  }

  double _markerSize(int photoCount) {
    if (photoCount >= 50) return 40;
    if (photoCount >= 20) return 34;
    if (photoCount >= 5) return 28;
    return 22;
  }

  void _openCity(CityGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceCityBody(group: group),
      ),
    );
  }

  Widget _buildMap(ColorScheme colorScheme) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCameraFit: _computeBounds(_groups!) != null
            ? CameraFit.bounds(
                bounds: _computeBounds(_groups!)!,
                padding: const EdgeInsets.all(32),
              )
            : null,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
          scrollWheelVelocity: 0.005,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.pho',
        ),
        MarkerLayer(
          markers: _groups!.map((group) {
            final size = _markerSize(group.photoCount);
            return Marker(
              point: LatLng(group.lat, group.lng),
              width: size,
              height: size,
              child: GestureDetector(
                onTap: () => _openCity(group),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: colorScheme.onPrimary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${group.photoCount}',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: size * 0.32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.places)),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.scanningPhotos),
                  if (_total > 0) ...[
                    const SizedBox(height: 8),
                    Text('$_scanned / $_total',
                        style: textTheme.bodySmall),
                    if (_withLocation > 0)
                      Text('$_withLocation with GPS',
                          style: textTheme.bodySmall),
                  ],
                ],
              ),
            )
          : _groups == null || _groups!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_outlined,
                          size: 64, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(l10n.noLocationData,
                          style: textTheme.bodyLarge),
                    ],
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: _buildMap(colorScheme),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _groups!.length,
                        itemBuilder: (context, index) {
                          final group = _groups![index];
                          return _CityListTile(
                            group: group,
                            onTap: () => _openCity(group),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _CityListTile extends StatelessWidget {
  final CityGroup group;
  final VoidCallback onTap;

  const _CityListTile({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: group.thumbnail != null
              ? Image.memory(group.thumbnail!, fit: BoxFit.cover)
              : Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.photo),
                ),
        ),
      ),
      title: Text(group.cityName),
      subtitle: Text('${group.countryCode} · ${l10n.photosInCity(group.photoCount)}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
