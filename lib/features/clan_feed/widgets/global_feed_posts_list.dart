import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/mock_data.dart';
import '../audio_player_widget.dart';

class GlobalFeedPostsList extends StatefulWidget {
  const GlobalFeedPostsList({super.key});

  @override
  State<GlobalFeedPostsList> createState() => _GlobalFeedPostsListState();
}

class _GlobalFeedPostsListState extends State<GlobalFeedPostsList> {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _feedChannel;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeedPosts();
    _subscribeToFeedRealtime();
  }

  @override
  void dispose() {
    _feedChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToFeedRealtime() {
    try {
      _feedChannel = _supabase
          .channel('public:tharavadu_feed_posts_global_sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tharavadu_feed_posts',
            callback: (payload) => _fetchFeedPosts(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tharavadu_posts',
            callback: (payload) => _fetchFeedPosts(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'taravad_messages',
            callback: (payload) => _fetchFeedPosts(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime subscription error in GlobalFeedPostsList: $e');
    }
  }

  Future<void> _fetchFeedPosts() async {
    try {
      final List<Map<String, dynamic>> allFetched = [];

      // 1. Try tharavadu_feed_posts
      try {
        final res0 = await _supabase
            .from('tharavadu_feed_posts')
            .select()
            .order('created_at', ascending: false)
            .limit(15);
        allFetched.addAll(List<Map<String, dynamic>>.from(res0));
      } catch (e) {
        debugPrint('tharavadu_feed_posts fetch note: $e');
      }

      // 2. Try tharavadu_posts
      try {
        final res1 = await _supabase
            .from('tharavadu_posts')
            .select()
            .order('created_at', ascending: false)
            .limit(15);
        allFetched.addAll(List<Map<String, dynamic>>.from(res1));
      } catch (_) {}

      // 3. Try taravad_messages
      try {
        final res2 = await _supabase
            .from('taravad_messages')
            .select()
            .order('created_at', ascending: false)
            .limit(15);
        allFetched.addAll(List<Map<String, dynamic>>.from(res2));
      } catch (_) {}

      // Deduplicate by ID and sort descending
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
        if (pAuthorId.isNotEmpty && pAuthorId == myUserId) {
          return true; // Creator always sees own posts
        }

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

        // Public posts broadcast to all feeds
        if (vis == 'public') return true;

        // Members-only posts restricted strictly to the user's own clan
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

        // Guest-only posts show for visitors / general explore
        return true;
      }).toList();

      filteredPosts.sort((a, b) {
        final dtA =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.now();
        final dtB =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.now();
        return dtB.compareTo(dtA);
      });

      if (mounted) {
        setState(() {
          _posts = filteredPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading feed posts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_posts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000080).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.forum_outlined,
                    size: 48,
                    color: Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'തറവാട് കമ്മ്യൂണിറ്റി ഫീഡ്',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'എല്ലാ തറവാടുകളിലെയും പൊതു അറിയിപ്പുകളും വിശേഷങ്ങളും ഇവിടെ ലഭ്യമാകും. മുകളിലെ തറവാട് സർക്കിളുകൾ ടാപ്പ് ചെയ്ത് നിങ്ങളുടെ തറവാട്ടിലേക്ക് പ്രവേശിക്കാം.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return const SizedBox(height: 10);
          }
          final postIndex = index ~/ 2;
          final post = _posts[postIndex];
          return _buildFeedPostCard(post);
        }, childCount: _posts.length * 2 - 1),
      ),
    );
  }

  Widget _buildFeedPostCard(Map<String, dynamic> post) {
    final senderName = post['sender_name']?.toString() ?? 'അംഗം';
    final senderPhoto = post['sender_photo']?.toString() ?? '';
    final text = (post['text'] ?? post['content'] ?? '').toString();
    final mediaUrl = post['media_url']?.toString();
    final audioUrl =
        post['audio_url']?.toString() ??
        (post['media_type'] == 'audio' ? mediaUrl : null);
    final isPhoto =
        post['media_type'] == 'photo' ||
        post['media_type'] == 'image' ||
        (mediaUrl != null &&
            !mediaUrl.endsWith('.m4a') &&
            !mediaUrl.endsWith('.mp3'));
    final visibility = post['visibility']?.toString() ?? 'members_only';

    // Format timestamp
    String timeStr = '';
    final rawDate = post['created_at']?.toString();
    if (rawDate != null) {
      final dt = DateTime.tryParse(rawDate);
      if (dt != null) {
        timeStr = DateFormat('hh:mm a · dd MMM').format(dt.toLocal());
      }
    }

    final me = MockData().currentUser;
    final myUserId = _supabase.auth.currentUser?.id ?? me?.id ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Visibility Chip, Timestamp
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF000080).withValues(alpha: 0.1),
                backgroundImage: senderPhoto.startsWith('http')
                    ? CachedNetworkImageProvider(senderPhoto)
                    : null,
                child: !senderPhoto.startsWith('http')
                    ? const Icon(
                        Icons.person,
                        color: Color(0xFF000080),
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (timeStr.isNotEmpty)
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              _buildVisibilityBadge(visibility),
              if ((post['author_id'] ?? post['user_id']) == myUserId)
                GestureDetector(
                  onTap: () => _confirmAndDeletePost(post),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),

          // Post Text Content
          if (text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ],

          // Attached Photo
          if (isPhoto && mediaUrl != null && mediaUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: mediaUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    )
                  : Image.file(
                      File(mediaUrl),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
            ),
          ],

          // Attached Audio Player
          if (audioUrl != null && audioUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            AudioPlayerWidget(audioUrl: audioUrl),
          ],
        ],
      ),
    );
  }

  Widget _buildVisibilityBadge(String visibility) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (visibility.toLowerCase().trim()) {
      case 'all_tharavadus':
      case 'public':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'എല്ലാവർക്കും';
        icon = Icons.public;
        break;
      case 'guest_only':
      case 'guest_allowed':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        label = 'ഗെസ്റ്റ് മോഡ്';
        icon = Icons.remove_red_eye_outlined;
        break;
      case 'members_only':
      case 'tharavadu_only':
      default:
        bg = Colors.amber.shade50;
        fg = const Color(0xFF854D0E);
        label = 'തറവാട്ടുകാർക്ക് മാത്രം';
        icon = Icons.lock_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeletePost(Map<String, dynamic> post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'മെസ്സേജ് ഡിലീറ്റ് ചെയ്യുക',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'ഈ പോസ്റ്റ് ഡിലീറ്റ് ചെയ്യണോ? (Are you sure you want to delete this post?)',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'റദ്ദാക്കുക',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'ഡിലീറ്റ് ചെയ്യുക',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final postId = post['id']?.toString();
      if (postId != null) {
        setState(() {
          _posts.removeWhere((p) => p['id']?.toString() == postId);
        });

        try {
          await _supabase
              .from('tharavadu_feed_posts')
              .delete()
              .eq('id', postId);
        } catch (_) {}
        try {
          await _supabase.from('tharavadu_posts').delete().eq('id', postId);
        } catch (_) {}
        try {
          await _supabase.from('taravad_messages').delete().eq('id', postId);
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('പോസ്റ്റ് വിജയകരമായി ഡിലീറ്റ് ചെയ്തു.'),
              backgroundColor: Color(0xFF000080),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }
}
