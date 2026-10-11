import 'package:cloud_firestore/cloud_firestore.dart';

/// Single member who has viewed a status update.
/// Only storing photo and name for registered members as per privacy & schema specs.
class StatusViewer {
  final String uid;
  final String name;
  final String photoUrl;
  final DateTime viewedAt;

  const StatusViewer({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.viewedAt,
  });

  factory StatusViewer.fromMap(Map<String, dynamic> map) {
    DateTime dt = DateTime.now();
    final rawTime = map['viewed_at'];
    if (rawTime is Timestamp) {
      dt = rawTime.toDate();
    } else if (rawTime is String) {
      dt = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else if (rawTime is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(rawTime);
    }

    return StatusViewer(
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? 'അംഗം',
      photoUrl: map['photo_url']?.toString() ?? '',
      viewedAt: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'photo_url': photoUrl,
      'viewed_at': Timestamp.fromDate(viewedAt),
    };
  }
}

/// Aggregated view analytics data for a status story document.
class StatusViewData {
  final int viewCount;
  final int guestViewCount;
  final List<String> viewedByIds;
  final List<StatusViewer> viewers;

  const StatusViewData({
    this.viewCount = 0,
    this.guestViewCount = 0,
    this.viewedByIds = const [],
    this.viewers = const [],
  });

  factory StatusViewData.fromMap(Map<String, dynamic> map) {
    final rawViewCount = map['view_count'];
    final int viewCount = rawViewCount is int
        ? rawViewCount
        : (int.tryParse(rawViewCount?.toString() ?? '0') ?? 0);

    final rawGuestCount = map['guest_view_count'];
    final int guestViewCount = rawGuestCount is int
        ? rawGuestCount
        : (int.tryParse(rawGuestCount?.toString() ?? '0') ?? 0);

    final rawViewedByIds = map['viewed_by_ids'];
    List<String> viewedByIds = [];
    if (rawViewedByIds is List) {
      viewedByIds = rawViewedByIds.map((e) => e.toString()).toList();
    }

    final rawViewers = map['viewers'];
    List<StatusViewer> viewers = [];
    if (rawViewers is List) {
      for (final v in rawViewers) {
        if (v is Map) {
          viewers.add(StatusViewer.fromMap(Map<String, dynamic>.from(v)));
        }
      }
    }

    return StatusViewData(
      viewCount: viewCount,
      guestViewCount: guestViewCount,
      viewedByIds: viewedByIds,
      viewers: viewers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'view_count': viewCount,
      'guest_view_count': guestViewCount,
      'viewed_by_ids': viewedByIds,
      'viewers': viewers.map((v) => v.toMap()).toList(),
    };
  }

  StatusViewData copyWith({
    int? viewCount,
    int? guestViewCount,
    List<String>? viewedByIds,
    List<StatusViewer>? viewers,
  }) {
    return StatusViewData(
      viewCount: viewCount ?? this.viewCount,
      guestViewCount: guestViewCount ?? this.guestViewCount,
      viewedByIds: viewedByIds ?? this.viewedByIds,
      viewers: viewers ?? this.viewers,
    );
  }
}
