import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  Map<String, dynamic>? _offerDetails;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOfferDetails();
  }

  Future<void> _loadOfferDetails() async {
    try {
      final api = ApiService();
      final response = await api.getOfferDetails(widget.offerId);
      if (response['success'] == true && response['offer'] != null) {
        setState(() {
          _offerDetails = response['offer'];
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
            'Opening Play Store... Complete the task to earn ₹${_offerDetails!['amount']}',
            AppColors.success,
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
              'Offer tracked! Complete the task to earn ₹${_offerDetails!['amount']}',
              AppColors.success,
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

                    const SizedBox(height: 36),

                    // ── Steps to Earn ──────────────────────────────────
                    _buildStepsSection(steps),

                    const SizedBox(height: 36),

                    // ── Terms & Speed Bento ────────────────────────────
                    Row(
                      children: [
                        Expanded(child: _buildTermsCard(offer)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildSpeedCard()),
                      ],
                    ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.tertiaryFixed.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              isCompleted ? 'COMPLETED' : 'UNLOCKED OFFER',
                              style: GoogleFonts.inter(
                                color: AppColors.tertiary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
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

                const SizedBox(height: 20),

                // Meta chips grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaChip(
                        icon: Icons.timer,
                        color: AppColors.secondary,
                        label: 'Expires in',
                        value: '2 days, 14h',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetaChip(
                        icon: Icons.verified,
                        color: AppColors.tertiary,
                        label: 'Reliability',
                        value: 'Guaranteed',
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

  Widget _buildMetaChip({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
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
        Row(
          children: [
            Icon(Icons.list_alt, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Steps to Earn',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
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
    // 1. Check explicit steps list
    final rawSteps = offer['steps'] as List<dynamic>?;
    final normalizedSteps =
        rawSteps
            ?.map((step) => _normalizeStepText(step))
            .where((step) => step.isNotEmpty)
            .toList() ??
        const <String>[];
    if (normalizedSteps.isNotEmpty) return normalizedSteps;

    // 2. Check events list
    final rawEvents = offer['events'] as List<dynamic>?;
    if (rawEvents != null && rawEvents.isNotEmpty) {
      final eventSteps = rawEvents.map((event) {
        if (event is Map) return _normalizeStepText(event['event_name']);
        return '';
      }).where((s) => s.isNotEmpty).toList();
      
      if (eventSteps.isNotEmpty) {
         return ["Click 'Start Offer' to open the partner page.", ...eventSteps, "Reward will be credited after verification."];
      }
    }

    // 3. Parse from Description (NEW)
    final description = offer['description'] as String? ?? '';
    if (description.isNotEmpty && description.contains('\n')) {
      // Split by newlines and filter for lines that look like steps
      final lines = description.split('\n');
      final parsedSteps = <String>[];
      
      for (var line in lines) {
        final clean = line.trim();
        if (clean.isEmpty) continue;
        
        // Match patterns like "Step 1:", "1.", "- ", "• "
        final stepPattern = RegExp(r'^(\d+[\.\)]|Step\s+\d+:?|[-•*])\s*(.*)', caseSensitive: false);
        final match = stepPattern.firstMatch(clean);
        
        if (match != null) {
          final content = match.group(2)?.trim() ?? '';
          if (content.isNotEmpty) parsedSteps.add(content);
        } else if (clean.length > 5 && clean.length < 100) {
          // If no pattern but looks like a standalone sentence in a list-y description
          parsedSteps.add(clean);
        }
      }
      
      if (parsedSteps.isNotEmpty) return parsedSteps;
    }

    return const [
      "Click 'Start Offer' to open the partner page.",
      'Complete the required action for this offer.',
      'Receive your cash reward after successful verification.',
    ];
  }

  String _normalizeStepText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  Widget _buildStep({
    required int number,
    required String text,
    required bool isFirst,
    required bool isLast,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isFirst ? AppColors.primary : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.inter(
                  color: isFirst ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurface,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Terms / Speed Cards ──────────────────────────────────────────────────

  Widget _buildTermsCard(Map<String, dynamic> offer) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.onSurfaceVariant, size: 22),
          const SizedBox(height: 12),
          Text(
            'TERMS',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            offer['terms'] as String? ??
                'Must be a new customer. Account must remain active for 30 days.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondaryFixed.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bolt, color: AppColors.secondary, size: 22),
          const SizedBox(height: 12),
          Text(
            'SPEED',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.onSecondaryContainer,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Reward typically processes within 24 hours of successful verification.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurface,
              height: 1.5,
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