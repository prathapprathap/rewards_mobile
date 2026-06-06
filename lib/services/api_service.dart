import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/offer_model.dart';
import 'api_cache.dart';

class ApiService {
  Future<User> loginWithGoogle({
    required String googleId,
    required String email,
    String? name,
    String? profilePic,
    String? deviceId,
    String? referralCode,
  }) async {
    try {
      final body = {
        'google_id': googleId,
        'email': email,
        'name': name,
        'profile_pic': profilePic,
        'device_id': deviceId,
      };
      if (referralCode != null && referralCode.isNotEmpty) {
        body['referral_code'] = referralCode;
      }
      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return User.fromJson(data['user']);
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<User> getUserProfile(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.userProfileEndpoint}/$id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<List<dynamic>> getUserOffers(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/offers'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load offers');
      }
    } catch (e) {
      throw Exception('Error fetching offers: $e');
    }
  }

  Future<Map<String, dynamic>> scratchOffer(int userId, int offerId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/scratch-offer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'offer_id': offerId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to scratch offer');
      }
    } catch (e) {
      throw Exception('Error scratching offer: $e');
    }
  }

  Future<List<dynamic>> getTasks() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.tasksEndpoint));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }



  Future<Map<String, dynamic>> getUserSpins(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/spins'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user spins');
      }
    } catch (e) {
      throw Exception('Error fetching user spins: $e');
    }
  }

  Future<Map<String, dynamic>> useSpin(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/use-spin'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to use spin');
      }
    } catch (e) {
      throw Exception('Error using spin: $e');
    }
  }

  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/app/settings'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> settingsList = jsonDecode(response.body);
        final Map<String, dynamic> settingsMap = {};
        for (var item in settingsList) {
          settingsMap[item['setting_key']] = item['setting_value'];
        }
        return settingsMap;
      } else {
        throw Exception('Failed to load app settings');
      }
    } catch (e) {
      throw Exception('Error fetching app settings: $e');
    }
  }

  /// Cache-first variant for screens that don't need real-time freshness.
  /// Calls [onData] up to twice: once with cached data (instant), once with
  /// fresh data when the network refresh lands.
  Future<void> getOfferwallOffersCached(
    void Function(List<Offer>) onData, {
    int? userId,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    await cachedJson(
      key: userId != null ? 'offerwall_offers_$userId' : 'offerwall_offers',
      ttl: ttl,
      fetch: () async {
        final res = await http.get(
          Uri.parse(
            '${ApiConstants.baseUrl}/offers/offerwall'
            '${userId != null ? '?userId=$userId' : ''}',
          ),
        );
        if (res.statusCode != 200) throw Exception('offerwall failed');
        return res.body;
      },
      onValue: (json) {
        if (json is List) {
          onData(json
              .map((e) => Offer.fromJson(e as Map<String, dynamic>))
              .toList());
        }
      },
    );
  }

  Future<void> getBannersCached(
    void Function(List<dynamic>) onData, {
    Duration ttl = const Duration(minutes: 10),
  }) async {
    await cachedJson(
      key: 'banners',
      ttl: ttl,
      fetch: () async {
        final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/offer18/banners'),
        );
        if (res.statusCode != 200) throw Exception('banners failed');
        return res.body;
      },
      onValue: (json) {
        if (json is Map && json['banners'] is List) {
          onData(json['banners'] as List);
        }
      },
    );
  }

  Future<void> getUserOffersCached(
    int userId,
    void Function(List<dynamic>) onData, {
    Duration ttl = const Duration(minutes: 2),
  }) async {
    await cachedJson(
      key: 'user_offers_$userId',
      ttl: ttl,
      fetch: () async {
        final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/users/$userId/offers'),
        );
        if (res.statusCode != 200) throw Exception('user offers failed');
        return res.body;
      },
      onValue: (json) {
        if (json is List) onData(json);
      },
    );
  }

  void invalidateUserOffersCache(int userId) {
    ApiCache.instance.invalidate('user_offers_$userId');
  }

  Future<Map<String, dynamic>> redeemPromoCode(int userId, String code) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users/promo/$userId/redeem'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Failed to redeem code',
      );
    }
  }

  Future<Map<String, dynamic>> getReferralStats(int userId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/referral-stats'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get referral stats');
    }
  }

  Future<Map<String, dynamic>> applyReferralCode(
    int userId,
    String code,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/apply-referral'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'referral_code': code}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to apply referral code');
  }

  // ── Device ID ──────────────────────────────────────────────────────────────

  /// Returns a stable unique device identifier using [device_info_plus].
  /// Falls back to an empty string if the platform is not supported.
  static Future<String> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return info.id; // Android hardware-level ID
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.identifierForVendor ?? '';
      }
    } catch (_) {}
    return '';
  }

  // ── Offerwall / Offer18 Methods ────────────────────────────────────────────

  /// Fetches the full list of active offerwall offers (with their events).
  Future<List<Offer>> getOfferwallOffers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/offers/offerwall'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => Offer.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load offerwall offers');
      }
    } catch (e) {
      throw Exception('Error fetching offerwall offers: $e');
    }
  }

  /// Returns the list of [OfferEvent]s for a given offer, optionally filtered
  /// by [userId] to mark which events the user has already completed.
  Future<List<OfferEvent>> getOfferEvents(int offerId, {int? userId}) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/offers/$offerId/events'
        '${userId != null ? '?userId=$userId' : ''}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> events = data['events'] ?? [];
        return events
            .map((e) => OfferEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load offer events');
      }
    } catch (e) {
      throw Exception('Error fetching offer events: $e');
    }
  }

  /// Track offer click and get tracking URL
  Future<Map<String, dynamic>> trackOfferClick({
    required int userId,
    required int offerId,
    String? deviceId,
  }) async {
    try {
      // Auto-resolve device ID if not provided
      final resolvedDeviceId = deviceId ?? await getDeviceId();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/offer18/track-click'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'offerId': offerId,
          'deviceId': resolvedDeviceId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      }
      throw Exception(data['error'] ?? data['message'] ?? 'Failed to track click');
    } catch (e) {
      throw Exception('Error tracking click: $e');
    }
  }

  /// Get click history for user
  Future<List<dynamic>> getClickHistory(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/offer18/clicks/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['clicks'] ?? [];
      } else {
        throw Exception('Failed to load click history');
      }
    } catch (e) {
      throw Exception('Error fetching click history: $e');
    }
  }

  /// Get wallet breakdown (coins, gems, cash)
  Future<Map<String, dynamic>> getWalletBreakdown(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/offer18/wallet/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['wallet'] ?? {'coins': 0, 'gems': 0, 'cash': 0};
      } else {
        throw Exception('Failed to load wallet breakdown');
      }
    } catch (e) {
      throw Exception('Error fetching wallet breakdown: $e');
    }
  }

  /// Get transaction history
  Future<List<dynamic>> getTransactionHistory(
    int userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/offer18/transactions/$userId?limit=$limit&offset=$offset',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transactions'] ?? [];
      } else {
        throw Exception('Failed to load transaction history');
      }
    } catch (e) {
      throw Exception('Error fetching transaction history: $e');
    }
  }

  /// Get active banners for home screen
  Future<List<dynamic>> getBanners() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/offer18/banners'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['banners'] ?? [];
      } else {
        throw Exception('Failed to load banners');
      }
    } catch (e) {
      throw Exception('Error fetching banners: $e');
    }
  }

  // Scratch Card Methods

  /// Get random scratchable offer for user
  Future<Map<String, dynamic>> getScratchableOffer(int userId) async {
    try {
      final offers = await getUserOffers(userId);

      if (offers.isEmpty) {
        return {
          'success': false,
          'message': 'No offers available',
        };
      }

      Map<String, dynamic>? selectedOffer;

      for (final rawOffer in offers) {
        final offer = Map<String, dynamic>.from(rawOffer as Map);
        final isCompleted =
            offer['is_completed'] == true || offer['is_completed'] == 1;
        final isScratched =
            offer['is_scratched'] == true || offer['is_scratched'] == 1;

        if (isScratched && !isCompleted) {
          selectedOffer = offer;
          break;
        }
      }

      selectedOffer ??= offers
          .cast<Map>()
          .map((offer) => Map<String, dynamic>.from(offer))
          .firstWhere(
            (offer) =>
                offer['is_scratched'] != true && offer['is_scratched'] != 1,
            orElse: () => <String, dynamic>{},
          );

      if (selectedOffer.isEmpty) {
        selectedOffer = offers
            .cast<Map>()
            .map((offer) => Map<String, dynamic>.from(offer))
            .first;
      }

      return {
        'success': true,
        'offer': selectedOffer,
      };
    } catch (e) {
      throw Exception('Error getting scratchable offer: $e');
    }
  }

  /// Mark offer as scratched
  Future<Map<String, dynamic>> markOfferScratched(
    int userId,
    int offerId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/scratch-offer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'offer_id': offerId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      }
      throw Exception(data['message'] ?? 'Failed to mark offer as scratched');
    } catch (e) {
      throw Exception('Error marking offer as scratched: $e');
    }
  }

  /// Get offer details with steps
  Future<Map<String, dynamic>> getOfferDetails(int offerId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/offers/$offerId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get offer details');
      }
    } catch (e) {
      throw Exception('Error getting offer details: $e');
    }
  }

  /// Upload a task screenshot for an offer that requires verification.
  /// [imageBase64DataUrl] must be a full data URL (e.g. "data:image/png;base64,...").
  Future<Map<String, dynamic>> uploadTaskSubmission({
    required int userId,
    required int offerId,
    required List<String> imageBase64DataUrls,
    required String contactInfo,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/offers/$offerId/submissions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image_files': imageBase64DataUrls,
        // Backwards-compat with older backends expecting a single image
        'image_file': imageBase64DataUrls.isNotEmpty ? imageBase64DataUrls.first : null,
        'contact_info': contactInfo,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return data is Map<String, dynamic> ? data : {};
    }
    throw Exception(data is Map && data['message'] != null
        ? data['message']
        : 'Upload failed (${response.statusCode})');
  }

  /// Fetch the latest submission status for a user+offer (null if none).
  Future<Map<String, dynamic>?> getTaskSubmission({
    required int userId,
    required int offerId,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/offers/$offerId/submission'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['submission'] != null) {
        return Map<String, dynamic>.from(data['submission']);
      }
    }
    return null;
  }

  /// Daily check-in
  Future<Map<String, dynamic>> dailyCheckIn(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/wallet/checkin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to check in');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Daily check-in history
  Future<Map<String, dynamic>> getCheckInHistory(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/wallet/checkin-history/$userId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get check-in history');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Request withdrawal
  Future<Map<String, dynamic>> requestWithdrawal({
    required int userId,
    required double amount,
    required String method,
    required String details,
    String? mobile,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/wallet/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
          'method': method,
          'details': details,
          if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Withdrawal request failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePayoutDetails(int userId, String upiId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.userProfileEndpoint}/$userId/payout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'upi_id': upiId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update payout details');
      }
    } catch (e) {
      throw Exception('Error updating payout details: $e');
    }
  }

  // ── Version / Maintenance gate ─────────────────────────────────────────────

  /// Returns maintenance + update state for the given app [version].
  Future<Map<String, dynamic>> versionCheck(String version) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/app/version-check?version=$version'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Version check failed');
  }

  // ── FCM Token registration ─────────────────────────────────────────────────

  Future<void> registerFcmToken(int userId, String token) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      // ignore — non-blocking
    }
  }

  // ── In-app notifications ───────────────────────────────────────────────────

  Future<List<dynamic>> getUserNotifications(int userId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/notifications'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load notifications');
  }

  Future<void> markNotificationRead(int userId, int notificationId) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/notifications/$notificationId/read'),
      );
    } catch (_) {}
  }

  /// Request account deletion — sends a request to admin for review.
  /// [note] is an optional reason supplied by the user.
  Future<Map<String, dynamic>> requestAccountDeletion(
    int userId, {
    String? note,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/request-deactivation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'note': note ?? 'Requested via app'}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Failed to submit deletion request');
  }
}

