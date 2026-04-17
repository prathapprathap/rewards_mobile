class User {
  final int id;
  final String googleId;
  final String email;
  final String? name;
  final String? profilePic;
  final String? deviceId;
  final String? referralCode;
  final String? referredBy;
  final double walletBalance;
  final double totalEarnings;
  final String? upiId;

  User({
    required this.id,
    required this.googleId,
    required this.email,
    this.name,
    this.profilePic,
    this.deviceId,
    this.referralCode,
    this.referredBy,
    required this.walletBalance,
    this.totalEarnings = 0.0,
    this.upiId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      googleId: json['google_id'],
      email: json['email'],
      name: json['name'],
      profilePic: json['profile_pic'],
      deviceId: json['device_id'],
      referralCode: json['referral_code'],
      referredBy: json['referred_by'],
      walletBalance: double.tryParse(json['wallet_balance'].toString()) ?? 0.0,
      totalEarnings:
          double.tryParse(json['total_earnings']?.toString() ?? '0') ?? 0.0,
      upiId: json['upi_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'google_id': googleId,
      'email': email,
      'name': name,
      'profile_pic': profilePic,
      'device_id': deviceId,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'wallet_balance': walletBalance,
      'total_earnings': totalEarnings,
      'upi_id': upiId,
    };
  }
}
