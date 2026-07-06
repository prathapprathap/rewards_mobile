import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../constants/app_design.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/ui/rupi_ui.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    // Listening to SettingsProvider to ensure rebuild on color changes
    Provider.of<SettingsProvider>(context);

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
                _buildProfileHeader(user),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: _buildSettingsHub(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return RupiHeader(
      height: 290,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 44),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Profile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
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
          const Spacer(),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: AppDesign.brXl,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: AppDesign.floatShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(33),
              child: user?.profilePic != null
                  ? Image.network(user!.profilePic!, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _avatarFallback())
                  : _avatarFallback(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.name ?? 'User',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          if (user?.email != null && user.email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              user.email,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: AppColors.primaryFixed,
        child: Icon(Icons.person_rounded, color: AppColors.primary, size: 46),
      );

  Widget _buildSettingsHub(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RupiSectionHeader(
              title: 'Settings', icon: Icons.tune_rounded),
          _buildSettingsItem(
            icon: Icons.star_rounded,
            iconColor: AppColors.coinGoldDeep,
            label: 'Rate Us',
            onTap: () async {
              final settings = Provider.of<SettingsProvider>(
                context,
                listen: false,
              );
              // Try app-specific Play Store URL from settings, fallback to package name
              final packageName = settings.getString('app_package_name', '');
              final storeUrl = packageName.isNotEmpty
                  ? 'market://details?id=$packageName'
                  : 'https://play.google.com/store/apps';
              try {
                final uri = Uri.parse(storeUrl);
                final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!launched) {
                  // Fallback to web Play Store
                  final webUri = Uri.parse(
                    packageName.isNotEmpty
                        ? 'https://play.google.com/store/apps/details?id=$packageName'
                        : 'https://play.google.com/store/apps',
                  );
                  await launchUrl(webUri, mode: LaunchMode.externalApplication);
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open Play Store')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            icon: Icons.chat_bubble_rounded,
            iconColor: AppColors.success,
            label: 'WhatsApp Channel',
            onTap: () async {
              final settings = Provider.of<SettingsProvider>(
                context,
                listen: false,
              );
              final url = settings.getString('whatsapp_link', '');
              if (url.isNotEmpty) {
                try {
                  final uri = Uri.parse(url);
                  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open WhatsApp')),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open WhatsApp')),
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('WhatsApp link not configured')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            icon: Icons.telegram_rounded,
            iconColor: AppColors.accentBlue,
            label: 'Join Telegram',
            onTap: () async {
              final settings = Provider.of<SettingsProvider>(
                context,
                listen: false,
              );
              final url = settings.getString('telegram_link', '');
              if (url.isNotEmpty) {
                try {
                  final uri = Uri.parse(url);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open Telegram')),
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Telegram link not configured')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            icon: Icons.help_rounded,
            iconColor: AppColors.accentTeal,
            label: 'Help & Support',
            onTap: () async {
              final settings = Provider.of<SettingsProvider>(
                context,
                listen: false,
              );
              final helpUrl = settings.getString('help_support_url', '');
              if (helpUrl.isNotEmpty) {
                try {
                  final uri = Uri.parse(helpUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return;
                } catch (_) {}
              }

              final email = settings.getString('support_email', 'support@rewardmobi.xyz');
              final siteName = settings.getString('site_name', 'Rupi Rewards');
              try {
                final uri = Uri(
                  scheme: 'mailto',
                  path: email,
                  queryParameters: {
                    'subject': '$siteName - Help & Support',
                  },
                );
                await launchUrl(uri);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contact us at $email')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            icon: Icons.privacy_tip_rounded,
            iconColor: AppColors.secondary,
            label: 'Privacy Policy',
            onTap: () async {
              final settings = Provider.of<SettingsProvider>(
                context,
                listen: false,
              );
              final url = settings.getString('privacy_policy_url', '');
              final siteUrl = settings.getString('site_url', '');
              final policyUrl = url.isNotEmpty
                  ? url
                  : siteUrl.isNotEmpty
                      ? '${siteUrl.endsWith('/') ? siteUrl : '$siteUrl/'}privacy-policy'
                      : '';
              if (policyUrl.isNotEmpty) {
                try {
                  final uri = Uri.parse(policyUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open Privacy Policy')),
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy policy URL not configured')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            label: 'Logout',
            isDestructive: true,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Logout',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await GoogleSignIn.instance.signOut();
              } catch (_) {}
              if (context.mounted) {
                Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).loadSettings();
                Provider.of<UserProvider>(context, listen: false).logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return RupiCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: AppDesign.brMd,
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: isDestructive ? AppColors.error : AppColors.onSurface,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.outline,
            size: 22,
          ),
        ],
      ),
    );
  }
}
