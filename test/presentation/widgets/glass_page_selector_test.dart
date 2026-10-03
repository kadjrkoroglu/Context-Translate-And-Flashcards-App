import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/presentation/widgets/glass_page_selector.dart';

void main() {
  late PageController controller;
  late List<int> selected;

  Widget subject() => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          GlassPageSelector(
            controller: controller,
            page: () => controller.hasClients ? controller.page ?? 1 : 1,
            labels: const ['Live', 'AI', 'Basic'],
            onSelected: (i) {
              selected.add(i);
              controller.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          SizedBox(
            height: 50,
            child: PageView(
              controller: controller,
              children: const [Text('p0'), Text('p1'), Text('p2')],
            ),
          ),
        ],
      ),
    ),
  );

  setUp(() {
    controller = PageController(initialPage: 1);
    selected = [];
  });

  tearDown(() => controller.dispose());

  testWidgets('tapping a label selects that page', (tester) async {
    await tester.pumpWidget(subject());
    await tester.tap(find.text('Basic'));
    await tester.pumpAndSettle();

    expect(selected, [2]);
    expect(controller.page, 2);
  });

  testWidgets('dragging the bubble moves the pages and snaps', (tester) async {
    await tester.pumpWidget(subject());
    await tester.drag(find.text('AI'), const Offset(-70, 0));
    await tester.pumpAndSettle();

    expect(selected.last, 0);
    expect(controller.page, 0);
  });
}
