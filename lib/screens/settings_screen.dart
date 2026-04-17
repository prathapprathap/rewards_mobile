import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Glass App Bar ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white.withOpacity(0.85),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Pewards',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Color(0xFF94A3B8)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page Header ───────────────────────────────────────
                  Text(
                    'Settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your kinetic assets and preferences.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Personal Identity ─────────────────────────────────
                  _buildSectionHeader(
                      icon: Icons.stars, label: 'Personal Identity'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          context,
                          icon: Icons.person_outline,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primaryFixed.withOpacity(0.4),
                          title: 'Profile Details',
                          subtitle: 'Edit your public presence and info',
                          onTap: () {},
                        ),
                        const SizedBox(height: 2),
                        _buildSettingsTile(
                          context,
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AppColors.secondary,
                          iconBg: AppColors.secondaryFixed.withOpacity(0.5),
                          title: 'Payout Methods',
                          subtitle: 'Connected banks and digital wallets',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Security & System ─────────────────────────────────
                  _buildSectionHeader(
                      icon: Icons.shield_outlined,
                      label: 'Security & System'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGridTile(
                          icon: Icons.lock_outline,
                          iconBg: AppColors.primaryContainer,
                          title: 'Security',
                          subtitle: '2FA, Passkeys & activity logs',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGridTile(
                          icon: Icons.notifications_active_outlined,
                          iconBg: AppColors.tertiaryContainer,
                          title: 'Notifications',
                          subtitle: 'Alerts for rewards & activity',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Assistance ────────────────────────────────────────
                  _buildSectionHeader(
                      icon: Icons.help_outline, label: 'Assistance'),
                  const SizedBox(height: 12),
                  _buildSupportCard(),

                  const SizedBox(height: 32),

                  // ── Sign Out ──────────────────────────────────────────
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 4),
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.logout, color: AppColors.error, size: 20),
                  //       const SizedBox(width: 10),
                  //       Text(
                  //         'Sign Out',
                  //         style: GoogleFonts.plusJakartaSans(
                  //           color: AppColors.error,
                  //           fontWeight: FontWeight.w700,
                  //           fontSize: 16,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Pewards v2.4.1 · PLATINUM TIER',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.outlineVariant,
                        letterSpacing: 1.4,
                      ),
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

  // ─── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 14),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  // ─── Settings Tile ────────────────────────────────────────────────────────

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(99)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.outlineVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Grid Tile ────────────────────────────────────────────────────────────

  Widget _buildGridTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(99)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.onSurfaceVariant),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Support Card ─────────────────────────────────────────────────────────

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceContainerHigh, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help with your Treasury?',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Our concierge team is available 24/7 to assist with your kinetic rewards and account configurations.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Contact Support',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent,
                color: AppColors.primary, size: 28),
          ),
        ],
      ),
    );
  }
}
