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
import '../services/api_service.dart' show LoginException;
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
  String? _autoDetectedCode;

  /// Referrer detection runs in the background from initState so it doesn't
  /// block the button, but signup awaits this (briefly, capped) right before
  /// calling login — otherwise a fast tap on a fresh install can race past
  /// detection and silently sign the user up with no referral code applied.
  late final Future<void> _playReferrerDetection;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
    _playReferrerDetection = _tryDetectPlayReferrer();
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
    super.dispose();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: '460766907792-i4qlh7r22he7r0m0aea6h6ho8jfe49ik.apps.googleusercontent.com',
      );
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      return;
    }
    _tryLightweightSignIn();
  }

  /// Shows Google's "Continue as …" bottom sheet over this screen (returning
  /// users get their previous account; after a logout it asks rather than
  /// signing in silently). Dismissing it just leaves the normal button.
  Future<void> _tryLightweightSignIn() async {
    // Disable the button while the sheet is up so a tap can't start a second,
    // concurrent Google sign-in.
    if (mounted) setState(() => _isLoading = true);
    try {
      final account = await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (account != null && mounted) {
        await _handleSuccessfulSignIn(account);
      }
    } catch (_) {
      // Dismissed / no account / unsupported — the button still works.
    } finally {
      if (mounted && !_isHandlingSignIn) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSuccessfulSignIn(GoogleSignInAccount account) async {
    if (_isHandlingSignIn) return;
    _isHandlingSignIn = true;
    if (mounted) setState(() => _isLoading = true);
    try {
      // Give referrer detection a brief chance to finish before deciding
      // there's no code — a fast tap right after launch would otherwise
      // race past it and silently sign up with no referral applied.
      await _playReferrerDetection.timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
      if (!mounted) return;

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

      // Do NOT navigate manually here — AuthWrapper (main.dart) reacts to
      // UserProvider.notifyListeners() and switches to MainLayout on its own.
      // Pushing a route here would stack MainLayout on top of AuthWrapper
      // instead of replacing it, so popping back (e.g. Android back button)
      // reveals a stale AuthWrapper still showing LoginScreen — causing a
      // silent login loop with no error.
    } catch (e) {
      _showError(_errorMessage(e));
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
      final account = await GoogleSignIn.instance.authenticate();
      if (account != null) {
        await _handleSuccessfulSignIn(account);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError(_errorMessage(e));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// User-facing text for a sign-in failure, or null when there's nothing to
  /// report (the user closed Google's account picker themselves).
  String? _errorMessage(Object e) {
    if (e is GoogleSignInException) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return null;
        case GoogleSignInExceptionCode.uiUnavailable:
          return 'Google Sign-In is not available right now. Please try again.';
        default:
          return 'Google Sign-In failed (${e.code.name}). Please try again.';
      }
    }
    // Backend rejections (device already registered, blocked, …) carry the
    // server's own message.
    if (e is LoginException) return e.message;

    final raw = e.toString();
    if (raw.contains('Error connecting to server') || raw.contains('timed out')) {
      return "Can't reach the server. Check your internet connection and try again.";
    }
    return raw.replaceAll('Exception: ', '').trim();
  }

  void _showError(String? msg) {
    if (msg == null || !mounted) return;
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
