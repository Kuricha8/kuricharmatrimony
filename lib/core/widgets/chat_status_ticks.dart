import 'package:flutter/material.dart';

enum MessageDeliveryStatus { sending, sent, delivered, read }

class ChatStatusTicks extends StatelessWidget {
  final MessageDeliveryStatus status;
  final double size;

  const ChatStatusTicks({super.key, required this.status, this.size = 14});

  factory ChatStatusTicks.fromMap(
    Map<String, dynamic> msg, {
    bool isMe = true,
  }) {
    if (!isMe) return const ChatStatusTicks(status: MessageDeliveryStatus.read);

    final isSeen =
        msg['is_seen'] == true ||
        msg['is_read'] == true ||
        msg['read_at'] != null ||
        msg['status'] == 'read' ||
        msg['read_by_user'] == true ||
        msg['read_by_admin'] == true;

    if (isSeen) {
      // Red Double Tick (✓✓) [Color: Colors.redAccent]
      return const ChatStatusTicks(status: MessageDeliveryStatus.read);
    }

    final isDelivered =
        msg['status'] == 'delivered' || msg['delivered_at'] != null;
    if (isDelivered) {
      // Blue Double Tick (✓✓) [Color: Colors.blueAccent]
      return const ChatStatusTicks(status: MessageDeliveryStatus.delivered);
    }

    final isSending =
        msg['id'] != null && msg['id'].toString().startsWith('temp_');
    if (isSending) {
      return const ChatStatusTicks(status: MessageDeliveryStatus.sending);
    }

    // Single Green Tick (✓) [Color: Colors.green]
    return const ChatStatusTicks(status: MessageDeliveryStatus.sent);
  }

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return Icon(Icons.access_time, size: size - 2, color: Colors.white70);

      case MessageDeliveryStatus.sent:
        // Sent (Message saved to server): Single Green Tick (✓) [Color: Colors.green]
        return Icon(Icons.check, size: size, color: Colors.green);

      case MessageDeliveryStatus.delivered:
        // Delivered (Reached receiver's device): Blue Double Tick (✓✓) [Color: Colors.blueAccent]
        return Icon(Icons.done_all, size: size, color: Colors.blueAccent);

      case MessageDeliveryStatus.read:
        // Seen / Read: Red Double Tick (✓✓) [Color: Colors.redAccent]
        return Icon(Icons.done_all, size: size, color: Colors.redAccent);
    }
  }
}
