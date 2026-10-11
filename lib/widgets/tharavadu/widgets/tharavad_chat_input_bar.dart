import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/mock_data.dart';
import '../tharavadu_media_service.dart';

class TharavadChatInputBar extends StatefulWidget {
  final Clan clan;
  final UserProfile? currentUser;

  const TharavadChatInputBar({super.key, required this.clan, this.currentUser});

  @override
  State<TharavadChatInputBar> createState() => _TharavadChatInputBarState();
}

class _TharavadChatInputBarState extends State<TharavadChatInputBar> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ValueNotifier<bool> _hasTextNotifier = ValueNotifier<bool>(false);

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedAudioPath;

  // Scope switcher state
  String _selectedScope =
      'THARAVAD_ONLY'; // 'THARAVAD_ONLY', 'GLOBAL_ALL', 'GUEST_PUBLIC'

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      _hasTextNotifier.value = _messageController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _hasTextNotifier.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  String _getCurrentUserId() {
    return _supabase.auth.currentUser?.id ??
        widget.currentUser?.id ??
        MockData().currentUser?.id ??
        'user_1';
  }

  Future<void> sendClanMessage({
    required String tharavadName,
    required String messageType,
    required String content,
    String? mediaUrl,
    int duration = 0,
  }) async {
    final user = widget.currentUser ?? MockData().currentUser;
    if (user == null) return;

    final currentUserName = user.name.isNotEmpty ? user.name : 'അംഗം';

    await _supabase.from('tharavad_chat_messages').insert({
      'sender_id': user.id,
      'sender_name': currentUserName,
      'tharavad_name': tharavadName,
      'message_type': messageType,
      'content': content,
      'media_url': mediaUrl ?? (messageType != 'TEXT' ? content : null),
      'media_duration': duration,
      'audience_scope': _selectedScope,
      'status': 'SENT',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await sendClanMessage(
        tharavadName: widget.clan.name,
        messageType: 'TEXT',
        content: text,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _startVoiceRecording() async {
    if (_isRecording) {
      try {
        final path = await _audioRecorder.stop();
        final finalPath = path ?? _recordedAudioPath;
        setState(() {
          _isRecording = false;
        });
        if (finalPath != null && File(finalPath).existsSync()) {
          _uploadAndSendVoiceNote(finalPath);
        }
      } catch (e) {
        debugPrint('Error stopping voice recording: $e');
        setState(() => _isRecording = false);
      }
      return;
    }

    try {
      final hasPerm = await _audioRecorder.hasPermission();
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('മൈക്രോഫോൺ അനുമതി ആവശ്യമാണ്.')),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordedAudioPath = filePath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'വോയ്‌സ് റെക്കോർഡിംഗ് ആരംഭിച്ചു. നിർത്താൻ വീണ്ടും അമർത്തുക.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting voice recording: $e');
    }
  }

  Future<void> _uploadAndSendVoiceNote(String localPath) async {
    try {
      final userId = _getCurrentUserId();
      final fileName =
          'voice_${DateTime.now().millisecondsSinceEpoch}_$userId.m4a';
      final file = File(localPath);
      final bytes = await file.readAsBytes();

      String audioUrl = localPath;
      try {
        await _supabase.storage
            .from('clan_chat_media')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'audio/m4a',
                upsert: true,
              ),
            );
        audioUrl = _supabase.storage
            .from('clan_chat_media')
            .getPublicUrl(fileName);
      } catch (_) {
        // Fallback to chat_media
        try {
          await _supabase.storage
              .from('chat_media')
              .uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(
                  contentType: 'audio/m4a',
                  upsert: true,
                ),
              );
          audioUrl = _supabase.storage
              .from('chat_media')
              .getPublicUrl(fileName);
        } catch (e) {
          debugPrint('Voice note storage upload error: $e');
        }
      }

      await sendClanMessage(
        tharavadName: widget.clan.name,
        messageType: 'AUDIO',
        content: audioUrl,
        mediaUrl: audioUrl,
      );
    } catch (e) {
      debugPrint('Voice upload error: $e');
    }
  }

  Future<void> _pickAndSendImage() async {
    final file = await TharavaduMediaService.instance.pickImage();
    if (file != null) {
      final userId = _getCurrentUserId();

      String? imageUrl;
      try {
        imageUrl = await TharavaduMediaService.instance.uploadMediaFile(
          file: file,
          userId: userId,
          bucket: 'clan_chat_media',
        );
      } catch (e) {
        debugPrint('Media upload error: $e');
        imageUrl = file.path;
      }

      if (imageUrl != null) {
        await sendClanMessage(
          tharavadName: widget.clan.name,
          messageType: 'IMAGE',
          content: imageUrl,
          mediaUrl: imageUrl,
        );
      }
    }
  }

  Future<void> _pickAndSendVideo() async {
    final picked = await TharavaduMediaService.instance.pickVideo(
      context: context,
    );
    if (picked != null) {
      final userId = _getCurrentUserId();

      String? videoUrl;
      try {
        videoUrl = await TharavaduMediaService.instance.uploadMediaFile(
          file: picked.file,
          userId: userId,
          bucket: 'clan_chat_media',
        );
      } catch (e) {
        debugPrint('Video upload error: $e');
        videoUrl = picked.file.path;
      }

      if (videoUrl != null) {
        await sendClanMessage(
          tharavadName: widget.clan.name,
          messageType: 'VIDEO',
          content: videoUrl,
          mediaUrl: videoUrl,
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attachmentOptionItem(
                icon: Icons.photo,
                color: Colors.blueAccent,
                label: 'Image Gallery',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage();
                },
              ),
              _attachmentOptionItem(
                icon: Icons.videocam,
                color: Colors.redAccent,
                label: 'Video Clip',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentOptionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _scopeChip('THARAVAD_ONLY', '🔒 THARAVAD_ONLY'),
          _scopeChip('GLOBAL_ALL', '🌐 GLOBAL_ALL'),
          _scopeChip('GUEST_PUBLIC', '👥 GUEST_PUBLIC'),
        ],
      ),
    );
  }

  Widget _scopeChip(String scopeKey, String label) {
    final isSelected = _selectedScope == scopeKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedScope = scopeKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF000080) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  void _pickAndSendMedia(BuildContext ctx) {
    _showAttachmentOptions();
  }

  void _recordAndSendVoiceNote() {
    _startVoiceRecording();
  }

  void _sendTextMessage() {
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildScopeSelector(),
          const Divider(height: 1, color: Colors.black12),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                // Attachment / Gallery / Camera (Photos & Videos)
                IconButton(
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    color: Colors.blue,
                  ),
                  onPressed: () => _pickAndSendMedia(context),
                ),
                // Text Field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'മെസ്സേജ് അല്ലെങ്കിൽ മീഡിയ അയക്കുക...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // Audio / Voice Record Button
                IconButton(
                  icon: Icon(
                    Icons.mic_rounded,
                    color: _isRecording ? Colors.redAccent : Colors.teal,
                  ),
                  onPressed: () => _recordAndSendVoiceNote(),
                ),
                // Send Button
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.indigo),
                  onPressed: () => _sendTextMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
