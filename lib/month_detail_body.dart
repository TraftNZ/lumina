import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:lumina/global.dart';
import 'package:intl/intl.dart';

class MonthDetailBody extends StatefulWidget {
  final int year;
  final int month;

  const MonthDetailBody({Key? key, required this.year, required this.month})
      : super(key: key);

  @override
  State<MonthDetailBody> createState() => _MonthDetailBodyState();
}

class _MonthDetailBodyState extends State<MonthDetailBody> {
  final List<AssetEntity> _assets = [];
  int _currentPage = 0;
  bool _loading = false;
  bool _hasMore = true;
  static const int _pageSize = 80;
  AssetPathEntity? _monthPath;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initMonthPath();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _initMonthPath() async {
    final re = await requestPermission();
    if (!re) return;

    final start = DateTime(widget.year, widget.month);
    final end = DateTime(widget.year, widget.month + 1);

    final filterOption = FilterOptionGroup(
      createTimeCond: DateTimeCond(min: start, max: end),
      orders: [
        const OrderOption(type: OrderOptionType.createDate, asc: false)
      ],
    );

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      filterOption: filterOption,
    );

    if (paths.isNotEmpty) {
      _monthPath = paths.first;
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _monthPath == null) return;
    _loading = true;

    final totalCount = await _monthPath!.assetCountAsync;
    final assets = await _monthPath!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    if (!mounted) return;
    setState(() {
      _assets.addAll(assets);
      _currentPage++;
      _hasMore = _assets.length < totalCount;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final title = DateFormat('MMMM yyyy', locale)
        .format(DateTime(widget.year, widget.month));
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: _assets.length,
        itemBuilder: (context, index) {
          return _AssetThumbnail(asset: _assets[index]);
        },
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
