import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:lumina/asset.dart';
import 'package:lumina/state_model.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lumina/storage/storage.dart';
import 'event_bus.dart';
import 'package:extended_image/extended_image.dart';
import 'package:lumina/video_route.dart';
import 'package:lumina/global.dart';
import 'package:lumina/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

class GalleryViewerRoute extends StatefulWidget {
  const GalleryViewerRoute({
    Key? key,
    required this.originIndex,
  }) : super(key: key);
  final int originIndex;

  @override
  GalleryViewerRouteState createState() => GalleryViewerRouteState();
}

class GalleryViewerRouteState extends State<GalleryViewerRoute> {
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
    all[currentIndex].readInfoFromData();
    assetModel.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant GalleryViewerRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isShowingImageInfo = false;
  void showImageInfo(BuildContext context) {
    final currentAsset = all[currentIndex];
    if (!currentAsset.isInfoReady()) {
      return;
    }
    if (_isShowingImageInfo) {
      return;
    }
    _isShowingImageInfo = true;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        List<Widget> columns = [];
        columns.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              all[currentIndex].name() ?? '',
              style: textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
        columns.add(const Divider(indent: 16, endIndent: 16));
        if (currentAsset.date != null) {
          columns.add(ListTile(
              leading: SizedBox(
                width: 40,
                child: Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              title: Text(l10n.date, style: textTheme.bodyMedium),
              subtitle: Text(
                currentAsset.date!,
                style: textTheme.bodySmall,
              )));
        }
        if (currentAsset.make != null && currentAsset.model != null) {
          List<String> children = [
            if (currentAsset.fNumber != null) "f/${currentAsset.fNumber}",
            if (currentAsset.exposureTime != null)
              "${currentAsset.exposureTime!}",
            if (currentAsset.focalLength != null)
              "${currentAsset.focalLength}mm",
            if (currentAsset.iSO != null) "ISO${currentAsset.iSO}",
          ];
          columns.add(
            ListTile(
              leading: SizedBox(
                width: 40,
                child: Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.camera_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              title: Text("${currentAsset.make} ${currentAsset.model}",
                  style: textTheme.bodyMedium),
              subtitle: Text(
                children.join("  \u2022  "),
                style: textTheme.bodySmall,
              ),
            ),
          );
        }
        columns.add(ListTile(
          leading: SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.photo_size_select_actual_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          title: Text(all[currentIndex].name()!,
              style: textTheme.bodyMedium),
          subtitle: currentAsset.isVideo()
              ? null
              : RichText(
                  text: TextSpan(
                    style: textTheme.bodySmall,
                    children: [
                      TextSpan(
                        text: currentAsset.imageWidth != null &&
                                currentAsset.imageHeight != null
                            ? "${(currentAsset.imageWidth! * currentAsset.imageHeight! / 1024 / 1024).floor()} MP"
                            : null,
                      ),
                      TextSpan(
                          text: currentAsset.imageWidth != null
                              ? "  \u2022  ${currentAsset.imageWidth!}x${currentAsset.imageHeight!}"
                              : null),
                    ],
                  ),
                ),
        ));

        columns.add(ListTile(
          leading: SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.center,
              child: Icon(
                all[currentIndex].hasLocal && all[currentIndex].hasRemote
                    ? Icons.cloud_done
                    : all[currentIndex].hasLocal
                        ? Icons.phone_android
                        : Icons.cloud_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          title: Text(
              l10n.library,
              style: textTheme.bodyMedium),
          subtitle: RichText(
            text: TextSpan(
              style: textTheme.bodySmall,
              children: [
                if (!currentAsset.isVideo())
                  TextSpan(
                      text: "${currentAsset.imageSize.toStringAsFixed(1)} MB"),
                if (Platform.isAndroid) ...[
                  const TextSpan(text: "  \u2022  "),
                  TextSpan(text: all[currentIndex].path()),
                ]
              ],
            ),
          ),
        ));

        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          padding: const EdgeInsets.only(top: 12),
          child: IntrinsicHeight(
            child: Column(
              children: columns,
            ),
          ),
        );
      },
    ).then((value) => _isShowingImageInfo = false);
  }

  void deleteCurrent(BuildContext context) {
    final asset = all[currentIndex];

    // Optimistically remove from UI and pop immediately
    assetModel.removeAssets([asset]);
    SnackBarManager.showSnackBar(l10n.movedToTrash);
    if (mounted) Navigator.of(context).pop();

    // Perform actual deletion in background (no refresh — optimistic removal is sufficient)
    () async {
      try {
        await asset.delete();
      } catch (e) {
        SnackBarManager.showSnackBar(e.toString());
      }
    }();
  }

