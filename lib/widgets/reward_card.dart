import 'package:flutter/material.dart';
import '../models/reward_model.dart';
import '../constants/colors.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;
  final VoidCallback onTap;

  const RewardCard({
    super.key,
    required this.reward,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = reward.isCompleted && reward.isScratched;

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'reward_card_${reward.id}',
        child: Container(
          decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark theme match
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? AppColors.success.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              blurRadius: isCompleted ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isCompleted
              ? Border.all(color: AppColors.success.withOpacity(0.5), width: 2)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section (Image/Pattern)
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      _buildBackground(),
                      if (reward.imageUrl != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Image.network(
                              reward.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.card_giftcard, color: Colors.white54, size: 40),
                            ),
                          ),
                        ),
                      // Badge
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _buildBadge(),
                      ),
                      // Logo (if any)
                      if (reward.status == RewardStatus.activating || reward.status == RewardStatus.expiringSoon)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.stars, size: 16, color: Colors.blue),
                        ),
                      ),
                      // Completed overlay checkmark
                      if (isCompleted)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.check, size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                // Bottom Section (Info)
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: isCompleted ? const Color(0xFF1A2E1A) : Colors.black,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          reward.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (isCompleted) ...[
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Earned ₹${reward.earnedAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ] else if (reward.hasPartialCompletion && reward.isScratched) ...[
                          Row(
                            children: [
                              const Icon(Icons.trending_up, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${reward.completedSteps}/${reward.totalSteps} steps done',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            reward.subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Scratched overlay for completed tasks
            if (isCompleted)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.success.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildBackground() {
    // Return different backgrounds based on status or type
    Color bgColor = Colors.blue.shade400;
    if (reward.isCompleted && reward.isScratched) {
      bgColor = const Color(0xFF2E7D32); // Success green for completed
    } else if (reward.title.contains('₹5')) {
      bgColor = Colors.blue.shade300;
    } else if (reward.subtitle.contains('Nykaa')) {
      bgColor = Colors.blue.shade100;
    } else if (reward.subtitle.contains('Boat')) {
      bgColor = Colors.red.shade900;
    }
    
    return Container(
      width: double.infinity,
      color: bgColor,
      child: Opacity(
        opacity: 0.1,
        child: CustomPaint(
          painter: PatternPainter(),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    String text = reward.statusText;
    Color color = Colors.black45;
    
    if (reward.status == RewardStatus.completed) {
      color = AppColors.success;
    } else if (reward.status == RewardStatus.isNew) {
      color = Colors.green.shade700;
    } else if (reward.status == RewardStatus.expiringSoon) {
      color = Colors.orange.shade900;
    } else if (reward.status == RewardStatus.activating) {
       color = Colors.blue.shade900;
    } else if (reward.status == RewardStatus.rewarded && reward.hasPartialCompletion) {
      text = '🔄 In Progress';
      color = Colors.amber.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw some random circles/icons patterns
    for (int i = 0; i < 5; i++) {
       canvas.drawCircle(Offset(size.width * (0.2 + i * 0.15), size.height * 0.3), 10, paint);
       canvas.drawCircle(Offset(size.width * (0.1 + i * 0.2), size.height * 0.7), 15, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
