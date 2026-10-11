/// Model representing a paid 3D Coin Ad Slot promotion
class CoinAdSlot {
  final String id;
  final String slotPosition; // 'front' | 'back'
  final String userId;
  final String? userName;
  final String imageUrl;
  final double amountPaid;
  final int durationDays;
  final DateTime startsAt;
  final DateTime expiresAt;
  final String status; // 'active', 'waiting', 'expired', 'admin_override'
  final String? paymentId;

  const CoinAdSlot({
    required this.id,
    required this.slotPosition,
    required this.userId,
    this.userName,
    required this.imageUrl,
    this.amountPaid = 200.00,
    this.durationDays = 7,
    required this.startsAt,
    required this.expiresAt,
    this.status = 'active',
    this.paymentId,
  });

  bool get isActive => (status.toLowerCase() == 'active') && !isExpired;
  bool get isWaiting =>
      status.toLowerCase() == 'waiting' || status.toLowerCase() == 'pending';
  bool get isExpired =>
      DateTime.now().isAfter(expiresAt) ||
      status.toLowerCase() == 'expired' ||
      status.toLowerCase() == 'admin_override';

  Duration get timeRemaining => expiresAt.isAfter(DateTime.now())
      ? expiresAt.difference(DateTime.now())
      : Duration.zero;

  String get remainingTimeString {
    final diff = timeRemaining;
    if (diff.isNegative || diff == Duration.zero) return 'Expired';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    if (days > 0) return '$days days $hours hrs left';
    final mins = diff.inMinutes % 60;
    return '$hours hrs $mins mins left';
  }

  factory CoinAdSlot.fromMap(Map<String, dynamic> map) {
    final img =
        map['ad_image_url']?.toString() ??
        map['image_url']?.toString() ??
        map['imageUrl']?.toString() ??
        map['adImageUrl']?.toString() ??
        '';

    final rawStatus =
        (map['status']?.toString() ??
                (map['is_active'] == true ? 'active' : 'inactive'))
            .toLowerCase();

    return CoinAdSlot(
      id: map['id']?.toString() ?? '',
      slotPosition:
          map['slot_position']?.toString() ??
          map['position']?.toString() ??
          'front',
      userId: map['user_id']?.toString() ?? '',
      userName:
          map['user_name']?.toString() ??
          map['kurichiyar_profiles']?['name']?.toString() ??
          map['profiles']?['name']?.toString(),
      imageUrl: img,
      amountPaid: (map['amount_paid'] != null)
          ? double.tryParse(map['amount_paid'].toString()) ?? 200.0
          : 200.0,
      durationDays: (map['duration_days'] != null)
          ? int.tryParse(map['duration_days'].toString()) ?? 7
          : 7,
      startsAt: map['starts_at'] != null
          ? DateTime.tryParse(map['starts_at'].toString()) ?? DateTime.now()
          : (map['created_at'] != null
                ? DateTime.tryParse(map['created_at'].toString()) ??
                      DateTime.now()
                : DateTime.now()),
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'].toString()) ??
                DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
      status: rawStatus,
      paymentId: map['payment_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'slot_position': slotPosition,
      'user_id': userId,
      'image_url': imageUrl,
      'amount_paid': amountPaid,
      'duration_days': durationDays,
      'starts_at': startsAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'status': status,
      'payment_id': paymentId,
    };
  }
}
