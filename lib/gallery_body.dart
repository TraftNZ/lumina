import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:img_syncer/proto/img_syncer.pb.dart';
import 'package:img_syncer/state_model.dart';
import 'package:img_syncer/storage/storage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:img_syncer/gallery_viewer_route.dart';
import 'package:img_syncer/asset.dart';
import 'package:img_syncer/event_bus.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:img_syncer/global.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:vibration/vibration.dart';
import 'package:img_syncer/setting_storage_route.dart';

class GalleryBody extends StatefulWidget {
  const GalleryBody({Key? key, required this.useLocal}) : super(key: key);
  final bool useLocal;

  @override
  GalleryBodyState createState() => GalleryBodyState();
}

class GalleryBodyState extends State<GalleryBody>
    with AutomaticKeepAliveClientMixin {
  bool _showToTopBtn = false;
  @override
  bool get wantKeepAlive => true;
  final ScrollController _scrollController = ScrollController();
  final _scrollSubject = PublishSubject<double>();
  int columCount = 4;
  double scrollOffset = 0;

  final Map<int, bool> _selectedIndices = {};

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  PersistentBottomSheetController? _bottomSheetController;

  @override
  void initState() {
    super.initState();
    _scrollSubject.stream
        .debounceTime(const Duration(milliseconds: 150))
        .listen((scrollPosition) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 4000) {
        getPhotos();
      }
      setState(() {
        scrollOffset = scrollPosition;
      });
    });
    _scrollController.addListener(() {
      _scrollSubject.add(_scrollController.position.pixels);
      if (_scrollController.offset > 1000 && !_showToTopBtn) {
        setState(() {
          _showToTopBtn = true;
        });
      } else if (_scrollController.offset <= 1000 && _showToTopBtn) {
        setState(() {
          _showToTopBtn = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(GalleryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _scrollSubject.close();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  bool _isRefreshing = false;
  Future<void> refresh() async {
    if (stateModel.isDownloading() || stateModel.isUploading()) {
      return;
    }
    if (_isRefreshing) {
      return;
    }
    _isRefreshing = true;
    if (widget.useLocal) {
      assetModel.refreshLocal();
    } else {
      assetModel.refreshRemote();
    }
    _isRefreshing = false;
  }

  void getPhotos() {
    if (widget.useLocal) {
      assetModel.getLocalPhotos();
    } else {
      assetModel.getRemotePhotos();
    }
  }

  void toggleSelection(int index) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator!) {
      Vibration.vibrate(duration: 10);
    }
    if (_selectedIndices[index] == null) {
      _selectedIndices[index] = true;
    } else {
      _selectedIndices[index] = !_selectedIndices[index]!;
    }
    var hasSelected = false;
    _selectedIndices.forEach((key, value) {
      if (value) {
        hasSelected = true;
      }
    });
    stateModel.setSelectionMode(hasSelected);

    if (!hasSelected && _bottomSheetController != null) {
      _bottomSheetController?.close();
      _bottomSheetController = null;
    } else {
      if (hasSelected && _bottomSheetController == null) {
        _showBottomSheet(context);
      }
    }

    setState(() {});
  }

  void clearSelection() {
    _selectedIndices.clear();
    stateModel.setSelectionMode(false);
    if (_bottomSheetController != null) {
      _bottomSheetController?.close();
      _bottomSheetController = null;
    }
    setState(() {});
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("${l10n.deleteThisPhotos}?"),
        content: Text(l10n.cantBeUndone),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              var toDelete = <Asset>[];
              try {
                final all = widget.useLocal
                    ? assetModel.localAssets
                    : assetModel.remoteAssets;
                _selectedIndices.forEach((key, value) async {
                  if (value) {
                    toDelete.add(all[key]);
                  }
                });
                if (widget.useLocal) {
                  PhotoManager.editor
                      .deleteWithIds(toDelete.map((e) => e.local!.id).toList())
                      .then((value) => eventBus.fire(LocalRefreshEvent()));
                } else {
                  storage.cli
                      .delete(DeleteRequest(
                        paths: toDelete.map((e) => e.remote!.path).toList(),
                      ))
                      .then((rsp) => eventBus.fire(RemoteRefreshEvent()));
                }
              } catch (e) {
                SnackBarManager.showSnackBar(e.toString());
              }
              SnackBarManager.showSnackBar(
                  '${l10n.delete} ${toDelete.length} ${l10n.photos}.');
              clearSelection();
              setState(() {});
              Navigator.of(context).pop();
            },
            child: Text(l10n.yes),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _shareAsset() async {
    if (!stateModel.isSelectionMode) {
      return;
    }
    final all =
        widget.useLocal ? assetModel.localAssets : assetModel.remoteAssets;
    final assets = <Asset>[];
    _selectedIndices.forEach((key, isSelected) {
      if (isSelected) {
        assets.add(all[key]);
      }
    });
    List<XFile> xfiles = [];
    for (var asset in assets) {
      final data = await asset.imageDataAsync();
      xfiles.add(XFile.fromData(
        data,
        name: asset.name(),
        mimeType: asset.mimeType(),
      ));
    }
    SharePlus.instance.share(ShareParams(files: xfiles));
  }

  void downloadSelected() async {
    if (widget.useLocal || !stateModel.isSelectionMode) {
      return;
    }
    if (settingModel.localFolderAbsPath == null) {
      SnackBarManager.showSnackBar(l10n.setLocalFirst);
      return;
    }
    final all =
        widget.useLocal ? assetModel.localAssets : assetModel.remoteAssets;
    final assets = <Asset>[];
    _selectedIndices.forEach((key, isSelected) {
      if (isSelected) {
        assets.add(all[key]);
      }
    });
    int count = 0;
    try {
      for (var asset in assets) {
        if (asset.name() == null) {
          continue;
        }
        Uint8List data;
        if (!asset.isVideo()) {
          data = await asset.imageDataAsync();
        } else {
          data = await asset.remote!.imageData();
        }
        if (Platform.isAndroid) {
          final absPath = '${settingModel.localFolderAbsPath}/${asset.name()}';
          final file = File(absPath);
          await file.writeAsBytes(data);
          await file.setLastModified(asset.dateCreated());
          await scanFile(absPath);
        } else if (Platform.isIOS) {
          var appDocDir = await getTemporaryDirectory();
          String savePath = "${appDocDir.path}/${asset.name()}";
          final file = File(savePath);
          await file.writeAsBytes(data);
          await file.setLastModified(asset.dateCreated());
          await Gal.putImage(savePath);
        }

        count++;
      }
    } catch (e) {
      SnackBarManager.showSnackBar("${l10n.downloadFailed}: $e");
    }
    SnackBarManager.showSnackBar("${l10n.download} $count ${l10n.photos}");
    eventBus.fire(LocalRefreshEvent());
    clearSelection();
  }

  void uploadSelected() async {
    if (!widget.useLocal || !stateModel.isSelectionMode) {
      return;
    }
    if (!settingModel.isRemoteStorageSetted) {
      SnackBarManager.showSnackBar(l10n.storageNotSetted);
      return;
    }
    final all =
        widget.useLocal ? assetModel.localAssets : assetModel.remoteAssets;
    final assets = <Asset>[];
    _selectedIndices.forEach((key, isSelected) {
      if (isSelected) {
        assets.add(all[key]);
      }
    });
    for (var asset in assets) {
      final entity = asset.local!;
      try {
        await storage.uploadAssetEntity(entity);
      } catch (e) {
        SnackBarManager.showSnackBar("${l10n.uploadFailed}: $e");
      }
    }
    SnackBarManager.showSnackBar(
        "${l10n.successfullyUpload} ${assets.length} ${l10n.photos}");
    eventBus.fire(RemoteRefreshEvent());

    clearSelection();
  }

  void _showBottomSheet(BuildContext context) {
    _bottomSheetController = Scaffold.of(context).showBottomSheet(
      (BuildContext context) {
        return SizedBox(
          height: 80,
          child: Consumer<StateModel>(
              builder: (context, model, child) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _bottomSheetIconButton(
                          Icons.share_outlined, l10n.share, _shareAsset),
                      _bottomSheetIconButton(Icons.delete_outline, l10n.delete,
                          () => _showDeleteDialog(context)),
                      if (widget.useLocal)
                        _bottomSheetIconButton(
                            Icons.cloud_upload_outlined,
                            l10n.upload,
                            uploadSelected,
                            isEnable: !model.isDownloading() &&
                                !model.isUploading()),
                      if (!widget.useLocal)
                        _bottomSheetIconButton(
                            Icons.cloud_download_outlined,
                            l10n.download,
                            downloadSelected,
                            isEnable: !model.isDownloading() &&
                                !model.isUploading()),
                    ],
                  )),
        );
      },
    );
    _bottomSheetController!.closed.then((value) => clearSelection());
  }

  Widget _bottomSheetIconButton(
      IconData icon, String text, Function()? onTap,
      {bool isEnable = true}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkResponse(
      containedInkWell: true,
      radius: 40,
      onTap: isEnable ? onTap : null,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isEnable
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withAlpha(97),
            ),
            const SizedBox(height: 4),
            Text(text,
                style: TextStyle(
                    color: isEnable
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withAlpha(97),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget appBar() {
    return Consumer<StateModel>(
      builder: (context, model, child) {
        return SliverAppBar(
          pinned: false,
          snap: false,
          floating: true,
          expandedHeight: 70,
          toolbarHeight: 70,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          actions: [
            if (!widget.useLocal) setRemoteStorageButton(context)
          ],
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text(
              'Lumina',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        );
      },
    );
  }

  Widget contentBuilder(BuildContext context, AssetModel model, Widget? child) {
    final all = widget.useLocal ? model.localAssets : model.remoteAssets;
    var children = <Widget>[];
    final totalwidth = MediaQuery.of(context).size.width - columCount * 3;
    final totalHeight = MediaQuery.of(context).size.height;
    final imgWidth = totalwidth / columCount;
    final imgHeight = imgWidth;
    final colorScheme = Theme.of(context).colorScheme;

    var currentChildren = <Widget>[];
    DateTime? currentDateTime;
    double currentScrollOffset = 0;
    for (int i = 0; i < all.length; i++) {
      if (all[i].name() == null) {
        continue;
      }
      final date = all[i].dateCreated();
      if (currentDateTime == null ||
          date.year != currentDateTime.year ||
          date.month != currentDateTime.month ||
          date.day != currentDateTime.day) {
        children.add(Wrap(
          spacing: 3,
          runSpacing: 3.0,
          alignment: WrapAlignment.start,
          children: currentChildren,
        ));
        currentScrollOffset -= 3;
        currentChildren = <Widget>[];
        DateFormat format = DateFormat('yyyy MMMM d${l10n.chineseday}  EEEEE',
            Localizations.localeOf(context).languageCode);
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            format.format(date),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ));
        currentScrollOffset += 40;
      }
      bool needLoadThumbnail = false;
      if (currentScrollOffset > scrollOffset - (2 * totalHeight) &&
          currentScrollOffset < scrollOffset + (3 * totalHeight)) {
        needLoadThumbnail = true;
        if (!all[i].loadThumbnailFinished()) {
          all[i].thumbnailDataAsync().then((value) => setState(() {}));
        }
      }
      var child = GestureDetector(
          onTap: () async {
            if (stateModel.isSelectionMode) {
              toggleSelection(i);
            } else {
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  transitionDuration: const Duration(milliseconds: 300),
                  reverseTransitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder: (BuildContext context,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                      Widget child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  pageBuilder: (BuildContext context, _, __) =>
                      GalleryViewerRoute(
                    useLocal: widget.useLocal,
                    originIndex: i,
                  ),
                ),
              );
            }
          },
          onLongPress: () {
            if (!stateModel.isSelectionMode) {
              toggleSelection(i);
            }
          },
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                    width: imgWidth,
                    height: imgHeight,
                    child: Hero(
                      tag:
                          "asset_${all[i].hasLocal ? "local" : "remote"}_${all[i].path()}",
                      child:
                          needLoadThumbnail && all[i].loadThumbnailFinished()
                              ? Image(
                                  image: all[i].thumbnailProvider(),
                                  fit: BoxFit.cover)
                              : Container(
                                  color: colorScheme.surfaceContainerHighest),
                      flightShuttleBuilder: (BuildContext flightContext,
                          Animation<double> animation,
                          HeroFlightDirection flightDirection,
                          BuildContext fromHeroContext,
                          BuildContext toHeroContext) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (BuildContext context, Widget? child) {
                            return Opacity(
                                opacity: animation.value,
                                child: all[i].loadThumbnailFinished()
                                    ? Image(
                                        image: all[i].thumbnailProvider(),
                                        fit: BoxFit.contain,
                                      )
                                    : Container(
                                        color: colorScheme
                                            .surfaceContainerHighest));
                          },
                        );
                      },
                    )),
              ),
              Consumer<StateModel>(builder: (context, stateModel, child) {
                double percent = 0;
                if (!widget.useLocal) {
                  percent = stateModel.getDownloadPercent(all[i].name()!);
                } else {
                  percent = stateModel.getUploadPercent(all[i].local!.id);
                }
                if (percent > 0) {
                  return Positioned(
                    bottom: 2,
                    right: 4,
                    width: 20,
                    height: 20,
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                              widget.useLocal
                                  ? Icons.arrow_upward_outlined
                                  : Icons.arrow_downward_outlined,
                              color: Colors.white,
                              size: 16),
                        ),
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                          value: percent,
                        )
                      ],
                    ),
                  );
                }
                var showCloudBadge = false;
                if (widget.useLocal &&
                    stateModel.notSyncedIDs.isNotEmpty &&
                    !stateModel.notSyncedIDs.contains(all[i].local!.id)) {
                  showCloudBadge = true;
                }
                if (!showCloudBadge) return const SizedBox.shrink();
                return Positioned(
                  bottom: 2,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(180),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.cloud_done_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                );
              }),
              if (all[i].isVideo())
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              if (stateModel.isSelectionMode)
                Positioned(
                  top: 2,
                  left: 2,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _selectedIndices[i] ?? false,
                      onChanged: (value) {
                        toggleSelection(i);
                      },
                      fillColor: WidgetStateProperty.all(
                          colorScheme.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ));
      currentChildren.add(child);
      if (currentChildren.length % columCount == 1) {
        currentScrollOffset += imgHeight + 3;
      }
      currentDateTime = all[i].dateCreated();

      if (i == all.length - 1) {
        children.add(Wrap(
          spacing: 3,
          runSpacing: 3.0,
          alignment: WrapAlignment.start,
          children: currentChildren,
        ));
      }
    }
    return SliverList.list(
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: refresh,
      child: Stack(
        children: [
          CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                appBar(),
                Consumer<AssetModel>(builder: contentBuilder),
              ]),
          Positioned(
            bottom: 20,
            right: 20,
            child: Offstage(
              offstage: !_showToTopBtn,
              child: FloatingActionButton.small(
                onPressed: _scrollToTop,
                heroTag: 'gallery_body_${widget.useLocal}_toTop',
                child: const Icon(Icons.arrow_upward),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget setRemoteStorageButton(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.settings_outlined),
    tooltip: 'Set remote storage',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingStorageRoute()),
      );
    },
  );
}
