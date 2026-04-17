import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'offer_detail_screen.dart';

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScratcherState> _scratchKey = GlobalKey<ScratcherState>();
  bool _isLoading = true;
  bool _isRevealed = false;
  bool _isClaimed = false;
  bool _hasScratched = false;
  bool _isStarting = false;
  bool _isScratching = false;
  double _progress = 0.0;
  Map<String, dynamic>? _offer;
  String? _errorMessage;

  // Completion tracking
  bool _isOfferCompleted = false;
  double _earnedAmount = 0.0;
  int _completedSteps = 0;
  int _totalSteps = 0;
  List<Map<String, dynamic>> _completedEvents = [];

  late AnimationController _successAnimController;
  late Animation<double> _successScaleAnim;

  @override
  void initState() {
    super.initState();
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
    _loadOffer();
  }

  @override
  void dispose() {
    _successAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadOffer() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        setState(() {
          _errorMessage = 'Please login first';
          _isLoading = false;
        });
        return;
      }

      final api = ApiService();
      final response = await api.getScratchableOffer(userId);

      if (response['success'] == true && response['offer'] != null) {
        final offer = response['offer'];

        // Check if this offer has been completed by the user
        await _checkOfferCompletion(userId, offer['id']);

        setState(() {
          _offer = offer;
          _isLoading = false;
          // If offer is already completed, show as pre-revealed
          if (_isOfferCompleted) {
            _isRevealed = true;
            _hasScratched = true;
          }
        });

        // Trigger success animation if completed
        if (_isOfferCompleted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _successAnimController.forward();
          });
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'No offers available';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading offer: $e');
      setState(() {
        _errorMessage = 'Failed to load offer';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkOfferCompletion(int userId, int offerId) async {
    try {
      final api = ApiService();
      final events = await api.getOfferEvents(offerId, userId: userId);

      int completedCount = 0;
      double earned = 0.0;
      List<Map<String, dynamic>> completedEventsList = [];

      for (final event in events) {
        if (event.isCompleted) {
          completedCount++;
          earned += event.points;
          completedEventsList.add({
            'event_name': event.eventName,
            'earned': event.points,
          });
        }
      }

      setState(() {
        _completedSteps = completedCount;
        _totalSteps = events.length;
        _earnedAmount = earned;
        _completedEvents = completedEventsList;
        _isOfferCompleted = events.isNotEmpty && completedCount >= events.length;
      });
    } catch (e) {
      print('Error checking offer completion: $e');
      // Not critical, just continue
    }
  }

  void _onScratchProgress(double progress) {
    setState(() => _progress = progress);

    // Auto-reveal at 50% like Google Pay
    if (progress >= 0.5 && !_isRevealed) {
      setState(() => _isRevealed = true);
      _scratchKey.currentState?.reveal(duration: const Duration(milliseconds: 500));
      
      // Mark as scratched
      if (!_hasScratched) {
        _markAsScratched();
      }
    }
  }

  Future<void> _markAsScratched() async {
    if (_offer == null) return;
    
    setState(() => _hasScratched = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      
      if (userId != null) {
        final api = ApiService();
        await api.markOfferScratched(userId, _offer!['id']);
      }
    } catch (e) {
      print('Error marking offer as scratched: $e');
    }
  }

  void _claimOffer() {
    if (_offer != null) {
      // Navigate to full offer details page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OfferDetailScreen(offerId: _offer!['id']),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _isOfferCompleted ? 'Reward Received!' : 'Scratch & Win',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _isOfferCompleted
                ? const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : AppColors.headerGradient,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _errorMessage != null
              ? _buildErrorView()
              : _isOfferCompleted
                  ? _buildCompletedView()
                  : _buildScratchCard(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: AppColors.textTertiary),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

  /// ─────────────────────────────────────────────────────────────
  /// COMPLETED VIEW - shown when the offer was already completed
  /// ─────────────────────────────────────────────────────────────
  Widget _buildCompletedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Success banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '🎉 Task Completed! Reward credited to wallet!',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Already-scratched card (revealed)
          ScaleTransition(
            scale: _successScaleAnim,
            child: Container(
              width: MediaQuery.of(context).size.width - 40,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    AppColors.successLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: AppColors.success.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Offer Image
                  if (_offer!['image_url'] != null)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(_offer!['image_url']),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Offer Name
                  Text(
                    _offer!['offer_name'] ?? 'Special Offer',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Heading
                  Text(
                    _offer!['heading'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // EARNED badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white70, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'REWARD RECEIVED',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${_earnedAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress indicator
                  if (_totalSteps > 0)
                    Column(
                      children: [
                        Text(
                          '$_completedSteps/$_totalSteps steps completed',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 1.0,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Completed events breakdown
          if (_completedEvents.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long, color: AppColors.success, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Earnings Breakdown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._completedEvents.asMap().entries.map((entry) {
                    final index = entry.key;
                    final event = entry.value;
                    final earned = (event['earned'] as num?)?.toDouble() ?? 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              event['event_name'] ?? 'Step ${index + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+₹${earned.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Earned',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '₹${_earnedAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Go back button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 20),
              label: const Text(
                'Back to Rewards',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.success.withOpacity(0.4),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildScratchCard() {
    return SingleChildScrollView(
      physics: _isScratching 
          ? const NeverScrollableScrollPhysics() // Disable scroll while scratching
          : const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Instruction text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, color: AppColors.accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isRevealed 
                        ? '🎉 Congratulations! Claim your offer below!'
                        : '👆 Scratch to reveal your reward!',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Progress indicator
          if (!_isRevealed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Text(
                    'Progress: ${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Scratch Card
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Scratcher(
                    key: _scratchKey,
                    brushSize: 40,
                    threshold: 50,
                    color: AppColors.accent,
                    enabled: !_isRevealed, // Disable after reveal
                    onScratchStart: () {
                      // Disable scrolling when scratching starts
                      setState(() => _isScratching = true);
                    },
                    onScratchEnd: () {
                      // Re-enable scrolling when scratching ends
                      setState(() => _isScratching = false);
                    },
                    onChange: _onScratchProgress,
                    onThreshold: () {
                      // This fires when threshold (50%) is reached
                      if (!_isRevealed) {
                        setState(() => _isRevealed = true);
                        _scratchKey.currentState?.reveal(duration: const Duration(milliseconds: 500));
                        if (!_hasScratched) {
                          _markAsScratched();
                        }
                      }
                    },
                    child: _buildRewardCard(),
                  ),
                ),
              ),
          ),

          const SizedBox(height: 24),

          // Hint text or Skip button
          if (!_isRevealed)
            Column(
              children: [
                Text(
                  'Scratch 50% to auto-reveal!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // Debug/Test skip button
                TextButton.icon(
                  onPressed: () {
                    setState(() => _isRevealed = true);
                    _scratchKey.currentState?.reveal(duration: const Duration(milliseconds: 500));
                    if (!_hasScratched) {
                      _markAsScratched();
                    }
                  },
                  icon: const Icon(Icons.skip_next, size: 16),
                  label: const Text('Skip Scratch (for testing)'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRewardCard() {
    return Container(
      width: MediaQuery.of(context).size.width - 40,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primaryLight,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Offer Image
          if (_offer!['image_url'] != null)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(_offer!['image_url']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          const SizedBox(height: 24),

          // Offer Name
          Text(
            _offer!['offer_name'] ?? 'Special Offer',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // Heading
          Text(
            _offer!['heading'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 24),

          // Reward Amount
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'WIN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_offer!['amount']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // CLAIM OFFER Button (shown after reveal)
          if (_isRevealed)
            ElevatedButton.icon(
              onPressed: _claimOffer,
              icon: const Icon(Icons.card_giftcard, size: 24),
              label: const Text(
                'CLAIM OFFER',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: AppColors.success.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
}
