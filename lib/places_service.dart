import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:img_syncer/global.dart';

class CityGroup {
  final String cityName;
  final String countryCode;
  final double lat;
  final double lng;
  final List<AssetEntity> assets;
  Uint8List? thumbnail;

  CityGroup({
    required this.cityName,
    required this.countryCode,
    required this.lat,
    required this.lng,
    required this.assets,
    this.thumbnail,
  });

  int get photoCount => assets.length;
}

class _City {
  final String name;
  final String country;
  final double lat;
  final double lng;

  _City({
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
  });
}

class PlacesService {
  PlacesService._();
  static final PlacesService instance = PlacesService._();

  List<_City>? _cities;
  List<CityGroup>? _cachedGroups;
  bool _scanning = false;

  bool get isScanning => _scanning;

  Future<void> _loadCities() async {
    if (_cities != null) return;
    final jsonStr = await rootBundle.loadString('assets/data/cities.json');
    final List<dynamic> list = json.decode(jsonStr);
    _cities = list.map((e) => _City(
      name: e['n'] as String,
      country: e['c'] as String,
      lat: (e['la'] as num).toDouble(),
      lng: (e['lo'] as num).toDouble(),
    )).toList();
  }

  _City? _findNearestCity(double lat, double lng) {
    if (_cities == null || _cities!.isEmpty) return null;
    _City? nearest;
    double minDist = double.infinity;
    for (final city in _cities!) {
      final dist = _haversineDistance(lat, lng, city.lat, city.lng);
      if (dist < minDist) {
        minDist = dist;
        nearest = city;
      }
    }
    if (minDist > 200.0) return null;
    return nearest;
  }

  static double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;

  Future<List<CityGroup>> scanPhotosForLocations({
    void Function(int scanned, int total, int withLocation)? onProgress,
  }) async {
    if (_cachedGroups != null) return _cachedGroups!;
    if (_scanning) return [];
    _scanning = true;

    try {
      await _loadCities();
      final re = await requestPermission();
      if (!re) return [];

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );

      AssetPathEntity? allPath;
      for (final p in paths) {
        if (p.isAll) {
          allPath = p;
          break;
        }
      }
      if (allPath == null && paths.isNotEmpty) {
        allPath = paths.first;
      }
      if (allPath == null) return [];

      final totalCount = await allPath.assetCountAsync;
      if (totalCount == 0) return [];

      final Map<String, CityGroup> groups = {};
      const pageSize = 100;
      int scanned = 0;
      int withLocation = 0;

      for (int page = 0; ; page++) {
        final assets = await allPath.getAssetListPaged(page: page, size: pageSize);
        if (assets.isEmpty) break;

        for (final asset in assets) {
          final latLng = await asset.latlngAsync();
          scanned++;
          if (latLng != null) withLocation++;
          if (scanned % 50 == 0) {
            onProgress?.call(scanned, totalCount, withLocation);
          }

          if (latLng == null) continue;
          final lat = latLng.latitude;
          final lng = latLng.longitude;

          final city = _findNearestCity(lat, lng);
          if (city == null) continue;

          final key = '${city.name}_${city.country}';
          if (groups.containsKey(key)) {
            groups[key]!.assets.add(asset);
          } else {
            groups[key] = CityGroup(
              cityName: city.name,
              countryCode: city.country,
              lat: city.lat,
              lng: city.lng,
              assets: [asset],
            );
          }
        }

        if (assets.length < pageSize) break;
      }

      onProgress?.call(totalCount, totalCount, withLocation);

      final result = groups.values.toList()
        ..sort((a, b) => b.photoCount.compareTo(a.photoCount));

      for (final group in result) {
        if (group.assets.isNotEmpty) {
          group.thumbnail = await group.assets.first.thumbnailDataWithSize(
            const ThumbnailSize.square(200),
            quality: 80,
          );
        }
      }

      if (result.isNotEmpty) {
        _cachedGroups = result;
      }
      return result;
    } finally {
      _scanning = false;
    }
  }

  void clearCache() {
    _cachedGroups = null;
  }
}
