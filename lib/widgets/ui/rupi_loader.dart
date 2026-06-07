import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

/// Branded loader — a glossy gold ₹ coin that flips like a spinning coin with a
/// soft violet glow and an orbiting sparkle. Replaces every plain
/// CircularProgressIndicator in the app.
class RupiLoader extends StatefulWidget {
  final double size;
  final String? label;

  const RupiLoader({super.key, this.size = 56, this.label});

  /// Centered, full-screen loader sitting on the lavender background.
  static Widget fullscreen({String? label}) => Container(
        color: AppColors.background,
        alignment: Alignment.center,
        child: RupiLoader(size: 64, label: label ?? 'Loading…'),
      );

  /// Convenience for use inside a Center()/body without a background fill.
  static Widget centered({String? label}) =>
      Center(child: RupiLoader(size: 56, label: label));

  @override
  State<RupiLoader> createState() => _RupiLoaderState();
}

class _RupiLoaderState extends State<RupiLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: s * 1.4,
          height: s * 1.4,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              // 3D coin flip about the Y axis.
              final flip = math.sin(t * 2 * math.pi) ;
              final coin = Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(t * 2 * math.pi),
                child: _coin(s, flip),
              );
              return Stack(
                alignment: Alignment.center,
                children: [
                  // soft pulsing glow
                  Container(
                    width: s * (1.05 + 0.1 * (0.5 + 0.5 * math.sin(t * 2 * math.pi))),
                    height: s * (1.05 + 0.1 * (0.5 + 0.5 * math.sin(t * 2 * math.pi))),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.primary.withValues(alpha: 0.22),
                        AppColors.primary.withValues(alpha: 0.0),
                      ]),
                    ),
                  ),
                  coin,
                  // orbiting sparkle
                  Transform.translate(
                    offset: Offset(
                      math.cos(t * 2 * math.pi) * s * 0.72,
                      math.sin(t * 2 * math.pi) * s * 0.72,
                    ),
                    child: Icon(Icons.auto_awesome,
                        size: s * 0.22, color: AppColors.coinGoldBright),
                  ),
                ],
              );
            },
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.label!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _coin(double s, double flip) {
    // Darker edge when the coin is near edge-on for a subtle 3D feel.
    final edgeFactor = (1 - flip.abs());
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.goldGradient,
        border: Border.all(
          color: AppColors.coinGoldDeep.withValues(alpha: 0.6 + 0.4 * edgeFactor),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.coinGoldDeep.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '₹',
          style: GoogleFonts.plusJakartaSans(
            fontSize: s * 0.5,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF7A5300),
          ),
        ),
      ),
    );
  }
}
