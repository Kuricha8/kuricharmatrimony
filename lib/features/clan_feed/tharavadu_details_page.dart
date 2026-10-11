import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../widgets/tharavadu/tharavadu_chat_feed.dart';

class TharavaduDetailsPage extends StatefulWidget {
  final Clan clan;
  final UserProfile? currentUser;
  final VoidCallback? onUploadSuccess;

  const TharavaduDetailsPage({
    super.key,
    required this.clan,
    this.currentUser,
    this.onUploadSuccess,
  });

  @override
  State<TharavaduDetailsPage> createState() => _TharavaduDetailsPageState();
}

class _TharavaduDetailsPageState extends State<TharavaduDetailsPage> {
  String? winningPhotoUrl;
  RealtimeChannel? _feedRealtimeChannel;
  bool _isTrending = false;

  @override
  void initState() {
    super.initState();
    winningPhotoUrl = widget.clan.imageUrl;
    _fetchWinningPhoto();
    _subscribeToFeedRealtime();
  }

  @override
  void dispose() {
    _feedRealtimeChannel?.unsubscribe();
    super.dispose();
  }

  bool _computeIsMember() {
    final user = widget.currentUser ?? MockData().currentUser;
    if (user == null || user.id == 'guest' || user.id.isEmpty) return false;
    if (user.isAdmin) return true;

    if (user.motherClanId == widget.clan.id ||
        user.fatherClanId == widget.clan.id ||
        user.tharavaduId == widget.clan.id) {
      return true;
    }

    final cName = widget.clan.name.trim().toLowerCase();
    final cNameMl = widget.clan.nameMl.trim().toLowerCase();
    final userTharavadu =
        (user.motherTharavadu ??
                user.mothersTarawad ??
                user.fatherTharavadu ??
                '')
            .trim()
            .toLowerCase();

    return cName.isNotEmpty &&
        (userTharavadu == cName || userTharavadu == cNameMl);
  }

