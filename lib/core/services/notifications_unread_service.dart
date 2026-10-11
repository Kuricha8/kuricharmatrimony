import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsUnreadService {
  NotificationsUnreadService._();
  static final NotificationsUnreadService instance =
      NotificationsUnreadService._();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  RealtimeChannel? _subscription;
  String? _currentUserId;

  Future<void> init(String userId) async {
    _currentUserId = userId;
    await _fetchInitialCount();
    _setupRealtime();
  }

  Future<void> _fetchInitialCount() async {
    if (_currentUserId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', _currentUserId!)
          .eq('is_read', false);

      unreadCount.value = (response as List).length;
    } catch (e) {
      debugPrint('Error fetching unread notifications count: $e');
    }
  }

  void _setupRealtime() {
    if (_currentUserId == null) return;

    _subscription?.unsubscribe();
    _subscription = Supabase.instance.client
        .channel('public:notifications:unread_$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _currentUserId!,
          ),
          callback: (payload) {
            _fetchInitialCount(); // Re-fetch on any change to stay perfectly in sync
          },
        )
        .subscribe();
  }

  void dispose() {
    _subscription?.unsubscribe();
    unreadCount.dispose();
  }
}
