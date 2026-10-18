import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/presentation/widgets/app_restart.dart';

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('$count'),
      TextButton(
        onPressed: () => setState(() => count++),
        child: const Text('add'),
      ),
      TextButton(
        onPressed: () => AppRestart.restart(context),
        child: const Text('restart'),
      ),
    ],
  );
}

void main() {
  testWidgets('restart rebuilds everything from scratch', (tester) async {
    await tester.pumpWidget(
      const AppRestart(child: MaterialApp(home: Scaffold(body: _Counter()))),
    );
    await tester.tap(find.text('add'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('restart'));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });
}
