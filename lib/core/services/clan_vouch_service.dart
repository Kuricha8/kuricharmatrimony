import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../utils/mock_data.dart';

class ClanVouchService {
  ClanVouchService._();
  static final ClanVouchService instance = ClanVouchService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if the viewer has already vouched for this candidate
  Future<bool> hasUserVouched(
    String targetProfileId,
    String currentUserId,
  ) async {
    if (targetProfileId.isEmpty || currentUserId.isEmpty) return false;
    try {
      final res = await _supabase
          .from('profile_vouches')
          .select('id')
          .eq('vouched_for', targetProfileId)
          .eq('vouched_by', currentUserId)
          .maybeSingle();
      return res != null;
    } catch (e) {
      debugPrint('hasUserVouched check: $e');
      return false;
    }
  }

  /// Get list of vouches for a profile
  Future<List<Map<String, dynamic>>> getVouchesForProfile(
    String targetProfileId,
  ) async {
    try {
      final res = await _supabase
          .from('profile_vouches')
          .select(
            'id, vouched_by, vouch_type, tharavadu_id, notes, created_at, kurichiyar_profiles!vouched_by(full_name, is_elder, avatar_url, tharavadu)',
          )
          .eq('vouched_for', targetProfileId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('Error getting vouches: $e');
      return [];
    }
  }

  /// Submit a new vouch
  Future<bool> submitVouch({
    required String targetProfileId,
    required UserProfile currentUser,
    String? notes,
  }) async {
    final bool isElder = currentUser.isElder;
    final String vouchType = isElder ? 'elder_vouch' : 'member_vouch';
    final int tharavaduId = currentUser.tharavaduId;

    try {
      // 1. Insert vouch record
      await _supabase.from('profile_vouches').insert({
        'vouched_for': targetProfileId,
        'vouched_by': currentUser.id,
        'vouch_type': vouchType,
        'tharavadu_id': tharavaduId,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Fetch updated counts
      final allVouches = await _supabase
          .from('profile_vouches')
          .select('vouch_type')
          .eq('vouched_for', targetProfileId);

      int elderCount = 0;
      int memberCount = 0;

      for (final v in (allVouches as List)) {
        if (v['vouch_type'] == 'elder_vouch') {
          elderCount++;
        } else {
          memberCount++;
        }
      }

      // 3. Compute trust badge
      String trustBadge = 'standard';
      if (elderCount >= 5) {
        trustBadge = 'gold';
      } else if (elderCount >= 2) {
        trustBadge = 'silver';
      }

      // 4. Update profile in database
      await _supabase
          .from('kurichiyar_profiles')
          .update({
            'elder_vouches_count': elderCount,
            'member_vouches_count': memberCount,
            'trust_badge': trustBadge,
          })
          .eq('id', targetProfileId);

      // 5. Update local mock data if present
      final index = MockData().profiles.indexWhere(
        (p) => p.id == targetProfileId,
      );
      if (index != -1) {
        final old = MockData().profiles[index];
        MockData().profiles[index] = old.copyWith(
          elderVouchesCount: elderCount,
          memberVouchesCount: memberCount,
          trustBadge: trustBadge,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error submitting vouch: $e');
      // Fallback local update for testing/offline
      final index = MockData().profiles.indexWhere(
        (p) => p.id == targetProfileId,
      );
      if (index != -1) {
        final old = MockData().profiles[index];
        final newElderCount = old.elderVouchesCount + (isElder ? 1 : 0);
        final newMemberCount = old.memberVouchesCount + (isElder ? 0 : 1);
        final newBadge = newElderCount >= 5
            ? 'gold'
            : (newElderCount >= 2 ? 'silver' : 'standard');
        MockData().profiles[index] = old.copyWith(
          elderVouchesCount: newElderCount,
          memberVouchesCount: newMemberCount,
          trustBadge: newBadge,
        );
      }
      return true;
    }
  }
}
