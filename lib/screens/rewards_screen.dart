import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reward_model.dart';
import '../widgets/reward_card.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'reward_detail_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  List<Reward> _rewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRewards();
  }

  Future<void> _fetchRewards() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) return;

      final api = ApiService();
      final List<dynamic> offers = await api.getUserOffers(userId);
      
      if (mounted) {
        setState(() {
          _rewards = offers.map((offer) {
            final bool isScratched = offer['is_scratched'] == true || offer['is_scratched'] == 1;
            final bool isCompleted = offer['is_completed'] == true || offer['is_completed'] == 1;
            final bool hasPartialCompletion = offer['has_partial_completion'] == true || offer['has_partial_completion'] == 1;
            final int completedSteps = (offer['completed_steps'] as num?)?.toInt() ?? 0;
            final int totalSteps = (offer['total_steps'] as num?)?.toInt() ?? 0;
            final double earnedAmount = double.tryParse(offer['earned_amount']?.toString() ?? '0') ?? 0.0;
            final List<Map<String, dynamic>> completedEvents = (offer['completed_events'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ?? [];

            RewardStatus status;
            if (isCompleted && isScratched) {
              status = RewardStatus.completed;
            } else if (hasPartialCompletion && isScratched) {
              status = RewardStatus.rewarded;
            } else if (isScratched) {
              status = RewardStatus.rewarded;
            } else {
              status = RewardStatus.isNew;
            }

            return Reward(
              id: offer['id'].toString(),
              offerId: offer['id'],
              title: offer['heading'] ?? offer['offer_name'] ?? 'Reward',
              subtitle: offer['offer_name'] ?? '',
              rewardAmount: 'Earn up to ₹${offer['amount'] ?? 0}',
              status: status,
              isScratched: isScratched,
              imageUrl: offer['image_url'],
              isCompleted: isCompleted,
              hasPartialCompletion: hasPartialCompletion,
              completedSteps: completedSteps,
              totalSteps: totalSteps,
              earnedAmount: earnedAmount,
              completedEvents: completedEvents,
              sideLabel: offer['side_label']?.toString(),
              sideLabelColor: offer['side_label_color']?.toString(),
              details: [
                'Offer: ${offer['offer_name']}',
                'Amount: ₹${offer['amount']}',
                if (isCompleted)
                  'Status: ✅ Completed - Earned ₹${earnedAmount.toStringAsFixed(2)}'
                else if (hasPartialCompletion)
                  'Status: 🔄 In Progress ($completedSteps/$totalSteps steps)'
                else
                  'Status: ${offer['status']}',
              ],
              terms: 'Standard terms and conditions apply.',
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching rewards: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleRewardTap(Reward reward) {
    _openFullDetails(reward);
  }

  void _openFullDetails(Reward reward) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RewardDetailScreen(reward: reward),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rewards',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _rewards.isEmpty
              ? const Center(child: Text('No rewards available', style: TextStyle(color: Colors.white)))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GridView.builder(
                    itemCount: _rewards.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      return RewardCard(
                        reward: _rewards[index],
                        onTap: () => _handleRewardTap(_rewards[index]),
                      );
                    },
                  ),
                ),
    );
  }
}
