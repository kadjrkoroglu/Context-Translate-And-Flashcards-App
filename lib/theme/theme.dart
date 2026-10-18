import 'package:flutter/material.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

class GlassThemeExtension extends ThemeExtension<GlassThemeExtension> {
  final Color baseGlassColor;
  final Color borderGlassColor;
  final List<Color> backgroundGradient;
  final List<Color> micGradient;

  GlassThemeExtension({
    required this.baseGlassColor,
    required this.borderGlassColor,
    required this.backgroundGradient,
    required this.micGradient,
  });

  @override
  GlassThemeExtension copyWith({
    Color? baseGlassColor,
    Color? borderGlassColor,
    List<Color>? backgroundGradient,
    List<Color>? micGradient,
  }) {
    return GlassThemeExtension(
      baseGlassColor: baseGlassColor ?? this.baseGlassColor,
      borderGlassColor: borderGlassColor ?? this.borderGlassColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      micGradient: micGradient ?? this.micGradient,
    );
  }

  @override
  GlassThemeExtension lerp(
    ThemeExtension<GlassThemeExtension>? other,
    double t,
  ) {
    if (other is! GlassThemeExtension) return this;
    return GlassThemeExtension(
      baseGlassColor: Color.lerp(baseGlassColor, other.baseGlassColor, t)!,
      borderGlassColor: Color.lerp(
        borderGlassColor,
        other.borderGlassColor,
        t,
      )!,
      backgroundGradient: [
        Color.lerp(backgroundGradient[0], other.backgroundGradient[0], t)!,
        Color.lerp(backgroundGradient[1], other.backgroundGradient[1], t)!,
      ],
      micGradient: [
        Color.lerp(micGradient[0], other.micGradient[0], t)!,
        Color.lerp(micGradient[1], other.micGradient[1], t)!,
      ],
    );
  }
}

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1E272E),
  canvasColor: const Color(0xFF1E272E),
  cardColor: const Color(0xFF1E272E),
  colorScheme: ColorScheme.dark(
    surface: const Color(0xFF1E272E),
    primary: Colors.grey.shade800,
    secondary: Colors.grey.shade700,
    tertiary: Colors.grey.shade600,
    surfaceContainer: Colors.grey.shade700,
    inversePrimary: Colors.white70,
    outline: const Color.fromARGB(255, 27, 27, 27),
  ),
  extensions: [
    GlassThemeExtension(
      baseGlassColor: Colors.white.withValues(alpha: 0.08),
      borderGlassColor: Colors.white.withValues(alpha: 0.1),
      backgroundGradient: [const Color(0xFF1E272E), const Color(0xFF1E272E)],
      micGradient: [
        Colors.white.withValues(alpha: 0.08),
        Colors.white.withValues(alpha: 0.08)
      ],
    ),
  ],
  // Small, see-through glass instead of the default white bar.
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF2D3743).withValues(alpha: 0.85),
    contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    actionTextColor: Colors.white,
    elevation: 0,
    insetPadding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
  ),
  // Swipe back from anywhere on the screen, not only the left edge.
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {TargetPlatform.iOS: SwipeablePageTransitionsBuilder()},
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.white,
    selectionColor: Colors.white24,
    selectionHandleColor: Colors.white,
  ),
);
