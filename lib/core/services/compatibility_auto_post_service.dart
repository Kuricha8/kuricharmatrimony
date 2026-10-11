import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompatibilityAutoPostService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Force auto-posts profile cards for all approved profiles to eligible Tharavadu chats
  static Future<int> forceAutoPostAllApprovedProfiles() async {
    int totalPosted = 0;
    try {
      final profilesRes = await _supabase
          .from('kurichiyar_profiles')
          .select('id, name, photo_url, father_clan_id, mother_clan_id')
          .or(
            'account_status.eq.approved,account_status.eq.APPROVED,account_status.eq.active,account_status.eq.ACTIVE,status.eq.APPROVED,status.eq.approved',
          );

      for (final profile in profilesRes) {
        final String profileId = profile['id'].toString();
        final count = await autoPostProfileCardToEligibleTharavads(
          profileId,
          candidateData: profile,
        );
        totalPosted += count;
      }
    } catch (e) {
      debugPrint('Error forceAutoPostAllApprovedProfiles: $e');
    }
    return totalPosted;
  }

  /// Posts a profile card for a single approved profile into all eligible Tharavadu chats
  static Future<int> autoPostProfileCardToEligibleTharavads(
    String profileId, {
    Map<String, dynamic>? candidateData,
  }) async {
    int postsCount = 0;
    try {
      final Map<String, dynamic>? candidateRes =
          candidateData ??
          await _supabase
              .from('kurichiyar_profiles')
              .select(
                'id, name, photo_url, tharavad_id, father_clan_id, mother_clan_id',
              )
              .eq('id', profileId)
              .maybeSingle();

      if (candidateRes == null) return 0;

      final candidateTharavadId =
          (candidateRes['tharavad_id'] ??
                  candidateRes['father_clan_id'] ??
                  candidateRes['mother_clan_id'])
              as int?;
      final fClan = candidateRes['father_clan_id'] as int?;
      final mClan = candidateRes['mother_clan_id'] as int?;

      if (candidateTharavadId == null) return 0;

      final clansRes = await _supabase
          .from('kurichiyar_clans')
          .select('id, name');

      for (final clan in clansRes) {
        final targetClanId = clan['id'] as int;

        // Skip candidate's own father/mother/candidate tharavads (incompatible clans)
        if (targetClanId == fClan ||
            targetClanId == mClan ||
            targetClanId == candidateTharavadId)
  { continue; }

        bool isCompatible = false;
        try {
          final rpcRes = await _supabase.rpc(
            'check_tharavad_compatibility',
            params: {
              'candidate_tharavad_id': candidateTharavadId,
              'target_chat_tharavad_id': targetClanId,
            },
          );
          isCompatible = (rpcRes == true);
        } catch (e) {
          try {
            final rpcRes2 = await _supabase.rpc(
              'check_tharavad_compatibility',
              params: {
                'candidate_tharavad_id': candidateTharavadId.toString(),
                'target_chat_tharavad_id': targetClanId.toString(),
              },
            );
            isCompatible = (rpcRes2 == true);
          } catch (e2) {
            debugPrint(
              'RPC check_tharavad_compatibility error for clan $targetClanId: $e2',
            );
          }
        }

        // Fallback exogamous rule check: target clan cannot be user's father or mother clan
        if (!isCompatible) {
          isCompatible = (targetClanId != fClan && targetClanId != mClan);
        }

        if (isCompatible) {
          final postPayload = {
            'clan_id': targetClanId,
            'user_id': profileId,
            'sender_name': candidateRes['name'] ?? 'അംഗം',
            'sender_photo': candidateRes['photo_url'] ?? '',
            'text': 'അഡ്മിൻ അനുമതി നൽകിയ പുതിയ പ്രൊഫൈൽ കാർഡ്!',
            'message_type': 'PROFILE_CARD',
            'is_profile_card': true,
            'shared_profile_id': profileId,
            'candidate_taravad_id': candidateTharavadId,
            'metadata': {'shared_profile_id': profileId},
            'created_at': DateTime.now().toIso8601String(),
          };

          try {
            await _supabase
                .from('taravad_messages')
                .insert(postPayload)
                .timeout(const Duration(seconds: 5));
            postsCount++;
          } catch (_) {
            try {
              await _supabase
                  .from('taravad_posts')
                  .insert(postPayload)
                  .timeout(const Duration(seconds: 5));
              postsCount++;
            } catch (_) {
              try {
                await _supabase
                    .from('clan_feed_posts')
                    .insert(postPayload)
                    .timeout(const Duration(seconds: 5));
                postsCount++;
              } catch (err) {
                debugPrint('Error inserting profile card into feed: $err');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error autoPostProfileCardToEligibleTharavads: $e');
    }
    return postsCount;
  }
}
