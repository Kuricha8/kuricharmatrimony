import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/mock_data.dart';

class GlobalFeedHeader extends StatefulWidget {
  const GlobalFeedHeader({super.key});

  @override
  State<GlobalFeedHeader> createState() => _GlobalFeedHeaderState();
}

class _GlobalFeedHeaderState extends State<GlobalFeedHeader> {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _countChannel;
  int _postCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCount();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _countChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtime() {
    try {
      _countChannel = _supabase
          .channel('public:tharavadu_feed_header_count')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tharavadu_feed_posts',
            callback: (payload) => _fetchCount(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tharavadu_posts',
            callback: (payload) => _fetchCount(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'taravad_messages',
            callback: (payload) => _fetchCount(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime count subscription error in GlobalFeedHeader: $e');
    }
  }

  Future<void> _fetchCount() async {
    try {
      final List<Map<String, dynamic>> allFetched = [];

      try {
        final res0 = await _supabase
            .from('tharavadu_feed_posts')
            .select(
              'id, author_id, user_id, visibility, clan_id, tharavadu_id',
            );
        allFetched.addAll(List<Map<String, dynamic>>.from(res0));
      } catch (_) {}

      try {
        final res1 = await _supabase
            .from('tharavadu_posts')
            .select(
              'id, author_id, user_id, visibility, clan_id, tharavadu_id',
            );
        allFetched.addAll(List<Map<String, dynamic>>.from(res1));
      } catch (_) {}

      try {
        final res2 = await _supabase
            .from('taravad_messages')
            .select(
              'id, author_id, user_id, visibility, clan_id, tharavadu_id',
            );
        allFetched.addAll(List<Map<String, dynamic>>.from(res2));
      } catch (_) {}

      final seenIds = <String>{};
      final uniquePosts = <Map<String, dynamic>>[];

      for (final p in allFetched) {
        final id = (p['id'] ?? '').toString();
        if (id.isNotEmpty && !seenIds.contains(id)) {
          seenIds.add(id);
          uniquePosts.add(p);
        }
      }

      final me = MockData().currentUser;
      final myTharavaduId =
          (me?.tharavaduId != 0 ? me?.tharavaduId : me?.motherClanId) ?? 0;
      final myUserId = _supabase.auth.currentUser?.id ?? me?.id ?? '';

      final filteredPosts = uniquePosts.where((p) {
        final pAuthorId = (p['author_id'] ?? p['user_id'] ?? '').toString();
        if (pAuthorId.isNotEmpty && pAuthorId == myUserId) return true;

        final rawVis = (p['visibility'] ?? p['privacy_level'] ?? 'public')
            .toString()
            .toLowerCase()
            .trim();
        String vis = 'public';
        if (rawVis == 'members_only' || rawVis == 'tharavadu_only') {
          vis = 'members_only';
        } else if (rawVis == 'guest_only' || rawVis == 'guest_allowed') {
          vis = 'guest_only';
        }

        if (vis == 'public') return true;

        if (vis == 'members_only') {
          final pClanId =
              int.tryParse(
                p['clan_id']?.toString() ??
                    p['tharavadu_id']?.toString() ??
                    '0',
              ) ??
              0;
          if (myTharavaduId != 0 && pClanId == myTharavaduId) return true;
          return false;
        }

        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _postCount = filteredPosts.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching post count in GlobalFeedHeader: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF000080).withValues(alpha: 0.04),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_outlined,
            size: 18,
            color: Color(0xFF000080),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'തറവാട് അപ്‌ഡേറ്റുകളും അറിയിപ്പുകളും (Global Feed)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080),
              ),
            ),
          ),
          if (!_isLoading)
            Text(
              '$_postCount പോസ്റ്റുകൾ',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }
}
