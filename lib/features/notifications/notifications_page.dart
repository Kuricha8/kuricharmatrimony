import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    _cleanupOldNotifications();
  }

  Future<void> _cleanupOldNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Purge notifications older than 7 days
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .toUtc()
        .toIso8601String();

    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('user_id', user.id)
          .lt('created_at', cutoff);
      debugPrint('Cleaned up old notifications for user ${user.id}');
    } catch (e) {
      debugPrint('Error cleaning up notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view notifications.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('notifications')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', user.id)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final now = DateTime.now().toUtc();
                final rawNotifications = snapshot.data ?? [];

                final myNotifications = rawNotifications.where((n) {
                  if (n['is_read'] != true) return true;
                  if (n['read_at'] == null) return true;
                  try {
                    final readAt = DateTime.parse(
                      n['read_at'].toString(),
                    ).toUtc();
                    return now.difference(readAt).inHours < 2;
                  } catch (_) {
                    return true;
                  }
                }).toList();

                if (myNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No new notifications',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: myNotifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notif = myNotifications[index];
                    return _NotificationDbTile(
                      notificationData: notif,
                      onTap: () {
                        _showNotificationDetails(context, notif);
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    Map<String, dynamic> notif,
  ) {
    if (notif['is_read'] != true) {
      Supabase.instance.client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', notif['id'])
          .then(
            (_) => debugPrint('Marked notification ${notif['id']} as read.'),
          );
    }

    final title = notif['title'] ?? 'Notification';
    final body = notif['body'] ?? '';
    final imageUrl = notif['image_url'] as String?;
    final linkUrl =
        notif['link_url'] as String? ?? notif['action_url'] as String?;
    final type = notif['type'] as String? ?? 'general';
    final createdAt =
        DateTime.tryParse(notif['created_at']?.toString() ?? '') ??
        DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    final isAdmin = type == 'admin_broadcast' || type == 'admin';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 12),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isAdmin)
                        const Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blueAccent,
                              child: Icon(
                                Icons.campaign,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                          ],
                        )
                      else
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade200,
                          child: Icon(
                            Icons.notifications,
                            color: Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? Colors.red.shade50
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                type.toUpperCase().replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isAdmin ? Colors.red : Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => const SizedBox(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (linkUrl != null && linkUrl.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final uri = Uri.tryParse(linkUrl);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.link),
                      label: const Text(
                        'Open Link',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.black54),
                      label: const Text(
                        'Dismiss',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _NotificationDbTile extends StatelessWidget {
  final Map<String, dynamic> notificationData;
  final VoidCallback onTap;

  const _NotificationDbTile({
    required this.notificationData,
    required this.onTap,
  });

  IconData _getIcon() {
    final type = notificationData['type'] as String?;
    switch (type) {
      case 'admin_broadcast':
        return Icons.campaign;
      case 'new_match':
        return Icons.favorite;
      case 'interest_alert':
        return Icons.volunteer_activism;
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'agreement_signed':
        return Icons.history_edu;
      case 'payment_success':
        return Icons.check_circle;
      case 'subscription_active':
        return Icons.workspace_premium;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor() {
    final type = notificationData['type'] as String?;
    switch (type) {
      case 'admin_broadcast':
        return Colors.red;
      case 'new_match':
        return Colors.pink;
      case 'interest_alert':
        return Colors.purple;
      case 'new_message':
        return Colors.blue;
      case 'agreement_signed':
        return Colors.teal;
      case 'payment_success':
        return Colors.green;
      case 'subscription_active':
        return Colors.amber.shade800;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final createdAt =
        DateTime.tryParse(notificationData['created_at']?.toString() ?? '') ??
        DateTime.now();
    final isRead = notificationData['is_read'] == true;
    final type = notificationData['type'] as String? ?? 'general';
    final isAdmin = type == 'admin_broadcast' || type == 'admin';

    return Stack(
      children: [
        Card(
          elevation: isRead ? 0 : 2,
          color: isRead ? Colors.grey.shade50 : Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isRead
                  ? Colors.grey.shade200
                  : _getColor().withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: isRead
                        ? Colors.grey.shade200
                        : _getColor().withValues(alpha: 0.1),
                    child: Icon(
                      _getIcon(),
                      color: isRead ? Colors.grey : _getColor(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? Colors.red.shade50
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                type.toUpperCase().replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isAdmin ? Colors.red : Colors.blue,
                                ),
                              ),
                            ),
                            Text(
                              dateFormat.format(createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notificationData['title'] ?? 'Notification',
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 16,
                            color: isRead ? Colors.black54 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notificationData['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isRead)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _getColor(),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getColor().withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
