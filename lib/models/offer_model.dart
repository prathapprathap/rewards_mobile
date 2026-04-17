/// Offer model with dynamic tracking link construction and multi-event support.
/// The [getTrackingLink] method injects userId and deviceId as query parameters
/// so that the provider can uniquely identify the conversion.
class Offer {
  final int id;
  final String offerId; // external provider ID
  final String offerName;
  final String? sideLabel;
  final String heading;
  final String? historyName;
  final String baseLink; // offer_url (destination)
  final String? trackingLink; // Offer18 / custom tracking URL (with macros)
  final double amount;
  final String currencyType; // 'cash' | 'coins' | 'gems'
  final String? eventName;
  final String? description;
  final String? imageUrl;
  final String status;
  final List<OfferEvent> events;

  const Offer({
    required this.id,
    required this.offerId,
    required this.offerName,
    this.sideLabel,
    required this.heading,
    this.historyName,
    required this.baseLink,
    this.trackingLink,
    required this.amount,
    this.currencyType = 'cash',
    this.eventName,
    this.description,
    this.imageUrl,
    this.status = 'active',
    this.events = const [],
  });

  /// Generates the tracking URL by injecting [userId] and [deviceId] into
  /// the base link as query parameters. All values are URI-encoded to prevent
  /// broken URLs when the subid contains special characters.
  String getTrackingLink(String userId, String deviceId) {
    final encodedUser = Uri.encodeComponent(userId);
    final encodedDevice = Uri.encodeComponent(deviceId);
    return '$baseLink&subid=$encodedUser&device_id=$encodedDevice';
  }

  /// Resolves the actual URL to open: prefers the tracking link (with macro
  /// substitution) if one is configured, otherwise falls back to the base link
  /// with appended subid / device_id parameters.
  String resolveUrl({
    required String clickId,
    required String userId,
    required String deviceId,
  }) {
    if (trackingLink != null && trackingLink!.isNotEmpty) {
      return trackingLink!
          .replaceAll('{clickid}', clickId)
          .replaceAll('{click_id}', clickId)
          .replaceAll('{user_id}', Uri.encodeComponent(userId))
          .replaceAll('{offer_id}', Uri.encodeComponent(offerId));
    }
    return getTrackingLink(userId, deviceId);
  }

  factory Offer.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'] as List<dynamic>? ?? [];
    return Offer(
      id: (json['id'] as num).toInt(),
      offerId: json['offer_id']?.toString() ?? '',
      offerName: json['offer_name']?.toString() ?? '',
      sideLabel: json['side_label']?.toString(),
      heading: json['heading']?.toString() ?? '',
      historyName: json['history_name']?.toString(),
      baseLink: json['offer_url']?.toString() ?? '',
      trackingLink: json['tracking_link']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currencyType: json['currency_type']?.toString() ?? 'cash',
      eventName: json['event_name']?.toString(),
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      status: json['status']?.toString() ?? 'active',
      events: rawEvents
          .map((e) => OfferEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'offer_id': offerId,
    'offer_name': offerName,
    'side_label': sideLabel,
    'heading': heading,
    'history_name': historyName,
    'offer_url': baseLink,
    'tracking_link': trackingLink,
    'amount': amount,
    'currency_type': currencyType,
    'event_name': eventName,
    'description': description,
    'image_url': imageUrl,
    'status': status,
    'events': events.map((e) => e.toJson()).toList(),
  };

  bool get isActive => status.toLowerCase() == 'active';

  String get currencySymbol {
    switch (currencyType) {
      case 'coins':
        return '🪙';
      case 'gems':
        return '💎';
      default:
        return '₹';
    }
  }
}

/// Represents a single completion milestone for an offer.
/// Multiple [OfferEvent]s allow step-by-step reward progression (e.g. Install →
/// Level 5 → Purchase), each awarding different [points] when the provider fires
/// a postback with the matching [eventId].
class OfferEvent {
  final String eventId; // unique ID sent in postback (e.g. "evt_install")
  final String eventName; // human-readable label  (e.g. "Install App")
  final double points; // reward amount for this event
  final String currencyType; // 'cash' | 'coins' | 'gems'
  final bool isCompleted;
  final DateTime? completedAt;

  const OfferEvent({
    required this.eventId,
    required this.eventName,
    required this.points,
    this.currencyType = 'cash',
    this.isCompleted = false,
    this.completedAt,
  });

  factory OfferEvent.fromJson(Map<String, dynamic> json) {
    return OfferEvent(
      eventId: json['event_id']?.toString() ?? '',
      eventName: json['event_name']?.toString() ?? '',
      points: double.tryParse(json['points']?.toString() ?? '0') ?? 0.0,
      currencyType: json['currency_type']?.toString() ?? 'cash',
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'event_name': eventName,
    'points': points,
    'currency_type': currencyType,
    'is_completed': isCompleted,
    'completed_at': completedAt?.toIso8601String(),
  };

  String get currencySymbol {
    switch (currencyType) {
      case 'coins':
        return '🪙';
      case 'gems':
        return '💎';
      default:
        return '₹';
    }
  }
}
