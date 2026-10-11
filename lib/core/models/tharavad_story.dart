import 'enums.dart';

class TharavadStory {
  final String id;
  final String creatorId;
  final int clanId;
  final String content;
  final String? mediaUrl;
  final List<String> mediaUrls;
  final String? postTypeRaw;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> likes;
  final List<String> views;

  const TharavadStory({
    required this.id,
    required this.creatorId,
    required this.clanId,
    required this.content,
    this.mediaUrl,
    this.mediaUrls = const [],
    this.postTypeRaw,
    required this.createdAt,
    required this.expiresAt,
    this.likes = const [],
    this.views = const [],
  });

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  Duration get timeRemaining {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  PostType get postType {
    if (postTypeRaw != null && postTypeRaw!.toUpperCase() == 'BEFORE_AFTER') {
      return PostType.photo;
    }
    if ((mediaUrl == null || mediaUrl!.isEmpty) && mediaUrls.isEmpty)
  { return PostType.text; }
    final urlStr = (mediaUrl ?? (mediaUrls.isNotEmpty ? mediaUrls.first : ''))
        .toLowerCase();
    if (urlStr.contains('.mp4') ||
        urlStr.contains('.mov') ||
        urlStr.contains('.webm') ||
        urlStr.contains('video')) {
      return PostType.video;
    }
    return PostType.photo;
  }

  bool get isBeforeAfter =>
      postTypeRaw != null && postTypeRaw!.toUpperCase() == 'BEFORE_AFTER' ||
      mediaUrls.length > 1;
  bool get isVideo => postType == PostType.video;
  bool get isPhoto => postType == PostType.photo;

  TharavadStory copyWith({
    String? id,
    String? creatorId,
    int? clanId,
    String? content,
    String? mediaUrl,
    List<String>? mediaUrls,
    String? postTypeRaw,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? likes,
    List<String>? views,
  }) {
    return TharavadStory(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      clanId: clanId ?? this.clanId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      postTypeRaw: postTypeRaw ?? this.postTypeRaw,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      likes: likes ?? this.likes,
      views: views ?? this.views,
    );
  }

  factory TharavadStory.fromMap(Map<String, dynamic> map) {
    int parsedClanId = 0;
    if (map['clan_id'] != null) {
      parsedClanId = int.tryParse(map['clan_id'].toString()) ?? 0;
    }

    DateTime created = DateTime.now();
    if (map['created_at'] != null) {
      created =
          DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now();
    }

    DateTime expires = created.add(const Duration(hours: 24));
    if (map['expires_at'] != null) {
      expires = DateTime.tryParse(map['expires_at'].toString()) ?? expires;
    }

    List<String> parsedMediaUrls = [];
    if (map['media_urls'] is List) {
      parsedMediaUrls = (map['media_urls'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (map['media_url'] != null &&
        map['media_url'].toString().isNotEmpty) {
      parsedMediaUrls = [map['media_url'].toString()];
    }

    return TharavadStory(
      id: map['id']?.toString() ?? '',
      creatorId:
          map['creator_id']?.toString() ?? map['user_id']?.toString() ?? '',
      clanId: parsedClanId,
      content: map['content']?.toString() ?? map['caption']?.toString() ?? '',
      mediaUrl:
          map['media_url']?.toString() ??
          (parsedMediaUrls.isNotEmpty ? parsedMediaUrls.first : null),
      mediaUrls: parsedMediaUrls,
      postTypeRaw: map['post_type']?.toString(),
      createdAt: created,
      expiresAt: expires,
      likes: map['likes'] != null ? List<String>.from(map['likes']) : [],
      views: map['views'] != null ? List<String>.from(map['views']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creator_id': creatorId,
      'clan_id': clanId,
      'content': content,
      'media_url': mediaUrl,
      'media_urls': mediaUrls,
      'post_type': postTypeRaw,
    };
  }
}
