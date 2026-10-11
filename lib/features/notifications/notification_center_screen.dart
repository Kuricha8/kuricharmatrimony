import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/notification_center_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'ഇപ്പോൾ (Just now)';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} മിനിറ്റ് മുൻപ് (${diff.inMinutes}m ago)';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} മണിക്കൂർ മുൻപ് (${diff.inHours}h ago)';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ദിവസം മുൻപ് (${diff.inDays}d ago)';
    } else {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'approval':
      case 'approved':
      case 'verified':
        return Icons.verified_user_rounded;
      case 'match':
      case 'interest':
      case 'like':
        return Icons.favorite_rounded;
      case 'new_member':
      case 'registration':
        return Icons.person_add_alt_1_rounded;
      case 'lineage':
      case 'clan':
      case 'checker':
        return Icons.account_tree_rounded;
      case 'announcement':
      case 'update':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'approval':
      case 'approved':
      case 'verified':
        return const Color(0xFF2E7D32);
      case 'match':
      case 'interest':
      case 'like':
        return const Color(0xFFD81B60);
      case 'new_member':
      case 'registration':
        return const Color(0xFF1976D2);
      case 'lineage':
      case 'clan':
      case 'checker':
        return const Color(0xFF00796B);
      case 'announcement':
      case 'update':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF1E3A8A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationCenterService.instance,
      builder: (context, _) {
        final notifications =
            NotificationCenterService.instance.currentNotifications;
        final unreadCount = NotificationCenterService.instance.unreadCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'അറിയിപ്പുകൾ (Inbox)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  unreadCount > 0
                      ? '$unreadCount പുതിയ അറിയിപ്പുകൾ (Unread)'
                      : 'എല്ലാ അറിയിപ്പുകളും വായിച്ചു',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            actions: [
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: () async {
                    await NotificationCenterService.instance.markAllAsRead();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('എല്ലാ അറിയിപ്പുകളും വായിച്ചതായി അടയാളപ്പെടുത്തി'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.done_all_rounded, color: Colors.amber, size: 18),
                  label: const Text(
                    'വായിച്ചു',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFF1E3A8A),
                  onRefresh: () async {
                    // Trigger refresh
                    await Future.delayed(const Duration(milliseconds: 400));
                  },
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return _buildNotificationCard(item);
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'അറിയിപ്പുകൾ ഒന്നുമില്ല',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'പുതിയ പ്രൊഫൈലുകൾ, അപ്രൂവലുകൾ, പ്രധാന അറിയിപ്പുകൾ വരുമ്പോൾ ഇവിടെ കാണാം.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationItem item) {
    final iconColor = _getNotificationColor(item.type);
    final iconData = _getNotificationIcon(item.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          NotificationCenterService.instance.markAsRead(item.id);
          if (item.route != null && item.route!.isNotEmpty) {
            Navigator.pushNamed(context, item.route!);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFF4F7FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? Colors.black.withValues(alpha: 0.05)
                  : const Color(0xFF1E3A8A).withValues(alpha: 0.25),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Notification Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  item.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E3A8A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(item.createdAt),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
