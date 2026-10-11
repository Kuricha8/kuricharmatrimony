import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../core/widgets/chat_status_ticks.dart';
import '../../core/widgets/watermarked_image.dart';
import '../../core/services/firebase_firestore_service.dart';
import '../../core/kinship_validator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversationScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final UserProfile? targetProfile;

  const ChatConversationScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.targetProfile,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _supabase = Supabase.instance.client;
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _canChat = false;
  String? _roomId;
  StreamSubscription? _chatSub;
  RealtimeChannel? _realtimeChannel;
  bool _kinshipConflict = false;

  String get _currentUserId {
    return _supabase.auth.currentUser?.id ??
        MockData().currentUser?.id ??
        'user-1';
  }

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  Future<void> _initChatRoom() async {
    _roomId = await _firestore.createOrGetChatRoom(
      _currentUserId,
      widget.receiverId,
    );

    // Check if room is approved (Uses serverAndCache)
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(_roomId)
        .get(const GetOptions(source: Source.serverAndCache))
        .then(
      (doc) {
        if (doc.exists && mounted) {
          setState(() {
            _canChat = doc.data()?['is_approved_by_admin'] ?? false;
          });
        }
      },
    );

    _subscribeToMessages();
    _setupProfileListeners();
  }

  void _setupProfileListeners() {
    final targetId = widget.targetProfile?.id ?? widget.receiverId;

    _realtimeChannel = _supabase
        .channel('public:kurichiyar_profiles:chat_room_\$_roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'kurichiyar_profiles',
          callback: (payload) {
            if (mounted) {
              final updatedId = payload.newRecord['id'];
              if (updatedId == _currentUserId || updatedId == targetId) {
                _revalidateKinship();
              }
            }
          },
        )
        .subscribe();

    _revalidateKinship();
  }

  Future<void> _revalidateKinship() async {
    final targetId = widget.targetProfile?.id ?? widget.receiverId;

    try {
      final myProfileData = await _supabase
          .from('kurichiyar_profiles')
          .select()
          .eq('id', _currentUserId)
          .maybeSingle();
      final targetProfileData = await _supabase
          .from('kurichiyar_profiles')
          .select()
          .eq('id', targetId)
          .maybeSingle();

      if (myProfileData != null && targetProfileData != null) {
        final me = UserProfile.fromMap(myProfileData);
        final them = UserProfile.fromMap(targetProfileData);

        final isValid = KinshipValidator.checkCompatibility(me, them);

        if (mounted) {
          setState(() {
            _kinshipConflict = !isValid;
            if (_kinshipConflict) {
              _canChat = false;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error revalidating kinship: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatSub?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToMessages() {
    if (_roomId == null) return;
    _chatSub?.cancel();
    _chatSub = _firestore.streamChatMessages(_roomId!).listen((snapshot) {
      if (mounted) {
        setState(() {
          _messages = snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  'sender_id': data['senderId'],
                  'content': data['text'],
                  'created_at': (data['timestamp'] as Timestamp?)
                      ?.toDate()
                      .toIso8601String(),
                  'is_seen': data['isRead'] ?? false,
                };
              })
              .toList()
              .reversed
              .toList(); // Reverse to show oldest at top, assuming order by desc in service
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (!_canChat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat is not approved yet.')),
      );
      return;
    }
    final text = _messageController.text.trim();
    if (text.isEmpty || _roomId == null) return;

    // Anti-leak regex check for phone numbers and social links
    final leakRegExp = RegExp(
      r'(\+?\d{10,13}|(instagram\.com|facebook\.com|wa\.me|t\.me)\/[a-zA-Z0-9_.-]+)',
      caseSensitive: false,
    );
    if (leakRegExp.hasMatch(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sharing phone numbers or social links is prohibited! You have a 15-minute cooldown.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      // In a real app, write to Firestore to disable user for 15 minutes.
      setState(() {
        _canChat = false;
      });
      Future.delayed(const Duration(minutes: 15), () {
        if (mounted) {
          setState(() {
            _canChat = true;
          });
        }
      });
      _messageController.clear();
      return;
    }

    final senderId = _currentUserId;
    _messageController.clear();

    try {
      await _firestore.sendMessage(_roomId!, senderId, text);
      _scrollToBottom();
    } catch (e) {
      debugPrint('[ChatConversationScreen] Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.targetProfile?.photoUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: photoUrl.startsWith('http')
                    ? WatermarkedImage(
                        imageUrl: photoUrl,
                        width: 36,
                        height: 36,
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 11, color: Colors.greenAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet. Say hello to ${widget.receiverName}!',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == _currentUserId;
                      final content = (msg['content'] ?? msg['message'] ?? '')
                          .toString();

                      final createdAt = msg['created_at'] != null
                          ? DateTime.tryParse(
                              msg['created_at'].toString(),
                            )?.toLocal()
                          : null;
                      final timeStr = createdAt != null
                          ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                          : '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.blueGrey.shade100,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: photoUrl.startsWith('http')
                                      ? Image.network(
                                          photoUrl,
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.person,
                                                    size: 16,
                                                  ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Color(0xFF000080),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(
                                          0xFF000080,
                                        ) // Solid Blue Sender Bubble
                                      : Colors
                                            .white, // White / Light Receiver Card
                                  border: isMe
                                      ? null
                                      : Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                                    bottomRight: Radius.circular(isMe ? 0 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isMe) ...[
                                      Text(
                                        widget.receiverName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF000080),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                    ],
                                    Text(
                                      content,
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 15,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (timeStr.isNotEmpty)
                                          Text(
                                            timeStr,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isMe
                                                  ? Colors.white70
                                                  : Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          ChatStatusTicks.fromMap(
                                            msg,
                                            isMe: true,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe) const SizedBox(width: 24),
                            if (!isMe) const SizedBox(width: 24),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          if (_kinshipConflict)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade400, width: 2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "മുറയല്ല / പൊരുത്തമില്ല (Kinship Conflict: Shared Mother's Tharavadu / Lineage)",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Chat Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: _canChat,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _kinshipConflict
                            ? 'Kinship conflict: Chat locked'
                            : (_canChat
                                  ? 'സന്ദേശം അയക്കുക (Send a message)...'
                                  : 'Admin approval required...'),
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF000080),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _canChat ? _sendMessage : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
