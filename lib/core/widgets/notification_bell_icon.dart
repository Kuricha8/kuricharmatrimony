import 'package:flutter/material.dart';
import '../services/notification_center_service.dart';
import '../../features/notifications/notification_center_screen.dart';

/// Reusable Notification Bell Icon for AppBars with a live unread badge counter.
class NotificationBellIcon extends StatelessWidget {
  final Color color;
  final double size;

  const NotificationBellIcon({
    super.key,
    this.color = Colors.white,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationCenterService.instance,
      builder: (context, _) {
        final unreadCount = NotificationCenterService.instance.unreadCount;

        return Badge.count(
          count: unreadCount,
          isLabelVisible: unreadCount > 0,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          alignment: Alignment.topRight,
          offset: const Offset(-2, 4),
          child: IconButton(
            icon: Icon(
              unreadCount > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: color,
              size: size,
            ),
            tooltip: 'അറിയിപ്പുകൾ (Notifications)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
