import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../core/utils/chat_filter.dart';
import '../../core/services/notification_manager.dart';
import 'package:flutter/services.dart';
import '../../features/match_agreement/pdf_service.dart';
import '../marriage_registration/registration_guide_page.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _supabase = Supabase.instance.client;
  UserProfile? _activeChatCandidate;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoadingCandidates = true;
  List<UserProfile> _chatCandidates = [];
  final Map<String, String> _lastMessages = {};

  List<Map<String, dynamic>> _messages = [];
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _realtimeChannel?.unsubscribe();
    NotificationManager.currentActiveChatId = null;
    super.dispose();
  }

  Future<void> _fetchCandidates() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final shortlists = await _supabase
          .from('user_shortlists')
          .select('shortlisted_profile_id')
          .eq('user_id', userId);

      final profileIds = shortlists
          .map((e) => e['shortlisted_profile_id'] as String)
          .toList();

      if (profileIds.isNotEmpty) {
        final profilesRes = await _supabase
            .from('kurichiyar_profiles')
            .select()
            .inFilter('id', profileIds);

        final candidates = profilesRes
            .map((e) => UserProfile.fromMap(e))
            .toList();

        // Optionally fetch last messages
        for (var c in candidates) {
          final lastMsgRes = await _supabase
              .from('chat_messages')
              .select('message')
              .or(
                'and(sender_id.eq.$userId,receiver_id.eq.${c.id}),and(sender_id.eq.${c.id},receiver_id.eq.$userId)',
              )
              .order('created_at', ascending: false)
              .limit(1);
          if (lastMsgRes.isNotEmpty) {
            _lastMessages[c.id] = lastMsgRes.first['message'] as String;
          }
        }

        if (mounted) {
          setState(() {
            _chatCandidates = candidates;
            _isLoadingCandidates = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _chatCandidates = [];
            _isLoadingCandidates = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching shortlists: $e");
      if (mounted) {
        setState(() => _isLoadingCandidates = false);
      }
    }
  }

  void _openChat(UserProfile candidate) {
    setState(() {
      _activeChatCandidate = candidate;
      _messages = [];
    });

    NotificationManager.currentActiveChatId = candidate.id;

    _fetchHistoricalMessages(candidate.id);

    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _supabase
        .channel('public:chat_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final newMsg = payload.newRecord;
            final userId = _supabase.auth.currentUser!.id;
            final cId = _activeChatCandidate?.id;

            if (cId != null && newMsg.isNotEmpty) {
              bool isRelevant =
                  (newMsg['sender_id'] == userId &&
                      newMsg['receiver_id'] == cId) ||
                  (newMsg['sender_id'] == cId &&
                      newMsg['receiver_id'] == userId);
              if (isRelevant) {
                if (mounted) {
                  setState(() {
                    if (payload.eventType == PostgresChangeEvent.insert) {
                      _messages.add(newMsg);

                      // Tier 3: In-app chat ultra-subtle haptic and micro-tap for incoming messages
                      if (newMsg['sender_id'] != userId) {
                        HapticFeedback.lightImpact();
                        SystemSound.play(SystemSoundType.click);
                      }
                    } else if (payload.eventType ==
                        PostgresChangeEvent.update) {
                      final index = _messages.indexWhere(
                        (m) => m['id'] == newMsg['id'],
                      );
                      if (index != -1) {
                        _messages[index] = newMsg;
                      }
                    }
                  });
                  if (payload.eventType == PostgresChangeEvent.insert) {
                    _scrollToBottom();
                  }
                }
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchHistoricalMessages(String candidateId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final res = await _supabase
          .from('chat_messages')
          .select()
          .or(
            'and(sender_id.eq.$userId,receiver_id.eq.$candidateId),and(sender_id.eq.$candidateId,receiver_id.eq.$userId)',
          )
          .order('created_at', ascending: true);

      if (mounted && _activeChatCandidate?.id == candidateId) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(res);
        });
        _scrollToBottom();

        // Mark unread messages as read
        final unreadIds = _messages
            .where((m) => m['receiver_id'] == userId && m['is_read'] != true)
            .map((m) => m['id'])
            .toList();

        if (unreadIds.isNotEmpty) {
          _supabase
              .from('chat_messages')
              .update({'is_read': true})
              .inFilter('id', unreadIds)
              .then((_) {
                debugPrint('Marked ${unreadIds.length} messages as read');
              })
              .catchError((e) {
                debugPrint('Failed to mark read: $e');
              });
        }
      }
    } catch (e) {
      debugPrint("Error fetching messages: $e");
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $amPm';
    } catch (_) {
      return '';
    }
  }

  Future<void> _sendChatMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeChatCandidate == null) return;

    if (ChatFilter.hasProhibitedContent(text)) {
      _showSecurityBlockDialog();
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    final candidateId = _activeChatCandidate!.id;
    if (userId == null) return;

    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'sender_id': userId,
        'receiver_id': candidateId,
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("MESSAGE SEND EXCEPTION: $e");
      try {
        await _supabase.from('chat_messages').insert({
          'sender_id': userId,
          'receiver_id': candidateId,
          'message': text,
          'content': text,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e2) {
        debugPrint("MESSAGE SEND EXCEPTION FALLBACK: $e2");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send message: $e2')),
          );
        }
      }
    }
  }

  void _showSecurityBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gpp_bad, color: Colors.red),
            SizedBox(width: 8),
            Text('Message Blocked'),
          ],
        ),
        content: const Text(
          'ഫോൺ നമ്പറുകളോ സോഷ്യൽ മീഡിയ അക്കൗണ്ടുകളോ നേരിട്ട് പങ്കുവെക്കാൻ അനുവാദമില്ല.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'I Understand',
              style: TextStyle(
                color: Color(0xFF000080),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildUpgradeOverlay(BuildContext context, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium Secure Inbox"),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade300, width: 2),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 64,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "പ്രീമിയം ഇൻബോക്സ് ലോക്ക് ചെയ്തിരിക്കുന്നു",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "മറ്റ് അംഗങ്ങളുമായി സുരക്ഷിതമായി സന്ദേശങ്ങൾ അയക്കാനും ചാറ്റ് ചെയ്യാനും പ്രീമിയം അംഗത്വം ആവശ്യമാണ്.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ബെനിഫിറ്റുകൾ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text("നേരിട്ടുള്ള കുടുംബ സന്ദേശങ്ങൾ"),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text("തത്സമയ മെസ്സേജ് അലേർട്ടുകൾ"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // അപ്ഗ്രേഡ് ബട്ടൺ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // സബ്സ്ക്രിപ്ഷൻ പ്ലാൻ പേജിലേക്ക് പോകാൻ
                    Navigator.pushNamed(context, '/subscription_plans');
                  },
                  icon: const Icon(Icons.star, color: Colors.white),
                  label: const Text(
                    "പ്ലാൻ അപ്ഗ്രേഡ് ചെയ്യുക",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatWindow(
    UserProfile candidate,
    MockData mockData,
    ThemeData theme,
  ) {
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(candidate.photoUrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Active Connection',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _activeChatCandidate = null;
              NotificationManager.currentActiveChatId = null;
            });
          },
        ),
        actions: [
          if (mockData.currentUser?.agreedMutualMatches.contains(
                candidate.id,
              ) ==
              true)
            TextButton.icon(
              onPressed: () {
                PdfService.generateAndDownloadAgreementPdf(
                  currentUser: mockData.currentUser!,
                  targetProfile: candidate,
                  agreementId: 'KM-BOND--',
                );
              },
              icon: const Icon(Icons.download, color: Colors.white, size: 18),
              label: const Text(
                'Agreement PDF',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
            tooltip: 'Marriage Registration Assistant',
            onPressed: () {
              final isCurrentUserMale =
                  mockData.currentUser!.gender.toString() == 'Gender.male' ||
                  mockData.currentUser!.gender.name == 'male';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RegistrationGuidePage(
                    groomName: isCurrentUserMale
                        ? mockData.currentUser!.name
                        : candidate.name,
                    brideName: isCurrentUserMale
                        ? candidate.name
                        : mockData.currentUser!.name,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: const Color(0xFF000080),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mark_chat_unread_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Start a secure conversation!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Real-time messages are encrypted and private.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == userId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF0D47A1)
                                : Colors.grey.shade200,
                            border: Border.all(
                              color: (isMe && msg['is_read'] == true)
                                  ? const Color(0xFF00E5FF)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: (isMe && msg['is_read'] == true)
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00E5FF,
                                      ).withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      spreadRadius: 1.5,
                                    ),
                                  ]
                                : null,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe
                                  ? const Radius.circular(16)
                                  : Radius.zero,
                              bottomRight: isMe
                                  ? Radius.zero
                                  : const Radius.circular(16),
                            ),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['message'] as String,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(msg['created_at']?.toString()),
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (isMe && msg['is_read'] == true) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.amberAccent,
                                      size: 12,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type secure message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF000080)),
                  onPressed: _sendChatMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, child) {
        final mockData = MockData();
        final me = mockData.currentUser;

        if (me == null) {
          return const Center(child: Text('Please sign in first'));
        }

        // Access Control Check: Premium is required
        if (!me.isPremium) {
          return _buildUpgradeOverlay(context, theme);
        }

        // If a chat is active, show the conversation window
        if (_activeChatCandidate != null) {
          return _buildChatWindow(_activeChatCandidate!, mockData, theme);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Premium Secure Inbox',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5C3E00),
                ),
              ),
            ),
            Expanded(
              child: _isLoadingCandidates
                  ? const Center(child: CircularProgressIndicator())
                  : _chatCandidates.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Your Secure Inbox is empty.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Shortlist candidates from your matching pool to initiate secure family-to-family messages.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _chatCandidates.length,
                      itemBuilder: (context, index) {
                        final candidate = _chatCandidates[index];
                        final lastMsgText =
                            _lastMessages[candidate.id] ??
                            'Click to start chatting securely';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            onTap: () => _openChat(candidate),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundImage: NetworkImage(candidate.photoUrl),
                            ),
                            title: Text(
                              candidate.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              lastMsgText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
