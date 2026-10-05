import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Grows its child (the mic icon) with the voice while listening.
class VoiceScale extends StatelessWidget {
  final ValueListenable<double> level;
  final bool active;
  final Widget child;

  const VoiceScale({
    super.key,
    required this.level,
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: level,
      builder: (context, value, child) => AnimatedScale(
        // A short tween between level updates keeps it smooth.
        scale: active ? 1 + 0.4 * value : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: child,
      ),
      child: child,
    );
  }
}
