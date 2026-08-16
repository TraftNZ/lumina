import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/timeline_scrollbar.dart';

class _CountingScrollController extends ScrollController {
  int jumpCount = 0;

  @override
  void jumpTo(double value) {
    jumpCount++;
    super.jumpTo(value);
  }
}

void main() {
  testWidgets('keeps normal touch scrolling and supports touch scrubbing', (
    tester,
  ) async {
    final controller = _CountingScrollController();
    final interactive = ValueNotifier(true);
    var markerCalls = 0;
    final scrubStates = <bool>[];
    final semantics = tester.ensureSemantics();
    addTearDown(controller.dispose);
    addTearDown(interactive.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: interactive,
            builder: (context, enabled, child) => TimelineScrollbar(
              controller: controller,
              interactive: enabled,
              dateForMetrics: (_) => DateTime(2020, 5),
              dateForFraction: (_) => DateTime(2020, 5),
              markersForMetrics: (_) {
                markerCalls++;
                return const [
                  TimelineMarker(year: 2024, scrollFraction: 0),
                  TimelineMarker(year: 2020, scrollFraction: 0.5),
                  TimelineMarker(year: 2016, scrollFraction: 1),
                ];
              },
              onScrubStateChanged: scrubStates.add,
              child: ListView.builder(
                controller: controller,
                itemExtent: 80,
                itemCount: 100,
                itemBuilder: (context, index) => Text('Photo $index'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byType(ListView),
      const Offset(0, -320),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();

    expect(controller.offset, greaterThan(0));
    expect(find.text('May 2020'), findsOneWidget);
    expect(find.bySemanticsLabel('May 2020'), findsWidgets);
    expect(find.text('2020'), findsOneWidget);

    final handle = find.byKey(const ValueKey('timeline-scrubber-handle'));
    expect(handle, findsOneWidget);
    final offsetBeforeScrub = controller.offset;
    await tester.drag(
      handle,
      const Offset(0, 260),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();

    expect(controller.offset, greaterThan(offsetBeforeScrub + 1000));
    expect(scrubStates, containsAllInOrder([true, false]));
    scrubStates.clear();

    final jumpsBeforeBurst = controller.jumpCount;
    final markerCallsBeforeBurst = markerCalls;
    final burstStart = tester.getCenter(handle);
    final scrubberRect = tester.getRect(find.byType(TimelineScrollbar));
    final burstDrag = await tester.startGesture(
      burstStart,
      kind: PointerDeviceKind.touch,
    );
    expect(scrubStates, [true]);
    for (var i = 0; i < 20; i++) {
      await burstDrag.moveBy(const Offset(0, -2));
    }
    expect(controller.jumpCount, jumpsBeforeBurst);
    await tester.pump();
    expect(controller.jumpCount, jumpsBeforeBurst + 1);
    expect(markerCalls, markerCallsBeforeBurst);
    final expectedFraction =
        ((burstStart.dy - 40 - scrubberRect.top - 72 - 28) /
                (scrubberRect.height - 72 - 112 - 56))
            .clamp(0.0, 1.0);
    await burstDrag.up();
    expect(controller.jumpCount, jumpsBeforeBurst + 1);
    expect(
      controller.offset,
      closeTo(controller.position.maxScrollExtent * expectedFraction, 1),
    );
    expect(scrubStates, [true, false]);
    scrubStates.clear();

    final jumpsBeforePointerUp = controller.jumpCount;
    final pointerUpDrag = await tester.startGesture(
      tester.getCenter(handle),
      kind: PointerDeviceKind.touch,
    );
    await pointerUpDrag.moveBy(const Offset(0, 40));
    expect(controller.jumpCount, jumpsBeforePointerUp);
    await pointerUpDrag.up();
    expect(controller.jumpCount, jumpsBeforePointerUp + 1);
    final offsetAfterPointerUp = controller.offset;
    await tester.pump();
    expect(controller.jumpCount, jumpsBeforePointerUp + 1);
    expect(controller.offset, offsetAfterPointerUp);

    final jumpsBeforeCancel = controller.jumpCount;
    final cancelledDrag = await tester.startGesture(
      tester.getCenter(handle),
      kind: PointerDeviceKind.touch,
    );
    await cancelledDrag.moveBy(const Offset(0, -40));
    await cancelledDrag.cancel();
    await tester.pump();
    expect(controller.jumpCount, jumpsBeforeCancel);

    final offsetBeforeNormalDrag = controller.offset;
    await tester.dragFrom(
      const Offset(200, 300),
      const Offset(0, -160),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();
    expect(controller.offset, greaterThan(offsetBeforeNormalDrag));

    final interruptedDrag = await tester.startGesture(
      tester.getCenter(handle),
      kind: PointerDeviceKind.touch,
    );
    await interruptedDrag.moveBy(const Offset(0, 30));
    await tester.pump();
    interactive.value = false;
    await tester.pump();
    await interruptedDrag.moveBy(const Offset(0, 80));
    await interruptedDrag.up();

    final offsetBeforeDisabledDrag = controller.offset;
    await tester.dragFrom(
      const Offset(200, 300),
      const Offset(0, -120),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();
    expect(controller.offset, greaterThan(offsetBeforeDisabledDrag));

    await tester.pump(const Duration(milliseconds: 1050));
    final handleOpacity = find.ancestor(
      of: handle,
      matching: find.byType(AnimatedOpacity),
    );
    expect(tester.widget<AnimatedOpacity>(handleOpacity).opacity, 0);
    semantics.dispose();
  });
}
