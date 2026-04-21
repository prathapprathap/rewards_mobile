import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class RibbonBadge extends StatelessWidget {
  final String label;
  final String? colorOverride;

  const RibbonBadge({super.key, required this.label, this.colorOverride});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.primary;
    
    if (colorOverride != null && colorOverride!.isNotEmpty) {
      try {
        String hex = colorOverride!;
        if (hex.startsWith('#')) hex = hex.substring(1);
        if (hex.length == 6) hex = 'FF$hex';
        color = Color(int.parse(hex, radix: 16));
      } catch (e) {
        debugPrint('Error parsing RibbonBadge color override: $e');
      }
    } else {
      final l = label.toLowerCase();
      if (l.contains('hot') || l.contains('limit')) {
        color = AppColors.secondary; // Actionable contrast
      } else if (l.contains('new') || l.contains('fresh')) {
        color = AppColors.primary;   // Brand primary
      } else if (l.contains('special') || l.contains('pro')) {
        color = AppColors.tertiaryFixedDim; // Highlight/Reward signal
      } else if (l.contains('premium') || l.contains('best')) {
        color = AppColors.tertiary;  // Distinctive accent
      }
    }

    return SizedBox(
      width: 60,
      height: 60,
      child: ClipPath(
        clipper: _RibbonClipper(),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                left: -12,
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: SizedBox(
                    width: 70,
                    child: Center(
                      child: Text(
                        label.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();
    
    // Smooth the corner
    var finalPath = Path();
    finalPath.addRRect(RRect.fromLTRBAndCorners(
      0, 0, size.width, size.height,
      topLeft: const Radius.circular(20),
    ));
    
    return Path.combine(PathOperation.intersect, path, finalPath);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
