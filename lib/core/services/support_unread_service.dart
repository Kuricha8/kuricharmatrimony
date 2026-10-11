import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks unread support messages (admin replies not yet read by the user).
/// Exposes [unreadCount] as a [ValueNotifier] so widgets can reactively rebuild.
class SupportUnreadService {
  SupportUnreadService._();
  static final SupportUnreadService instance = SupportUnreadService._();

  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  RealtimeChannel? _channel;
  String? _userId;
  bool _initialized = false;

  /// Call once from [DashboardShell.initState] after the user is known.
  void init(String userId) {
    if (_initialized && _userId == userId) return;
    _userId = userId;
    _initialized = true;

    _fetchUnread();
    _subscribeRealtime();
  }

  /// Call when the user opens the support chat screen — reset badge to 0.
  void markAllRead() {
    unreadCount.value = 0;
  }

  /// Dispose when the user logs out.
  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
    _userId = null;
    _initialized = false;
    unreadCount.value = 0;
  }

  Future<void> _fetchUnread() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final res = await Supabase.instance.client
          .from('support_messages')
          .select('id')
          .eq('user_id', userId)
          .eq('is_from_admin', true)
          .eq('read_by_user', false);
      unreadCount.value = res.length;
    } on PostgrestException catch (pe) {
      debugPrint(
        'SupportUnreadService PostgrestException (safe fallback): ${pe.message}',
      );
    } catch (e) {
      debugPrint('SupportUnreadService fetch error: $e');
    }
  }

  void _subscribeRealtime() {
    final userId = _userId;
    if (userId == null) return;

    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('support_unread_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'support_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _fetchUnread(),
        )
        .subscribe((status, [error]) {
          debugPrint('SupportUnreadService realtime: $status');
        });
  }
}
