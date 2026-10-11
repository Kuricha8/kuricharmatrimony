import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kurichiyar_matrimony/core/models/models.dart';

class TharavadPhotoService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Scans all feed photos for a specific clan, calculates the highest likes,
  /// and updates the Tharavad's main image dynamically.
  static Future<void> updateTharavadMainPhoto(int clanId) async {
    try {
      // 1. Fetch all posts for this clan that have an image
      final response = await _supabase
          .from('clan_feed_posts')
          .select()
          .eq('clan_id', clanId)
          .eq('is_profile_photo', true)
          .not('media_url', 'is', null);

      if (response.isEmpty) {
        return; // No photos exist for this Tharavad
      }

      // 2. Parse posts to identify the one with the highest number of likes
      String? winningPhotoUrl;
      int maxLikes = -1;

      for (var row in response) {
        try {
          final post = StatusPost.fromMap(row);

          // Ensure it's a photo post and has a valid URL
          if (post.feedPhotoUrl != null && post.feedPhotoUrl!.isNotEmpty) {
            final likeCount = post.likes.length;

            if (likeCount > maxLikes) {
              maxLikes = likeCount;
              winningPhotoUrl = post.feedPhotoUrl;
            }
          }
        } catch (e) {
          debugPrint('Error parsing StatusPost in photo selection: $e');
        }
      }

      // 3. Update the tharavad_master table with the winning photo
      if (winningPhotoUrl != null) {
        await _supabase
            .from('tharavad_master')
            .update({'image_url': winningPhotoUrl})
            .eq('id', clanId);

        debugPrint(
          'Tharavad $clanId main photo updated to: $winningPhotoUrl (Likes: $maxLikes)',
        );
      }
    } catch (e) {
      debugPrint('Error in updateTharavadMainPhoto: $e');
    }
  }
}
