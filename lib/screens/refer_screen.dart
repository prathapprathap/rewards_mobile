import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/colors.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

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
  bool _isLoading = true;

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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final referralCode = user?.referralCode ?? (user?.id != null ? 'PEWARD${user!.id}' : 'T973WC');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildCenteredText('UNLIMITED REWARDS FOR EVERY NEW USER'),
                  const SizedBox(height: 24),
                  _buildReferralCodeCard(context, referralCode),
                  const SizedBox(height: 24),
                  
                  // Stats Section
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('REFERRALS', _stats['total_referrals'].toString(), Icons.people_rounded)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('EARNINGS', '₹${_stats['total_commission']}', Icons.account_balance_wallet_rounded)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  _buildMissionTitle('THE REFERRAL MISSION'),
                  const SizedBox(height: 20),
                  _buildMissionStep(
                    phase: 'PHASE 01',
                    title: 'DEPLOY INVITE',
                    description: 'SHARE YOUR UNIQUE LINK WITH YOUR SQUAD VIA WHATSAPP OR SOCIALS.',
                    icon: Icons.share_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildMissionStep(
                    phase: 'PHASE 02',
                    title: 'SQUAD JOINS',
                    description: 'YOUR FRIENDS JOIN THE PLATFORM USING YOUR LINK AND VERIFY PROFILE.',
                    icon: Icons.people_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildMissionStep(
                    phase: 'PHASE 03',
                    title: '1ST COMPLETION',
                    description: 'FRIEND COMPLETES THEIR FIRST OFFER. YOU GET REWARDS INSTANTLY!',
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 120), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildWhatsappFab(context, referralCode),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar(dynamic user) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 24,
              errorBuilder: (c, e, s) => Icon(Icons.eco, color: AppColors.primary, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'REFER & EARN',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        _buildWalletPill(user),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildWalletPill(dynamic user) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/coin.png',
            height: 20,
            errorBuilder: (c, e, s) => Icon(Icons.monetization_on, color: AppColors.coinGold, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            (user?.walletBalance ?? 0.00).toStringAsFixed(2),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredText(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppColors.onSurfaceVariant.withOpacity(0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard(BuildContext context, String code) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurfaceVariant.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code Copied!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'COPY',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurfaceVariant.withOpacity(0.4),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: AppColors.onSurfaceVariant.withOpacity(0.1))),
      ],
    );
  }

  Widget _buildMissionStep({
    required String phase,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant.withOpacity(0.5),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsappFab(BuildContext context, String code) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Share.share('Use my referral code $code to join Peward and earn unlimited rewards!');
              },
              icon: const Icon(Icons.chat_bubble_rounded),
              label: Text(
                'WHATSAPP',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 10,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Share.share('Join Peward using my code $code and earn cash daily!');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.share_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
