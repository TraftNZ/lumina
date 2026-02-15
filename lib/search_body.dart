import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:img_syncer/proto/img_syncer.pbgrpc.dart';
import 'package:img_syncer/storage/storage.dart';
import 'package:img_syncer/global.dart';
import 'package:img_syncer/asset.dart';
import 'package:img_syncer/state_model.dart';
import 'package:extended_image/extended_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

class SearchBody extends StatefulWidget {
  const SearchBody({Key? key}) : super(key: key);

  @override
  State<SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<SearchBody> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Debouncer _debouncer = Debouncer(milliseconds: 300);

  List<String> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debouncer.run(() {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await storage.cli
          .searchPhotos(SearchPhotosRequest(query: query))
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
    // Set search results as temporary unified assets for viewing
    assetModel.setSearchResults(assets);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchResultsViewer(originIndex: 0),
      ),
    ).then((_) {
      // Restore normal view after returning
      assetModel.clearSearchResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.searchPhotos,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          style: textTheme.bodyLarge,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            _debouncer.cancel();
            _performSearch(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _results = [];
                  _hasSearched = false;
                });
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              l10n.noResults,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
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
              return _SearchResultThumbnail(
                path: _results[index],
                onTap: () => _openResult(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            l10n.searchPhotos,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.searchHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SearchResultThumbnail extends StatefulWidget {
  final String path;
  final VoidCallback onTap;

  const _SearchResultThumbnail({
    required this.path,
    required this.onTap,
  });

  @override
  State<_SearchResultThumbnail> createState() => _SearchResultThumbnailState();
}

class _SearchResultThumbnailState extends State<_SearchResultThumbnail> {
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
        setState(() {
          _thumbData = response;
        });
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

class SearchResultsViewer extends StatefulWidget {
  final int originIndex;

  const SearchResultsViewer({Key? key, required this.originIndex}) : super(key: key);

  @override
  State<SearchResultsViewer> createState() => SearchResultsViewerState();
}

class SearchResultsViewerState extends State<SearchResultsViewer> {
  late final ExtendedPageController _pageController;
  late List<Asset> all;
  late int currentIndex;
  bool showAppBar = true;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.originIndex;
    _pageController = ExtendedPageController(
      initialPage: widget.originIndex,
      keepPage: true,
    );
    all = assetModel.getUnifiedAssets();
    if (all.isNotEmpty && currentIndex < all.length) {
      all[currentIndex].readInfoFromData();
    }
    assetModel.addListener(_onAssetModelChanged);
  }

  void _onAssetModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    assetModel.removeListener(_onAssetModelChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No results')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: showAppBar ? null : Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: showAppBar ? null : Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (showAppBar) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareCurrentImage(),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadCurrentImage(),
            ),
          ],
        ],
      ),
      body: GestureDetector(
        onTap: () => setState(() => showAppBar = !showAppBar),
        child: ExtendedImageGesturePageView.builder(
          controller: _pageController,
          itemCount: all.length,
          onPageChanged: (int index) {
            setState(() {
              currentIndex = index;
            });
            all[index].readInfoFromData();
          },
          itemBuilder: (context, index) {
            final asset = all[index];
            if (asset.isVideo()) {
              return GestureDetector(
                onTap: () => setState(() => showAppBar = !showAppBar),
                child: const Center(
                  child: Icon(Icons.play_circle_outline, size: 80, color: Colors.white),
                ),
              );
            }
            return ExtendedImage(
              image: asset,
              fit: BoxFit.contain,
              mode: ExtendedImageMode.gesture,
              initGestureConfigHandler: (state) => GestureConfig(
                minScale: 1.0,
                maxScale: 3.0,
                inPageView: true,
              ),
              onDoubleTap: (gestureState) {
                if (gestureState.gestureDetails?.totalScale != null) {
                  final newScale = gestureState.gestureDetails!.totalScale! >= 2.0 ? 1.0 : 2.0;
                  gestureState.handleDoubleTap(scale: newScale);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _shareCurrentImage() async {
    if (currentIndex >= all.length) return;
    final asset = all[currentIndex];
    try {
      final data = await asset.imageDataAsync();
      final tempDir = await getTemporaryDirectory();
      final fileName = asset.name() ?? 'image.jpg';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(data);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _downloadCurrentImage() async {
    if (currentIndex >= all.length) return;
    final asset = all[currentIndex];
    try {
      final data = await asset.imageDataAsync();
      final fileName = asset.name() ?? 'image.jpg';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(data);
      await Gal.putImage(file.path, album: 'Pho');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.savedToGallery)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }
}

Future<Uint8List?> httpGetWithTimeout(String url) async {
  final client = http.Client();
  try {
    final response = await client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    return null;
  } finally {
    client.close();
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}
