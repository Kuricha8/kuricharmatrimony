import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/mock_data.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String type;
  final bool isRead;
  final String? route;
  final Map<String, dynamic>? data;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.type = 'general',
    this.isRead = false,
    this.route,
    this.data,
  });

  AppNotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    String? type,
    bool? isRead,
    String? route,
    Map<String, dynamic>? data,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      route: route ?? this.route,
      data: data ?? this.data,
    );
  }
}

/// Service managing the Notification Inbox and unread badge count
/// with support for Firestore streams, Supabase fallback, and Guest broadcast notifications.
class NotificationCenterService extends ChangeNotifier {
  static final NotificationCenterService _instance =
      NotificationCenterService._internal();
  static NotificationCenterService get instance => _instance;

  NotificationCenterService._internal() {
    _init();
  }

  static const String _readIdsPrefKey = 'read_notification_ids_v1';
  final Set<String> _readIds = {};
  int _unreadCount = 0;
  List<AppNotificationItem> _currentNotifications = [];
  StreamSubscription? _firestoreSub;

  int get unreadCount => _unreadCount;
  List<AppNotificationItem> get currentNotifications =>
      List.unmodifiable(_currentNotifications);

  Future<void> _init() async {
    await _loadReadIds();
    _listenToNotifications();
  }

