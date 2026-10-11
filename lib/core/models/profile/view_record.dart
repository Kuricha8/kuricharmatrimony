import '../enums.dart';

class ViewRecord {
  final String viewerIdHash;
  final int viewerClanId;
  final Gender viewerGender;
  final int viewerAge;
  final String viewerRegion;
  final DateTime viewedAt;

  const ViewRecord({
    required this.viewerIdHash,
    required this.viewerClanId,
    required this.viewerGender,
    required this.viewerAge,
    required this.viewerRegion,
    required this.viewedAt,
  });

  factory ViewRecord.fromMap(Map<String, dynamic> map) {
    return ViewRecord(
      viewerIdHash: map['viewerIdHash'] ?? '',
      viewerClanId: map['viewerClanId'] ?? 0,
      viewerGender: map['viewerGender'] == 'female' ? Gender.female : Gender.male,
      viewerAge: map['viewerAge'] ?? 0,
      viewerRegion: map['viewerRegion'] ?? '',
      viewedAt: map['viewedAt'] != null ? DateTime.parse(map['viewedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'viewerIdHash': viewerIdHash,
      'viewerClanId': viewerClanId,
      'viewerGender': viewerGender.name,
      'viewerAge': viewerAge,
      'viewerRegion': viewerRegion,
      'viewedAt': viewedAt.toIso8601String(),
    };
  }
}

class ProfileVisitor {
  final String visitorId;
  final String visitorName;
  final String visitorPhotoUrl;
  final int visitorClanId;
  final DateTime visitedAt;

  const ProfileVisitor({
    required this.visitorId,
    required this.visitorName,
    required this.visitorPhotoUrl,
    required this.visitorClanId,
    required this.visitedAt,
  });

  factory ProfileVisitor.fromMap(Map<String, dynamic> map) {
    return ProfileVisitor(
      visitorId: map['visitor_id'] ?? '',
      visitorName: map['visitor_name'] ?? 'Unknown',
      visitorPhotoUrl: map['visitor_photo_url'] ?? '',
      visitorClanId: map['visitor_clan_id'] ?? 0,
      visitedAt: map['visited_at'] != null ? DateTime.parse(map['visited_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitor_id': visitorId,
      'visitor_name': visitorName,
      'visitor_photo_url': visitorPhotoUrl,
      'visitor_clan_id': visitorClanId,
      'visited_at': visitedAt.toIso8601String(),
    };
  }
}
