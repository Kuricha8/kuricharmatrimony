import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/notification_manager.dart';
import '../../core/services/rule_based_chatbot_service.dart';
import '../../core/services/support_unread_service.dart';
import '../../widgets/support/chat_message_bubble.dart';

/// Clean, professional Support Desk screen with integrated offline Chatbot, FAQ Chips, and Admin Escalation.
class UserSupportChatScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserSupportChatScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserSupportChatScreen> createState() => _UserSupportChatScreenState();
}

class _UserSupportChatScreenState extends State<UserSupportChatScreen> {
  final _supabase = Supabase.instance.client;
  final _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  RealtimeChannel? _realtimeChannel;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isBotTyping = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    SupportUnreadService.instance.markAllRead();
    _fetchMessages();
    _markAsRead();
    _subscribeToMessages();
  }

  void _initTts() async {
    try {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  void _speakMessage(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _flutterTts.stop();
      final bool isMalayalam = RegExp(r'[\u0D00-\u0D7F]').hasMatch(text);
      if (isMalayalam) {
        await _flutterTts.setLanguage('ml-IN');
      } else {
        await _flutterTts.setLanguage('en-US');
      }
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _msgController.dispose();
    _scrollController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToMessages() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _supabase
        .channel('public:support_user_${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'support_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: widget.userId,
          ),
          callback: (payload) {
            if (mounted) {
              _fetchMessages();
              _markAsRead();
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchMessages() async {
    try {
      final res = await _supabase
          .from('support_messages')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error fetching support messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Safe update of read status with fallback if read_at column is missing
  Future<void> _markAsRead() async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      try {
        await _supabase
            .from('support_messages')
            .update({
              'read_by_user': true,
              'is_seen': true,
              'status': 'read',
              'read_at': nowIso,
            })
            .eq('user_id', widget.userId)
            .eq('is_from_admin', true)
            .eq('read_by_user', false);
      } on PostgrestException catch (pe) {
        if (pe.message.contains('read_at') || pe.code == 'PGRST204') {
          await _supabase
              .from('support_messages')
              .update({'read_by_user': true, 'is_seen': true, 'status': 'read'})
              .eq('user_id', widget.userId)
              .eq('is_from_admin', true)
              .eq('read_by_user', false);
        }
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
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

  /// Trigger message send (either from typing text or tapping a FAQ chip)
  Future<void> _sendMessage([String? customText]) async {
    final text = (customText ?? _msgController.text).trim();
    if (text.isEmpty) return;

    if (customText == null) {
      _msgController.clear();
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();

    // 1. Optimistic User Message UI update
    final userTempMsg = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': widget.userId,
      'message': text,
      'sender_type': 'user',
      'is_from_admin': false,
      'status': 'sent',
      'is_seen': false,
      'read_by_admin': false,
      'created_at': nowIso,
    };

    setState(() {
      _messages.add(userTempMsg);
      _isBotTyping = true;
    });
    _scrollToBottom();

    // Save User message to Supabase DB
    try {
      await _supabase.from('support_messages').insert({
        'user_id': widget.userId,
        'message': text,
        'sender_type': 'user',
        'is_from_admin': false,
        'read_by_user': true,
        'read_by_admin': false,
        'status': 'sent',
        'is_seen': false,
        'created_at': nowIso,
      });
    } catch (e) {
      debugPrint('Error saving user message to DB: $e');
    }

    // 2. Process Chatbot Response after realistic 500ms delay
    await Future.delayed(const Duration(milliseconds: 500));

    final botResponseText = RuleBasedChatbotService.instance.getResponse(text);
    final isEscalated = RuleBasedChatbotService.instance.isEscalationRequested(
      text,
    );
    final botNowIso = DateTime.now().toUtc().toIso8601String();

    final botMsg = {
      'id': 'bot_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': widget.userId,
      'message': botResponseText,
      'sender_type': 'bot',
      'is_bot': true,
      'is_from_admin': true,
      'read_by_user': true,
      'read_by_admin': true,
      'status': 'read',
      'created_at': botNowIso,
    };

    if (mounted) {
      setState(() {
        _isBotTyping = false;
        _messages.add(botMsg);
      });
      _scrollToBottom();
      if (_isSpeakerOn) {
        _speakMessage(botResponseText);
      }
    }

    // Save Bot message to Supabase DB
    try {
      await _supabase.from('support_messages').insert({
        'user_id': widget.userId,
        'message': botResponseText,
        'sender_type': 'bot',
        'is_bot': true,
        'is_from_admin': true,
        'read_by_user': true,
        'read_by_admin': true,
        'status': 'read',
        'created_at': botNowIso,
      });
    } catch (e) {
      debugPrint('Error saving bot message to DB: $e');
    }

    // 3. Admin Escalation handling
    if (isEscalated) {
      _triggerAdminEscalation(text);
    }
  }

  /// Notify Super Admin via FCM and mark thread as escalated
  Future<void> _triggerAdminEscalation(String userQuery) async {
    try {
      final adminProfiles = await _supabase
          .from('kurichiyar_profiles')
          .select('id')
          .eq('role', 'super_admin')
          .limit(1);

      if (adminProfiles.isNotEmpty) {
        final adminId = adminProfiles.first['id'] as String;
        await NotificationManager.instance.sendPushNotification(
          adminId,
          '⚠️ Support Thread Escalated',
          '${widget.userName} requested live support: "$userQuery"',
          data: {
            'type': 'support_escalation',
            'user_id': widget.userId,
            'is_escalated_to_admin': 'true',
          },
        );
      }
    } catch (err) {
      debugPrint('Support admin escalation notification error: $err');
    }
  }

  String _formatDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) return 'Today';
    if (msgDate == yesterday) return 'Yesterday';
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help & Support Desk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'AI & Live Support Active',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isSpeakerOn
                ? 'ശബ്ദം ഓഫ് ചെയ്യുക (Mute)'
                : 'ശബ്ദം ഓൺ ചെയ്യുക (Unmute)',
            icon: Icon(
              _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
              color: _isSpeakerOn ? Colors.greenAccent : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _isSpeakerOn = !_isSpeakerOn;
                if (!_isSpeakerOn) {
                  _flutterTts.stop();
                }
              });
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.phone_in_talk, color: Colors.white, size: 16),
            label: const Text('സഹായത്തിനായി വിളിക്കുക'),
            onPressed: () async {
              try {
                await _flutterTts.setLanguage('ml-IN');
                await _flutterTts.speak("കുറിച്ച്യർ മാട്രിമോണിയിലേക്ക് സ്വാഗതം. നിങ്ങളുടെ കോൾ അഡ്മിനുമായി കണക്റ്റ് ചെയ്യുന്നു, ദയവായി കാത്തിരിക്കുക. ശ്രദ്ധിക്കുക: വ്യക്തിഗത ഫോൺ നമ്പറുകളോ സോഷ്യൽ മീഡിയ വിവരങ്ങളോ കോളിൽ പങ്കുവെക്കരുത്. നിയമലംഘനം നടത്തിയാൽ പ്രൊഫൈൽ സ്ഥിരമായി നീക്കം ചെയ്യപ്പെടും.");
              } catch (_) {}

              final callId = 'support_call_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';

              // Notify admin via Firestore
              try {
                final adminProfiles = await _supabase
                    .from('kurichiyar_profiles')
                    .select('id')
                    .eq('role', 'super_admin')
                    .limit(1);
                
                String adminId = 'admin';
                if (adminProfiles.isNotEmpty) {
                  adminId = adminProfiles.first['id'] as String;
                }

                await FirebaseFirestore.instance.collection('calls').doc(callId).set({
                  'caller_id': widget.userId,
                  'caller_name': widget.userName,
                  'target_user_id': adminId,
                  'channel_name': callId,
                  'status': 'calling',
                  'call_type': 'audio',
                  'created_at': FieldValue.serverTimestamp(),
                });
              } catch (e) {
                debugPrint('Error notifying admin of call: $e');
              }

              final jitsiMeet = JitsiMeet();
              final options = JitsiMeetConferenceOptions(
                room: callId,
                configOverrides: {
                  "startWithVideoMuted": true,
                  "startWithAudioMuted": false,
                },
                userInfo: JitsiMeetUserInfo(
                    displayName: widget.userName,
                    email: widget.userId,
                ),
              );
              jitsiMeet.join(options);
            },
          ),
          IconButton(
            tooltip: 'Refresh Chat',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.smart_toy_outlined,
                                size: 64,
                                color: Colors.teal.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'How can we help you today?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap a quick topic chip below or type your inquiry.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          itemCount: _messages.length + (_isBotTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Render bot typing indicator
                            if (index == _messages.length && _isBotTyping) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 12,
                                  left: 4,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFF005F73),
                                      child: const Icon(
                                        Icons.smart_toy,
                                        size: 14,
                                        color: Colors.cyanAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.teal.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Support Bot is typing...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.teal.shade800,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final msg = _messages[index];
                            final String senderType = (msg['sender_type'] ?? '')
                                .toString()
                                .toLowerCase();
                            final rawAdmin = msg['is_from_admin'];
                            final senderId = msg['sender_id']?.toString();
                            final isFromAdmin =
                                rawAdmin == true ||
                                rawAdmin == 1 ||
                                rawAdmin.toString().toLowerCase() == 'true' ||
                                msg['is_admin_reply'] == true ||
                                senderType == 'admin' ||
                                senderType == 'bot' ||
                                msg['is_bot'] == true ||
                                (senderId != null &&
                                    senderId.isNotEmpty &&
                                    senderId != widget.userId);
                            final isMe = !isFromAdmin;

                            // Date divider check
                            bool showDivider = false;
                            String? dividerText;
                            if (msg['created_at'] != null) {
                              final dt = DateTime.tryParse(
                                msg['created_at'].toString(),
                              )?.toLocal();
                              if (dt != null) {
                                if (index == 0) {
                                  showDivider = true;
                                  dividerText = _formatDateDivider(dt);
                                } else {
                                  final prevMsg = _messages[index - 1];
                                  if (prevMsg['created_at'] != null) {
                                    final prevDt = DateTime.tryParse(
                                      prevMsg['created_at'].toString(),
                                    )?.toLocal();
                                    if (prevDt != null &&
                                        (dt.day != prevDt.day ||
                                            dt.month != prevDt.month ||
                                            dt.year != prevDt.year)) {
                                      showDivider = true;
                                      dividerText = _formatDateDivider(dt);
                                    }
                                  }
                                }
                              }
                            }

                            return ChatMessageBubble(
                              message: msg,
                              isMe: isMe,
                              senderTitle: isMe
                                  ? 'You'
                                  : (senderType == 'bot' ||
                                            msg['is_bot'] == true
                                        ? '🤖 Support Assistant'
                                        : 'Support Team'),
                              showDateDivider: showDivider,
                              dateDividerText: dividerText,
                              onSpeakTap: !isMe
                                  ? () => _speakMessage(
                                      msg['message']?.toString() ?? '',
                                    )
                                  : null,
                            );
                          },
                        ),
                ),

                // 1. Horizontal Scrollable FAQ Action Chips
                Container(
                  height: 48,
                  color: Colors.grey.shade50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    itemCount: RuleBasedChatbotService.quickActionChips.length,
                    itemBuilder: (context, idx) {
                      final chipText =
                          RuleBasedChatbotService.quickActionChips[idx];
                      final isEscalateChip = chipText.contains("Live Admin");
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(
                            isEscalateChip
                                ? Icons.headset_mic
                                : Icons.help_outline,
                            size: 14,
                            color: isEscalateChip
                                ? Colors.white
                                : const Color(0xFF000080),
                          ),
                          label: Text(
                            chipText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isEscalateChip
                                  ? Colors.white
                                  : const Color(0xFF000080),
                            ),
                          ),
                          backgroundColor: isEscalateChip
                              ? Colors.orange.shade800
                              : Colors.blue.shade50,
                          side: BorderSide(
                            color: isEscalateChip
                                ? Colors.orange.shade800
                                : Colors.blue.shade200,
                          ),
                          onPressed: () => _sendMessage(chipText),
                        ),
                      );
                    },
                  ),
                ),

                // Input Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            decoration: InputDecoration(
                              hintText: 'Ask a question or tap a chip...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF000080),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => _sendMessage(),
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
