import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/clan_feed/tharavadu_list.dart';

class TharavaduLikesSyncService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Aggregates all likes across all posts/messages for a given clan
  /// and automatically updates the global like count in `clans` / `tharavadus` / `kurichiyar_clans` / `tharavad_master`.
  static Future<int> syncClanTotalLikes(int clanId) async {
    if (clanId <= 0) return 0;

    int totalLikes = 0;

    try {
      // 1. Count likes from `clan_feed_posts`
      try {
        final feedPosts = await _supabase
            .from('clan_feed_posts')
            .select('id, reactions, likes')
            .eq('clan_id', clanId.toString());

        for (final row in feedPosts) {
          if (row['reactions'] is Map) {
            totalLikes += (row['reactions'] as Map).length;
          } else if (row['likes'] is List) {
            totalLikes += (row['likes'] as List).length;
          }
        }
      } catch (e) {
        debugPrint('TharavaduLikesSyncService clan_feed_posts query note: $e');
      }

      // 2. Count likes from `post_likes` / `tharavad_post_likes` / `taravad_post_likes` for taravad messages/posts
      try {
        final messages = await _supabase
            .from('taravad_messages')
            .select('id')
            .eq('clan_id', clanId.toString());

        final postIds = messages.map((m) => m['id'].toString()).toList();
        if (postIds.isNotEmpty) {
          try {
            final likesRes = await _supabase
                .from('post_likes')
                .select('id')
                .inFilter('post_id', postIds);
            totalLikes += (likesRes as List).length;
          } catch (_) {
            try {
              final likesRes2 = await _supabase
                  .from('tharavad_post_likes')
                  .select('id')
                  .inFilter('post_id', postIds);
              totalLikes += (likesRes2 as List).length;
            } catch (_) {
              try {
                final likesRes3 = await _supabase
                    .from('taravad_post_likes')
                    .select('id')
                    .inFilter('post_id', postIds);
                totalLikes += (likesRes3 as List).length;
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        debugPrint('TharavaduLikesSyncService taravad_messages query note: $e');
      }

      // 3. Count likes from `tharavadu_posts` / `taravad_posts`
      try {
        final posts = await _supabase
            .from('tharavadu_posts')
            .select('id, likes_count')
            .eq('clan_id', clanId.toString());

        for (final p in posts) {
          totalLikes += (p['likes_count'] as int?) ?? 0;
        }
      } catch (_) {
        try {
          final posts = await _supabase
              .from('taravad_posts')
              .select('id, likes_count')
              .eq('clan_id', clanId.toString());

          for (final p in posts) {
            totalLikes += (p['likes_count'] as int?) ?? 0;
          }
        } catch (_) {}
      }

      debugPrint(
        'TharavaduLikesSyncService: Total aggregated likes for Clan $clanId = $totalLikes',
      );

      // 4. Update the global like count in database tables
      final updatePayload = {
        'likes_count': totalLikes,
        'total_likes': totalLikes,
      };

      // Table 1: `clans`
      try {
        await _supabase
            .from('clans')
            .update(updatePayload)
            .eq('id', clanId.toString());
      } catch (e) {
        debugPrint('TharavaduLikesSyncService update clans note: $e');
      }

      // Table 2: `tharavadus` / `tharavad_master`
      try {
        await _supabase
            .from('tharavad_master')
            .update(updatePayload)
            .eq('id', clanId.toString());
      } catch (_) {
        try {
          await _supabase
              .from('tharavadus')
              .update(updatePayload)
              .eq('id', clanId.toString());
        } catch (_) {}
      }

      // Table 3: `kurichiyar_clans`
      try {
        await _supabase
            .from('kurichiyar_clans')
            .update(updatePayload)
            .eq('id', clanId.toString());
      } catch (_) {}

      // 5. Update in-memory state in TharavaduService
      final clan = getClanById(clanId);
      if (clan != null) {
        TharavaduService.instance.addOrUpdateClanLocally(clan);
      }

      return totalLikes;
    } catch (e) {
      debugPrint('TharavaduLikesSyncService error: $e');
      return totalLikes;
    }
  }
}
