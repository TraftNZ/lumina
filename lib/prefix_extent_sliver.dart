import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Returns the item containing [scrollOffset] using cumulative item ends.
///
/// Flutter's varied-extent sliver scans every preceding extent for this lookup.
/// A timeline scrubber performs distant lookups repeatedly, so keeping the
/// prefix sums and using binary search avoids work proportional to row count.
int prefixExtentIndexForScrollOffset(
  List<double> cumulativeExtents,
  double scrollOffset,
) {
  if (cumulativeExtents.isEmpty || scrollOffset <= 0) return 0;

  var low = 0;
  var high = cumulativeExtents.length;
  while (low < high) {
    final middle = (low + high) >> 1;
    if (cumulativeExtents[middle] < scrollOffset) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return low >= cumulativeExtents.length ? cumulativeExtents.length - 1 : low;
}

/// A lazy varied-extent sliver with prefix-sum offset lookup.
///
/// [itemExtents] and [cumulativeExtents] must have the same length and remain
/// immutable for the lifetime of the widget instance.
class SliverPrefixExtentList extends SliverMultiBoxAdaptorWidget {
  SliverPrefixExtentList.builder({
    super.key,
    required NullableIndexedWidgetBuilder itemBuilder,
    required this.itemExtents,
    required this.cumulativeExtents,
    ChildIndexGetter? findChildIndexCallback,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : assert(itemExtents.length == cumulativeExtents.length),
       assert(itemCount == null || itemCount == itemExtents.length),
       super(
         delegate: SliverChildBuilderDelegate(
           itemBuilder,
           findChildIndexCallback: findChildIndexCallback,
           childCount: itemCount,
           addAutomaticKeepAlives: addAutomaticKeepAlives,
           addRepaintBoundaries: addRepaintBoundaries,
           addSemanticIndexes: addSemanticIndexes,
         ),
       );

  final List<double> itemExtents;
  final List<double> cumulativeExtents;

  @override
  RenderSliverPrefixExtentList createRenderObject(BuildContext context) {
    return RenderSliverPrefixExtentList(
      childManager: context as SliverMultiBoxAdaptorElement,
      itemExtents: itemExtents,
      cumulativeExtents: cumulativeExtents,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverPrefixExtentList renderObject,
  ) {
    renderObject.updateExtents(itemExtents, cumulativeExtents);
  }
}

class RenderSliverPrefixExtentList extends RenderSliverFixedExtentBoxAdaptor {
  RenderSliverPrefixExtentList({
    required super.childManager,
    required List<double> itemExtents,
    required List<double> cumulativeExtents,
  }) : assert(itemExtents.length == cumulativeExtents.length),
       _itemExtents = itemExtents,
       _cumulativeExtents = cumulativeExtents;

  List<double> _itemExtents;
  List<double> _cumulativeExtents;

  void updateExtents(List<double> itemExtents, List<double> cumulativeExtents) {
    assert(itemExtents.length == cumulativeExtents.length);
    if (identical(_itemExtents, itemExtents) &&
        identical(_cumulativeExtents, cumulativeExtents)) {
      return;
    }
    _itemExtents = itemExtents;
    _cumulativeExtents = cumulativeExtents;
    markNeedsLayout();
  }

  double? _extentForIndex(int index, SliverLayoutDimensions dimensions) {
    if (index < 0 || index >= _itemExtents.length) return null;
    return _itemExtents[index];
  }

  @override
  ItemExtentBuilder get itemExtentBuilder => _extentForIndex;

  @override
  double? get itemExtent => null;

  @override
  double indexToLayoutOffset(double itemExtent, int index) {
    if (index <= 0 || _cumulativeExtents.isEmpty) return 0;
    if (index > _cumulativeExtents.length) {
      return _cumulativeExtents.last;
    }
    return _cumulativeExtents[index - 1];
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return prefixExtentIndexForScrollOffset(_cumulativeExtents, scrollOffset);
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return prefixExtentIndexForScrollOffset(_cumulativeExtents, scrollOffset);
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  }) {
    return _cumulativeExtents.isEmpty ? 0 : _cumulativeExtents.last;
  }

  @override
  double computeMaxScrollOffset(
    SliverConstraints constraints,
    double itemExtent,
  ) {
    return _cumulativeExtents.isEmpty ? 0 : _cumulativeExtents.last;
  }
}
