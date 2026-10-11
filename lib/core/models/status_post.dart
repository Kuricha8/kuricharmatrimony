import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'enums.dart';
import 'user_profile.dart';

class StatusPost {
  final String id;
  final String creatorId;
  final int clanId;
  final String content;
  final DateTime createdAt;
  final List<String> likes;
  final Map<String, String> reactions;
  final List<String> viewers;
  final List<ViewRecord> views;
  final String? videoUrl;
  final int? videoDuration;
  final String? feedPhotoUrl; // maps to /feed_photos/ storage path
  final String? feedAudioUrl; // maps to /feed_audio/ storage path
  final PostType postType;
  final String? backgroundColor; // Hex color string for text statuses
  final String? textColor; // Hex color string for text statuses
  final bool isProfilePhoto;
  final String? creatorName;
  final String? creatorPhotoUrl;
  final String? creatorTharavadu;

  const StatusPost({
    required this.id,
    required this.creatorId,
    required this.clanId,
    required this.content,
    required this.createdAt,
    this.likes = const [],
    this.reactions = const {},
    this.viewers = const [],
    this.views = const [],
    this.videoUrl,
    this.videoDuration,
    this.feedPhotoUrl,
    this.feedAudioUrl,
    this.postType = PostType.text,
    this.backgroundColor,
    this.textColor,
    this.isProfilePhoto = false,
    this.creatorName,
    this.creatorPhotoUrl,
    this.creatorTharavadu,
  });

  bool get isVideo => postType == PostType.video;
  bool get isPhoto => postType == PostType.photo;
  bool get isAudio => postType == PostType.audio;

  bool get isExpired {
    final now = DateTime.now();
    return now.difference(createdAt).inHours >= 24;
  }

