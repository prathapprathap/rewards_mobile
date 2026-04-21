import 'package:flutter/material.dart';
import '../models/reward_model.dart';
import '../constants/colors.dart';

class RewardDetailScreen extends StatelessWidget {
  final Reward reward;

  const RewardDetailScreen({
    super.key,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = reward.isCompleted && reward.isScratched;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.success : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.stars,
                size: 16,
                color: isCompleted ? Colors.white : Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isCompleted ? 'Reward Received' : 'RupiTask',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success/Illustration Card
                if (isCompleted)
                  _buildCompletedCard()
                else
                  _buildDefaultCard(),

                const SizedBox(height: 20),

                // Completed events breakdown (for multi-step offers)
                if (isCompleted && reward.completedEvents.isNotEmpty) ...[
                  _buildCompletedEventsCard(),
                  const SizedBox(height: 20),
                ],

                // Badges
                Row(
                  children: [
                    if (isCompleted)
                      _buildChip('✅ Completed', AppColors.success),
                    if (reward.hasPartialCompletion && !isCompleted)
                      _buildChip('🔄 ${reward.completedSteps}/${reward.totalSteps} Steps', Colors.amber.shade800),
                    if (reward.expiryDays != null) ...[
                      const SizedBox(width: 8),
                      _buildChip('${reward.expiryDays}d left', Colors.orange.shade900),
                    ],
                    if (reward.status == RewardStatus.activating) ...[
                      const SizedBox(width: 8),
                      _buildChip('Activating', Colors.blue.shade900),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Title & Subtitle
                Text(
                  reward.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reward.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 32),

                // Details section
                _buildExpandableSection('Details', reward.details),
                const Divider(color: Colors.white10),
                _buildExpandableSection('Terms & conditions', [
                  reward.terms ?? 'Standard terms and conditions apply.',
                ]),
                
                const SizedBox(height: 40),

                // Like section
                const Text(
                  'Was this offer helpful?',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildLikeButton(Icons.thumb_up_outlined),
                    const SizedBox(width: 16),
                    _buildLikeButton(Icons.thumb_down_outlined),
                  ],
                ),
                
                const SizedBox(height: 100), // Space for sticky button
              ],
            ),
          ),
          // Sticky Bottom
          if (isCompleted)
            _buildCompletedBottomBar()
          else
            _buildDefaultBottomBar(),
        ],
      ),
    );
  }

  /// Success card for completed offers
  Widget _buildCompletedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withOpacity(0.15),
            const Color(0xFF1B5E20).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Success icon with animation ring
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withOpacity(0.2),
              border: Border.all(
                color: AppColors.success,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🎉 Reward Received!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Earned amount
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.success.withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.currency_rupee, color: AppColors.success, size: 28),
                const SizedBox(width: 4),
                Text(
                  reward.earnedAmount.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Credited to your wallet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Regular illustration card for non-completed offers
  Widget _buildDefaultCard() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 100, color: Colors.pink.shade200),
            const SizedBox(height: 10),
            Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(8),
               ),
               child: const Icon(Icons.currency_rupee, color: Colors.pink, size: 30),
            )
          ],
        ),
      ),
    );
  }

  /// Card showing completed events breakdown for multi-step offers
  Widget _buildCompletedEventsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, color: AppColors.success, size: 22),
              SizedBox(width: 10),
              Text(
                'Completed Steps',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...reward.completedEvents.asMap().entries.map((entry) {
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
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event['event_name'] ?? 'Step ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
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
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Earned',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${settings.currencySymbol}${reward.earnedAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0),
              Colors.black.withOpacity(0.8),
              Colors.black,
            ],
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.success.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 22),
              const SizedBox(width: 10),
              Text(
                'Reward Received  ₹${reward.earnedAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0),
              Colors.black.withOpacity(0.8),
              Colors.black,
            ],
          ),
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFAECBFA),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.open_in_new, size: 18),
              SizedBox(width: 8),
              Text(
                'Redeem Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildExpandableSection(String title, List<String> bulletPoints) {
    return Theme(
      data: ThemeData.dark().copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        childrenPadding: const EdgeInsets.only(left: 16, bottom: 16),
        children: bulletPoints.map((point) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Expanded(
                child: Text(
                  point,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildLikeButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}
