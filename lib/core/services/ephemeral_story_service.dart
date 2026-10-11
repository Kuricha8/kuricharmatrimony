import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_model.dart';
import '../services/notification_manager.dart';

class EphemeralStoryService {
  static final EphemeralStoryService instance = EphemeralStoryService._();
  EphemeralStoryService._();

  final _supabase = Supabase.instance.client;

  /// Fetch active story feed aggregated by author via RPC get_active_story_feed
  Future<List<AuthorStoryTray>> fetchStoryFeed() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      final response = await _supabase.rpc(
        'get_active_story_feed',
        params: {'current_user_id': userId},
      );

      if (response is List) {
        return response
            .map(
              (item) =>
                  AuthorStoryTray.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[EphemeralStoryService] error fetching story feed: $e');
      return [];
    }
  }

  /// Record story view (idempotent)
  Future<void> recordStoryView(String storyId, {bool ghostMode = false}) async {
    final viewerId = _supabase.auth.currentUser?.id;
    if (viewerId == null || viewerId.isEmpty) return;

    try {
      await _supabase.from('story_views').upsert({
        'story_id': storyId,
        'viewer_id': viewerId,
        'is_ghost_mode': ghostMode,
        'viewed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'story_id, viewer_id');
    } catch (e) {
      debugPrint('[EphemeralStoryService] view log error: $e');
    }
  }

  /// Submit interaction (Poll vote, reaction, countdown RSVP, chain response)
  Future<void> submitInteraction({
    required String storyId,
    required String interactionType,
    required Map<String, dynamic> payload,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    try {
      await _supabase.from('story_interactions').insert({
        'story_id': storyId,
        'user_id': userId,
        'interaction_type': interactionType,
        'payload': payload,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[EphemeralStoryService] interaction submit error: $e');
    }
  }

  /// Immediately burn/purge view_once story upon completion or dismissal
  Future<void> burnViewOnceStory(String storyId) async {
    try {
      await _supabase.from('stories').delete().eq('id', storyId);
      debugPrint('[EphemeralStoryService] burned view_once story: $storyId');
    } catch (e) {
      debugPrint('[EphemeralStoryService] burn story error: $e');
    }
  }

  /// Publish new story
  Future<bool> publishStory({
    required StoryType storyType,
    required List<String> mediaUrls,
    String? mediaType,
    List<int>? mediaDurationsMs,
    String? caption,
    Map<String, dynamic>? metadata,
    String? targetRoute,
    PrivacyType privacyType = PrivacyType.public,
    List<String>? privacyWhitelist,
    List<String>? privacyBlacklist,
    DateTime? expiresAt,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception(
        'User is not authenticated (userId is null). Please log in to publish.',
      );
    }

    try {
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
          case StoryType.bioCard:
            return 'bio_card';
          case StoryType.audioWave:
            return 'audio_wave';
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

      // Fetch user profile first to get maternal clan ID for insertion and FCM
      final profileRes = await _supabase
          .from('kurichiyar_profiles')
          .select('full_name, mother_tharavadu')
          .eq('id', userId)
          .maybeSingle();
      final maternalClanId = profileRes != null
          ? profileRes['mother_tharavadu']
          : null;

      final payloadMetadata = Map<String, dynamic>.from(metadata ?? {});
      payloadMetadata['media_type'] = mediaType ?? 'image';
      if (maternalClanId != null)
  { payloadMetadata['maternal_clan_id'] = maternalClanId; }

      final payload = {
        'user_id': userId,
        'story_type': typeToStr(storyType),
        'media_urls': mediaUrls,
        'media_durations_ms': mediaDurationsMs ?? [5000],
        'metadata': payloadMetadata,
        'privacy_type': privacyToStr(privacyType),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'expires_at':
            (expiresAt ?? DateTime.now().add(const Duration(hours: 24)))
                .toUtc()
                .toIso8601String(),
      };
      if (caption != null) payload['caption'] = caption;
      if (targetRoute != null) payload['target_route'] = targetRoute;
      if (privacyWhitelist != null)
  { payload['privacy_whitelist'] = privacyWhitelist; }
      if (privacyBlacklist != null)
  { payload['privacy_blacklist'] = privacyBlacklist; }

      debugPrint('SUBMITTED STORY PAYLOAD: $payload');

      try {
        await _supabase.from('stories').insert(payload);
      } on PostgrestException catch (e) {
        debugPrint(
          '[EphemeralStoryService] DB Insert PostgrestException on "stories" table: code=${e.code} msg=${e.message} details=${e.details}',
        );
        try {
          // Fallback insert to tharavad_stories
          final fallbackPayload = {
            'creator_id': userId,
            'user_id': userId,
            'clan_id': maternalClanId ?? 0,
            'content': caption ?? '',
            'media_url': mediaUrls.isNotEmpty ? mediaUrls.first : null,
            'media_type': typeToStr(storyType),
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'expires_at':
                (expiresAt ?? DateTime.now().add(const Duration(hours: 24)))
                    .toUtc()
                    .toIso8601String(),
          };
          await _supabase.from('tharavad_stories').insert(fallbackPayload);
          debugPrint(
            '[EphemeralStoryService] Successfully inserted via tharavad_stories fallback!',
          );
        } catch (fallbackError) {
          debugPrint(
            '[EphemeralStoryService] Fallback insert to tharavad_stories also failed: $fallbackError',
          );
          // Re-throw so caller gets notified or handled
          rethrow;
        }
      }

      // Trigger FCM push notification to maternal Tharavadu members
      try {
        if (profileRes != null && maternalClanId != null) {
          final userName = profileRes['name'] ?? 'A member';

          final clanMembersRes = await _supabase
              .from('kurichiyar_profiles')
              .select('fcm_token')
              .eq('mother_tharavadu', maternalClanId)
              .not('fcm_token', 'is', null)
              .neq('id', userId);
          final tokens = List<Map<String, dynamic>>.from(clanMembersRes)
              .map((r) => r['fcm_token']?.toString() ?? '')
              .where((t) => t.isNotEmpty)
              .toList();

          if (tokens.isNotEmpty) {
            await NotificationManager.instance.sendPush(
              tokens: tokens,
              title: 'New Status',
              body: '$userName added a new status!',
            );
          }
        }
      } catch (e) {
        debugPrint('FCM status trigger error: $e');
      }

      return true;
    } catch (e) {
      debugPrint('[EphemeralStoryService] publish story error: $e');
      rethrow;
    }
  }
}
