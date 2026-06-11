import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/colors.dart';
import '../constants/app_design.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_toast.dart';
import '../widgets/ui/rupi_ui.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  Map<String, dynamic> _stats = {
    'total_referrals': 0,
    'successful_referrals': 0,
    'total_commission': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) return;

    try {
      final api = ApiService();
      final stats = await api.getReferralStats(userId);
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      debugPrint('Error fetching referral stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to SettingsProvider for dynamic color updates
    final settings = Provider.of<SettingsProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final referralCode = user?.referralCode ??
        (user?.id != null ? 'REWARD${user!.id}' : 'T973WC');
    final hasAppliedReferralCode =
        (user?.referredBy?.trim().isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header + overlapping content share ONE sliver so the content
          // paints on top of the header curve (not under it).
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeader(context, user),
                Transform.translate(
                  offset: const Offset(0, -8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInviteHero(context, referralCode),
                    const SizedBox(height: 14),
                    _buildShareRow(context, referralCode),
                    const SizedBox(height: 20),
                    if (!hasAppliedReferralCode)
                      _buildReferralAutoDetectInfo()
                    else
                      _buildReferralVerifiedCard(user!.referredBy!),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Referrals',
                            _stats['total_referrals'].toString(),
                            Icons.people_alt_rounded,
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildStatCard(
                            'Earnings',
                            '${settings.currencySymbol}${(_stats['total_commission'] as num).toStringAsFixed(2)}',
                            Icons.savings_rounded,
                            AppColors.coinGoldDeep,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const RupiSectionHeader(
                        title: 'How it works',
                        icon: Icons.auto_awesome_rounded),
                    _buildMissionStep(
                      index: 1,
                      title: 'Share your link',
                      description:
                          'Send your invite link to friends and family.',
                      icon: Icons.share_rounded,
                      isLast: false,
                    ),
                    _buildMissionStep(
                      index: 2,
                      title: 'They use your code',
                      description:
                          'Your code is applied automatically when they sign up.',
                      icon: Icons.qr_code_rounded,
                      isLast: false,
                    ),
                    _buildMissionStep(
                      index: 3,
                      title: 'Earn for life',
                      description:
                          'When your referral completes any offer, you earn the offer amount — for a lifetime (excludes special offers).',
                      icon: Icons.workspace_premium_rounded,
                      isLast: true,
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    final canGoBack = Navigator.of(context).canPop();
    return RupiHeader(
      height: 140,
      child: Row(
        children: [
          if (canGoBack) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
          ],
          Text(
            'Refer & Earn',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          RupiBalancePill(
            amount: (user?.walletBalance ?? 0.00).toStringAsFixed(2),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteHero(BuildContext context, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D34D6), Color(0xFFFF5FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppDesign.brXl,
        boxShadow: AppDesign.softShadow(
            color: AppColors.primary, opacity: 0.32, y: 12, blur: 26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.card_giftcard_rounded,
              color: Colors.white, size: 38),
          const SizedBox(height: 12),
          Text(
            'Invite friends,\nearn unlimited rewards 🎁',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppDesign.brMd,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR CODE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        code,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    CustomToast.show(context, 'Code Copied!');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: AppDesign.brSm,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.copy_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Copy',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralAutoDetectInfo() {
    return RupiCard(
      color: AppColors.coinGoldBright.withValues(alpha: 0.14),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.coinGoldBright.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_rounded,
                color: AppColors.coinGoldDeep, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No referral applied',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Referral codes are auto-applied during signup via invite links.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralVerifiedCard(String referredBy) {
    return RupiCard(
      color: AppColors.successLight,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Referral verified',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Applied code: $referredBy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return RupiCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppDesign.brSm,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStep({
    required int index,
    required String title,
    required String description,
    required IconData icon,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppDesign.softShadow(opacity: 0.25, y: 4, blur: 10),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.primaryFixedDim,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareRow(BuildContext context, String code) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final siteName = settings.getString('site_name', 'Rupi Rewards');
    final siteUrl = settings.getString('site_url', '').trim();

    // Build download link with embedded referral code
    // ALWAYS use the backend download endpoint to ensure IP/UA attribution works
    String downloadLink = '';
    if (siteUrl.isNotEmpty) {
      final base = siteUrl.endsWith('/')
          ? siteUrl.substring(0, siteUrl.length - 1)
          : siteUrl;
      downloadLink = '$base/api/download/$code';
    }

    final shareMessage = downloadLink.isNotEmpty
        ? '🎉 Join $siteName and earn real cash rewards!\n\n'
            '📲 Download now: $downloadLink\n\n'
            '🎁 My referral code: $code\n'
            'Use my code during signup to get bonus rewards!'
        : '🎉 Join $siteName using my referral code $code and earn unlimited rewards!';

    return Row(
      children: [
        Expanded(
          child: RupiButton(
            label: 'Share & Invite',
            icon: Icons.share_rounded,
            onPressed: () =>
                SharePlus.instance.share(ShareParams(text: shareMessage)),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: shareMessage));
            CustomToast.show(context, 'Share message copied!');
          },
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.onSurface,
              borderRadius: AppDesign.brMd,
            ),
            child: const Icon(Icons.copy_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
