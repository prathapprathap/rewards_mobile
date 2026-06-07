import 'package:flutter/material.dart';
import 'colors.dart';

/// Rupi Rewards Design System 2.0 — Shape, spacing, elevation & motion tokens.
/// Use these everywhere so the whole app shares one playful, rounded, soft-shadow
/// language inspired by the 3D mascot icon.
class AppDesign {
  AppDesign._();

  // ─── Corner radii (generous, friendly) ───────────────────────────────────
  static const double rSm = 14;
  static const double rMd = 20;
  static const double rLg = 28;
  static const double rXl = 36;
  static const double rPill = 100;

  static BorderRadius get brSm => BorderRadius.circular(rSm);
  static BorderRadius get brMd => BorderRadius.circular(rMd);
  static BorderRadius get brLg => BorderRadius.circular(rLg);
  static BorderRadius get brXl => BorderRadius.circular(rXl);
  static BorderRadius get brPill => BorderRadius.circular(rPill);

  /// Fully-rounded ("pill") radius — pass the control height so it always reads
  /// as a perfect stadium even for short controls.
  static BorderRadius brPillFor(double height) =>
      BorderRadius.circular(height / 2);

  // ─── Spacing scale ───────────────────────────────────────────────────────
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  // ─── Motion ──────────────────────────────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration med = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 600);
  static const Curve bouncy = Curves.easeOutBack;

  // ─── Soft elevation (colored, premium) ───────────────────────────────────
  static List<BoxShadow> softShadow({Color? color, double y = 10, double blur = 24, double opacity = 0.10}) => [
        BoxShadow(
          color: (color ?? AppColors.primary).withValues(alpha: opacity),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.07),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];
}
