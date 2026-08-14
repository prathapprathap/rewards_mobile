import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/colors.dart';
import '../constants/app_design.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import 'main_layout.dart';
import '../widgets/custom_toast.dart';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';

/// Tries to extract a referral code from a free-text string.
/// Matches: "referral code: ABC123", "?ref=ABC123", or
/// "/api/download/ABC123" in a copied invite/download link.
String? extractReferralCode(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final text = raw.toString();
  final patterns = <RegExp>[
    RegExp(r'referral code[:\s]+([A-Z0-9]{4,12})', caseSensitive: false),
    RegExp(r'[?&](?:ref|referral|code)=([A-Z0-9]{4,12})', caseSensitive: false),
    RegExp(r'\bref(?:erral)?[=:]\s*([A-Z0-9]{4,12})', caseSensitive: false),
    RegExp(r'/api/download/([A-Z0-9]{4,12})', caseSensitive: false),
  ];
  for (final re in patterns) {
    final m = re.firstMatch(text);
    if (m != null) return m.group(1)!.toUpperCase();
  }
  return null;
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Hero ────────────────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -30,
                      child: _bubble(160, Colors.white.withValues(alpha: 0.08)),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -20,
                      child: _bubble(100, Colors.white.withValues(alpha: 0.07)),
                    ),
                    Positioned(
                      top: 70,
                      left: 36,
                      child: _bubble(
                          18, AppColors.coinGoldBright.withValues(alpha: 0.6)),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: AppDesign.brXl,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22)),
                            ),
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: AppDesign.brLg,
                                boxShadow: AppDesign.floatShadow,
                              ),
                              child: ClipRRect(
                                borderRadius: AppDesign.brLg,
                                child: Image.asset(
                                  'assets/images/app_icon_clean.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    decoration: BoxDecoration(
                                        gradient: AppColors.goldGradient),
                                    child: const Center(
                                      child: Text('₹',
                                          style: TextStyle(
                                              fontSize: 46,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF7A5300))),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'Rupi Rewards',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Play games, complete tasks &\nturn your time into real cash 💰',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom Sheet ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(36)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _featurePill(Icons.bolt_rounded, 'Instant'),
                        const SizedBox(width: 8),
                        _featurePill(Icons.verified_rounded, 'Secure'),
                        const SizedBox(width: 8),
                        _featurePill(Icons.workspace_premium_rounded, 'Trusted'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Let\'s get started',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in with Google — it only takes a second',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _GoogleSignInButton(),
                    const SizedBox(height: 18),
                    Text(
                      'By continuing you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.outline,
                        height: 1.5,
                      ),
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

  Widget _bubble(double d, Color c) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      );

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Google Sign-In Button ────────────────────────────────────────────────────

class _GoogleSignInButton extends StatefulWidget {
  const _GoogleSignInButton();

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _isLoading = false;
  bool _initialized = false;
  bool _isHandlingSignIn = false;
  StreamSubscription? _authSubscription;
  String? _autoDetectedCode;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
    _tryDetectPlayReferrer();
  }

  /// Detects the installation referrer from the Google Play Store (e.g. if the user installed
  /// the app from a referral link). This is 100% compliant with Google Play Console policies.
  Future<void> _tryDetectPlayReferrer() async {
    try {
      final details = await AndroidPlayInstallReferrer.installReferrer;
      final referrer = details.installReferrer;
      if (referrer != null && referrer.isNotEmpty) {
        String? code = extractReferralCode(referrer);
        if (code == null) {
          final clean = referrer.trim().toUpperCase();
          if (RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(clean)) {
            code = clean;
          }
        }
        if (code != null && mounted) {
          _autoDetectedCode = code;
          debugPrint('Detected Google Play Referral Code: $code');
        }
      }
    } catch (e) {
      debugPrint('Error detecting Play Install Referrer: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();

      _authSubscription =
          GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (mounted &&
            event is GoogleSignInAuthenticationEventSignIn &&
            !_isHandlingSignIn) {
          _handleSuccessfulSignIn(event.user);
        }
      });

      if (mounted) setState(() => _initialized = true);

      GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (_) {}
  }

  Future<void> _handleSuccessfulSignIn(GoogleSignInAccount account) async {
    if (_isHandlingSignIn) return;
    _isHandlingSignIn = true;
    if (mounted) setState(() => _isLoading = true);
    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

      await provider.login(
        account.id,
        account.email,
        account.displayName,
        account.photoUrl,
        referralCode: _autoDetectedCode,
      );

      // Refresh settings upon login to detect latest branding colors
      await settingsProvider.loadSettings();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } catch (e) {
      _showError(_parseError(e.toString()));
    } finally {
      _isHandlingSignIn = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // _showReferralCodeDialog removed as per user request for auto-detection only

  Future<void> _handleSignIn() async {
    if (!_initialized) {
      _showError('Google Sign In is not ready yet');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await GoogleSignIn.instance.authenticate();
    } catch (e) {
      _showError(_parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String raw) {
    if (raw.contains('"message":"')) {
      final start = raw.indexOf('"message":"') + 11;
      final end = raw.indexOf('"', start);
      if (end != -1) return raw.substring(start, end);
    }
    return raw.replaceAll('Exception: ', '').trim();
  }

  void _showError(String msg) {
    if (!mounted) return;
    CustomToast.show(
      context,
      msg,
      title: 'Sign In Failed',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _isLoading ? null : _handleSignIn,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isLoading
              ? Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.google,
                        size: 18, color: const Color(0xFFDB4437)),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
