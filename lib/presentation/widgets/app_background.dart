import 'package:flutter/material.dart';
import 'package:translate_app/theme/theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();

    final colors =
        glassTheme?.backgroundGradient ??
        [
          const Color.fromARGB(255, 149, 157, 160),
          const Color.fromARGB(255, 94, 106, 121),
        ];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      // A still, soft light at the top and a shade at the bottom give depth.
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.6),
            radius: 0.95,
            colors: [Color(0x12FFFFFF), Color(0x00FFFFFF)],
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.3, 0.76),
              radius: 1.1,
              colors: [Color(0x29000000), Color(0x00000000)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
