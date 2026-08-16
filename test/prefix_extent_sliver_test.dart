import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/prefix_extent_sliver.dart';

void main() {
  test('prefix extent lookup finds distant rows by cumulative boundary', () {
    const cumulativeExtents = <double>[10, 30, 35, 80];

    expect(prefixExtentIndexForScrollOffset(cumulativeExtents, 0), 0);
    expect(prefixExtentIndexForScrollOffset(cumulativeExtents, 9), 0);
    expect(prefixExtentIndexForScrollOffset(cumulativeExtents, 10), 0);
    expect(prefixExtentIndexForScrollOffset(cumulativeExtents, 10.1), 1);
    expect(prefixExtentIndexForScrollOffset(cumulativeExtents, 30), 1);
    expect(prefixExtentIndexForScrollOffset(cumulativeExtents, 34), 2);
    expect(prefixExtentIndexForScrollOffset(cumulativeExtents, 79), 3);
    expect(prefixExtentIndexForScrollOffset(cumulativeExtents, 200), 3);
  });

  testWidgets('prefix extent sliver lays out a distant row', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final itemExtents = List<double>.generate(
      10000,
      (index) => index.isEven ? 20 : 30,
      growable: false,
    );
    var runningExtent = 0.0;
    final cumulativeExtents = itemExtents
        .map((extent) {
          runningExtent += extent;
          return runningExtent;
        })
        .toList(growable: false);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          controller: controller,
          cacheExtent: 0,
          slivers: [
            SliverPrefixExtentList.builder(
              itemCount: itemExtents.length,
              itemExtents: itemExtents,
              cumulativeExtents: cumulativeExtents,
              itemBuilder: (context, index) => SizedBox(
                height: itemExtents[index],
                child: Text('Row $index'),
              ),
            ),
          ],
        ),
      ),
    );

    controller.jumpTo(cumulativeExtents[8999] + 1);
    await tester.pump();

    expect(find.text('Row 9000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
