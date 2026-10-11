import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/theme/subscription_theme.dart';
import '../../core/utils/mock_data.dart';
import '../../features/clan_feed/tharavadu_list.dart';
import '../../widgets/profile/profile_header_widget.dart';
import '../../widgets/profile/profile_matrimony_card_widget.dart';
import '../../widgets/profile/profile_actions_widget.dart';
import '../../widgets/profile/profile_details_sections_widget.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback onLoggedOut;
  const ProfileTab({super.key, required this.onLoggedOut});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserProfile? _myProfile;
  int _likes = 0;
  int _comments = 0;
  final GlobalKey _gk = GlobalKey();
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _realtimeChannel;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _firestoreProfileSub;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _firestoreProfileSub?.cancel();
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final profileId = FirebaseAuth.instance.currentUser?.uid ??
          _supabase.auth.currentUser?.id ??
          MockData().currentUser?.id ??
          '';
      if (profileId.isEmpty) return;

      // 1. Primary: Cached one-time fetch using Source.serverAndCache
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(profileId)
            .get(const GetOptions(source: Source.serverAndCache));
        if (doc.exists && doc.data() != null && mounted) {
          final data = Map<String, dynamic>.from(doc.data()!);
          data['id'] = data['id'] ?? doc.id;
          final profile = UserProfile.fromMap(data);
          setState(() => _myProfile = profile);
          MockData().syncProfileData(profile);
        }
      } catch (err) {
        debugPrint('ProfileTab Firestore user fetch error: $err');
      }

      // 2. Initial fallback fetch from Supabase if not yet present in Firestore
      try {
        final res = await _supabase
            .from('kurichiyar_profiles')
            .select()
            .eq('id', profileId)
            .maybeSingle();

        if (res != null && mounted && _myProfile == null) {
          setState(() => _myProfile = UserProfile.fromMap(res));
        }
      } catch (_) {}

      await _fetchLikesAndComments(profileId);
      _subscribeToLikesAndComments(profileId);
    } catch (_) {}
  }

  Future<void> _fetchLikesAndComments(String profileId) async {
    try {
      final likesRes = await _supabase
          .from('profile_card_likes')
          .select('id')
          .eq('profile_id', profileId);
      final commentsRes = await _supabase
          .from('profile_card_comments')
          .select('id')
          .eq('profile_id', profileId);
      if (mounted) {
        setState(() {
          _likes = likesRes.length;
          _comments = commentsRes.length;
        });
      }
    } catch (_) {}
  }

  void _subscribeToLikesAndComments(String profileId) {
    _realtimeChannel = _supabase
        .channel('profile_engagement_$profileId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profile_card_likes',
          callback: (_) => _fetchLikesAndComments(profileId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profile_card_comments',
          callback: (_) => _fetchLikesAndComments(profileId),
        )
        .subscribe();
  }

  /// Shows tharavad-wise breakdown of likes.
  void _showLikesSheet(BuildContext context, String profileId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TharavadLikesSheet(profileId: profileId),
    );
  }

  /// Shows all comments grouped by tharavad.
  void _showCommentsSheet(BuildContext context, String profileId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TharavadCommentsSheet(profileId: profileId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me =
        _myProfile ?? MockData().currentUser ?? MockData().profiles.first;
    final st = SubscriptionTheme(
      SubscriptionTheme.parse(
        me.subscriptionTier == SubscriptionTier.tier2
            ? 'gold'
            : me.subscriptionTier == SubscriptionTier.tier3
            ? 'diamond'
            : 'free',
      ),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              ProfileHeaderWidget(
                me: me,
                subTheme: st,
                onProfileUpdated: (up) => setState(() => _myProfile = up),
              ),
              const SizedBox(height: 16),
              ProfileMatrimonyCardWidget(
                me: me,
                totalProfileLikes: _likes,
                totalComments: _comments,
                globalKey: _gk,
                onLikesTap: () => _showLikesSheet(context, me.id),
                onCommentsTap: () => _showCommentsSheet(context, me.id),
              ),
              const SizedBox(height: 16),
              ProfileDetailsSectionsWidget(me: me),
              const SizedBox(height: 16),
              ProfileActionsWidget(
                me: me,
                grievanceEmail: 'admin@kurichiyarmatrimony.in',
                onLoggedOut: widget.onLoggedOut,
                onProfileUpdated: (up) => setState(() => _myProfile = up),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Likes Breakdown Sheet ────────────────────────────────────────────────────

class _TharavadLikesSheet extends StatefulWidget {
  final String profileId;
  const _TharavadLikesSheet({required this.profileId});
  @override
  State<_TharavadLikesSheet> createState() => _TharavadLikesSheetState();
}

class _TharavadLikesSheetState extends State<_TharavadLikesSheet> {
  final _supabase = Supabase.instance.client;
  Map<String, int> _byTharavad = {};
  int _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      // Call existing DB RPC: get_likes_by_tharavad(profile_id)
      final res = await _supabase.rpc(
        'get_likes_by_tharavad',
        params: {'profile_id': widget.profileId},
      );

      final Map<String, int> grouped = {};
      for (final row in (res as List)) {
        final tharavadId = row['tharavad_id'];
        final clanName = tharavadId != null
            ? (getClanById(tharavadId as int)?.name ??
                  row['tharavad_name']?.toString() ??
                  'Unknown')
            : (row['tharavad_name']?.toString() ?? 'Unknown');
        final count = (row['likes_count'] as int?) ?? 1;
        grouped[clanName] = (grouped[clanName] ?? 0) + count;
      }
      // Sort by count desc
      final sorted = Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );
      if (mounted) {
        setState(() {
          _byTharavad = sorted;
          _total = sorted.values.fold(0, (acc, v) => acc + v);
          _loading = false;
        });
      }
    } catch (e) {
      // Fallback: fetch raw rows and group in-app
      try {
        final res = await _supabase
            .from('profile_card_likes')
            .select('tharavad_name, tharavad_id')
            .eq('profile_id', widget.profileId);

        final Map<String, int> grouped = {};
        for (final row in res) {
          final tharavadId = row['tharavad_id'];
          final clanName = tharavadId != null
              ? (getClanById(tharavadId as int)?.name ??
                    row['tharavad_name']?.toString() ??
                    'Unknown')
              : (row['tharavad_name']?.toString() ?? 'Unknown');
          grouped[clanName] = (grouped[clanName] ?? 0) + 1;
        }
        final sorted = Map.fromEntries(
          grouped.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
        );
        if (mounted) {
          setState(() {
            _byTharavad = sorted;
            _total = res.length;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.88,
      minChildSize: 0.35,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _SheetHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.star_purple500, color: Color(0xFF5C3E00)),
                  const SizedBox(width: 10),
                  Text(
                    'Likes by Tharavad',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5C3E00),
                    ),
                  ),
                  const Spacer(),
                  _CountBadge(count: _total),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _byTharavad.isEmpty
                  ? const _EmptyState(message: 'No likes yet.')
                  : ListView.separated(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      itemCount: _byTharavad.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final entry = _byTharavad.entries.elementAt(i);
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFF8E1),
                            child: Icon(
                              Icons.home_work_rounded,
                              color: Color(0xFF5C3E00),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C3E00),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: Text(
                              '${entry.value} ❤️',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5C3E00),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Comments Breakdown Sheet ─────────────────────────────────────────────────

class _TharavadCommentsSheet extends StatefulWidget {
  final String profileId;
  const _TharavadCommentsSheet({required this.profileId});
  @override
  State<_TharavadCommentsSheet> createState() => _TharavadCommentsSheetState();
}

class _TharavadCommentsSheetState extends State<_TharavadCommentsSheet> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _commentsList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _supabase
          .from('profile_card_comments')
          .select(
            'commenter_name, comment_text, created_at, commenter_photo, tharavad_name, tharavad_id',
          )
          .eq('profile_id', widget.profileId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _commentsList = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _tharavadLabel(Map<String, dynamic> c) {
    final id = c['tharavad_id'];
    if (id != null) {
      final clan = getClanById(id as int);
      if (clan != null) return clan.name;
    }
    return c['tharavad_name']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _SheetHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.comment_rounded, color: Color(0xFF5C3E00)),
                  const SizedBox(width: 10),
                  Text(
                    'Profile Comments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5C3E00),
                    ),
                  ),
                  const Spacer(),
                  _CountBadge(count: _commentsList.length),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _commentsList.isEmpty
                  ? const _EmptyState(message: 'No comments yet.')
                  : ListView.separated(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      itemCount: _commentsList.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = _commentsList[i];
                        final name =
                            c['commenter_name']?.toString() ?? 'Anonymous';
                        final text = c['comment_text']?.toString() ?? '';
                        final photo = c['commenter_photo']?.toString() ?? '';
                        final tharavad = _tharavadLabel(c);
                        final rawTs = c['created_at']?.toString() ?? '';
                        final ts = DateTime.tryParse(rawTs);
                        final timeStr = ts != null
                            ? DateFormat(
                                'dd MMM yyyy • hh:mm a',
                              ).format(ts.toLocal())
                            : '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: photo.startsWith('http')
                                    ? NetworkImage(photo)
                                    : null,
                                backgroundColor: Colors.amber.shade100,
                                child: !photo.startsWith('http')
                                    ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5C3E00),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF5C3E00),
                                                ),
                                              ),
                                              if (tharavad.isNotEmpty)
                                                Text(
                                                  tharavad,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        Colors.amber.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      text,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helper widgets ────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF5C3E00),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
