import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:photo_manager/photo_manager.dart' hide LatLng;
import 'package:lumina/places_service.dart';

class PlaceCityBody extends StatefulWidget {
  final CityGroup group;

  const PlaceCityBody({Key? key, required this.group}) : super(key: key);

  @override
  State<PlaceCityBody> createState() => _PlaceCityBodyState();
}

class _PlaceCityBodyState extends State<PlaceCityBody> {
  List<LatLng> _photoLocations = [];

  @override
  void initState() {
    super.initState();
    _loadPhotoLocations();
  }

  Future<void> _loadPhotoLocations() async {
    final locations = <LatLng>[];
    for (final asset in widget.group.assets) {
      final ll = await asset.latlngAsync();
      if (ll != null) {
        locations.add(LatLng(ll.latitude, ll.longitude));
      }
    }
    if (mounted) {
      setState(() => _photoLocations = locations);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.cityName),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(widget.group.lat, widget.group.lng),
                initialZoom: 11,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                  scrollWheelVelocity: 0.005,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.pho',
                ),
                MarkerLayer(
                  markers: _photoLocations.map((loc) {
                    return Marker(
                      point: loc,
                      width: 12,
                      height: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: colorScheme.onPrimary, width: 1.5),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: widget.group.assets.length,
              itemBuilder: (context, index) {
                return _AssetThumbnail(asset: widget.group.assets[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetThumbnail extends StatefulWidget {
  final AssetEntity asset;

  const _AssetThumbnail({required this.asset});

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail> {
  Uint8List? _thumbData;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  Future<void> _loadThumb() async {
    final data = await widget.asset
        .thumbnailDataWithSize(const ThumbnailSize.square(200), quality: 80);
    if (mounted && data != null) {
      setState(() => _thumbData = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbData == null) {
      return Container(color: Colors.grey[300]);
    }
    return Image.memory(_thumbData!, fit: BoxFit.cover);
  }
}
