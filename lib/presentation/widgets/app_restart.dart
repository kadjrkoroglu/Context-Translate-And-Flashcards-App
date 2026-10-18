import 'package:flutter/widgets.dart';

/// Rebuilds the whole app from scratch, like a cold start, without quitting it.
class AppRestart extends StatefulWidget {
  final Widget child;

  const AppRestart({super.key, required this.child});

  static void restart(BuildContext context) =>
      context.findAncestorStateOfType<_AppRestartState>()?.restart();

  @override
  State<AppRestart> createState() => _AppRestartState();
}

class _AppRestartState extends State<AppRestart> {
  Key _key = UniqueKey();

  void restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
