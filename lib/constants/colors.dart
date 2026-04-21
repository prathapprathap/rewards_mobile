import 'package:flutter/material.dart';

/// Pewards Design System — Color Tokens
/// Based on the Material You palette from the Stitch design specs.
class AppColors {
  // ─── Primary (Lime Green) ────────────────────────────────────────────────
  static Color primary = const Color(0xFF6DC000);
  static Color primaryContainer = const Color(0xFF8ED73B);
  static Color primaryFixed = const Color(0xFFDCF8B6);
  static Color primaryFixedDim = const Color(0xFFB4E874);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static Color onPrimaryFixed = const Color(0xFF141F00);
  static Color onPrimaryFixedVariant = const Color(0xFF3B5600);

  // ─── Secondary (Green) ───────────────────────────────────────────────────
  static Color secondary = const Color(0xFF386B01);
  static Color secondaryContainer = const Color(0xFF4C8D02);
  static Color secondaryFixed = const Color(0xFFD6F5A0);
  static Color secondaryFixedDim = const Color(0xFFBAE67E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF0F2000);
  static const Color onSecondaryFixed = Color(0xFF071000);
  static const Color onSecondaryFixedVariant = Color(0xFF274D00);

  // ─── Tertiary (Gold) — Reward Signal ────────────────────────────────────
  static Color tertiary = const Color(0xFF795900);
  static Color tertiaryContainer = const Color(0xFF987000);
  static Color tertiaryFixed = const Color(0xFFFFDFA0);
  static Color tertiaryFixedDim = const Color(0xFFFBBC05);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFFFFF);
  static const Color onTertiaryFixed = Color(0xFF261A00);
  static const Color onTertiaryFixedVariant = Color(0xFF5C4300);

  // ─── Surface / Background ────────────────────────────────────────────────
  static Color background = const Color(0xFFF1F9F1);
  static Color surface = const Color(0xFFF1F9F1);
  static Color surfaceBright = const Color(0xFFF1F9F1);
  static Color surfaceDim = const Color(0xFFD4E1D4);
  static Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  static Color surfaceContainerLow = const Color(0xFFECF5EC);
  static Color surfaceContainer = const Color(0xFFE6F0E6);
  static Color surfaceContainerHigh = const Color(0xFFDFEBDF);
  static Color surfaceContainerHighest = const Color(0xFFD9E6D9);

  // ─── On-Surface ──────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF191D19);
  static const Color onSurfaceVariant = Color(0xFF414941);
  static const Color onBackground = Color(0xFF191D19);

  // ─── Outline ─────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF727972);
  static const Color outlineVariant = Color(0xFFC1C9C1);

  // ─── Error ───────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ─── Legacy aliases ──────────────────────────────────────────────────────
  static Color get primaryDark => onPrimaryFixedVariant;
  static Color get primaryLight => primaryFixed;
  static Color get accent => primaryContainer;
  static Color get accentLight => primaryFixed;
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color coinGold = Color(0xFFFFD700);
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textTertiary = outline;
  static const Color border = outlineVariant;
  static Color get divider => surfaceContainerLow;
  static Color shadowLight = Colors.black.withValues(alpha: 0.04);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.08);
  static Color get cardColor => surfaceContainerLowest;

  // ─── Gradients ───────────────────────────────────────────────────────────
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get headerGradient => LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get accentGradient => LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradient => LinearGradient(
    colors: [surfaceContainerLowest, surfaceContainerLow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<Color> get meshGradient1 => [
    primary,
    tertiaryFixedDim,
    secondary,
    primaryContainer,
  ];

  static List<Color> get meshGradient2 => [
    secondaryContainer,
    tertiaryContainer,
    onPrimaryFixedVariant,
  ];

  static void updateColors(String hex) {
    try {
      if (hex.startsWith('#')) hex = hex.substring(1);
      
      // Handle different hex lengths
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join('');
      }
      
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      
      final color = Color(int.parse(hex, radix: 16));
      primary = color;

      // Derive related shades
      final hsl = HSLColor.fromColor(color);
      primaryContainer = hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor();
      primaryFixed = hsl.withLightness(0.9).withSaturation(0.4).toColor();
      primaryFixedDim = hsl.withLightness(0.7).toColor();
      onPrimaryFixedVariant = hsl.withLightness(0.25).toColor();

      // Derive secondary (analogous - shift hue by 30)
      final secondaryHsl = HSLColor.fromAHSL(1.0, (hsl.hue + 30) % 360, hsl.saturation * 0.8, hsl.lightness * 0.8);
      secondary = secondaryHsl.toColor();
      secondaryContainer = secondaryHsl.withLightness((secondaryHsl.lightness + 0.1).clamp(0.0, 1.0)).toColor();
      secondaryFixed = secondaryHsl.withLightness(0.9).toColor();
      secondaryFixedDim = secondaryHsl.withLightness(0.7).toColor();

      // Derive tertiary (complementary-ish - shift hue by 180)
      final tertiaryHsl = HSLColor.fromAHSL(1.0, (hsl.hue + 180) % 360, 0.9, 0.6);
      tertiary = tertiaryHsl.toColor();
      tertiaryContainer = tertiaryHsl.withLightness(0.4).toColor();
      tertiaryFixed = tertiaryHsl.withLightness(0.9).toColor();
      tertiaryFixedDim = tertiaryHsl.toColor();
      
      // Derive background and surface from a very desaturated/light version of the primary
      background = hsl.withSaturation(0.05).withLightness(0.98).toColor();
      surface = background;
      surfaceBright = background;
      surfaceContainerLowest = Colors.white;
      surfaceContainerLow = hsl.withSaturation(0.04).withLightness(0.96).toColor();
      surfaceContainer = hsl.withSaturation(0.04).withLightness(0.94).toColor();
      surfaceContainerHigh = hsl.withSaturation(0.04).withLightness(0.92).toColor();
      surfaceContainerHighest = hsl.withSaturation(0.04).withLightness(0.90).toColor();
      
    } catch (e) {
      debugPrint('Error updating colors with hex $hex: $e');
    }
  }
}
