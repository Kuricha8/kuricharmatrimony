import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/mock_data.dart';
import '../../../core/kurichiyar_logic_engine.dart';
import '../../../core/services/compatibility_filter_service.dart';
import '../../../core/services/tharavadu_likes_sync_service.dart';
import '../../../core/services/notification_manager.dart';
import '../../../features/clan_feed/tharavadu_list.dart';
import '../../../features/clan_feed/audio_player_widget.dart';
import '../tharavadu_profile_card_item.dart';
import '../in_chat_poll.dart';
import '../in_chat_post.dart';

class TharavadPostCardList extends StatefulWidget {
  final Clan clan;
  final UserProfile? currentUser;
  final Function(String effectiveImageUrl)? onClanImageUpdate;

  const TharavadPostCardList({
    super.key,
    required this.clan,
    this.currentUser,
    this.onClanImageUpdate,
  });

  @override
  State<TharavadPostCardList> createState() => _TharavadPostCardListState();
}

class _TharavadPostCardListState extends State<TharavadPostCardList> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _chatMessages = [];
  int _lastMessagesCount = 0;
  bool? _isClanMember;
  String? _currentWinningIconPostId;

  @override
  void initState() {
    super.initState();
    final initialUser = widget.currentUser ?? MockData().currentUser;
    _isClanMember = _computeIsMember(initialUser);

    if (widget.currentUser != null) {
      CompatibilityFilterService.instance.init(widget.currentUser!);
    }
    _checkInitialMembership();
    _runMatrimonyDebug();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getCurrentUserId() {
    return _supabase.auth.currentUser?.id ??
        widget.currentUser?.id ??
        MockData().currentUser?.id ??
        'user_1';
  }

  Future<void> _checkInitialMembership() async {
    if (widget.clan.id == 9999) {
      if (mounted) setState(() => _isClanMember = true);
      return;
    }

    final u = widget.currentUser ?? MockData().currentUser;
    if (u != null && u.id != 'guest') {
      final isMember = _computeIsMember(u);
      if (isMember) {
        if (mounted) setState(() => _isClanMember = true);
      }
    }
  }

  Future<void> _runMatrimonyDebug() async {
    try {
      final String activeTharavadName = widget.clan.name;
      final String currentMoiety = KurichiyarLogicEngine.getMoiety(
        activeTharavadName,
      );
      final String targetMoiety = (currentMoiety.toUpperCase().contains('PAN'))
          ? 'BANDHU'
          : 'PANTHI';
      final String currentUserId = _supabase.auth.currentUser?.id ?? '';

      debugPrint('--- MATRIMONY DEBUG START ---');
      debugPrint(
        'Active Clan: $activeTharavadName | Moiety: $currentMoiety | Target:$targetMoiety',
      );
      debugPrint('Logged-in User ID: $currentUserId');

      final response = await _supabase.from('kurichiyar_profiles').select();
      debugPrint('Total Raw Profiles in DB: ${response.length}');

      for (var p in response) {
        final pId = p['id'];
        final pName = p['name'] ?? p['full_name'];
        final pMoiety =
            (p['moiety'] ??
                    KurichiyarLogicEngine.getMoiety(
                      p['mother_tharavadu'] ?? '',
                    ))
                .toString()
                .toUpperCase();
        final isSelf = pId == currentUserId;
        final matchesTarget = pMoiety.contains(targetMoiety.toUpperCase());

        debugPrint(
          'Profile: $pName | ID: $pId | Moiety:$pMoiety | IsSelf: $isSelf | TargetMatch:$matchesTarget',
        );
      }
      debugPrint('--- MATRIMONY DEBUG END ---');
    } catch (e) {
      debugPrint('MATRIMONY DEBUG ERROR: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getTharavadMessagesStream(
    String tharavadName,
  ) {
    return _supabase
        .from('tharavad_chat_messages')
        .stream(primaryKey: ['id'])
        .eq('tharavad_name', tharavadName)
        .order('created_at', ascending: true);
  }

  Stream<List<Map<String, dynamic>>> getMatchingProfilesStream() {
    final String currentMoiety = KurichiyarLogicEngine.getMoiety(
      widget.clan.name,
    );
    final String targetMoiety = (currentMoiety == 'PANTHI')
        ? 'BANDHU'
        : 'PANTHI';
    return _supabase
        .from('kurichiyar_profiles')
        .stream(primaryKey: ['id'])
        .eq('moiety', targetMoiety)
        .order('created_at', ascending: false);
  }

  Map<String, dynamic> _mapTharavadMessage(Map<String, dynamic> row) {
    final myId = _getCurrentUserId();
    final String msgType = row['message_type'] ?? 'TEXT';
    final String content = row['content'] ?? '';
    return {
      'id': row['id']?.toString() ?? '',
      'sender_name': row['sender_name'] ?? 'അംഗം',
      'sender_photo': row['sender_photo'] ?? '',
      'sender_id': row['sender_id'] ?? 'user_1',
      'text': msgType == 'TEXT' ? content : '',
      'media_url': msgType != 'TEXT' ? content : '',
      'message_type': msgType,
      'is_profile_card':
          row['is_profile_card'] == true || row['is_profile_card'] == 'true',
      'is_profile_card_empty':
          row['is_profile_card_empty'] == true ||
          row['is_profile_card_empty'] == 'true',
      'is_me': row['sender_id'] == myId,
      'likes': row['likes_count'] ?? 0,
      'liked_by': <String>{},
      'member_liked_by': <String>{},
      'comments': <String>[],
      'status': row['status'] ?? 'SENT',
      'timestamp':
          DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now(),
      'time': DateFormat('hh:mm a').format(
        DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now(),
      ),
    };
  }

  Widget _buildStatusTicks(String? status) {
    final s = (status ?? 'SENT').toUpperCase();
    if (s == 'READ') {
      return const Icon(Icons.done_all, size: 14, color: Colors.green);
    } else if (s == 'DELIVERED') {
      return const Icon(Icons.done_all, size: 14, color: Colors.amber);
    } else {
      return const Icon(Icons.check, size: 14, color: Colors.red);
    }
  }

  bool _computeIsMember(UserProfile? u) {
    if (widget.clan.id == 9999) return true;
    if (u == null || u.id == 'guest' || u.id.isEmpty) return false;
    if (u.isAdmin) return true;

    final String myMotherClan = (u.motherTharavadu ?? u.mothersTarawad ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final String activeClan = widget.clan.name.toLowerCase().trim();

    final bool isClanMember =
        myMotherClan.isNotEmpty &&
        (activeClan.contains(myMotherClan) ||
            myMotherClan.contains(activeClan));

    if (isClanMember) return true;

    final targetClanId = widget.clan.id;
    final targetClanIdStr = targetClanId.toString();

    if (targetClanId != 0) {
      if (u.tharavaduId == targetClanId ||
          u.motherClanId == targetClanId ||
          u.fatherClanId == targetClanId ||
          (u.ownIllamId != null && u.ownIllamId == targetClanId) ||
          (u.motherIllamId != null && u.motherIllamId == targetClanId) ||
          (u.fatherIllamId != null && u.fatherIllamId == targetClanId) ||
          u.tharavaduId.toString() == targetClanIdStr ||
          u.motherClanId.toString() == targetClanIdStr ||
          u.fatherClanId.toString() == targetClanIdStr) {
        return true;
      }
    }

    final cName = widget.clan.name.trim().toLowerCase();
    final cNameMl = widget.clan.nameMl.trim().toLowerCase();
    final cNameEn = widget.clan.nameEn.trim().toLowerCase();

    final userTharavaduNames = <String>[
      u.tharavaduName.trim().toLowerCase(),
      (u.motherTharavadu ?? '').trim().toLowerCase(),
      (u.mothersTarawad ?? '').trim().toLowerCase(),
      (u.fatherTharavadu ?? '').trim().toLowerCase(),
    ];

    for (final name in userTharavaduNames) {
      if (name.isNotEmpty &&
          (name == cName ||
              name == cNameMl ||
              name == cNameEn ||
              cName.contains(name) ||
              cNameMl.contains(name) ||
              cNameEn.contains(name) ||
              name.contains(cName) ||
              name.contains(cNameMl) ||
              name.contains(cNameEn))) {
        return true;
      }
    }

    final cleanClanEn = _normalizeTharavaduText(widget.clan.name);
    final cleanClanMl = _normalizeTharavaduText(widget.clan.nameMl);

    final normalizedUserNames = userTharavaduNames
        .map((n) => _normalizeTharavaduText(n))
        .where((n) => n.isNotEmpty)
        .toList();

    for (final uName in normalizedUserNames) {
      if (cleanClanEn.isNotEmpty &&
          (cleanClanEn.contains(uName) || uName.contains(cleanClanEn))) {
        return true;
      }
      if (cleanClanMl.isNotEmpty &&
          (cleanClanMl.contains(uName) || uName.contains(cleanClanMl))) {
        return true;
      }
    }

    return false;
  }

  String _normalizeTharavaduText(String? str) {
    if (str == null) return '';
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[\(\)\[\]\{\}\-\_\,\.\:\;\/\\\|]'), ' ')
        .replaceAll('panthi', '')
        .replaceAll('bandhu', '')
        .replaceAll('പന്തി', '')
        .replaceAll('ബന്ധു', '')
        .replaceAll('തറവാട്', '')
        .replaceAll('tharavadu', '')
        .replaceAll('tharavad', '')
        .replaceAll('ഗ്രൂപ്പ്', '')
        .replaceAll('group', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _canViewMessage(Map<String, dynamic> row) {
    final bool isMember =
        _isClanMember ??
        _computeIsMember(widget.currentUser ?? MockData().currentUser);
    final bool isOwn = row['sender_id'] == _getCurrentUserId();
    if (isOwn) return true;

    final String scope = row['audience_scope'] ?? 'THARAVAD_ONLY';
    if (scope == 'GLOBAL_ALL' || scope == 'GLOBAL_COMMUNITY') return true;
    if (scope == 'GUEST_PUBLIC' || scope == 'GUEST_VIEW') return true;

    return isMember;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToBottomIfNeeded(int currentCount) {
    if (currentCount > _lastMessagesCount) {
      _lastMessagesCount = currentCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  Future<void> _toggleLikeInDB(String postId, bool isLiked) async {
    final userId = _getCurrentUserId();
    if (postId.startsWith('msg_')) return;

    if (isLiked) {
      try {
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      } catch (_) {
        try {
          await _supabase.from('tharavad_post_likes').insert({
            'post_id': postId,
            'user_id': userId,
          });
        } catch (_) {
          try {
            await _supabase.from('taravad_post_likes').insert({
              'post_id': postId,
              'user_id': userId,
            });
          } catch (e) {
            debugPrint('Error inserting like in DB: $e');
          }
        }
      }
    } else {
      try {
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } catch (_) {
        try {
          await _supabase
              .from('tharavad_post_likes')
              .delete()
              .eq('post_id', postId)
              .eq('user_id', userId);
        } catch (_) {
          try {
            await _supabase
                .from('taravad_post_likes')
                .delete()
                .eq('post_id', postId)
                .eq('user_id', userId);
          } catch (e) {
            debugPrint('Error deleting like in DB: $e');
          }
        }
      }
    }

    _checkAndUpdateTharavadProfilePhoto();
    TharavaduLikesSyncService.syncClanTotalLikes(widget.clan.id);
  }

  void _checkAndUpdateTharavadProfilePhoto() {
    String? topPhotoUrl;
    String? topPostId;
    String? topAuthorId;
    int maxLikes = 0;
    DateTime? earliestCreatedAt;

    final candidatePhotos = _chatMessages.where((msg) {
      final mediaUrl = msg['media_url'] as String?;
      final isVideo = msg['is_video'] == true;
      final isAudio =
          msg['message_type'] == 'AUDIO' ||
          (mediaUrl != null &&
              (mediaUrl.endsWith('.m4a') || mediaUrl.endsWith('.mp3')));
      return mediaUrl != null && mediaUrl.isNotEmpty && !isVideo && !isAudio;
    }).toList();

    for (final msg in candidatePhotos) {
      final int likes =
          msg['likes'] as int? ??
          (msg['liked_by'] as Set<String>?)?.length ??
          0;
      final ts = msg['timestamp'] is DateTime
          ? msg['timestamp'] as DateTime
          : DateTime.tryParse(msg['created_at']?.toString() ?? '') ??
                DateTime.now();

      if (likes > maxLikes ||
          (likes == maxLikes &&
              maxLikes > 0 &&
              earliestCreatedAt != null &&
              ts.isBefore(earliestCreatedAt))) {
        maxLikes = likes;
        topPhotoUrl = msg['media_url'] as String;
        topPostId = msg['id']?.toString();
        topAuthorId =
            msg['user_id']?.toString() ?? msg['author_id']?.toString();
        earliestCreatedAt = ts;
      }
    }

    final effectiveImageUrl = (topPhotoUrl != null && topPhotoUrl.isNotEmpty)
        ? topPhotoUrl
        : (widget.clan.imageUrl ?? '');

    if (topPostId != _currentWinningIconPostId) {
      _currentWinningIconPostId = topPostId;
      if (effectiveImageUrl.isNotEmpty) {
        widget.onClanImageUpdate?.call(effectiveImageUrl);
        MockData().submitClanPhoto(
          widget.clan.id,
          effectiveImageUrl,
          isProfilePhoto: true,
        );

        try {
          _supabase
              .from('kurichiyar_clans')
              .update({
                'image_url': effectiveImageUrl,
                'profile_image_url': effectiveImageUrl,
                'icon_url': effectiveImageUrl,
                'icon_post_id': topPostId,
              })
              .eq('id', widget.clan.id);
        } catch (_) {}

        TharavaduService.instance.syncClans();
      }

      if (topAuthorId != null && topAuthorId.isNotEmpty && maxLikes > 0) {
        NotificationManager.showNotification(
          title: '🎉 തറവാട് ഐക്കൺ അപ്‌ഡേറ്റ്!',
          body:
              'അഭിനന്ദനങ്ങൾ! നിങ്ങളുടെ ഫോട്ടോ ${widget.clan.name} തറവാടിന്റെ ഔദ്യോഗിക പ്രൊഫൈൽ ചിത്രമായി മാറി ($maxLikes ലൈക്കുകൾ)!',
        );
      }
    }
  }

  bool _validateLikingPermission(Map<String, dynamic> msg) {
    final user = widget.currentUser ?? MockData().currentUser;
    final bool isLoggedIn =
        user != null && user.id != 'guest' && user.id.isNotEmpty;
    if (!isLoggedIn && _supabase.auth.currentUser == null) {
      _showGuestAuthPrompt();
      return false;
    }

    final bool isMember = _isClanMember ?? _computeIsMember(user);
    final rawVisibility =
        (msg['visibility']?.toString() ??
                msg['privacy_level']?.toString() ??
                'public')
            .toLowerCase()
            .trim();

    String visibility = 'public';
    if (rawVisibility == 'members_only' || rawVisibility == 'tharavadu_only') {
      visibility = 'members_only';
    } else if (rawVisibility == 'guest_only' ||
        rawVisibility == 'guest_allowed') {
      visibility = 'guest_only';
    } else {
      visibility = 'public';
    }

    if (visibility == 'members_only') {
      if (!isMember && widget.clan.id != 9999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'സ്വന്തം തറവാട്ടുകാർക്ക് മാത്രമേ ലൈക്ക് ചെയ്യാനാകൂ (Members Only).',
            ),
            backgroundColor: Color(0xFF000080),
          ),
        );
        return false;
      }
    } else if (visibility == 'guest_only') {
      if (isMember && widget.clan.id != 9999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ഗെസ്റ്റ് സന്ദർശകർക്ക് മാത്രമേ ലൈക്ക് ചെയ്യാനാകൂ (Guest Only).',
            ),
            backgroundColor: Color(0xFFE65100),
          ),
        );
        return false;
      }
    }

    return true;
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuestAuthPrompt() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFF000080),
                child: Icon(Icons.lock_person, size: 28, color: Colors.amber),
              ),
              const SizedBox(height: 16),
              const Text(
                'സന്ദേശമയക്കാൻ ലോഗിൻ ചെയ്യുക',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'തറവാട് സന്ദേശങ്ങൾ അയക്കാനും ഫോട്ടോകളും വീഡിയോകളും പങ്കുവെക്കാനും ദയവായി രജിസ്റ്റർ ചെയ്യുക അല്ലെങ്കിൽ ലോഗിൻ ചെയ്യുക.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF000080)),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFF000080),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChatMessageComments(
    BuildContext context,
    Map<String, dynamic> msg,
  ) {
    final commentController = TextEditingController();
    final comments = (msg['comments'] as List<String>?) ?? <String>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'അഭിപ്രായങ്ങൾ (Comments)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'അഭിപ്രായങ്ങൾ ഒന്നും ലഭ്യമല്ല.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          comments[index],
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    },
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'അഭിപ്രായം രേഖപ്പെടുത്തുക...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF000080)),
                    onPressed: () async {
                      final text = commentController.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          comments.add(text);
                          msg['comments'] = comments;
                        });
                        commentController.clear();
                        Navigator.pop(ctx);

                        final postId = msg['id'];
                        final userId =
                            _supabase.auth.currentUser?.id ??
                            widget.currentUser?.id;
                        if (postId != null && userId != null) {
                          try {
                            await _supabase.from('post_comments').insert({
                              'post_id': postId,
                              'user_id': userId,
                              'comment': text,
                              'created_at': DateTime.now().toIso8601String(),
                            });
                          } catch (_) {}
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDeletePost(Map<String, dynamic> msg) async {
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
          'ഈ മെസ്സേജ് ഡിലീറ്റ് ചെയ്യണോ? (Delete this message?)',
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
      final postId = msg['id']?.toString();
      if (postId != null) {
        try {
          await _supabase
              .from('tharavad_chat_messages')
              .delete()
              .eq('id', postId);
        } catch (e) {
          debugPrint('Error deleting tharavad message: $e');
        }

        _checkAndUpdateTharavadProfilePhoto();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('മെസ്സേജ് വിജയകരമായി ഡിലീറ്റ് ചെയ്തു.'),
              backgroundColor: Color(0xFF000080),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Widget _buildVisibilityBadge(String? rawVis) {
    final raw = (rawVis ?? 'public').toLowerCase().trim();
    String vis = 'public';
    if (raw == 'members_only' || raw == 'tharavadu_only') {
      vis = 'members_only';
    } else if (raw == 'guest_only' || raw == 'guest_allowed') {
      vis = 'guest_only';
    } else {
      vis = 'public';
    }

    IconData icon;
    String label;
    Color color;
    Color bgColor;

    if (vis == 'members_only') {
      icon = Icons.lock_outline;
      label = 'തറവാട്ടുകാർക്ക് മാത്രം';
      color = const Color(0xFF000080);
      bgColor = const Color(0xFFE8EAF6);
    } else if (vis == 'guest_only') {
      icon = Icons.remove_red_eye_outlined;
      label = 'ഗെസ്റ്റ് മോഡ്';
      color = const Color(0xFFE65100);
      bgColor = const Color(0xFFFFF3E0);
    } else {
      icon = Icons.public_outlined;
      label = 'എല്ലാവർക്കും കാണാം';
      color = const Color(0xFF2E7D32);
      bgColor = const Color(0xFFE8F5E9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isMe, bool canPost) {
    final type = msg['message_type'] ?? 'TEXT';
    final hasMedia =
        msg['media_url'] != null && msg['media_url'].toString().isNotEmpty;
    final isAudio = type == 'AUDIO';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isMe)
                  Text(
                    msg['sender_name'] ?? 'അംഗം',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF000080),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (isMe ||
                    (_supabase.auth.currentUser?.id != null &&
                        (msg['user_id'] == _supabase.auth.currentUser!.id ||
                            msg['author_id'] ==
                                _supabase.auth.currentUser!.id)))
                  GestureDetector(
                    onTap: () => _confirmAndDeletePost(msg),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 15,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasMedia) ...[
              const SizedBox(height: 6),
              if (msg['is_tharavadu_tag'] == true) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade500),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Color(0xFFB8860B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '🏛️ തറവാട് ഐക്കൺ നോമിനേഷൻ (${msg['likes'] ?? 0} ലൈക്കുകൾ)',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5C3E00),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: msg['is_video'] == true
                    ? Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF000080),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (msg['media_url'].toString().startsWith('http'))
                              Image.network(
                                msg['media_url'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(),
                              ),
                            Container(color: Colors.black38),
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 54,
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: () => _openFullScreenImage(
                          context,
                          msg['media_url'].toString(),
                        ),
                        child: Image.network(
                          msg['media_url'].toString(),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, err, stack) =>
                              const SizedBox(),
                        ),
                      ),
              ),
            ],
            if (isAudio && msg['media_url'] != null) ...[
              const SizedBox(height: 6),
              AudioPlayerWidget(
                audioUrl: msg['media_url'].toString(),
                accentColor: const Color(0xFF000080),
              ),
            ] else if (msg['message_type'] == 'POLL')
              InChatPollWidget(
                msg: msg,
                isClanMember: canPost,
                onVote: (idx) {
                  if (!canPost) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'നിങ്ങളുടെ സ്വന്തം തറവാട്ടിൽ മാത്രമേ വോട്ട് ചെയ്യാൻ അനുവാദമുള്ളൂ.',
                        ),
                        backgroundColor: Color(0xFF000080),
                      ),
                    );
                    return;
                  }
                  final userVotedOptionIndex = msg['user_voted_index'] as int?;
                  final options = (msg['poll_options'] as List<dynamic>);
                  final opt = options[idx] as Map<String, dynamic>;
                  setState(() {
                    if (userVotedOptionIndex == null) {
                      opt['votes'] = (opt['votes'] as int) + 1;
                      msg['user_voted_index'] = idx;
                    } else if (userVotedOptionIndex != idx) {
                      final prevOpt =
                          options[userVotedOptionIndex] as Map<String, dynamic>;
                      prevOpt['votes'] = ((prevOpt['votes'] as int) - 1).clamp(
                        0,
                        9999,
                      );
                      opt['votes'] = (opt['votes'] as int) + 1;
                      msg['user_voted_index'] = idx;
                    }
                  });
                },
              )
            else if (msg['message_type'] == 'POST' ||
                msg['message_type'] == 'ANNOUNCEMENT')
              InChatPostWidget(msg: msg)
            else if (msg['text'].toString().isNotEmpty && !isAudio) ...[
              const SizedBox(height: 4),
              Text(
                msg['text'],
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!_validateLikingPermission(msg)) {
                          return;
                        }
                        final myId = _getCurrentUserId();
                        final likedBy =
                            (msg['liked_by'] as Set<String>?) ?? <String>{};
                        final bool wasLiked = likedBy.contains(myId);
                        setState(() {
                          if (wasLiked) {
                            likedBy.remove(myId);
                            msg['likes'] = ((msg['likes'] as int? ?? 1) - 1)
                                .clamp(0, 9999);
                          } else {
                            likedBy.add(myId);
                            msg['likes'] = (msg['likes'] as int? ?? 0) + 1;
                          }
                          msg['liked_by'] = likedBy;
                        });
                        _toggleLikeInDB(msg['id'].toString(), !wasLiked);
                      },
                      child: Row(
                        children: [
                          Icon(
                            ((msg['liked_by'] as Set<String>?)?.contains(
                                      _getCurrentUserId(),
                                    ) ??
                                    false)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color:
                                ((msg['liked_by'] as Set<String>?)?.contains(
                                      _getCurrentUserId(),
                                    ) ??
                                    false)
                                ? Colors.red
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${msg['likes'] ?? 0}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () {
                        if (!canPost) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'നിങ്ങളുടെ സ്വന്തം തറവാട്ടിലെ പോസ്റ്റുകളിൽ മാത്രമേ നിങ്ങൾക്ക് പ്രതികരിക്കാനാകൂ (Members Only).',
                              ),
                              backgroundColor: Color(0xFF000080),
                            ),
                          );
                          return;
                        }
                        _showChatMessageComments(context, msg);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 15,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(msg['comments'] as List<dynamic>?)?.length ?? 0}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildVisibilityBadge(
                      msg['visibility']?.toString() ??
                          msg['privacy_level']?.toString(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      msg['time'] ?? '',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      _buildStatusTicks(msg['status']?.toString()),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getWelcomeMessages() {
    final displayName = widget.clan.nameMl.isNotEmpty
        ? widget.clan.nameMl
        : widget.clan.name;
    final welcomeId = 'welcome_${widget.clan.id}';
    final welcomeDate = DateTime.now().subtract(const Duration(days: 2));

    return [
      {
        'id': welcomeId,
        'sender_name': 'സിസ്റ്റം',
        'sender_photo': '',
        'text':
            '🏛️ സ്വാഗതം! ഇത് നിങ്ങളുടെ ഔദ്യോഗിക $displayName തറവാട് കൂട്ടായ്മയാണ്.',
        'media_url': '',
        'message_type': 'ANNOUNCEMENT',
        'likes': 0,
        'liked_by': <String>{},
        'member_liked_by': <String>{},
        'comments': <String>[],
        'is_me': false,
        'timestamp': welcomeDate,
        'time': DateFormat('hh:mm a').format(welcomeDate),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isMember =
        _isClanMember ??
        _computeIsMember(widget.currentUser ?? MockData().currentUser);
    final bool canPost = (isMember || widget.clan.id == 9999);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getTharavadMessagesStream(widget.clan.name),
      builder: (context, chatSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: getMatchingProfilesStream(),
          builder: (context, profilesSnapshot) {
            if (chatSnapshot.connectionState == ConnectionState.waiting &&
                chatSnapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF000080)),
              );
            }

            final List<Map<String, dynamic>> dbMessages =
                (chatSnapshot.data ?? [])
                    .map((row) => _mapTharavadMessage(row))
                    .toList();

            final List<Map<String, dynamic>> dbWelcomeMessages = [];
            dbWelcomeMessages.addAll(_getWelcomeMessages());
            dbWelcomeMessages.addAll(dbMessages);

            final rawProfiles = profilesSnapshot.data ?? [];
            final String activeClan = widget.clan.name.trim().toLowerCase();
            final String currentUserId = _getCurrentUserId();

            final eligibleMatches = rawProfiles.where((profile) {
              final pId = profile['id'] ?? '';
              final pMotherClan = (profile['mother_tharavadu'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              return pId != currentUserId && !pMotherClan.contains(activeClan);
            }).toList();

            final List<Map<String, dynamic>> cardMessages = [];
            final String feedMoiety = KurichiyarLogicEngine.getMoiety(
              widget.clan.name,
            );
            final String oppositeMoiety =
                (feedMoiety.toUpperCase().contains('PAN'))
                ? 'BANDHU'
                : 'PANTHI';

            if (eligibleMatches.isEmpty) {
              final emptyMsgId = 'card_matrimony_empty_${widget.clan.id}';
              cardMessages.add({
                'id': emptyMsgId,
                'sender_name': 'സിസ്റ്റം',
                'sender_photo': '',
                'text':
                    '$oppositeMoiety വംശത്തിലുള്ള പുതിയ പ്രൊഫൈലുകൾ ഉടൻ ലഭ്യമാകും',
                'media_url': '',
                'message_type': 'PROFILE_CARD_EMPTY',
                'is_profile_card_empty': true,
                'likes': 0,
                'liked_by': <String>{},
                'member_liked_by': <String>{},
                'comments': <String>[],
                'is_me': false,
                'timestamp': DateTime.now().subtract(
                  const Duration(minutes: 5),
                ),
                'time': DateFormat(
                  'hh:mm a',
                ).format(DateTime.now().subtract(const Duration(minutes: 5))),
              });
            } else {
              for (final cand in eligibleMatches.take(2)) {
                final cardMsgId = 'card_matrimony_${cand['id']}';
                cardMessages.add({
                  'id': cardMsgId,
                  'sender_name': cand['full_name'] ?? cand['name'] ?? 'അംഗം',
                  'sender_photo': cand['photo_url'] ?? '',
                  'text': 'അനുയോജ്യമായ പുതിയ ആലോചന (Compatible Match)',
                  'media_url': cand['photo_url'] ?? '',
                  'message_type': 'PROFILE_CARD',
                  'is_profile_card': true,
                  'shared_profile_id': cand['id'],
                  'age': cand['age'] ?? 25,
                  'father_clan': cand['father_tharavadu'] ?? 'Kurichiyar',
                  'mother_clan': cand['mother_tharavadu'] ?? 'Kurichiyar',
                  'likes': 0,
                  'liked_by': <String>{},
                  'member_liked_by': <String>{},
                  'comments': <String>[],
                  'is_me': false,
                  'timestamp': DateTime.now().subtract(
                    const Duration(minutes: 5),
                  ),
                  'time': DateFormat(
                    'hh:mm a',
                  ).format(DateTime.now().subtract(const Duration(minutes: 5))),
                });
              }
            }

            final List<Map<String, dynamic>> combined = List.from(
              dbWelcomeMessages,
            );
            combined.addAll(cardMessages);
            combined.sort(
              (a, b) => (a['timestamp'] as DateTime).compareTo(
                b['timestamp'] as DateTime,
              ),
            );

            _chatMessages = combined;

            final List<Map<String, dynamic>> displayMessages = combined
                .where(_canViewMessage)
                .toList();

            _scrollToBottomIfNeeded(displayMessages.length);

            if (displayMessages.isEmpty) {
              return const Center(child: Text('സന്ദേശങ്ങൾ ഒന്നുമില്ല.'));
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              itemCount: displayMessages.length,
              itemBuilder: (context, index) {
                final msg = displayMessages[index];
                final isMe = msg['sender_id'] == _getCurrentUserId();
                final isProfileCard = msg['is_profile_card'] == true;
                final isProfileCardEmpty = msg['is_profile_card_empty'] == true;

                if (isProfileCardEmpty) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: const Color(0xFFFFF9E6),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final String feedMoietyVal =
                                    KurichiyarLogicEngine.getMoiety(
                                      widget.clan.name,
                                    );
                                final String oppositeMoietyVal =
                                    (feedMoietyVal.toUpperCase().contains(
                                      'PAN',
                                    ))
                                    ? 'BANDHU'
                                    : 'PANTHI';
                                return Text(
                                  '$oppositeMoietyVal വംശത്തിലുള്ള പുതിയ പ്രൊഫൈലുകൾ ഉടൻ ലഭ്യമാകും',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 13,
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

                if (isProfileCard) {
                  return TharavaduProfileCardItem(
                    msg: msg,
                    isClanMember: canPost,
                    currentUserId: _getCurrentUserId(),
                    clan: widget.clan,
                    onLikeToggle: (postId, isLiked) {
                      final myId = _getCurrentUserId();
                      final likedBy =
                          (msg['liked_by'] as Set<String>?) ?? <String>{};
                      setState(() {
                        if (isLiked) {
                          likedBy.add(myId);
                          msg['likes'] = (msg['likes'] as int? ?? 0) + 1;
                        } else {
                          likedBy.remove(myId);
                          msg['likes'] = ((msg['likes'] as int? ?? 1) - 1)
                              .clamp(0, 9999);
                        }
                        msg['liked_by'] = likedBy;
                      });
                      _toggleLikeInDB(postId, isLiked);
                    },
                    onCommentTap: (m) => _showChatMessageComments(context, m),
                  );
                }

                return _buildChatBubble(msg, isMe, canPost);
              },
            );
          },
        );
      },
    );
  }
}
