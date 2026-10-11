enum StoryType {
  standard,
  beforeAfter,
  countdown,
  poll,
  chainRoot,
  viewOnce,
  audioWave,
  bioCard,
}

enum PrivacyType { public, contactsOnly, closeCircle, excluded, geoFenced }

class EphemeralStory {
  final String id;
  final String userId;
  final StoryType storyType;
  final String mediaType;
  final List<String> mediaUrls;
  final String? thumbnailUrl;
  final List<int> mediaDurationsMs;
  final String? caption;
  final Map<String, dynamic> metadata;
  final PrivacyType privacyType;
  final List<String>? privacyWhitelist;
  final List<String>? privacyBlacklist;
  final String? targetRoute;
  final bool isSponsored;
  final int priorityWeight;
  final bool isFlagged;
  final DateTime createdAt;
  final DateTime expiresAt;

  EphemeralStory({
    required this.id,
    required this.userId,
    required this.storyType,
    required this.mediaType,
    required this.mediaUrls,
    this.thumbnailUrl,
    this.mediaDurationsMs = const [5000],
    this.caption,
    required this.metadata,
    required this.privacyType,
    this.privacyWhitelist,
    this.privacyBlacklist,
    this.targetRoute,
    this.isSponsored = false,
    this.priorityWeight = 0,
    this.isFlagged = false,
    required this.createdAt,
    required this.expiresAt,
  });

  factory EphemeralStory.fromMap(Map<String, dynamic> map) {
    StoryType parseStoryType(String? val) {
      switch (val) {
        case 'before_after':
          return StoryType.beforeAfter;
        case 'countdown':
          return StoryType.countdown;
        case 'poll':
          return StoryType.poll;
        case 'chain_root':
          return StoryType.chainRoot;
        case 'view_once':
          return StoryType.viewOnce;
        case 'audio_wave':
          return StoryType.audioWave;
        case 'bio_card':
          return StoryType.bioCard;
        default:
          return StoryType.standard;
      }
    }

    PrivacyType parsePrivacyType(String? val) {
      switch (val) {
        case 'contacts_only':
          return PrivacyType.contactsOnly;
        case 'close_circle':
          return PrivacyType.closeCircle;
        case 'excluded':
          return PrivacyType.excluded;
        case 'geo_fenced':
          return PrivacyType.geoFenced;
        default:
          return PrivacyType.public;
      }
    }

    final rawUrls = map['media_urls'];
    List<String> urls = [];
    if (rawUrls is List) {
      urls = rawUrls.map((e) => e.toString()).toList();
    } else if (rawUrls is String) {
      urls = [rawUrls];
    }

    final rawDurations = map['media_durations_ms'];
    List<int> durations = [5000];
    if (rawDurations is List) {
      durations = rawDurations
          .map((e) => int.tryParse(e.toString()) ?? 5000)
          .toList();
    }

    final metadata = Map<String, dynamic>.from(map['metadata'] ?? {});
    return EphemeralStory(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      storyType: parseStoryType(map['story_type']?.toString()),
      mediaType:
          map['media_type']?.toString() ??
          metadata['media_type']?.toString() ??
          'image',
      mediaUrls: urls,
      thumbnailUrl: metadata['thumbnail_url']?.toString(),
      mediaDurationsMs: durations,
      caption: map['caption']?.toString(),
      metadata: metadata,
      privacyType: parsePrivacyType(map['privacy_type']?.toString()),
      privacyWhitelist: map['privacy_whitelist'] != null
          ? List<String>.from(map['privacy_whitelist'])
          : null,
      privacyBlacklist: map['privacy_blacklist'] != null
          ? List<String>.from(map['privacy_blacklist'])
          : null,
      targetRoute: map['target_route']?.toString(),
      isSponsored: map['is_sponsored'] == true,
      priorityWeight:
          int.tryParse(map['priority_weight']?.toString() ?? '0') ?? 0,
      isFlagged: map['is_flagged'] == true,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt:
          DateTime.tryParse(map['expires_at']?.toString() ?? '') ??
          DateTime.now().add(const Duration(hours: 24)),
    );
  }

  Map<String, dynamic> toMap() {
    String typeToStr(StoryType t) {
      switch (t) {
        case StoryType.beforeAfter:
          return 'before_after';
        case StoryType.countdown:
          return 'countdown';
        case StoryType.poll:
          return 'poll';
        case StoryType.chainRoot:
          return 'chain_root';
        case StoryType.viewOnce:
          return 'view_once';
        case StoryType.audioWave:
          return 'audio_wave';
        case StoryType.bioCard:
          return 'bio_card';
        default:
          return 'standard';
      }
    }

    String privacyToStr(PrivacyType p) {
      switch (p) {
        case PrivacyType.contactsOnly:
          return 'contacts_only';
        case PrivacyType.closeCircle:
          return 'close_circle';
        case PrivacyType.excluded:
          return 'excluded';
        case PrivacyType.geoFenced:
          return 'geo_fenced';
        default:
          return 'public';
      }
    }

    return {
      'user_id': userId,
      'story_type': typeToStr(storyType),
      'media_type': mediaType,
      'media_urls': mediaUrls,
      'media_durations_ms': mediaDurationsMs,
      'caption': caption,
      'metadata': metadata,
      'privacy_type': privacyToStr(privacyType),
      'privacy_whitelist': privacyWhitelist,
      'privacy_blacklist': privacyBlacklist,
      'is_sponsored': isSponsored,
      'priority_weight': priorityWeight,
      'is_flagged': isFlagged,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

class AuthorStoryTray {
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final bool hasUnseen;
  final DateTime latestStoryTime;
  final List<EphemeralStory> stories;

  AuthorStoryTray({
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.hasUnseen,
    required this.latestStoryTime,
    required this.stories,
  });

  factory AuthorStoryTray.fromMap(Map<String, dynamic> map) {
    final rawStories = map['story_tray'];
    List<EphemeralStory> parsedStories = [];
    if (rawStories is List) {
      parsedStories = rawStories
          .map((s) => EphemeralStory.fromMap(Map<String, dynamic>.from(s)))
          .toList();
    }

    return AuthorStoryTray(
      authorId: map['author_id']?.toString() ?? '',
      authorName: map['author_name']?.toString() ?? 'User',
      authorAvatar: map['author_avatar']?.toString(),
      hasUnseen: map['has_unseen'] == true,
      latestStoryTime:
          DateTime.tryParse(map['latest_story_time']?.toString() ?? '') ??
          DateTime.now(),
      stories: parsedStories,
    );
  }
}

class PollOption {
  final int id;
  final String text;
  int votes;

  PollOption({required this.id, required this.text, this.votes = 0});

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      text: map['text']?.toString() ?? '',
      votes: int.tryParse(map['votes']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'votes': votes};
}
