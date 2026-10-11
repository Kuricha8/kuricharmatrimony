import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../core/kurichiyar_clan_engine.dart';

class TharavadChatRoomScreen extends StatefulWidget {
  final Clan clan;
  final UserProfile? currentUser;

  const TharavadChatRoomScreen({
    super.key,
    required this.clan,
    this.currentUser,
  });

  @override
  State<TharavadChatRoomScreen> createState() => _TharavadChatRoomScreenState();
}

class _TharavadChatRoomScreenState extends State<TharavadChatRoomScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Audience scope selection
  String _selectedScope = 'PRIVATE'; // 'PRIVATE', 'GLOBAL', 'GUEST'
  int _lastMessagesCount = 0;

  // Recording State
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _localRecordingPath;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  bool _computeIsMember() {
    final user = widget.currentUser ?? MockData().currentUser;
    if (user == null || user.id == 'guest' || user.id.isEmpty) return false;
    if (user.isAdmin) return true;

    final String myMotherClan =
        (user.motherTharavadu ?? user.mothersTarawad ?? '')
            .toString()
            .toLowerCase()
            .trim();
    final String activeClan = widget.clan.name.toLowerCase().trim();

    final bool isClanMember =
        myMotherClan.isNotEmpty &&
        (activeClan.contains(myMotherClan) ||
            myMotherClan.contains(activeClan));

    if (isClanMember) return true;

    if (user.motherClanId == widget.clan.id ||
        user.fatherClanId == widget.clan.id ||
        user.tharavaduId == widget.clan.id) {
      return true;
    }

    return false;
  }

  Stream<List<Map<String, dynamic>>> getFilteredFeedStream({
    required String tharavadName,
    required String selectedScopeTab,
    required bool isClanMember,
  }) {
    return _supabase
        .from('tharavad_chat_messages')
        .stream(primaryKey: ['id'])
        .eq('tharavad_name', tharavadName)
        .map((list) {
          return list.where((row) {
            final String scope = row['audience_scope'] ?? 'THARAVAD_ONLY';
            if (selectedScopeTab == 'PRIVATE' && isClanMember) {
              return scope == 'THARAVAD_ONLY';
            } else if (selectedScopeTab == 'GLOBAL') {
              return scope == 'GLOBAL_ALL' || scope == 'GLOBAL_COMMUNITY';
            } else {
              return scope == 'GUEST_PUBLIC' || scope == 'GUEST_VIEW';
            }
          }).toList();
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

  // Audio Recording Handlers
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _localRecordingPath = path;
        });
      }
    } catch (e) {
      debugPrint('Error starting recorder: $e');
    }
  }

  Future<void> _stopAndSendAudio({bool cancel = false}) async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (cancel || path == null || _localRecordingPath == null) {
        return;
      }

      final file = File(_localRecordingPath!);
      if (!await file.exists()) return;

      // Upload to Supabase Storage: chat-media/audio
      final filename = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = 'audio/$filename';

      String audioUrl = '';
      try {
        await _supabase.storage.from('chat-media').upload(storagePath, file);
        audioUrl = _supabase.storage
            .from('chat-media')
            .getPublicUrl(storagePath);
      } catch (e) {
        debugPrint('Storage upload failed: $e. Using local path for demo.');
        audioUrl = 'file://${file.path}';
      }

      _sendChatMessage(messageType: 'AUDIO', mediaUrl: audioUrl);
    } catch (e) {
      debugPrint('Error stopping recorder: $e');
    }
  }

  // Media Picker Handlers
  Future<void> _pickAndSendMedia(FileType type) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    if (type == FileType.image) {
      pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
    } else if (type == FileType.video) {
      pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final filename =
          'media_${DateTime.now().millisecondsSinceEpoch}.${pickedFile.path.split('.').last}';
      final storagePath = 'attachments/$filename';

      String mediaUrl = '';
      try {
        await _supabase.storage.from('chat-media').upload(storagePath, file);
        mediaUrl = _supabase.storage
            .from('chat-media')
            .getPublicUrl(storagePath);
      } catch (e) {
        debugPrint('Media upload failed: $e. Using local path fallback.');
        mediaUrl = 'file://${file.path}';
      }

      _sendChatMessage(
        messageType: type == FileType.image ? 'IMAGE' : 'VIDEO',
        mediaUrl: mediaUrl,
      );
    }
  }

  // Send Message Wrapper
  Future<void> _sendChatMessage({
    String messageType = 'TEXT',
    String? mediaUrl,
  }) async {
    final textContent = _messageController.text.trim();
    if (messageType == 'TEXT' && textContent.isEmpty) return;

    final me = widget.currentUser ?? MockData().currentUser;
    final senderName = me?.name ?? 'അംഗം';
    final senderPhoto = me?.photoUrl ?? '';
    final senderId = me?.id ?? 'guest_user';

    final payload = {
      'tharavad_name': widget.clan.name,
      'sender_name': senderName,
      'sender_photo': senderPhoto,
      'sender_id': senderId,
      'text': messageType == 'TEXT' ? textContent : '',
      'media_url': mediaUrl ?? '',
      'message_type': messageType,
      'audience_scope': _selectedScope == 'PRIVATE'
          ? 'THARAVAD_ONLY'
          : (_selectedScope == 'GLOBAL' ? 'GLOBAL_ALL' : 'GUEST_PUBLIC'),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    _messageController.clear();

    try {
      // 1. Send to Supabase
      await _supabase.from('tharavad_chat_messages').insert(payload);
    } catch (e) {
      debugPrint('Supabase insert failed: $e.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('സന്ദേശം അയക്കാൻ സാധിച്ചില്ല: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final moietyLabel = KurichiyarClanEngine.getMoiety(widget.clan.name);

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // Classic WhatsApp background
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54), // Classic WhatsApp Dark Green
        foregroundColor: Colors.white,
        leadingWidth: 70,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Row(
            children: [
              const SizedBox(width: 4),
              const Icon(Icons.arrow_back, size: 24),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal.shade100,
                backgroundImage:
                    widget.clan.imageUrl != null &&
                        widget.clan.imageUrl!.isNotEmpty
                    ? NetworkImage(widget.clan.imageUrl!)
                    : null,
                child:
                    widget.clan.imageUrl == null ||
                        widget.clan.imageUrl!.isEmpty
                    ? Text(
                        widget.clan.name[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.clan.nameMl.isNotEmpty
                  ? widget.clan.nameMl
                  : widget.clan.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Builder(
                  builder: (context) {
                    final bool isOnline = widget.clan.id % 2 == 0;
                    final String lastSeenFormatted =
                        'today at ${DateFormat('h:mm a').format(DateTime.now().subtract(const Duration(minutes: 42)))}';
                    return Row(
                      children: [
                        if (isOnline) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isOnline
                              ? '$moietyLabel • Online'
                              : '$moietyLabel • Last seen: $lastSeenFormatted',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOnline
                                ? Colors.greenAccent
                                : Colors.white70,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Realtime Messages list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getFilteredFeedStream(
                tharavadName: widget.clan.name,
                selectedScopeTab: _selectedScope,
                isClanMember: _computeIsMember(),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                _scrollToBottomIfNeeded(messages.length);

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'സന്ദേശങ്ങൾ ഒന്നുമില്ല.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe =
                        msg['sender_id'] ==
                        (widget.currentUser?.id ?? MockData().currentUser?.id);
                    return _buildChatBubble(msg, isMe);
                  },
                );
              },
            ),
          ),

          // Scope Switcher Toggle Chips
          _buildScopeSelector(),

          // Input Media Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // Bubble builder
  Widget _buildChatBubble(Map<String, dynamic> msg, bool isMe) {
    final type = msg['message_type'] ?? 'TEXT';
    final mediaUrl = msg['media_url'] ?? '';
    final scope = msg['audience_scope'] ?? 'THARAVAD_ONLY';

    String scopeText = 'തറവാട് മാത്രം';
    IconData scopeIcon = Icons.lock;
    if (scope == 'GLOBAL_ALL' || scope == 'GLOBAL_COMMUNITY') {
      scopeText = 'ഗ്ലോബൽ ഫീഡ്';
      scopeIcon = Icons.public;
    } else if (scope == 'GUEST_PUBLIC' || scope == 'GUEST_VIEW') {
      scopeText = 'ഗസ്റ്റ് പേജ്';
      scopeIcon = Icons.people;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE2F9C2) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Text(
                msg['sender_name'] ?? 'അംഗം',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF075E54),
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 2),

            // Message Body by Type
            if (type == 'AUDIO')
              ChatVoicePlayerBubble(url: mediaUrl)
            else if (type == 'IMAGE')
              _buildImageMessage(mediaUrl)
            else if (type == 'VIDEO')
              _buildVideoMessage(mediaUrl)
            else
              Text(
                msg['text'] ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),

            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Audience Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(scopeIcon, size: 9, color: Colors.black54),
                      const SizedBox(width: 2),
                      Text(
                        scopeText,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTime(msg['created_at']),
                  style: const TextStyle(fontSize: 9, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMessage(String url) {
    final cleanUrl = url.replaceFirst('file://', '');
    return GestureDetector(
      onTap: () => _viewFullScreenFile(url, isVideo: false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: url.startsWith('file://')
            ? Image.file(
                File(cleanUrl),
                width: 200,
                height: 150,
                fit: BoxFit.cover,
              )
            : Image.network(url, width: 200, height: 150, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildVideoMessage(String url) {
    return GestureDetector(
      onTap: () => _viewFullScreenFile(url, isVideo: true),
      child: Container(
        width: 200,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: Icon(Icons.play_arrow, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _viewFullScreenFile(String url, {required bool isVideo}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: isVideo
                  ? const Center(
                      child: Text(
                        'Video Playback Support',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : (url.startsWith('file://')
                        ? Image.file(File(url.replaceFirst('file://', '')))
                        : Image.network(url)),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Scope toggle chips
  Widget _buildScopeSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _scopeChip('PRIVATE', '🔒 തറവാട് മാത്രം'),
          _scopeChip('GLOBAL', '🌐 എല്ലാവർക്കും'),
          _scopeChip('GUEST', '👥 ഗസ്റ്റ് പേജ്'),
        ],
      ),
    );
  }

  Widget _scopeChip(String scopeKey, String label) {
    final isSelected = _selectedScope == scopeKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.teal.shade900,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF075E54),
      backgroundColor: Colors.teal.shade50,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedScope = scopeKey;
          });
        }
      },
    );
  }

  // Input Bar
  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Attachment selector
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: () => _showAttachmentOptions(),
          ),

          // Message input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _messageController,
                maxLines: 5,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'സന്ദേശങ്ങൾ അയക്കുക...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Recording / Send button
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopAndSendAudio(),
            child: InkWell(
              onTap: () {
                if (_messageController.text.trim().isNotEmpty) {
                  _sendChatMessage();
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF075E54),
                  foregroundColor: Colors.white,
                  radius: 22,
                  child: _isRecording
                      ? const Icon(Icons.mic, color: Colors.redAccent)
                      : (_messageController.text.trim().isEmpty
                            ? const Icon(Icons.mic)
                            : const Icon(Icons.send)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attachmentItem(Icons.photo, 'Photo Gallery', () {
                Navigator.pop(ctx);
                _pickAndSendMedia(FileType.image);
              }),
              _attachmentItem(Icons.videocam, 'Video Clip', () {
                Navigator.pop(ctx);
                _pickAndSendMedia(FileType.video);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentItem(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.teal.shade50,
          child: IconButton(
            icon: Icon(icon, color: const Color(0xFF075E54)),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }
}

// In-chat Audio Player Bubble
class ChatVoicePlayerBubble extends StatefulWidget {
  final String url;
  const ChatVoicePlayerBubble({super.key, required this.url});

  @override
  State<ChatVoicePlayerBubble> createState() => _ChatVoicePlayerBubbleState();
}

class _ChatVoicePlayerBubbleState extends State<ChatVoicePlayerBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;

  @override
  void initState() {
    super.initState();
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _durationSub = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _positionSub = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        final cleanUrl = widget.url.replaceFirst('file://', '');
        if (widget.url.startsWith('file://')) {
          await _audioPlayer.play(DeviceFileSource(cleanUrl));
        } else {
          await _audioPlayer.play(UrlSource(widget.url));
        }
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint('Audio playback failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = _duration.inMilliseconds.toDouble();
    final currentVal = _position.inMilliseconds.toDouble().clamp(0.0, maxVal);

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF075E54),
            radius: 18,
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 18,
              ),
              onPressed: _toggleAudio,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  min: 0.0,
                  max: maxVal > 0 ? maxVal : 1.0,
                  value: currentVal,
                  activeColor: const Color(0xFF075E54),
                  inactiveColor: Colors.black12,
                  onChanged: (val) {
                    _audioPlayer.seek(Duration(milliseconds: val.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