  Duration get timeRemaining {
    final expiry = createdAt.add(const Duration(hours: 24));
    final diff = expiry.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  StatusPost copyWith({
    String? id,
    String? creatorId,
    int? clanId,
    String? content,
    DateTime? createdAt,
    List<String>? likes,
    Map<String, String>? reactions,
    List<String>? viewers,
    List<ViewRecord>? views,
    String? videoUrl,
    int? videoDuration,
    String? feedPhotoUrl,
    String? feedAudioUrl,
    PostType? postType,
    String? backgroundColor,
    String? textColor,
    bool? isProfilePhoto,
    String? creatorName,
    String? creatorPhotoUrl,
    String? creatorTharavadu,
  }) {
    return StatusPost(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      clanId: clanId ?? this.clanId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      reactions: reactions ?? this.reactions,
      viewers: viewers ?? this.viewers,
      views: views ?? this.views,
      videoUrl: videoUrl ?? this.videoUrl,
      videoDuration: videoDuration ?? this.videoDuration,
      feedPhotoUrl: feedPhotoUrl ?? this.feedPhotoUrl,
      feedAudioUrl: feedAudioUrl ?? this.feedAudioUrl,
      postType: postType ?? this.postType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      isProfilePhoto: isProfilePhoto ?? this.isProfilePhoto,
      creatorName: creatorName ?? this.creatorName,
      creatorPhotoUrl: creatorPhotoUrl ?? this.creatorPhotoUrl,
      creatorTharavadu: creatorTharavadu ?? this.creatorTharavadu,
    );
  }

  factory StatusPost.fromMap(Map<String, dynamic> map) {
    String currentField = 'unknown';
    try {
      currentField = 'photo/video/audio/media';
      final photo =
          map['photo_url'] ??
          map['feed_photo_url'] ??
          map['image_url'] ??
          map['imageUrl'];
      final video = map['video_url'] ?? map['videoUrl'];
      final audio = map['audio_url'] ?? map['feed_audio_url'];
      final media = map['media_url'] ?? map['mediaUrl'] ?? map['url'];

      currentField = 'postType';
      final rawType =
          map['status_type'] ??
          map['post_type'] ??
          map['media_type'] ??
          map['type'];
      PostType type = PostType.text;
      if (rawType != null) {
        type = PostType.values.firstWhere(
          (e) => e.name.toLowerCase() == rawType.toString().toLowerCase(),
          orElse: () => PostType.text,
        );
      } else {
        if (video != null) {
          type = PostType.video;
        } else if (photo != null) {
          type = PostType.photo;
        } else if (audio != null) {
          type = PostType.audio;
        }
      }

      currentField = 'effectiveMedia';
      final effectiveMedia = photo ?? video ?? audio ?? media;
      if (type == PostType.text &&
          effectiveMedia != null &&
          effectiveMedia.toString().isNotEmpty) {
        final mediaStr = effectiveMedia.toString().toLowerCase();
        if (mediaStr.contains('.mp4') ||
            mediaStr.contains('.mov') ||
            mediaStr.contains('.webm') ||
            mediaStr.contains('/video')) {
          type = PostType.video;
        } else if (mediaStr.contains('.mp3') ||
            mediaStr.contains('.m4a') ||
            mediaStr.contains('.wav') ||
            mediaStr.contains('.aac') ||
            mediaStr.contains('/audio')) {
          type = PostType.audio;
        } else if (mediaStr.startsWith('http') ||
            mediaStr.contains('.jpg') ||
            mediaStr.contains('.png') ||
            mediaStr.contains('.jpeg') ||
            mediaStr.contains('.webp') ||
            mediaStr.contains('/photo') ||
            mediaStr.contains('/image')) {
          type = PostType.photo;
        }
      }

      currentField = 'creator_id';
      final String creatorId =
          map['creator_id']?.toString() ??
          map['user_id']?.toString() ??
          map['userId']?.toString() ??
          map['author_id']?.toString() ??
          '';

      currentField = 'clan_id';
      int clanId = 0;
      if (map['clan_id'] != null) {
        clanId = int.tryParse(map['clan_id'].toString()) ?? 0;
      } else if (map['tharavad_id'] != null) {
        clanId = int.tryParse(map['tharavad_id'].toString()) ?? 0;
      } else if (map['tharavadu_id'] != null) {
        clanId = int.tryParse(map['tharavadu_id'].toString()) ?? 0;
      } else if (map['mother_clan_id'] != null) {
        clanId = int.tryParse(map['mother_clan_id'].toString()) ?? 0;
      } else if (map['clanId'] != null) {
        clanId = int.tryParse(map['clanId'].toString()) ?? 0;
      }

      currentField = 'content';
      final String contentStr =
          map['text_content'] ?? map['content'] ?? map['caption'] ?? '';
      if (clanId == 0 &&
          contentStr.startsWith('{') &&
          contentStr.endsWith('}')) {
        try {
          final d = jsonDecode(contentStr);
          if (d is Map) {
            clanId =
                int.tryParse(
                  d['clan_id']?.toString() ??
                      d['tharavad_id']?.toString() ??
                      '0',
                ) ??
                0;
          }
        } catch (_) {}
      }

      // Author Profile Details resolution from join or embedded fields
      currentField = 'creatorName & creatorPhotoUrl';
      final authorMap =
          map['author'] ?? map['profiles'] ?? map['kurichiyar_profiles'];
      String? creatorName =
          map['creator_name'] ??
          map['user_name'] ??
          map['author_name'] ??
          (authorMap is Map
              ? (authorMap['full_name'] ?? authorMap['name'])
              : null);
      String? creatorPhotoUrl =
          map['creator_photo_url'] ??
          map['user_avatar'] ??
          map['avatar_url'] ??
          (authorMap is Map
              ? (authorMap['photo_url'] ?? authorMap['avatar_url'])
              : null);
      String? creatorTharavadu =
          map['tharavad_name'] ??
          map['tharavadu_name'] ??
          map['mother_tharavadu'] ??
          (authorMap is Map
              ? (authorMap['tharavadu_name'] ?? authorMap['mother_tharavadu'])
              : null);

      if ((creatorName == null || creatorPhotoUrl == null) &&
          contentStr.startsWith('{') &&
          contentStr.endsWith('}')) {
        try {
          final d = jsonDecode(contentStr);
          if (d is Map) {
            creatorName ??=
                d['author_name']?.toString() ??
                d['creator_name']?.toString() ??
                d['user_name']?.toString();
            creatorPhotoUrl ??=
                d['author_avatar']?.toString() ??
                d['creator_photo_url']?.toString() ??
                d['user_avatar']?.toString();
            creatorTharavadu ??=
                d['tharavad_name']?.toString() ?? d['tharavadu']?.toString();
          }
        } catch (_) {}
      }

      final String? resolvedPhotoUrl =
          photo ?? (type == PostType.photo ? media : null);
      final String? resolvedVideoUrl =
          video ?? (type == PostType.video ? media : null);
      final String? resolvedAudioUrl =
          audio ?? (type == PostType.audio ? media : null);

      currentField = 'likes';
      List<String> likesList = [];
      if (map['likes'] != null && map['likes'] is List) {
        likesList = (map['likes'] as List).map((e) => e.toString()).toList();
      }

      currentField = 'reactions';
      Map<String, String> reactionsMap = {};
      if (map['reactions'] != null && map['reactions'] is Map) {
        reactionsMap = (map['reactions'] as Map).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );
      }

      currentField = 'views';
      List<String> viewersList = [];
      if (map['views'] != null && map['views'] is List) {
        for (var v in (map['views'] as List)) {
          if (v is String) {
            viewersList.add(v);
          } else if (v is Map) {
            viewersList.add(
              v['viewerIdHash']?.toString() ??
                  v['user_id']?.toString() ??
                  v.toString(),
            );
          }
        }
      }

      currentField = 'createdAt';
      DateTime createdAtVal = DateTime.now();
      if (map['created_at'] != null) {
        createdAtVal =
            DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now();
      }

      return StatusPost(
        id: map['id']?.toString() ?? '',
        creatorId: creatorId,
        clanId: clanId,
        content: contentStr,
        createdAt: createdAtVal,
        likes: likesList,
        reactions: reactionsMap,
        viewers: viewersList,
        videoUrl: resolvedVideoUrl,
        videoDuration: map['video_duration'] != null
            ? int.tryParse(map['video_duration'].toString())
            : null,
        feedPhotoUrl: resolvedPhotoUrl,
        feedAudioUrl: resolvedAudioUrl,
        postType: type,
        backgroundColor: map['background_color'] ?? map['bg_color'],
        textColor: map['text_color'],
        isProfilePhoto: map['is_profile_photo'] ?? false,
        creatorName: creatorName,
        creatorPhotoUrl: creatorPhotoUrl,
        creatorTharavadu: creatorTharavadu,
      );
    } catch (e) {
      debugPrint(
        '[DIAGNOSTIC] Error parsing field: $currentField on item ${map['id']}: $e',
      );
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    String? mediaUrl;
    if (postType == PostType.video) {
      mediaUrl = videoUrl;
    } else if (postType == PostType.photo) {
      mediaUrl = feedPhotoUrl;
    } else if (postType == PostType.audio) {
      mediaUrl = feedAudioUrl;
    } else if (postType == PostType.promotion) {
      mediaUrl = 'profile_card';
    }

    return {
      'creator_id': creatorId,
      'clan_id': clanId,
      'text_content': content,
      'media_url': mediaUrl,
      'video_duration': videoDuration,
      'status_type': postType.name,
      'bg_color': backgroundColor,
      'text_color': textColor,
      'reactions': reactions,
      'views': viewers,
      'is_profile_photo': isProfilePhoto,
      'creator_name': creatorName,
      'creator_photo_url': creatorPhotoUrl,
      'tharavad_name': creatorTharavadu,
    };
  }
}

class StatusItem {
  final String id;
  final String userId;
  final String content;
  final String? mediaUrl;
  final String mediaType;
  final DateTime? createdAt;

  StatusItem({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrl,
    required this.mediaType,
    this.createdAt,
  });

  factory StatusItem.fromMap(Map<String, dynamic> map) {
    return StatusItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      content: map['content'] ?? '',
      mediaUrl: map['media_url'],
      mediaType: map['media_type'] ?? 'text',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
