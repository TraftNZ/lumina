import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

typedef TimelineDateForMetrics = DateTime? Function(ScrollMetrics metrics);
typedef TimelineDateForFraction = DateTime? Function(double scrollFraction);
typedef TimelineMarkersForMetrics =
    List<TimelineMarker> Function(ScrollMetrics metrics);
typedef TimelineScrubStateChanged = void Function(bool scrubbing);

@immutable
class TimelineMarker {
  final int year;
  final double scrollFraction;

  const TimelineMarker({required this.year, required this.scrollFraction});
}

/// A touch-first timeline scrubber modelled after Google Photos.
///
/// Normal drags remain owned by [child]. Once scrolling reveals the scrubber,
/// its large right-edge handle can be dragged directly to any point in the
/// loaded timeline. Year markers and a localized month label provide context
/// without forcing the gallery to eagerly render off-screen tiles.
class TimelineScrollbar extends StatefulWidget {
  final ScrollController controller;
  final Widget child;
  final TimelineDateForMetrics dateForMetrics;
  final TimelineDateForFraction dateForFraction;
  final TimelineMarkersForMetrics? markersForMetrics;
  final TimelineScrubStateChanged? onScrubStateChanged;
  final bool interactive;
  final bool showDatePreview;

  const TimelineScrollbar({
    super.key,
    required this.controller,
    required this.child,
    required this.dateForMetrics,
    required this.dateForFraction,
    this.markersForMetrics,
    this.onScrubStateChanged,
    this.interactive = true,
    this.showDatePreview = true,
  });

  @override
  State<TimelineScrollbar> createState() => _TimelineScrollbarState();
}

class _TimelineScrollbarState extends State<TimelineScrollbar> {
  static const _topInset = 72.0;
  static const _bottomInset = 112.0;
  static const _handleExtent = 56.0;
  static const _markerExtent = 28.0;

  Timer? _hideTimer;
  bool _overlayVisible = false;
  bool _scrubbing = false;
  double _scrollFraction = 0;
  DateTime? _previewDate;
  List<TimelineMarker> _markers = const [];
  double _lastMinScrollExtent = -1;
  double _lastMaxScrollExtent = -1;
  double? _pendingJumpFraction;
  double? _lastJumpedFraction;
  int? _liveJumpFrameCallbackId;
  int? _scrubPointer;
  DateFormat? _dateFormatter;
  String _dateFormatterLocale = '';

