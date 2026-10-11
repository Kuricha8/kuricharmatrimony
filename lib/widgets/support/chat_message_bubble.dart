import 'package:flutter/material.dart';
import '../../core/widgets/chat_status_ticks.dart';

/// Professional, ticketing-grade chat message bubble widget.
/// Supports sender distinction (User vs Admin vs Bot), badges, timestamps, read ticks, and date dividers.
class ChatMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final String senderTitle;
  final String? userAvatarUrl;
  final bool showDateDivider;
  final String? dateDividerText;
  final VoidCallback? onSpeakTap;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.senderTitle,
    this.userAvatarUrl,
    this.showDateDivider = false,
    this.dateDividerText,
    this.onSpeakTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = message['message']?.toString() ?? '';
    final createdAt = message['created_at'] != null
        ? DateTime.tryParse(message['created_at'].toString())?.toLocal()
        : null;

    final timeStr = createdAt != null
        ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';

    final String senderType = (message['sender_type'] ?? '')
        .toString()
        .toLowerCase();
    final bool isBot = senderType == 'bot' || message['is_bot'] == true;

    Color badgeColor = Colors.amber.shade900;
    IconData badgeIcon = Icons.verified_user;
    Color avatarBg = const Color(0xFF000080);
    IconData avatarIcon = Icons.shield_outlined;
    Color avatarIconColor = Colors.amberAccent;
    String displayTitle = senderTitle.isNotEmpty ? senderTitle : 'Support Team';

    if (isBot) {
      badgeColor = Colors.teal.shade800;
      badgeIcon = Icons.smart_toy;
      avatarBg = const Color(0xFF005F73);
      avatarIcon = Icons.smart_toy;
      avatarIconColor = Colors.cyanAccent;
      displayTitle = '🤖 Support Assistant';
    }

    return Column(
      children: [
        if (showDateDivider &&
            dateDividerText != null &&
            dateDividerText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dateDividerText!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: avatarBg,
                  child: Icon(avatarIcon, size: 16, color: avatarIconColor),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF000080) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 2),
                      bottomRight: Radius.circular(isMe ? 2 : 16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(
                            color: isBot
                                ? Colors.teal.shade100
                                : Colors.grey.shade200,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badgeIcon, size: 12, color: badgeColor),
                            const SizedBox(width: 4),
                            Text(
                              displayTitle,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (onSpeakTap != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: onSpeakTap,
                                child: Icon(
                                  Icons.volume_up,
                                  size: 14,
                                  color: badgeColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                          height: 1.35,
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
                            ChatStatusTicks.fromMap(message, isMe: true),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 8),
              if (!isMe) const SizedBox(width: 32),
            ],
          ),
        ),
      ],
    );
  }
}