  Future<void> _loadReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_readIdsPrefKey);
      if (list != null) {
        _readIds.addAll(list);
      }
    } catch (e) {
      debugPrint('Error loading read notification ids: $e');
    }
  }

  void _listenToNotifications() {
    try {
      _firestoreSub?.cancel();
      _firestoreSub = FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('created_at', descending: true)
          .limit(50)
          .snapshots()
          .listen(
            (snapshot) {
              _processFirestoreDocs(snapshot.docs);
            },
            onError: (err) {
              debugPrint('Firestore notifications listener notice: $err');
              _loadFallbackNotifications();
            },
          );
    } catch (e) {
      debugPrint('Error setting up notifications listener: $e');
      _loadFallbackNotifications();
    }
  }

  void _processFirestoreDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final currentUserId = MockData().currentUser?.id ??
        Supabase.instance.client.auth.currentUser?.id ??
        '';

    final List<AppNotificationItem> list = [];

    for (final doc in docs) {
      final data = doc.data();
      final targetUserId = (data['user_id'] ?? data['userId'] ?? '').toString();
      final isBroadcast = data['is_broadcast'] == true ||
          data['isBroadcast'] == true ||
          data['target'] == 'all' ||
          data['target'] == 'guest' ||
          targetUserId.isEmpty;

      // Filter: user specific OR global broadcast
      if (isBroadcast || (currentUserId.isNotEmpty && targetUserId == currentUserId)) {
        final id = doc.id;
        final title = (data['title'] ?? 'അറിയിപ്പ്').toString();
        final body = (data['body'] ?? data['message'] ?? '').toString();
        final type = (data['type'] ?? 'general').toString().toLowerCase();
        final route = (data['route'] ?? data['screen'])?.toString();

        DateTime createdAt = DateTime.now();
        final rawTs = data['created_at'] ?? data['timestamp'];
        if (rawTs is Timestamp) {
          createdAt = rawTs.toDate();
        } else if (rawTs is String) {
          createdAt = DateTime.tryParse(rawTs) ?? DateTime.now();
        }

        final bool isRead = _readIds.contains(id) ||
            data['is_read'] == true ||
            data['isRead'] == true;

        list.add(
          AppNotificationItem(
            id: id,
            title: title,
            body: body,
            createdAt: createdAt,
            type: type,
            isRead: isRead,
            route: route,
            data: data,
          ),
        );
      }
    }

    // Always merge in default system broadcasts if list is small or guest mode
    if (list.length < 3) {
      final systemItems = _getSystemBroadcastNotifications();
      for (final item in systemItems) {
        if (!list.any((n) => n.id == item.id)) {
          final isRead = _readIds.contains(item.id);
          list.add(item.copyWith(isRead: isRead));
        }
      }
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _currentNotifications = list;
    _recalculateUnreadCount();
  }

  void _loadFallbackNotifications() {
    final List<AppNotificationItem> list = [];
    final systemItems = _getSystemBroadcastNotifications();
    for (final item in systemItems) {
      final isRead = _readIds.contains(item.id);
      list.add(item.copyWith(isRead: isRead));
    }
    _currentNotifications = list;
    _recalculateUnreadCount();
  }

  List<AppNotificationItem> _getSystemBroadcastNotifications() {
    final now = DateTime.now();
    return [
      AppNotificationItem(
        id: 'sys_notif_welcome',
        title: 'കുറിച്ച്യർ മാട്രിമോണിയിലേക്ക് സ്വാഗതം! 🎉',
        body: 'സമുദായ പാരമ്പര്യവും തറവാട് ബന്ധങ്ങളും സംരക്ഷിച്ചു കൊണ്ടുള്ള മാട്രിമോണി പ്ലാറ്റ്‌ഫോം. നിങ്ങളുടെ പങ്കാളിയെ ഇവിടെ കണ്ടെത്താം.',
        createdAt: now.subtract(const Duration(hours: 1)),
        type: 'announcement',
      ),
      AppNotificationItem(
        id: 'sys_notif_clan_checker',
        title: 'തറവാട് പൊരുത്തം ചെക്കർ ലഭ്യമാണ് 🏛️',
        body: '57 കുറിച്ച്യർ തറവാടുകളിലെ പന്തി/ബന്ധു പാരമ്പര്യം മുൻനിർത്തി വിവാഹ പൊരുത്തം ഇപ്പോൾ ഒറ്റ ക്ലിക്കിൽ പരിശോധിക്കാം.',
        createdAt: now.subtract(const Duration(hours: 5)),
        type: 'lineage',
        route: '/moiety_checker',
      ),
      AppNotificationItem(
        id: 'sys_notif_new_members',
        title: 'പുതിയ പ്രൊഫൈലുകൾ ചേർക്കപ്പെട്ടു 🌟',
        body: 'ഇന്ന് പബ്ലിക് ഹബ്ബിൽ പുതിയ അംഗീകൃത പ്രൊഫൈലുകൾ ചേർക്കപ്പെട്ടിട്ടുണ്ട്. ഇപ്പോൾ തന്നെ ഹബ്ബ് സന്ദർശിക്കൂ.',
        createdAt: now.subtract(const Duration(days: 1)),
        type: 'new_member',
      ),
      AppNotificationItem(
        id: 'sys_notif_free_reg',
        title: 'സൗജന്യ പ്രൊഫൈൽ രജിസ്ട്രേഷൻ 📝',
        body: 'നിങ്ങളുടെ വിവരങ്ങൾ കൃത്യമായി നൽകി സൗജന്യമായി അക്കൗണ്ട് രജിസ്റ്റർ ചെയ്യാം. കമ്മ്യൂണിറ്റി പരിശോധനയ്ക്ക് ശേഷം വേരിഫൈഡ് ബാഡ്ജ് ലഭിക്കും.',
        createdAt: now.subtract(const Duration(days: 2)),
        type: 'approval',
      ),
    ];
  }

  void _recalculateUnreadCount() {
    _unreadCount = _currentNotifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    _readIds.add(id);
    _currentNotifications = _currentNotifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    _recalculateUnreadCount();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readIdsPrefKey, _readIds.toList());
    } catch (_) {}

    // Update Firestore if possible
    try {
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .update({'is_read': true}).catchError((_) {});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    for (final n in _currentNotifications) {
      _readIds.add(n.id);
    }

    _currentNotifications = _currentNotifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();

    _recalculateUnreadCount();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readIdsPrefKey, _readIds.toList());
    } catch (_) {}

    // Update Firestore batch
    try {
      final currentUserId = MockData().currentUser?.id;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        final query = await FirebaseFirestore.instance
            .collection('notifications')
            .where('user_id', isEqualTo: currentUserId)
            .where('is_read', isEqualTo: false)
            .get();

        for (final doc in query.docs) {
          doc.reference.update({'is_read': true}).catchError((_) {});
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    super.dispose();
  }
}
