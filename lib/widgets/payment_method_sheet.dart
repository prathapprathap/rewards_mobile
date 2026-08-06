import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../constants/app_design.dart';

class _PaymentMethodOption {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool enabled;

  const _PaymentMethodOption({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.enabled,
  });
}

/// Bottom sheet for picking a withdrawal payment method. Only [enabled]
/// methods (per admin settings) are tappable; disabled ones render greyed
/// out with an "INACTIVE" badge. Returns the chosen method label, or null
/// if dismissed without a selection.
Future<String?> showPaymentMethodSheet(
  BuildContext context, {
  required bool upiEnabled,
  required bool bankEnabled,
}) {
  final options = [
    _PaymentMethodOption(
      label: 'UPI',
      icon: Icons.smartphone_rounded,
      iconColor: AppColors.primary,
      enabled: upiEnabled,
    ),
    _PaymentMethodOption(
      label: 'Bank Transfer',
      icon: Icons.account_balance_rounded,
      iconColor: AppColors.accentTeal,
      enabled: bankEnabled,
    ),
  ];

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PaymentMethodSheet(options: options),
  );
}

class _PaymentMethodSheet extends StatelessWidget {
  final List<_PaymentMethodOption> options;

  const _PaymentMethodSheet({required this.options});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppDesign.brXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Withdraw Money',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.close, size: 18, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how you want to cash out your balance',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: options
                  .map((o) => _MethodCard(
                        option: o,
                        onTap: o.enabled
                            ? () => Navigator.of(context).pop(o.label)
                            : null,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final _PaymentMethodOption option;
  final VoidCallback? onTap;

  const _MethodCard({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = option.enabled;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : AppColors.surfaceContainer,
          borderRadius: AppDesign.brMd,
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Stack(
          children: [
            if (!enabled)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'INACTIVE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: enabled
                        ? option.iconColor.withValues(alpha: 0.12)
                        : AppColors.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: AppDesign.brSm,
                  ),
                  child: Icon(
                    option.icon,
                    color: enabled ? option.iconColor : AppColors.outline,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  option.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: enabled ? AppColors.onSurface : AppColors.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
