import 'enums.dart';

class AppNotification {
  final String id;
  final String userId; // Empty if broadcast
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? senderImageUrl;
  final String? senderName;
  final int? senderAge;
  final String? senderClan;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.senderImageUrl,
    this.senderName,
    this.senderAge,
    this.senderClan,
  });

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    String? senderImageUrl,
    String? senderName,
    int? senderAge,
    String? senderClan,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      senderName: senderName ?? this.senderName,
      senderAge: senderAge ?? this.senderAge,
      senderClan: senderClan ?? this.senderClan,
    );
  }
}

class Announcement {
  final String id;
  final String message;
  final String? imageUrl;
  final String targetType;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.message,
    this.imageUrl,
    required this.targetType,
    required this.createdAt,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id']?.toString() ?? '',
      message: map['message'] ?? '',
      imageUrl: map['image_url'],
      targetType: map['target_type'] ?? 'all',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }
}

class CommunityHistory {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime date;

  CommunityHistory({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.date,
  });

  factory CommunityHistory.fromMap(Map<String, dynamic> map) {
    return CommunityHistory(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['image_url'],
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
    );
  }
}
