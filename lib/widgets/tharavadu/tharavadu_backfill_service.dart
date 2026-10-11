import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';

class TharavaduBackfillService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Static in-memory profile cache (10-min TTL) ─────────────────────────
  static List<UserProfile>? _profileCache;
  static DateTime? _cacheTime;
  static const _cacheTtl = Duration(minutes: 10);

  /// Invalidate the cache (call when a profile is approved/updated).
  static void invalidateCache() {
    _profileCache = null;
    _cacheTime = null;
  }

  /// Returns true if a profile row belongs to an admin / system / anonymous user
  /// that must never appear as a matrimony profile card in chat feeds.
  static bool _isAdminOrAnonymous(Map<String, dynamic> r) {
    final name = (r['full_name'] ?? r['name'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final role = (r['role'] ?? '').toString().trim().toLowerCase();

    if (role == 'admin' || role == 'moderator' || role == 'superadmin')
  { return true; }
    if (name.isEmpty ||
        name == 'anonymous' ||
        name == 'admin' ||
        name == 'system')
  { return true; }
    return false;
  }

  static Future<List<UserProfile>> fetchApprovedProfiles() async {
    // Return cached result if still fresh
    if (_profileCache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheTtl) {
      return List.unmodifiable(_profileCache!);
    }
    final List<UserProfile> list = [];
    try {
      final res = await _supabase
          .from('kurichiyar_profiles')
          .select(
            'id, full_name, photo_url, father_clan_id, mother_clan_id, age, gender, father_tharavadu, mother_tharavadu, account_status, status, role',
          );

      for (final r in res) {
        // Exclude admin / anonymous users
        if (_isAdminOrAnonymous(r)) continue;

        final isApp =
            r['account_status'].toString().toLowerCase() == 'approved' ||
            r['status'].toString().toLowerCase() == 'approved' ||
            r['account_status'].toString().toLowerCase() == 'active';

        if (isApp) {
          list.add(
            UserProfile(
              id: r['id'].toString(),
              name: r['full_name'] ?? 'അംഗം',
              age: (r['age'] as int?) ?? 24,
              gender: (r['gender'] == 'MALE' || r['gender'] == 'male')
                  ? Gender.male
                  : Gender.female,
              photoUrl: r['photo_url'] ?? '',
              email: '',
              fatherClanId: (r['father_clan_id'] as int?) ?? 0,
              motherClanId: (r['mother_clan_id'] as int?) ?? 0,
              fatherTharavadu: r['father_tharavadu'] ?? 'Kurichiyar',
              motherTharavadu: r['mother_tharavadu'] ?? 'Kurichiyar',
              maritalStatus: MaritalStatus.first,
              isOutOfCaste: false,
            ),
          );
        }
      }
    } catch (_) {}
    // Save to cache
    _profileCache = list;
    _cacheTime = DateTime.now();
    return list;
  }

  static Future<bool> checkTharavadCompatibility(
    int candidateTharavadId,
    int targetTharavadId,
  ) async {
    try {
      final rpcRes = await _supabase.rpc(
        'check_tharavad_compatibility',
        params: {
          'candidate_tharavad_id': candidateTharavadId,
          'target_chat_tharavad_id': targetTharavadId,
        },
      );
      return rpcRes == true;
    } catch (_) {
      return (candidateTharavadId != targetTharavadId);
    }
  }
}
