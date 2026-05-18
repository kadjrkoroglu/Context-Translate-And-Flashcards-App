import 'package:flutter/material.dart';

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

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFF7A8386),
  canvasColor: const Color(0xFF7A8386),
  cardColor: const Color(0xFF7A8386),
  colorScheme: ColorScheme.light(
    surface: const Color(0xFF7A8386),
    primary: Colors.grey.shade400,
    secondary: Colors.grey.shade500,
    tertiary: Colors.grey.shade600,
    surfaceContainer: Colors.black,
    inversePrimary: Colors.white,
    outline: Colors.black,
  ),
  extensions: [
    GlassThemeExtension(
      baseGlassColor: Colors.white.withValues(alpha: 0.12),
      borderGlassColor: Colors.white.withValues(alpha: 0.15),
      backgroundGradient: [const Color(0xFF7A8386), const Color(0xFF7A8386)],
      micGradient: [
        Colors.white.withValues(alpha: 0.12),
        Colors.white.withValues(alpha: 0.12)
      ],
    ),
  ],
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.black,
    selectionColor: Colors.black26,
    selectionHandleColor: Colors.black,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF2D3436),
  canvasColor: const Color(0xFF2D3436),
  cardColor: const Color(0xFF2D3436),
  colorScheme: ColorScheme.dark(
    surface: const Color(0xFF2D3436),
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
      backgroundGradient: [const Color(0xFF2D3436), const Color(0xFF2D3436)],
      micGradient: [
        Colors.white.withValues(alpha: 0.08),
        Colors.white.withValues(alpha: 0.08)
      ],
    ),
  ],
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.white,
    selectionColor: Colors.white24,
    selectionHandleColor: Colors.white,
  ),
);