  void download(Asset asset) async {
    if (asset.isLocal()) {
      return;
    }
    OverlayEntry loadingDialog = OverlayEntry(
      builder: (context) => Center(
        child: Consumer<StateModel>(
          builder: (context, stateModel, child) => CircularProgressIndicator(
            strokeWidth: 5,
            value: stateModel.getDownloadPercent(asset.name()!),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(loadingDialog);
    try {
      if (asset.name() != null) {
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
        }
        if (Platform.isIOS) {
          var appDocDir = await getTemporaryDirectory();
          String savePath = "${appDocDir.path}/${asset.name()}";
          final file = File(savePath);
          await file.writeAsBytes(data);
          await file.setLastModified(asset.dateCreated());
          await Gal.putImage(savePath);
        }
      }
      SnackBarManager.showSnackBar("${l10n.download} ${asset.name()} ${l10n.success}");
      eventBus.fire(LocalRefreshEvent());
    } catch (e) {
      SnackBarManager.showSnackBar(e.toString());
    } finally {
      loadingDialog.remove();
    }
  }

  void upload(Asset asset) async {
    if (!asset.isLocal()) {
      return;
    }
    OverlayEntry loadingDialog = OverlayEntry(
      builder: (context) => Center(
        child: SizedBox(
          height: 50.0,
          width: 50.0,
          child: Consumer<StateModel>(
            builder: (context, value, child) {
              return CircularProgressIndicator(
                strokeWidth: 5,
                value: stateModel.getUploadPercent(asset.local!.id),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(loadingDialog);
    if (!settingModel.isRemoteStorageSetted) {
      SnackBarManager.showSnackBar(l10n.storageNotSetted);
      return;
    }
    final entity = asset.local!;
    try {
      await storage.uploadAssetEntity(entity);
      if (mounted) {
        SnackBarManager.showSnackBar("${l10n.upload} ${asset.name()} ${l10n.success}");
      }
      eventBus.fire(RemoteRefreshEvent());
    } catch (e) {
      print(e);
      SnackBarManager.showSnackBar(e.toString());
    } finally {
      loadingDialog.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => deleteCurrent(context),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () async {
                    final data = await all[currentIndex].imageDataAsync();
                    SharePlus.instance.share(ShareParams(
                      files: [
                        XFile.fromData(data,
                            name: all[currentIndex].name(),
                            mimeType: all[currentIndex].mimeType()),
                      ],
                    ));
                  },
                ),
                if (all[currentIndex].isCloudOnly)
                  Consumer<StateModel>(builder: (context, model, child) {
                    return IconButton(
                      icon: const Icon(Icons.cloud_download_outlined),
                      onPressed: () =>
                          model.isDownloading() || model.isUploading()
                              ? null
                              : download(all[currentIndex]),
                    );
                  }),
                if (all[currentIndex].hasLocal)
                  Consumer<StateModel>(builder: (context, stateModel, child) {
                    return IconButton(
                      icon: all[currentIndex].hasRemote
                          ? const Icon(Icons.cloud_done_outlined)
                          : const Icon(Icons.cloud_upload_outlined),
                      onPressed: () =>
                          stateModel.isDownloading() || stateModel.isUploading()
                              ? null
                              : upload(all[currentIndex]),
                    );
                  }),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    all[currentIndex].imageDataAsync().then(
                          (value) => showImageInfo(context),
                        );
                  },
                ),
              ],
            )
          : null,
      body: Hero(
        tag:
            "asset_${all[currentIndex].dedupKey ?? all[currentIndex].path()}",
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
                child: ExtendedImage(
                  image: all[currentIndex].thumbnailProvider(),
                  fit: BoxFit.contain,
                ),
              );
            },
          );
        },
        child: Container(
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: ExtendedImageGesturePageView.builder(
            itemCount: all.length,
            controller: _pageController,
            onPageChanged: (int index) {
              setState(() {
                currentIndex = index;
              });
              all[index].readInfoFromData().then((value) {
                if (index + 1 >= 0 && index + 1 < all.length) {
                  all[index + 1].readInfoFromData();
                }
                if (index - 1 >= 0 && index - 1 < all.length) {
                  all[index - 1].readInfoFromData();
                }
              });
              if (all.length - index < 5) {
                assetModel.getMorePhotos();
              }
            },
            itemBuilder: (BuildContext context, int index) {
              return Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  ExtendedImage(
                    image: all[index],
                    fit: BoxFit.contain,
                    mode: ExtendedImageMode.gesture,
                    initGestureConfigHandler: (state) {
                      return GestureConfig(
                        minScale: 1.0,
                        maxScale: 3.0,
                        inPageView: true,
                        gestureDetailsIsChanged: (details) {
                          if (details == null) {
                            return;
                          }
                          if (details.totalScale == 1.0 &&
                              details.offset!.dy < -100) {
                            showImageInfo(context);
                          }
                        },
                      );
                    },
                    loadStateChanged: (ExtendedImageState state) {
                      switch (state.extendedImageLoadState) {
                        case LoadState.loading:
                          return ExtendedImage(
                            image: all[index].thumbnailProvider(),
                            fit: BoxFit.contain,
                          );
                        case LoadState.completed:
                          return null;
                        case LoadState.failed:
                          return null;
                        default:
                          return null;
                      }
                    },
                    onDoubleTap: (ExtendedImageGestureState gestureState) {
                      if (gestureState.gestureDetails != null &&
                          gestureState.gestureDetails!.totalScale != null) {
                        double newScale =
                            gestureState.gestureDetails!.totalScale! >= 2.0
                                ? 1.0
                                : 2.0;
                        gestureState.handleDoubleTap(scale: newScale);
                      }
                    },
                  ),
                  if (all[index].isVideo())
                    const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 60,
                    ),
                  GestureDetector(
                    onTap: () {
                      if (all[index].isVideo()) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => VideoRoute(
                              asset: all[index],
                            ),
                          ),
                        );
                      } else {
                        setState(() {
                          showAppBar = !showAppBar;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
