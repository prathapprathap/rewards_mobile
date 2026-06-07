import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/app_design.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_toast.dart';
import '../widgets/ui/rupi_ui.dart';

class SpecialCodeScreen extends StatefulWidget {
  const SpecialCodeScreen({super.key});

  @override
  State<SpecialCodeScreen> createState() => _SpecialCodeScreenState();
}

class _SpecialCodeScreenState extends State<SpecialCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnack('Please enter a secret code');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final result = await api.redeemPromoCode(userId, code);

      if (mounted) {
        CustomToast.show(
          context,
          result['message'] ?? 'Reward claimed successfully.',
          title: 'Success!',
        );
        userProvider.refreshUser();
        _codeController.clear();
      }
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    CustomToast.show(
      context,
      message,
      title: 'Error',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(color: AppColors.onSurface),
        title: Text(
          'Special Code',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Ticket hero
              Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: AppDesign.brXl,
                  boxShadow: AppDesign.softShadow(
                      color: AppColors.primary, opacity: 0.3, y: 12, blur: 24),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.confirmation_num_rounded,
                        size: 76, color: Colors.white),
                    Positioned(
                      top: 24,
                      right: 26,
                      child: Icon(Icons.auto_awesome,
                          color: AppColors.coinGoldBright, size: 26),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              RupiCard(
                padding: const EdgeInsets.all(26),
                child: Column(
                  children: [
                    Text(
                      'Got a secret code? 🎟️',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter it below to instantly unlock your reward.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'ENTER CODE',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: AppColors.outline,
                        ),
                        filled: true,
                        fillColor: AppColors.primaryFixed.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: AppDesign.brMd,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 20),
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RupiButton(
                      label: 'Claim Reward',
                      icon: Icons.redeem_rounded,
                      loading: _isLoading,
                      onPressed: _isLoading ? null : _redeemCode,
                    ),
                    const SizedBox(height: 20),
                    Divider(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.coinGoldBright.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.tips_and_updates_rounded,
                              color: AppColors.coinGoldDeep, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Codes are shared on our official social media handles — keep an eye out!',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
