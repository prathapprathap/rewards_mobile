import 'package:flutter/material.dart';

/// Rupi Rewards Design System 2.0 — Color Tokens
/// Royal Violet + Coin Gold + Soft Lavender brand palette (matches the playful
/// 3D mascot app icon).
/// Gold (tertiary), the playful accents and the lavender surfaces are FIXED
/// brand identity; only the violet family follows the admin-pushed
/// `primary_color` (see updateColors).
class AppColors {
  // ─── Primary (Royal Violet) ──────────────────────────────────────────────
  static Color primary = const Color(0xFF6D34D6);
  static Color primaryContainer = const Color(0xFF8B5CF6);
  static Color primaryFixed = const Color(0xFFEADDFE);
  static Color primaryFixedDim = const Color(0xFFC4A6F6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static Color onPrimaryFixed = const Color(0xFF21054E);
  static Color onPrimaryFixedVariant = const Color(0xFF4A1A9E);

  // ─── Secondary (Deep Indigo Violet) ──────────────────────────────────────
  static Color secondary = const Color(0xFF5126B0);
  static Color secondaryContainer = const Color(0xFF7A4FD6);
  static Color secondaryFixed = const Color(0xFFEADDFE);
  static Color secondaryFixedDim = const Color(0xFFC4A6F6);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF1B0640);
  static const Color onSecondaryFixed = Color(0xFF150538);
  static const Color onSecondaryFixedVariant = Color(0xFF3A1683);

  // ─── Tertiary (Coin Gold) — Reward Signal / Brand Accent (FIXED) ─────────
  static Color tertiary = const Color(0xFFC8860D);
  static Color tertiaryContainer = const Color(0xFFFFC83D);
  static Color tertiaryFixed = const Color(0xFFFFE9A8);
  static Color tertiaryFixedDim = const Color(0xFFFFCE4D);
  static const Color onTertiary = Color(0xFF3D2600);
  static const Color onTertiaryContainer = Color(0xFF3D2600);
  static const Color onTertiaryFixed = Color(0xFF3D2600);
  static const Color onTertiaryFixedVariant = Color(0xFF7A5300);

  // ─── Playful Accents (FIXED brand identity) ──────────────────────────────
  static const Color accentPink = Color(0xFFFF5FA2);
  static const Color accentPinkSoft = Color(0xFFFFE1ED);
  static const Color accentTeal = Color(0xFF18C8C8);
  static const Color accentTealSoft = Color(0xFFD6F7F7);
  static const Color accentBlue = Color(0xFF4D8BFF);
  static const Color accentBlueSoft = Color(0xFFDDEBFF);
  static const Color coinGoldBright = Color(0xFFFFC83D);
  static const Color coinGoldDeep = Color(0xFFE8A317);

  // ─── Surface / Background — Soft Lavender (FIXED) ────────────────────────
  static Color background = const Color(0xFFF5F2FE);
  static Color surface = const Color(0xFFF5F2FE);
  static Color surfaceBright = const Color(0xFFFCFAFF);
  static Color surfaceDim = const Color(0xFFE9E2F8);
  static Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  static Color surfaceContainerLow = const Color(0xFFF2ECFD);
  static Color surfaceContainer = const Color(0xFFECE4FB);
  static Color surfaceContainerHigh = const Color(0xFFE5DBF8);
  static Color surfaceContainerHighest = const Color(0xFFDDD0F4);

  // ─── On-Surface ──────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF1C1235);
  static const Color onSurfaceVariant = Color(0xFF5A5070);
  static const Color onBackground = Color(0xFF1C1235);

  // ─── Outline ─────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF8B82A6);
  static const Color outlineVariant = Color(0xFFD8CFEC);

  // ─── Error ───────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFE5484D);
  static const Color errorContainer = Color(0xFFFFE0E1);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7A0C12);

  // ─── Legacy aliases ──────────────────────────────────────────────────────
  static Color get primaryDark => onPrimaryFixedVariant;
  static Color get primaryLight => primaryFixed;
  static Color get accent => primaryContainer;
  static Color get accentLight => primaryFixed;
  static const Color success = Color(0xFF1FB57A);
  static const Color successLight = Color(0xFFD9F7EC);
  static const Color coinGold = Color(0xFFFFC83D);
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textTertiary = outline;
  static const Color border = outlineVariant;
  static Color get divider => surfaceContainerLow;
  static Color shadowLight = const Color(0xFF6D34D6).withValues(alpha: 0.06);
  static Color shadowMedium = const Color(0xFF6D34D6).withValues(alpha: 0.12);
  static Color get cardColor => surfaceContainerLowest;

  // ─── Gradients ───────────────────────────────────────────────────────────
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Rich brand header gradient (violet → light violet), great for curved
  /// hero headers and the bottom-nav FAB.
  static LinearGradient get headerGradient => LinearGradient(
    colors: [secondary, primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Glossy gold gradient for coins, balances and reward signals.
  static LinearGradient get goldGradient => const LinearGradient(
    colors: [Color(0xFFFFE08A), Color(0xFFFFC83D), Color(0xFFE8A317)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get accentGradient => LinearGradient(
    colors: [primaryContainer, primaryFixedDim],
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
    accentPink,
    secondary,
    primaryContainer,
  ];

  static List<Color> get meshGradient2 => [
    secondaryContainer,
    tertiaryContainer,
    primaryFixedDim,
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

      // Re-derive ONLY the violet/primary family from the admin-pushed color.
      // The gold accent (tertiary), the playful accents and the lavender
      // surfaces/background are part of the fixed brand identity and are
      // intentionally left untouched, so changing the admin color shifts the
      // violet shade without breaking the violet + gold + lavender look.
      final hsl = HSLColor.fromColor(color);
      primaryContainer = hsl.withLightness((hsl.lightness + 0.14).clamp(0.0, 1.0)).toColor();
      primaryFixed = hsl.withSaturation((hsl.saturation * 0.5).clamp(0.0, 1.0)).withLightness(0.90).toColor();
      primaryFixedDim = hsl.withLightness(0.74).toColor();
      onPrimaryFixed = hsl.withLightness(0.12).toColor();
      onPrimaryFixedVariant = hsl.withLightness(0.30).toColor();

      // Secondary tracks the same hue, a little darker/deeper (indigo violet).
      final secondaryHsl = hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0));
      secondary = secondaryHsl.toColor();
      secondaryContainer = secondaryHsl.withLightness((secondaryHsl.lightness + 0.16).clamp(0.0, 1.0)).toColor();
      secondaryFixed = primaryFixed;
      secondaryFixedDim = primaryFixedDim;

    } catch (e) {
      debugPrint('Error updating colors with hex $hex: $e');
    }
  }
}
