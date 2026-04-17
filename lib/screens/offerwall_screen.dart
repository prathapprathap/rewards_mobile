import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'offer_detail_screen.dart';
import '../constants/colors.dart';
import '../models/offer_model.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

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
      final offers = await api.getOfferwallOffers();
      if (mounted) {
        setState(() {
          _offers = offers;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.headerGradient),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '🎯 Offerwall',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete offers & earn rewards',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
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
    );
  }

  Widget _buildLoader() {
    return Center(child: CircularProgressIndicator(color: AppColors.primary));
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 72,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadOffers,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 72, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text(
            'No offers available right now',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Check back soon for new opportunities!',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
        ],
      ),
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
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    hasSideLabel ? 28 : 16,
                    16,
                    16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Offer icon / image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: offer.imageUrl != null
                            ? Image.network(
                                offer.imageUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderIcon(index),
                              )
                            : _placeholderIcon(index),
                      ),
                      const SizedBox(width: 14),
                      // Offer info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.offerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              offer.heading,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Reward badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Earn ${offer.currencySymbol}${offer.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),

                // Events progress strip (only if multi-event offer)
                if (totalEvents > 0) ...[
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$completedEvents / $totalEvents milestones',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: progress == 1.0
                                    ? AppColors.success
                                    : AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1.0
                                  ? AppColors.success
                                  : AppColors.accent,
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
                  style: const TextStyle(
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colors[index % colors.length].withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.card_giftcard_rounded,
        color: colors[index % colors.length],
        size: 32,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: event.isCompleted
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.accentLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: event.isCompleted
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.accent.withValues(alpha: 0.3),
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
            color: event.isCompleted ? AppColors.success : AppColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            event.eventName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: event.isCompleted ? AppColors.success : AppColors.accent,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${event.currencySymbol}${event.points}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: event.isCompleted
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
