import 'dart:io';
import 'package:flutter/material.dart';

class TharavaduComposerBar extends StatelessWidget {
  final bool canPost;
  final bool isUploading;
  final bool isRecording;
  final int recordDurationSeconds;
  final File? pendingMediaFile;
  final bool pendingIsVideo;
  final String? pendingVideoDuration;
  final TextEditingController messageController;
  final String selectedVisibility;
  final ValueChanged<String> onVisibilityChanged;
  final bool isTharavaduTag;
  final ValueChanged<bool> onTharavaduTagChanged;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onTagCandidate;
  final VoidCallback onToggleVoice;
  final VoidCallback onCancelVoice;
  final VoidCallback onSendVoice;
  final VoidCallback onRemovePendingMedia;
  final VoidCallback onSendMessage;

  const TharavaduComposerBar({
    super.key,
    required this.canPost,
    required this.isUploading,
    required this.isRecording,
    required this.recordDurationSeconds,
    required this.pendingMediaFile,
    required this.pendingIsVideo,
    required this.pendingVideoDuration,
    required this.messageController,
    this.selectedVisibility = 'members_only',
    this.isTharavaduTag = false,
    required this.onTharavaduTagChanged,
    required this.onVisibilityChanged,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onTagCandidate,
    required this.onToggleVoice,
    required this.onCancelVoice,
    required this.onSendVoice,
    required this.onRemovePendingMedia,
    required this.onSendMessage,
  });

  String _formatTimer(int totalSecs) {
    final m = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Posting Restriction: If visiting another Tharavadu's feed, keep the bottom posting bar completely hidden (Read-only / Guest mode).
    if (!canPost) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 2. Post Visibility Dropdown / Selector
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 15,
                      color: Color(0xFF000080),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'കാണാവുന്നത്:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000080),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildVisibilityOption(
                              keyName: 'members_only',
                              icon: Icons.lock_outline,
                              label: '🔒 തറവാട്ടുകാർക്ക്',
                              tooltip: 'ഈ തറവാട്ടിലെ അംഗങ്ങൾക്ക് മാത്രം കാണാം',
                              activeColor: const Color(0xFF000080),
                            ),
                            const SizedBox(width: 6),
                            _buildVisibilityOption(
                              keyName: 'public',
                              icon: Icons.public,
                              label: '🌐 എല്ലാവർക്കും',
                              tooltip:
                                  'എല്ലാ തറവാട്ടുകാർക്കും കാണാം (Universal / Community)',
                              activeColor: const Color(0xFF1B5E20),
                            ),
                            const SizedBox(width: 6),
                            _buildVisibilityOption(
                              keyName: 'guest_only',
                              icon: Icons.remove_red_eye_outlined,
                              label: '👁️ ഗെസ്റ്റ് മോഡ്',
                              tooltip: 'ഗെസ്റ്റ് സന്ദർശകർക്ക് വായിക്കാം',
                              activeColor: const Color(0xFFE65100),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Staged Media Preview Banner & Tharavadu Tag Option
              if (pendingMediaFile != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isTharavaduTag
                        ? Colors.amber.shade50
                        : Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTharavaduTag
                          ? Colors.amber.shade400
                          : Colors.blueGrey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: pendingIsVideo
                                ? Container(
                                    width: 44,
                                    height: 44,
                                    color: const Color(0xFF000080),
                                    child: const Icon(
                                      Icons.videocam,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  )
                                : Image.file(
                                    pendingMediaFile!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pendingIsVideo
                                      ? 'വീഡിയോ ചേർത്തു (${pendingVideoDuration ?? "Selected"})'
                                      : (isTharavaduTag
                                            ? '🏛️ തറവാട് ഐക്കൺ നോമിനേഷൻ'
                                            : 'ഫോട്ടോ ചേർത്തു (Photo Selected)'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isTharavaduTag
                                        ? const Color(0xFF5C3E00)
                                        : const Color(0xFF000080),
                                  ),
                                ),
                                Text(
                                  pendingMediaFile!.path
                                      .split(Platform.pathSeparator)
                                      .last,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: onRemovePendingMedia,
                            tooltip: 'Remove Media',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      if (!pendingIsVideo) ...[
                        const Divider(height: 12),
                        InkWell(
                          onTap: () => onTharavaduTagChanged(!isTharavaduTag),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isTharavaduTag,
                                activeColor: const Color(0xFF000080),
                                onChanged: (val) =>
                                    onTharavaduTagChanged(val ?? false),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 4),
                              const Expanded(
                                child: Text(
                                  'തറവാട് ഔദ്യോഗിക ഫോട്ടോയായി ടാഗ് ചെയ്യുക (ഏറ്റവും കൂടുതൽ ലൈക്ക് ലഭിച്ചാൽ പ്രൊഫൈൽ ഐക്കണാകും)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF000080),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Voice Recording Active Bar
              if (isRecording)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'റെക്കോർഡ് ചെയ്യുന്നു: ${_formatTimer(recordDurationSeconds)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                        tooltip: 'Cancel',
                        onPressed: onCancelVoice,
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF000080)),
                        tooltip: 'Send Audio',
                        onPressed: onSendVoice,
                      ),
                    ],
                  ),
                )
              else
                // Regular Input Bar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.add_photo_alternate,
                        color: Color(0xFF000080),
                        size: 22,
                      ),
                      tooltip: 'ഫോട്ടോ തിരഞ്ഞെടുക്കുക',
                      onPressed: isUploading ? null : onPickImage,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.videocam,
                        color: Color(0xFF000080),
                        size: 22,
                      ),
                      tooltip: 'വീഡിയോ (Max 30 min)',
                      onPressed: isUploading ? null : onPickVideo,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.loyalty_outlined,
                        color: Colors.amber,
                        size: 22,
                      ),
                      tooltip: 'വിവാഹാലോചന ടാഗ് ചെയ്യുക',
                      onPressed: isUploading ? null : onTagCandidate,
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: messageController,
                          minLines: 1,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'തറവാട് സന്ദേശം ടൈപ്പ് ചെയ്യുക...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.mic,
                        color: Color(0xFF000080),
                        size: 22,
                      ),
                      tooltip: 'വോയ്‌സ് മെസ്സേജ്',
                      onPressed: isUploading ? null : onToggleVoice,
                    ),
                    if (isUploading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF000080),
                          ),
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF000080),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 16,
                          ),
                          onPressed: onSendMessage,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityOption({
    required String keyName,
    required IconData icon,
    required String label,
    required String tooltip,
    required Color activeColor,
  }) {
    final isSelected = selectedVisibility == keyName;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onVisibilityChanged(keyName),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
