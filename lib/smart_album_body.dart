import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lumina/proto/lumina.pbgrpc.dart';
import 'package:lumina/storage/storage.dart';
import 'package:lumina/global.dart';
import 'package:lumina/asset.dart';
import 'package:lumina/state_model.dart';
import 'package:lumina/search_body.dart';

class SmartAlbumBody extends StatefulWidget {
  final String query;
  final String title;

  const SmartAlbumBody({Key? key, required this.query, required this.title}) : super(key: key);

  @override
  State<SmartAlbumBody> createState() => _SmartAlbumBodyState();
}

class _SmartAlbumBodyState extends State<SmartAlbumBody> {
  List<String> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final response = await storage.cli
          .searchPhotos(SearchPhotosRequest(query: widget.query))
          .timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _results = response.success ? response.paths : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    }
  }

  void _openResult(int index) {
    final assets = _results.map((path) => Asset(remote: RemoteImage(storage.cli, path))).toList();
    assetModel.setSearchResults(assets);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchResultsViewer(originIndex: 0),
      ),
    ).then((_) {
      assetModel.clearSearchResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noResults,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_results.length} ${l10n.photos}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
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
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          return _SmartAlbumThumbnail(
                            path: _results[index],
                            onTap: () => _openResult(index),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SmartAlbumThumbnail extends StatefulWidget {
  final String path;
  final VoidCallback onTap;

  const _SmartAlbumThumbnail({required this.path, required this.onTap});

  @override
  State<_SmartAlbumThumbnail> createState() => _SmartAlbumThumbnailState();
}

class _SmartAlbumThumbnailState extends State<_SmartAlbumThumbnail> {
  Uint8List? _thumbData;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    var urlPath = widget.path;
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
    return GestureDetector(
      onTap: widget.onTap,
      child: _thumbData == null
          ? Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)
          : Image.memory(_thumbData!, fit: BoxFit.cover),
    );
  }
}
