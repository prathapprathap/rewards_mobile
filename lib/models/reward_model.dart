enum RewardStatus {
  activating,
  isNew,
  expiringSoon,
  rewarded,
  completed,
}

class Reward {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final RewardStatus status;
  final int? expiryDays;
  final List<String> details;
  final String? terms;
  final String? rewardAmount;
  final bool isScratched;
  final int? offerId;
  // Completion tracking fields
  final bool isCompleted;
  final bool hasPartialCompletion;
  final int completedSteps;
  final int totalSteps;
  final double earnedAmount;
  final List<Map<String, dynamic>> completedEvents;
  final String? sideLabel;
  final String? sideLabelColor;

  Reward({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.status,
    this.expiryDays,
    this.details = const [],
    this.terms,
    this.rewardAmount,
    this.isScratched = false,
    this.offerId,
    this.isCompleted = false,
    this.hasPartialCompletion = false,
    this.completedSteps = 0,
    this.totalSteps = 0,
    this.earnedAmount = 0.0,
    this.completedEvents = const [],
    this.sideLabel,
    this.sideLabelColor,
  });

  // Helper for status text
  String get statusText {
    switch (status) {
      case RewardStatus.activating:
        return 'Activating';
      case RewardStatus.isNew:
        return 'New';
      case RewardStatus.expiringSoon:
        return '${expiryDays}d left';
      case RewardStatus.rewarded:
        return 'Cashback rewarded';
      case RewardStatus.completed:
        return '✅ Reward Received';
    }
  }
}
