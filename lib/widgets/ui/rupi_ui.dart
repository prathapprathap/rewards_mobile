import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../constants/app_design.dart';

export 'rupi_loader.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Rupi Rewards 2.0 — shared playful component kit.
/// Build screens out of these so the whole app feels like one fresh design.
/// ─────────────────────────────────────────────────────────────────────────

/// Primary action button: glossy violet gradient pill with a press-bounce.
class RupiButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final bool gold;
  final EdgeInsets padding;

  const RupiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.gold = false,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  });

  @override
  State<RupiButton> createState() => _RupiButtonState();
}

class _RupiButtonState extends State<RupiButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final gradient = widget.gold ? AppColors.goldGradient : AppColors.headerGradient;
    final fg = widget.gold ? const Color(0xFF5A3D00) : Colors.white;

    return AnimatedScale(
      scale: _scale,
      duration: AppDesign.fast,
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _scale = 0.96) : null,
        onTapUp: enabled ? (_) => setState(() => _scale = 1) : null,
        onTapCancel: enabled ? () => setState(() => _scale = 1) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: Container(
          width: widget.expand ? double.infinity : null,
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: enabled ? gradient : null,
            color: enabled ? null : AppColors.surfaceContainerHigh,
            borderRadius: AppDesign.brPillFor(56),
            boxShadow: enabled
                ? AppDesign.softShadow(
                    color: widget.gold ? AppColors.coinGoldDeep : AppColors.primary,
                    opacity: 0.32,
                    y: 8,
                    blur: 18)
                : null,
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: fg),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: enabled ? fg : AppColors.outline, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: enabled ? fg : AppColors.outline,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary / ghost button — soft lavender fill, violet text.
class RupiSoftButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  const RupiSoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryFixed,
      borderRadius: AppDesign.brPillFor(52),
      child: InkWell(
        borderRadius: AppDesign.brPillFor(52),
        onTap: onPressed,
        child: Container(
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary, size: 19),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft rounded surface card with the brand shadow.
class RupiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;
  final Gradient? gradient;
  final BoxBorder? border;

  const RupiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.color,
    this.onTap,
    this.radius = AppDesign.rLg,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surfaceContainerLowest) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: AppDesign.cardShadow,
      ),
      child: child,
    );
    if (onTap == null) return Container(margin: margin, child: content);
    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}

/// Curved gradient hero header used at the top of every primary screen.
class RupiHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final EdgeInsets padding;

  const RupiHeader({
    super.key,
    required this.child,
    this.height = 200,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 28),
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(
          children: [
            // playful bokeh circles
            Positioned(
              top: -30,
              right: -20,
              child: _bubble(120, Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              bottom: 10,
              left: -30,
              child: _bubble(90, Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              top: 40,
              left: 30,
              child: _bubble(16, AppColors.coinGoldBright.withValues(alpha: 0.5)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(double d, Color c) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      );
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 36);
    p.quadraticBezierTo(
        size.width / 2, size.height + 12, size.width, size.height - 36);
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Section title with optional trailing action.
class RupiSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const RupiSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: AppDesign.brSm,
              ),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Friendly empty / error state with a big soft icon bubble.
class RupiEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? tint;

  const RupiEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final c = tint ?? AppColors.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  c.withValues(alpha: 0.18),
                  c.withValues(alpha: 0.04),
                ]),
              ),
              child: Icon(icon, size: 50, color: c),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              RupiButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Glossy gold pill that shows the coin balance.
class RupiBalancePill extends StatelessWidget {
  final String amount;
  final String? label;
  final VoidCallback? onTap;

  const RupiBalancePill({super.key, required this.amount, this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: AppDesign.brPillFor(40),
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldGradient,
              ),
              child: const Center(
                child: Text('₹',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF7A5300))),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8))),
            ],
          ],
        ),
      ),
    );
  }
}

/// Soft circular icon button used in headers / app bars.
class RupiIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? fg;
  final bool onHeader;

  const RupiIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.bg,
    this.fg,
    this.onHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = bg ?? (onHeader ? Colors.white.withValues(alpha: 0.18) : AppColors.surfaceContainerLowest);
    final foreground = fg ?? (onHeader ? Colors.white : AppColors.onSurface);
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: foreground),
        ),
      ),
    );
  }
}

/// Small rounded status / category chip.
class RupiChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const RupiChip({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppDesign.brPillFor(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