  @override
  void didUpdateWidget(covariant TimelineScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showDatePreview && _overlayVisible) {
      _invalidatePendingJump();
      _hideTimer?.cancel();
      _overlayVisible = false;
      if (_scrubbing) widget.onScrubStateChanged?.call(false);
      _scrubbing = false;
      _scrubPointer = null;
    } else if (!widget.interactive && oldWidget.interactive) {
      _invalidatePendingJump();
      if (_scrubbing) {
        _scrubbing = false;
        widget.onScrubStateChanged?.call(false);
        _scheduleHide();
      }
      _scrubPointer = null;
    }
  }

  @override
  void dispose() {
    _scrubPointer = null;
    _invalidatePendingJump();
    _hideTimer?.cancel();
    if (_scrubbing) widget.onScrubStateChanged?.call(false);
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.showDatePreview) return false;

    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      _showOverlay(notification.metrics);
    } else if (notification is ScrollEndNotification && !_scrubbing) {
      _scheduleHide();
    }
    return false;
  }

  void _showOverlay(ScrollMetrics metrics) {
    final scrollableExtent = metrics.maxScrollExtent - metrics.minScrollExtent;
    if (scrollableExtent <= 0) return;

    final fraction =
        ((metrics.pixels - metrics.minScrollExtent) / scrollableExtent).clamp(
          0.0,
          1.0,
        );
    final date = widget.dateForMetrics(metrics);
    if (date == null) return;
    final month = DateTime(date.year, date.month);

    _hideTimer?.cancel();
    if (_overlayVisible &&
        _previewDate == month &&
        (_scrollFraction - fraction).abs() < 0.002 &&
        _lastMinScrollExtent == metrics.minScrollExtent &&
        _lastMaxScrollExtent == metrics.maxScrollExtent) {
      return;
    }
    final markers = widget.markersForMetrics?.call(metrics) ?? const [];
    setState(() {
      _overlayVisible = true;
      _scrollFraction = fraction;
      _previewDate = month;
      _markers = markers;
      _lastMinScrollExtent = metrics.minScrollExtent;
      _lastMaxScrollExtent = metrics.maxScrollExtent;
    });
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || _scrubbing) return;
      setState(() => _overlayVisible = false);
    });
  }

  void _beginScrub(Offset globalPosition, double height) {
    if (!widget.interactive || !widget.controller.hasClients) return;
    _lastJumpedFraction = null;
    _hideTimer?.cancel();
    setState(() {
      _scrubbing = true;
      _overlayVisible = true;
    });
    widget.onScrubStateChanged?.call(true);
    _scrubTo(globalPosition, height);
  }

  void _updateScrub(Offset globalPosition, double height) {
    if (!_scrubbing) return;
    _scrubTo(globalPosition, height);
  }

  void _handlePointerDown(PointerDownEvent event, double height) {
    if (_scrubPointer != null ||
        !widget.interactive ||
        !widget.controller.hasClients) {
      return;
    }
    _scrubPointer = event.pointer;
    _beginScrub(event.position, height);
  }

  void _handlePointerMove(PointerMoveEvent event, double height) {
    if (_scrubPointer != event.pointer) return;
    _updateScrub(event.position, height);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_scrubPointer != event.pointer) return;
    _scrubPointer = null;
    _endScrub();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_scrubPointer != event.pointer) return;
    _scrubPointer = null;
    _cancelScrub();
  }

  void _endScrub() {
    if (!_scrubbing) return;
    final pendingFraction = _pendingJumpFraction;
    _invalidatePendingJump();
    setState(() => _scrubbing = false);
    if (pendingFraction != null &&
        widget.interactive &&
        widget.showDatePreview &&
        (_lastJumpedFraction == null ||
            (_lastJumpedFraction! - pendingFraction).abs() > 0.0001)) {
      _jumpToFraction(pendingFraction);
    }
    widget.onScrubStateChanged?.call(false);
    _scheduleHide();
  }

  void _cancelScrub() {
    if (!_scrubbing) return;
    _invalidatePendingJump();
    setState(() => _scrubbing = false);
    widget.onScrubStateChanged?.call(false);
    _scheduleHide();
  }

  void _scrubTo(Offset globalPosition, double height) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !widget.controller.hasClients) return;
    final localY = renderObject.globalToLocal(globalPosition).dy;
    final travel = math.max(
      1.0,
      height - _topInset - _bottomInset - _handleExtent,
    );
    final fraction = ((localY - _topInset - _handleExtent / 2) / travel).clamp(
      0.0,
      1.0,
    );
    _requestJumpToFraction(fraction);
  }

  void _requestJumpToFraction(double fraction) {
    _pendingJumpFraction = fraction;
    final date = widget.dateForFraction(fraction);
    final month = date == null ? null : DateTime(date.year, date.month);
    if ((_scrollFraction - fraction).abs() > 0.0001 ||
        (month != null && _previewDate != month)) {
      setState(() {
        _overlayVisible = true;
        _scrollFraction = fraction;
        if (month != null) _previewDate = month;
      });
    }
    _scheduleLiveJump();
  }

  void _scheduleLiveJump() {
    if (!_scrubbing || _liveJumpFrameCallbackId != null) return;
    _liveJumpFrameCallbackId = SchedulerBinding.instance.scheduleFrameCallback((
      _,
    ) {
      _liveJumpFrameCallbackId = null;
      if (!mounted ||
          !_scrubbing ||
          !widget.interactive ||
          !widget.showDatePreview) {
        return;
      }
      final fraction = _pendingJumpFraction;
      if (fraction != null) _jumpToFraction(fraction);
    });
  }

  void _invalidatePendingJump() {
    final callbackId = _liveJumpFrameCallbackId;
    if (callbackId != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(callbackId);
      _liveJumpFrameCallbackId = null;
    }
    _pendingJumpFraction = null;
  }

  void _jumpToFraction(double fraction) {
    final position = widget.controller.position;
    final extent = position.maxScrollExtent - position.minScrollExtent;
    if (extent <= 0) return;
    _lastJumpedFraction = fraction;
    widget.controller.jumpTo(position.minScrollExtent + extent * fraction);
    _showOverlay(position);
  }

  void _adjustPosition(double delta) {
    if (!widget.interactive || !widget.controller.hasClients) return;
    _invalidatePendingJump();
    _jumpToFraction((_scrollFraction + delta).clamp(0.0, 1.0));
    _scheduleHide();
  }

  List<TimelineMarker> _visibleMarkers(double travel) {
    if (_markers.isEmpty) return const [];
    final visible = <TimelineMarker>[];
    var lastY = double.negativeInfinity;
    for (final marker in _markers) {
      final y = travel * marker.scrollFraction;
      if (y - lastY < _markerExtent + 4) continue;
      if ((marker.scrollFraction - _scrollFraction).abs() * travel < 36) {
        continue;
      }
      visible.add(marker);
      lastY = y;
    }
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = _previewDate;
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_dateFormatter == null || _dateFormatterLocale != locale) {
      _dateFormatter = DateFormat.yMMM(locale);
      _dateFormatterLocale = locale;
    }
    final dateLabel = date == null ? null : _dateFormatter!.format(date);

    return LayoutBuilder(
      builder: (context, constraints) {
        final travel = math.max(
          0.0,
          constraints.maxHeight - _topInset - _bottomInset - _handleExtent,
        );
        final handleTop = _topInset + travel * _scrollFraction;
        final markerTravel = travel + _handleExtent - _markerExtent;
        final markers = _visibleMarkers(markerTravel);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: widget.child,
                ),
              ),
            ),
            if (widget.showDatePreview && date != null) ...[
              for (final marker in markers)
                Positioned(
                  top: _topInset + markerTravel * marker.scrollFraction,
                  right: 62,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _overlayVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 140),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SizedBox(
                          height: _markerExtent,
                          width: 58,
                          child: Center(
                            child: Text(
                              '${marker.year}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: handleTop + (_handleExtent - 38) / 2,
                right: 62,
                child: IgnorePointer(
                  child: Semantics(
                    hidden: !_overlayVisible || _scrubbing,
                    liveRegion: !_scrubbing,
                    label: _scrubbing ? null : dateLabel,
                    child: ExcludeSemantics(
                      child: AnimatedOpacity(
                        opacity: _overlayVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 140),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.inverseSurface,
                            borderRadius: BorderRadius.circular(19),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 38,
                              minWidth: 92,
                              maxWidth: 160,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                dateLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: colorScheme.onInverseSurface,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: handleTop,
                right: 0,
                width: 64,
                height: _handleExtent,
                child: IgnorePointer(
                  ignoring: !_overlayVisible || !widget.interactive,
                  child: AnimatedOpacity(
                    opacity: _overlayVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 140),
                    child: Semantics(
                      label: _scrubbing ? null : dateLabel,
                      onIncrease: widget.interactive
                          ? () => _adjustPosition(0.08)
                          : null,
                      onDecrease: widget.interactive
                          ? () => _adjustPosition(-0.08)
                          : null,
                      child: Listener(
                        key: const ValueKey('timeline-scrubber-handle'),
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (event) =>
                            _handlePointerDown(event, constraints.maxHeight),
                        onPointerMove: (event) =>
                            _handlePointerMove(event, constraints.maxHeight),
                        onPointerUp: _handlePointerUp,
                        onPointerCancel: _handlePointerCancel,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 48,
                            height: _handleExtent,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(28),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.unfold_more,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
