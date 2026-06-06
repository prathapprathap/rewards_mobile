import 'package:flutter/material.dart';

/// Rupi Rewards Design System — Color Tokens
/// Emerald + Gold + Cream brand palette.
/// Gold (tertiary) and the cream surfaces are FIXED brand identity; only the
/// green family follows the admin-pushed `primary_color` (see updateColors).
class AppColors {
  // ─── Primary (Deep Emerald Green) ────────────────────────────────────────
  static Color primary = const Color(0xFF15663C);
  static Color primaryContainer = const Color(0xFF1E8A50);
  static Color primaryFixed = const Color(0xFFC9E8D5);
  static Color primaryFixedDim = const Color(0xFF7FC79E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static Color onPrimaryFixed = const Color(0xFF04190E);
  static Color onPrimaryFixedVariant = const Color(0xFF0C3D23);

  // ─── Secondary (Pine Green) ──────────────────────────────────────────────
  static Color secondary = const Color(0xFF0F5132);
  static Color secondaryContainer = const Color(0xFF1B7A4B);
  static Color secondaryFixed = const Color(0xFFC9E8D5);
  static Color secondaryFixedDim = const Color(0xFF7FC79E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF04190E);
  static const Color onSecondaryFixed = Color(0xFF021109);
  static const Color onSecondaryFixedVariant = Color(0xFF0C3D23);

  // ─── Tertiary (Gold) — Reward Signal / Brand Accent (FIXED) ──────────────
  static Color tertiary = const Color(0xFF9A7B16);
  static Color tertiaryContainer = const Color(0xFFC8A23C);
  static Color tertiaryFixed = const Color(0xFFF3E4B3);
  static Color tertiaryFixedDim = const Color(0xFFCBA135);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFFFFF);
  static const Color onTertiaryFixed = Color(0xFF261A00);
  static const Color onTertiaryFixedVariant = Color(0xFF5C4300);

  // ─── Surface / Background — Warm Cream (FIXED) ───────────────────────────
  static Color background = const Color(0xFFF5F1E6);
  static Color surface = const Color(0xFFF5F1E6);
  static Color surfaceBright = const Color(0xFFFAF7EF);
  static Color surfaceDim = const Color(0xFFE5DFCE);
  static Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  static Color surfaceContainerLow = const Color(0xFFF0EBDC);
  static Color surfaceContainer = const Color(0xFFEAE4D2);
  static Color surfaceContainerHigh = const Color(0xFFE4DDC9);
  static Color surfaceContainerHighest = const Color(0xFFDED6C0);

  // ─── On-Surface ──────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF1A1C18);
  static const Color onSurfaceVariant = Color(0xFF44483D);
  static const Color onBackground = Color(0xFF1A1C18);

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
  static const Color coinGold = Color(0xFFCBA135);
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

      // Re-derive ONLY the green/primary family from the admin-pushed color.
      // The gold accent (tertiary) and the cream surfaces/background are part
      // of the fixed brand identity and are intentionally left untouched, so
      // changing the admin color shifts the green shade without breaking the
      // emerald + gold + cream look.
      final hsl = HSLColor.fromColor(color);
      primaryContainer = hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
      primaryFixed = hsl.withSaturation((hsl.saturation * 0.5).clamp(0.0, 1.0)).withLightness(0.86).toColor();
      primaryFixedDim = hsl.withLightness(0.66).toColor();
      onPrimaryFixed = hsl.withLightness(0.08).toColor();
      onPrimaryFixedVariant = hsl.withLightness(0.22).toColor();

      // Secondary tracks the same hue, a little darker/deeper (pine).
      final secondaryHsl = hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0));
      secondary = secondaryHsl.toColor();
      secondaryContainer = secondaryHsl.withLightness((secondaryHsl.lightness + 0.14).clamp(0.0, 1.0)).toColor();
      secondaryFixed = primaryFixed;
      secondaryFixedDim = primaryFixedDim;

    } catch (e) {
      debugPrint('Error updating colors with hex $hex: $e');
    }
  }
}
