import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'offer_detail_screen.dart';
import '../constants/colors.dart';
import '../models/offer_model.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/ui/rupi_ui.dart';

/// Formats a reward amount, dropping the decimals when it is a whole number
/// (e.g. 90.0 → "90", 0.1 → "0.1").
String _formatAmount(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class OfferwallScreen extends StatefulWidget {
  const OfferwallScreen({super.key});

  @override
  State<OfferwallScreen> createState() => _OfferwallScreenState();
}

class _OfferwallScreenState extends State<OfferwallScreen>
    with TickerProviderStateMixin {
  List<Offer> _offers = [];
  bool _isLoading = true;
  String? _errorMessage;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadOffers();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final api = ApiService();
      final userId =
          Provider.of<UserProvider>(context, listen: false).user?.id;
      // Cache-first: instant render from cache, then refresh in background.
      // Passing userId lets the backend hide offers this user already finished.
      await api.getOfferwallOffersCached(userId: userId, (offers) {
        if (!mounted) return;
        setState(() {
          _offers = offers;
          _isLoading = false;
          _errorMessage = null;
        });
        if (!_fadeController.isCompleted) _fadeController.forward();
      });
    } catch (e) {
      if (mounted && _offers.isEmpty) {
        setState(() {
          _errorMessage = 'Failed to load offers. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Navigates to the OfferDetailScreen when user taps an offer card.
  Future<void> _showOfferDetail(Offer offer) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferDetailScreen(offerId: offer.id),
      ),
    );
    if (mounted) {
      userProvider.refreshUser();
      // Re-fetch so an offer the user just finished drops off the list.
      _loadOffers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, user)),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Transform.translate(
              offset: const Offset(0, -8),
              child: _isLoading
                  ? _buildLoader()
                  : _errorMessage != null
                  ? _buildError()
                  : _offers.isEmpty
                  ? _buildEmpty()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: _loadOffers,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: _offers.length,
                          itemBuilder: (context, index) {
                            return _OfferCard(
                              offer: _offers[index],
                              index: index,
                              onTap: () => _showOfferDetail(_offers[index]),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    final canGoBack = Navigator.of(context).canPop();
    return RupiHeader(
      height: 122,
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
            'Offerwall',
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

  Widget _buildLoader() {
    return RupiLoader.fullscreen(label: 'Finding offers…');
  }

  Widget _buildError() {
    return RupiEmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Couldn\'t load offers',
      subtitle: _errorMessage,
      actionLabel: 'Try Again',
      onAction: _loadOffers,
      tint: AppColors.error,
    );
  }

  Widget _buildEmpty() {
    return const RupiEmptyState(
      icon: Icons.inbox_rounded,
      title: 'No offers right now',
      subtitle: 'Check back soon for fresh ways to earn!',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offer Card
// ─────────────────────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final int index;
  final VoidCallback onTap;

  const _OfferCard({
    required this.offer,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completedEvents = offer.events.where((e) => e.isCompleted).length;
    final totalEvents = offer.events.length;
    final progress = totalEvents > 0 ? completedEvents / totalEvents : 0.0;
    final sideLabel = offer.sideLabel?.trim() ?? '';
    final hasSideLabel = sideLabel.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.06),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    13,
                    hasSideLabel ? 20 : 10,
                    13,
                    10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Offer icon / image
                      Container(
                        width: 48,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child:
                            (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  offer.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholderIcon(index),
                                ),
                              )
                            : _placeholderIcon(index),
                      ),
                      const SizedBox(width: 12),
                      // Offer info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.offerName,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.onSurface,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              offer.heading,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: AppColors.onSurfaceVariant,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Reward badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Earn ${offer.currencySymbol}${_formatAmount(offer.amount)}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.outline,
                      ),
                    ],
                  ),
                ),

                // Events progress strip (only if multi-event offer)
                if (totalEvents > 0) ...[
                  Divider(
                    height: 1,
                    color: AppColors.primary.withValues(alpha: 0.06),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$completedEvents / $totalEvents milestones',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: progress == 1.0
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1.0
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Event chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: offer.events
                              .map((e) => _EventChip(event: e))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasSideLabel)
            Positioned(
              top: -4,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.24),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  sideLabel.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholderIcon(int index) {
    const colors = [
      Color(0xFF7B68EE),
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFFFBE0B),
    ];
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors[index % colors.length].withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.card_giftcard_rounded,
        color: colors[index % colors.length],
        size: 24,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Event Chip
// ─────────────────────────────────────────────────────────────────────────────

class _EventChip extends StatelessWidget {
  final OfferEvent event;

  const _EventChip({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: event.isCompleted
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: event.isCompleted
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            event.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 12,
            color: event.isCompleted ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            event.eventName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: event.isCompleted ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${event.currencySymbol}${_formatAmount(event.points)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: event.isCompleted
                  ? AppColors.success
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
