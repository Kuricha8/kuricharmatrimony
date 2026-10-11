import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  int _badgeCount = 0;
  bool _isListening = false;
  RealtimeChannel? _subscription;

  int get badgeCount => _badgeCount;

  void init() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _isListening) return;

    _isListening = true;

    // Initial fetch of unread count
    _fetchInitialCount(userId);

    // Subscribe to realtime updates on notifications table for this user (v2 API)
    _subscription = _supabase
        .channel('public:notifications:user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (PostgresChangePayload payload) {
            _handleRealtimePayload(payload);
          },
        )
        .subscribe();
  }

  Future<void> _fetchInitialCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      _badgeCount = response.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching initial notifications: $e');
    }
  }

  void _handleRealtimePayload(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;

    if (payload.eventType == PostgresChangeEvent.insert) {
      if (newRecord['is_read'] == false) {
        _badgeCount++;
        notifyListeners();
      }
    } else if (payload.eventType == PostgresChangeEvent.update) {
      final wasRead = oldRecord['is_read'] == true;
      final isRead = newRecord['is_read'] == true;

      if (!wasRead && isRead) {
        _badgeCount = (_badgeCount > 0) ? _badgeCount - 1 : 0;
        notifyListeners();
      } else if (wasRead && !isRead) {
        _badgeCount++;
        notifyListeners();
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      if (oldRecord['is_read'] == false) {
        _badgeCount = (_badgeCount > 0) ? _badgeCount - 1 : 0;
        notifyListeners();
      }
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      // The realtime listener will decrement the badge count
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
      // Realtime listener will handle multiple updates, or we can just zero it out
      _badgeCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _isListening = false;
    super.dispose();
  }
}
