import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../constants/colors.dart';
import '../constants/app_design.dart';
import '../providers/settings_provider.dart';
import '../widgets/ui/rupi_ui.dart';

import 'daily_checkin_screen.dart';
import 'offerwall_screen.dart';
import 'special_code_screen.dart';

class ExtraScreen extends StatelessWidget {
  const ExtraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to SettingsProvider for dynamic color updates
    Provider.of<SettingsProvider>(context);
    final user = Provider.of<UserProvider>(context).user;

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
                _buildHeader(user),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroBanner(),
                        const SizedBox(height: 24),
                        RupiSectionHeader(
                            title: 'Earn More',
                            icon: Icons.auto_awesome_rounded),
                        _buildMenuSection(context),
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

  Widget _buildHeader(dynamic user) {
    return RupiHeader(
      height: 122,
      child: Row(
        children: [
          Text(
            'Earn',
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

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5126B0), Color(0xFFFF5FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppDesign.brXl,
        boxShadow: AppDesign.softShadow(
            color: AppColors.accentPink, opacity: 0.3, y: 10, blur: 22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'More ways to earn 🎉',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Daily bonuses, offers & secret codes — pick your reward.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.redeem_rounded, color: Colors.white, size: 52),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.event_available_rounded,
          iconColor: AppColors.primary,
          title: 'Daily Check-In',
          subtitle: 'Claim your daily attendance reward',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DailyCheckInScreen()),
            );
          },
        ),
        const SizedBox(height: 14),
        _buildMenuItem(
          icon: Icons.grid_view_rounded,
          iconColor: AppColors.accentTeal,
          title: 'Offerwalls',
          subtitle: 'Complete premium offers from the wall',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OfferwallScreen()),
            );
          },
        ),
        const SizedBox(height: 14),
        _buildMenuItem(
          icon: Icons.confirmation_num_rounded,
          iconColor: AppColors.coinGoldDeep,
          title: 'Special Code',
          subtitle: 'Enter a secret code to claim rewards',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpecialCodeScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return RupiCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: AppDesign.brMd,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right_rounded,
                color: AppColors.primary, size: 18),
          ),
        ],
      ),
    );
  }
}
