import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'web_view_screen.dart';
import '../widgets/custom_toast.dart';
import '../constants/colors.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';

class OfferDetailScreen extends StatefulWidget {
  final int offerId;

  const OfferDetailScreen({super.key, required this.offerId});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  bool _isLoading = true;
  bool _isStarting = false;
  bool _isUploading = false;
  Map<String, dynamic>? _offerDetails;
  Map<String, dynamic>? _submission;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOfferDetails();
  }

  bool get _requiresScreenshot =>
      _offerDetails != null &&
      (_offerDetails!['requires_screenshot'] == true ||
          _offerDetails!['requires_screenshot'] == 1);

  String? get _submissionStatus =>
      _submission != null ? _submission!['status'] as String? : null;

  Future<void> _loadOfferDetails() async {
    try {
      final api = ApiService();
      final response = await api.getOfferDetails(widget.offerId);
      if (response['success'] == true && response['offer'] != null) {
        final offer = Map<String, dynamic>.from(response['offer']);
        Map<String, dynamic>? submission;
        if ((offer['requires_screenshot'] == true ||
                offer['requires_screenshot'] == 1) &&
            mounted) {
          final userId =
              Provider.of<UserProvider>(context, listen: false).user?.id;
          if (userId != null) {
            try {
              submission = await api.getTaskSubmission(
                userId: userId,
                offerId: widget.offerId,
              );
            } catch (_) {}
          }
        }
        setState(() {
          _offerDetails = offer;
          _submission = submission;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load offer details';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Failed to load offer details';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadScreenshot() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
    if (userId == null) {
      _showSnack('Please login first', AppColors.error);
      return;
    }

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await File(picked.path).readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final mime = (ext == 'jpg' || ext == 'jpeg')
          ? 'image/jpeg'
          : (ext == 'webp')
              ? 'image/webp'
              : 'image/png';
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      final api = ApiService();
      final result = await api.uploadTaskSubmission(
        userId: userId,
        offerId: widget.offerId,
        imageBase64DataUrl: dataUrl,
      );

      if (mounted) {
        _showSnack(
          'Screenshot uploaded. Pending admin review.',
          AppColors.primary,
        );
        setState(() {
          _submission = result['submission'] is Map
              ? Map<String, dynamic>.from(result['submission'])
              : {'status': 'pending'};
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          e.toString().replaceFirst('Exception: ', ''),
          AppColors.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Check if URL is a Play Store link
  bool _isPlayStoreUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    return uri.host.contains('play.google.com') ||
           uri.host.contains('market.android.com') ||
           url.startsWith('market://');
  }

  /// Open Play Store app directly
  Future<void> _openPlayStore(String url) async {
    try {
      // Convert web URL to Play Store app URL if needed
      String playStoreUrl = url;
      
      if (url.contains('play.google.com')) {
        // Extract package name from URL
        final uri = Uri.parse(url);
        final packageName = uri.queryParameters['id'];
        if (packageName != null) {
          playStoreUrl = 'market://details?id=$packageName';
        }
      }
      
      final uri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Force external app (Play Store)
        );
        
        if (mounted) {
          _showSnack(
            'Redirecting to Play Store... Complete all steps to earn ₹${_offerDetails!['amount']}',
            AppColors.primary,
          );
          // Delay before popping back
          Future.delayed(
            const Duration(seconds: 2),
            () => mounted ? Navigator.pop(context) : null,
          );
        }
      } else {
        _showSnack('Could not open Play Store', AppColors.error);
      }
    } catch (e) {
      _showSnack('Failed to open Play Store: $e', AppColors.error);
    }
  }

  Future<void> _startOffer() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) {
      _showSnack('Please login first', AppColors.error);
      return;
    }


    setState(() => _isStarting = true);
    try {
      final api = ApiService();
      final trackingData = await api.trackOfferClick(
        userId: userId,
        offerId: widget.offerId,
        deviceId: null,
      );

      final trackingUrl =
          (trackingData['trackingUrl'] as String?)?.isNotEmpty == true
          ? trackingData['trackingUrl'] as String
          : _offerDetails?['offer_url'] as String?;

final safeUrl = trackingUrl?.startsWith('http://') == true
    ? trackingUrl!.replaceFirst('http://', 'https://')
    : trackingUrl;

      if (safeUrl != null && safeUrl.isNotEmpty) {
        if (!mounted) return;
        
        // Check if it's a Play Store URL
        if (_isPlayStoreUrl(safeUrl)) {
          // Open Play Store app directly
          await _openPlayStore(safeUrl);
        } else {  
          // Open in WebView for other URLs
          final navigator = Navigator.of(context);
          final offerName = _offerDetails?['offer_name'] ?? 'Offer';
          final result = await navigator.push(
            MaterialPageRoute(
              builder: (context) =>
                  WebViewScreen(url: safeUrl, offerName: offerName),
            ),
          );

          if (result == true && mounted) {
            _showSnack(
              'Follow the instructions carefully to earn ₹${_offerDetails!['amount']}',
              AppColors.primary,
            );
            Future.delayed(
              const Duration(seconds: 2),
              () => mounted ? navigator.pop() : null,
            );
          }
        }
      } else {
        _showSnack('This offer has no URL configured yet.', Colors.orange);
      }
    } catch (e) {
      _showSnack('Failed to start offer: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _showSnack(String message, [Color? color]) {
    if (!mounted) return;
    final isError = color == AppColors.error || color == Colors.red;
    CustomToast.show(
      context,
      message,
      title: isError ? 'Oops!' : 'Success',
      isError: isError,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Listen to SettingsProvider for dynamic color updates
    Provider.of<SettingsProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
          ? _buildErrorView()
          : _buildBody(),
    );
  }

  // ─── Error View ───────────────────────────────────────────────────────────

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 72, color: AppColors.outlineVariant),
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main Body ────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final offer = _offerDetails!;
    final steps = _resolveSteps(offer);
    final bool isCompleted =
        offer['is_completed'] == true || offer['is_completed'] == 1;

    return Stack(
      children: [
        // Scrollable content
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Glass App Bar ──────────────────────────────────────
              _buildTopBar(),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero Reward Card ───────────────────────────────
                    _buildHeroCard(offer, isCompleted),

                    const SizedBox(height: 16),

                    // ── Steps to Earn ──────────────────────────────────
                    _buildStepsSection(steps),

                    if (_requiresScreenshot) ...[
                      const SizedBox(height: 16),
                      _buildScreenshotPanel(),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Fixed CTA Button ─────────────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0, child: _buildCTA()),
      ],
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.88)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Rewards',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Reward Card ─────────────────────────────────────────────────────

  Widget _buildHeroCard(Map<String, dynamic> offer, bool isCompleted) {
    final settings = Provider.of<SettingsProvider>(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glow border
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    AppColors.tertiaryFixedDim.withValues(alpha: 0.0),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status chip + Icon row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer['offer_name'] ??
                                offer['heading'] ??
                                'Special Offer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child:
                          (offer['image_url'] != null &&
                              (offer['image_url'] as String).isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                offer['image_url'],
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.account_balance,
                              color: AppColors.primary,
                              size: 30,
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Reward value
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${settings.currencySymbol}${offer['amount'] ?? 0}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Cash Reward',
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
    );
  }

  // ─── Steps Section ────────────────────────────────────────────────────────

  Widget _buildStepsSection(List<dynamic> steps) {
    final resolvedSteps = steps.isNotEmpty
        ? steps
        : [
            "Click 'Start Offer' to open the partner page.",
            'Complete the required action for this offer.',
            'Receive your cash reward after successful verification.',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.list_alt, 'Steps to Earn'),
        const SizedBox(height: 20),
        ...resolvedSteps.asMap().entries.map((entry) {
          final isLast = entry.key == resolvedSteps.length - 1;
          return _buildStep(
            number: entry.key + 1,
            text: entry.value.toString(),
            isFirst: entry.key == 0,
            isLast: isLast,
          );
        }),
      ],
    );
  }

  List<String> _resolveSteps(Map<String, dynamic> offer) {
    List<String> finalSteps = [];

    // 1. Process explicit steps
    final rawSteps = offer['steps'] as List<dynamic>?;
    if (rawSteps != null && rawSteps.isNotEmpty) {
      finalSteps = rawSteps
          .map((step) => _normalizeStepText(step))
          .where((step) => step.isNotEmpty)
          .toList();
    }

    // 2. Process events if no explicit steps (or complement them)
    if (finalSteps.isEmpty) {
      final rawEvents = offer['events'] as List<dynamic>?;
      if (rawEvents != null && rawEvents.isNotEmpty) {
        finalSteps = rawEvents.map((event) {
          if (event is Map) {
            final name = _normalizeStepText(event['event_name']);
            final desc = event['description']?.toString().trim() ?? 
                         event['event_description']?.toString().trim() ?? '';
            return desc.isNotEmpty ? "$name|$desc" : name;
          }
          return '';
        }).where((s) => s.isNotEmpty).toList();
      }
    }

    // 3. Fallback to Description parsing if still empty
    if (finalSteps.isEmpty) {
      final description = offer['description'] as String? ?? '';
      if (description.isNotEmpty && description.contains('\n')) {
        final lines = description.split('\n');
        for (var line in lines) {
          final clean = line.trim();
          if (clean.isEmpty) continue;
          final stepPattern = RegExp(r'^(\d+[\.\)]|Step\s+\d+:?|[-•*])\s*(.*)', caseSensitive: false);
          final match = stepPattern.firstMatch(clean);
          if (match != null) {
            final content = match.group(2)?.trim() ?? '';
            if (content.isNotEmpty) finalSteps.add(content);
          } else if (clean.length > 5 && clean.length < 100) {
            finalSteps.add(clean);
          }
        }
      }
    }

    // 4. Ensure "Start Mission" and "Verification" are added if we have steps
    if (finalSteps.isNotEmpty) {
      // Don't duplicate "Start Mission" if already present
      if (!finalSteps.any((s) => s.toLowerCase().contains("start mission"))) {
        finalSteps.insert(0, "Start Mission|Click 'Start Offer' to open the partner page.");
      }
      
      // Don't duplicate "Verification" if already present
      if (!finalSteps.any((s) => s.toLowerCase().contains("verification"))) {
        finalSteps.add("Verification|Reward will be credited after successful verification.");
      }
    }

    return finalSteps;
  }

  bool _isParsedAsSteps(String description) {
    if (description.isEmpty) return false;
    if (!description.contains('\n')) return false;
    final lines = description.split('\n');
    int stepCount = 0;
    for (var line in lines) {
       final clean = line.trim();
       if (clean.isEmpty) continue;
       final stepPattern = RegExp(r'^(\d+[\.\)]|Step\s+\d+:?|[-•*])\s*(.*)', caseSensitive: false);
       if (stepPattern.hasMatch(clean)) stepCount++;
    }
    return stepCount >= 2;
  }


  String _normalizeStepText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    // Replace multiple spaces with a single space, but preserve newlines
    return text.replaceAll(RegExp(r'[^\S\r\n]+'), ' ');
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }


  Widget _buildStep({
    required int number,
    required String text,
    required bool isFirst,
    required bool isLast,
  }) {
    // Split combined text/description if present
    final parts = text.split('|');
    final title = parts[0].trim();
    final description = parts.length > 1 ? parts[1].trim() : '';

    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 28, // Center of the number circle (12 + 16)
            top: 40,
            bottom: 0,
            child: Container(
              width: 2,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isFirst ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isFirst 
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isFirst ? null : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: isFirst ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: GoogleFonts.plusJakartaSans(
                      color: isFirst ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...description.split('\n').where((s) => s.trim().isNotEmpty).map((bullet) {
                        final cleanBullet = bullet.startsWith('• ') ? bullet.substring(2) : bullet;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w900)),
                              Expanded(
                                child: Text(
                                  cleanBullet,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Screenshot Panel ─────────────────────────────────────────────────────

  Widget _buildScreenshotPanel() {
    final status = _submissionStatus;
    final note = _submission?['admin_note'] as String?;

    Color badgeBg;
    Color badgeFg;
    String badgeText;
    String subtitle;
    bool canUpload;

    switch (status) {
      case 'pending':
        badgeBg = const Color(0xFFFFF4D6);
        badgeFg = const Color(0xFFB4760E);
        badgeText = 'Pending';
        subtitle = 'Your screenshot is awaiting admin review.';
        canUpload = false;
        break;
      case 'approved':
        badgeBg = const Color(0xFFD4F5E2);
        badgeFg = const Color(0xFF137A3D);
        badgeText = 'Approved';
        subtitle = 'Reward credited to your wallet.';
        canUpload = false;
        break;
      case 'rejected':
        badgeBg = const Color(0xFFFDE2E2);
        badgeFg = const Color(0xFFB42318);
        badgeText = 'Rejected';
        subtitle = note != null && note.isNotEmpty
            ? note
            : 'Submission rejected. Please try again.';
        canUpload = true;
        break;
      default:
        badgeBg = AppColors.primary.withValues(alpha: 0.12);
        badgeFg = AppColors.primary;
        badgeText = 'Action Required';
        subtitle = 'Upload a screenshot to verify task completion.';
        canUpload = true;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit Screenshot',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ),
          if (_submission?['screenshot_url'] is String &&
              (_submission!['screenshot_url'] as String).isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                _submission!['screenshot_url'],
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: AppColors.surfaceContainer,
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image,
                      color: AppColors.outline, size: 28),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: (!canUpload || _isUploading) ? null : _uploadScreenshot,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !canUpload
                      ? AppColors.surfaceContainer
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: !canUpload
                        ? AppColors.outlineVariant
                        : AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isUploading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    else ...[
                      Icon(
                        Icons.upload_file,
                        color: !canUpload
                            ? AppColors.outline
                            : AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status == 'rejected' ? 'Re-upload' : 'Upload',
                        style: GoogleFonts.plusJakartaSans(
                          color: !canUpload
                              ? AppColors.onSurfaceVariant
                              : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CTA ──────────────────────────────────────────────────────────────────

  Widget _buildCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0),
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isStarting ? null : _startOffer,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isStarting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else ...[
                      Text(
                        'Start Offer',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SECURE REDIRECTION TO PARTNER SITE',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.outline,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}