  Future<void> _fetchWinningPhoto() async {
    // Visibility Requirement: Dynamic Tharavadu DP is visible ONLY to members of that specific Tharavadu
    final bool isMember = _computeIsMember();
    if (!isMember) {
      if (mounted) {
        setState(() {
          winningPhotoUrl = null;
          _isTrending = false;
        });
      }
      return;
    }

    try {
      final myId = (widget.currentUser ?? MockData().currentUser)?.id;

      // 1. Try Supabase RPC first
      try {
        final rpcParams = <String, dynamic>{'p_clan_id': widget.clan.id};
        if (myId != null) rpcParams['p_viewer_id'] = myId;

        final rpcRes = await Supabase.instance.client
            .rpc('get_tharavadu_dynamic_dp', params: rpcParams)
            .maybeSingle();

        if (rpcRes != null &&
            rpcRes['image_url'] != null &&
            rpcRes['image_url'].toString().isNotEmpty) {
          if (mounted) {
            setState(() {
              winningPhotoUrl = rpcRes['image_url'].toString();
              _isTrending = ((rpcRes['like_count'] as int?) ?? 0) > 0;
            });
            return;
          }
        }
      } catch (_) {}

      // 2. Direct Query Fallback (Highest Likes Priority + Earliest Timestamp Tie-breaker)
      dynamic result = [];
      try {
        result = await Supabase.instance.client
            .from('tharavadu_feed_posts')
            .select(
              'media_url, likes_count, likes, created_at, is_video, media_type',
            )
            .or(
              'clan_id.eq.${widget.clan.id},tharavadu_id.eq.${widget.clan.id},tharavadu_id.eq."${widget.clan.id}"',
            )
            .not('media_url', 'is', null)
            .neq('media_url', '')
            .neq('is_video', true)
            .neq('media_type', 'video')
            .order('likes_count', ascending: false)
            .order('created_at', ascending: true)
            .limit(1);
      } catch (_) {
        try {
          result = await Supabase.instance.client
              .from('tharavadu_posts')
              .select(
                'media_url, likes_count, likes, created_at, is_video, media_type',
              )
              .eq('clan_id', widget.clan.id)
              .not('media_url', 'is', null)
              .neq('media_url', '')
              .neq('is_video', true)
              .neq('media_type', 'video')
              .order('likes_count', ascending: false)
              .order('created_at', ascending: true)
              .limit(1);
        } catch (_) {}
      }

      if (mounted) {
        if (result is List && result.isNotEmpty) {
          final top = result.first;
          final topUrl = top['media_url']?.toString();
          if (topUrl != null && topUrl.isNotEmpty) {
            setState(() {
              winningPhotoUrl = topUrl;
              _isTrending =
                  ((top['likes_count'] ?? top['likes']) as int? ?? 0) > 0;
            });
            return;
          }
        }
        setState(() {
          winningPhotoUrl = widget.clan.imageUrl;
          _isTrending = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching winning photo: $e');
    }
  }

  void _subscribeToFeedRealtime() {
    try {
      _feedRealtimeChannel = Supabase.instance.client
          .channel('public:tharavadu_details_header_${widget.clan.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tharavadu_feed_posts',
            callback: (payload) {
              _fetchWinningPhoto();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tharavadu_posts',
            callback: (payload) {
              _fetchWinningPhoto();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'post_likes',
            callback: (payload) {
              _fetchWinningPhoto();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tharavad_post_likes',
            callback: (payload) {
              _fetchWinningPhoto();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'taravad_post_likes',
            callback: (payload) {
              _fetchWinningPhoto();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime error in details page: $e');
    }
  }

  Future<void> _showEditClanDialog(BuildContext context) async {
    final nameEnCtrl = TextEditingController(text: widget.clan.name);
    final nameMlCtrl = TextEditingController(text: widget.clan.nameMl);
    final imageCtrl = TextEditingController(
      text: winningPhotoUrl ?? widget.clan.imageUrl ?? '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFF000080)),
            const SizedBox(width: 8),
            const Text(
              'Edit Clan / Tharavadu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(
                    labelText: 'English Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameMlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Malayalam Name (മലയാളം)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Photo / Cover Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newEn = nameEnCtrl.text.trim();
                final newMl = nameMlCtrl.text.trim();
                final newImg = imageCtrl.text.trim();

                try {
                  await Supabase.instance.client
                      .from('kurichiyar_clans')
                      .update({
                        'name': newEn,
                        'name_ml': newMl,
                        if (newImg.isNotEmpty) 'image_url': newImg,
                      })
                      .eq('id', widget.clan.id);
                  if (mounted && newImg.isNotEmpty) {
                    setState(() => winningPhotoUrl = newImg);
                  }
                  widget.onUploadSuccess?.call();
                } catch (e) {
                  debugPrint('Error updating clan: $e');
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.clan.displayName;
    final activeTharavaduPhoto = winningPhotoUrl ?? widget.clan.imageUrl;
    final u = widget.currentUser ?? MockData().currentUser;
    final bool isAdmin = u?.role == 'admin' || u?.role == 'super_admin';

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: _isTrending
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amberAccent.withValues(alpha: 0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        )
                      : null,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: CircleAvatar(
                      key: ValueKey(activeTharavaduPhoto),
                      radius: 20,
                      backgroundColor: Colors.amber.shade100,
                      backgroundImage:
                          activeTharavaduPhoto != null &&
                              activeTharavaduPhoto.isNotEmpty
                          ? NetworkImage(activeTharavaduPhoto)
                          : null,
                      child:
                          (activeTharavaduPhoto == null ||
                              activeTharavaduPhoto.isEmpty)
                          ? Text(
                              displayName.isNotEmpty ? displayName[0] : 'ത',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                if (_isTrending)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.clan.groupName} Moiety • Tharavadu Feed',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, size: 24),
              tooltip: 'Edit Tharavadu Info',
              onPressed: () => _showEditClanDialog(context),
            ),
        ],
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
      ),
      body: TharavaduChatFeed(
        clan: widget.clan,
        currentUser: widget.currentUser ?? MockData().currentUser,
        onUploadSuccess: widget.onUploadSuccess,
        onClanImageUpdate: (url) {
          setState(() {
            winningPhotoUrl = url;
          });
        },
      ),
    );
  }
}
