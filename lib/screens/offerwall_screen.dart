import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../models/offer_model.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_dialog.dart';

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

  /// Opens the Offer bottom-sheet with all its events when user taps an offer card.
  void _showOfferSheet(Offer offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfferBottomSheet(offer: offer),
    ).then((_) {
      // Refresh in case user completed something
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.refreshUser();
    });
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                padding:
                    const EdgeInsets.fromLTRB(20, 56, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                        color: Colors.white.withOpacity(0.8),
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
                                onTap: () => _showOfferSheet(_offers[index]),
                              );
                            },
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 72, color: AppColors.textTertiary),
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
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back soon for new opportunities!',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
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
    final completedEvents =
        offer.events.where((e) => e.isCompleted).length;
    final totalEvents = offer.events.length;
    final progress = totalEvents > 0 ? completedEvents / totalEvents : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              padding: const EdgeInsets.all(16),
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
                              horizontal: 10, vertical: 5),
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
                  const Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                ],
              ),
            ),

            // Events progress strip (only if multi-event offer)
            if (totalEvents > 0) ...[
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        color: colors[index % colors.length].withOpacity(0.15),
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
            ? AppColors.success.withOpacity(0.1)
            : AppColors.accentLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: event.isCompleted
              ? AppColors.success.withOpacity(0.4)
              : AppColors.accent.withOpacity(0.3),
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
            color:
                event.isCompleted ? AppColors.success : AppColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            event.eventName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color:
                  event.isCompleted ? AppColors.success : AppColors.accent,
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

// ─────────────────────────────────────────────────────────────────────────────
// Offer Detail Bottom-Sheet (with full event timeline)
// ─────────────────────────────────────────────────────────────────────────────

class _OfferBottomSheet extends StatefulWidget {
  final Offer offer;

  const _OfferBottomSheet({required this.offer});

  @override
  State<_OfferBottomSheet> createState() => _OfferBottomSheetState();
}

class _OfferBottomSheetState extends State<_OfferBottomSheet> {
  bool _isLaunching = false;

  Future<void> _launchOffer() async {
    final userProvider =
        Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) return;

    setState(() => _isLaunching = true);
    try {
      final api = ApiService();
      // Ensure device ID is fetched (use a timeout just in case the plugin hangs)
      final deviceId = await ApiService.getDeviceId().timeout(const Duration(seconds: 5), onTimeout: () => '');

      debugPrint('🚀 Starting tracking for Offer ID: ${widget.offer.id} for UI: $userId');

      final trackingData = await api.trackOfferClick(
        userId: userId,
        offerId: widget.offer.id,
        deviceId: deviceId,
      ).timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Connection timeout. Please check your internet.'));

      final trackingUrl = trackingData['trackingUrl'] as String?;
      debugPrint('🔗 Received Tracking URL: $trackingUrl');

      if (trackingUrl != null && trackingUrl.isNotEmpty) {
        final uri = Uri.parse(trackingUrl);
        
        // Use launchUrl directly as canLaunchUrl can be unreliable on some Android versions.
        // It will throw an exception if it fails, which we catch.
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (launched) {
          if (mounted) {
            AppDialog.show(
              context,
              title: 'Offer Started!',
              message: 'Redirecting to complete tasks. Follow instructions to earn rewards.',
              type: DialogType.success,
              onConfirm: () => Navigator.pop(context),
            );
          }
        } else {
          throw Exception('Could not launch the browser. Please check your settings.');
        }
      } else {
        throw Exception('Tracking URL not available for this offer.');
      }
    } catch (e) {
      debugPrint('❌ Offer Launch Error: $e');
      if (mounted) {
        AppDialog.show(
          context,
          title: 'Error',
          message: 'Failed to start offer: ${e.toString().replaceAll('Exception: ', '')}',
          type: DialogType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final hasEvents = offer.events.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        if (offer.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              offer.imageUrl!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _FallbackIcon(size: 72),
                            ),
                          )
                        else
                          _FallbackIcon(size: 72),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.offerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                offer.heading,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: AppColors.accentGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Total: ${offer.currencySymbol}${offer.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Description
                    if (offer.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'About This Offer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        offer.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],

                    // Milestones / Events timeline
                    if (hasEvents) ...[
                      const SizedBox(height: 28),
                      const Text(
                        'Reward Milestones',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Complete each step to earn progressive rewards.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...offer.events.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final event = entry.value;
                        final isLast =
                            idx == offer.events.length - 1;
                        return _EventTimelineTile(
                          event: event,
                          isLast: isLast,
                          stepNumber: idx + 1,
                        );
                      }).toList(),
                    ],

                    const SizedBox(height: 32),

                    // How it works info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppColors.accent, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'How does this work?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _infoRow('1.',
                              'Tap "Start Offer" — we record your unique click.'),
                          _infoRow('2.',
                              'Complete the required tasks inside the app.'),
                          _infoRow('3.',
                              'The provider verifies completion & notifies us.'),
                          _infoRow('4.',
                              'Your wallet is credited automatically!'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CTA Button
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLaunching ? null : _launchOffer,
                  icon: _isLaunching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 26),
                  label: Text(
                    _isLaunching ? 'Opening...' : 'Start Offer',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor:
                        AppColors.success.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            num,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final double size;

  const _FallbackIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.card_giftcard_rounded,
          color: AppColors.accent, size: 32),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Event Timeline Tile
// ─────────────────────────────────────────────────────────────────────────────

class _EventTimelineTile extends StatelessWidget {
  final OfferEvent event;
  final int stepNumber;
  final bool isLast;

  const _EventTimelineTile({
    required this.event,
    required this.stepNumber,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = event.isCompleted ? AppColors.success : AppColors.accent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      event.isCompleted ? AppColors.success : AppColors.accentLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: event.isCompleted
                        ? AppColors.success
                        : AppColors.accent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: event.isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : Text(
                          '$stepNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border,
                    margin:
                        const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Event info
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: event.isCompleted
                      ? AppColors.success.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: event.isCompleted
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.eventName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: event.isCompleted
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (event.isCompleted &&
                              event.completedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Completed ${_formatDate(event.completedAt!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.success.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: event.isCompleted
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.accentLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${event.currencySymbol}${event.points.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: event.isCompleted
                              ? AppColors.success
                              : AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
