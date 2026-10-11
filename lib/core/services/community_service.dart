import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../utils/mock_data.dart';

class CommunityService {
  static final CommunityService instance = CommunityService._();
  CommunityService._();

  SupabaseClient get _supabase => Supabase.instance.client;
  RealtimeChannel? _announcementChannel;
  RealtimeChannel? _historyChannel;

  void subscribeToUpdates() {
    _subscribeToAnnouncements();
    _subscribeToHistory();
  }

  void _subscribeToAnnouncements() {
    _announcementChannel = _supabase
        .channel('public:announcements')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (payload) {
            fetchAnnouncements();
          },
        )
        .subscribe();
    fetchAnnouncements();
  }

  void _subscribeToHistory() {
    _historyChannel = _supabase
        .channel('public:community_history')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_history',
          callback: (payload) {
            fetchHistory();
          },
        )
        .subscribe();
    fetchHistory();
  }

  Future<void> fetchAnnouncements() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => Announcement.fromMap(json))
          .toList();
      MockData().updateAnnouncements(list);
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
      // Mock Fallback
      MockData().updateAnnouncements([
        Announcement(
          id: 'm1',
          message:
              'Welcome to the Kurichiyar Matrimony App! Explore our new features.',
          imageUrl:
              'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=800',
          targetType: 'all',
          createdAt: DateTime.now(),
        ),
      ]);
    }
  }

  Future<void> fetchHistory() async {
    try {
      final response = await _supabase
          .from('community_history')
          .select()
          .order('date', ascending: false);

      final list = (response as List)
          .map((json) => CommunityHistory.fromMap(json))
          .toList();
      MockData().updateHistory(list);
    } catch (e) {
      debugPrint('Error fetching history: $e');
      // Mock Fallback
      MockData().updateHistory([
        CommunityHistory(
          id: 'h1',
          title: 'The Great Kurichiyar Uprising',
          content:
              'The Kurichiyars are a scheduled tribe of Kerala, known for their participation in the Pazhassi Raja revolts against the British...',
          imageUrl:
              'https://images.unsplash.com/photo-1517436073-3b1b1b1b1b1b?w=800',
          date: DateTime(1812, 1, 1),
        ),
      ]);
    }
  }

  void dispose() {
    _announcementChannel?.unsubscribe();
    _historyChannel?.unsubscribe();
  }
}
