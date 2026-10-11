import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/status_service.dart';
import '../services/match_status_security_service.dart';
import 'chat_filter.dart';
import '../kurichiyar_logic_engine.dart';
import '../../features/subscriptions/subscription_service.dart';
import '../security/flutter_window_manager.dart';

class MockData extends ChangeNotifier {
  static final MockData _instance = MockData._internal();
  factory MockData() => _instance;
  MockData._internal() {
    _setupGlobalRealtimeSync();
    listenToTharavadStories();
  }

  void _setupGlobalRealtimeSync() {
    try {
      Supabase.instance.client
          .channel('public:kurichiyar_profiles:mock_data')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'kurichiyar_profiles',
            callback: (payload) {
              if (payload.eventType == PostgresChangeEvent.delete) {
                final deletedId = payload.oldRecord['id'];
                if (deletedId != null) {
                  removeProfile(deletedId);
                }
              } else if (payload.eventType == PostgresChangeEvent.update ||
                  payload.eventType == PostgresChangeEvent.insert) {
                final record = payload.newRecord;
                if (record.isNotEmpty) {
                  try {
                    final updatedProfile = UserProfile.fromMap(record);
                    syncProfileData(updatedProfile);
                  } catch (e) {
                    debugPrint('Error parsing realtime profile update: $e');
                  }
                }
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime setup note: $e');
    }
  }

  void syncProfileData(UserProfile updatedProfile) {
    final idx = _profiles.indexWhere((p) => p.id == updatedProfile.id);
    if (idx != -1) {
      _profiles[idx] = updatedProfile;
    } else {
      _profiles.add(updatedProfile);
    }
    final authUser = Supabase.instance.client.auth.currentUser;
    if (_currentUser == null ||
        _currentUser?.id == updatedProfile.id ||
        (authUser != null && authUser.id == updatedProfile.id)) {
      _currentUser = updatedProfile;
    }
    notifyListeners();
  }

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  void setCurrentUser(UserProfile user) {
    _currentUser = user;
    final idx = _profiles.indexWhere((p) => p.id == user.id);
    if (idx != -1) {
      _profiles[idx] = user;
    } else {
      _profiles.add(user);
    }
    notifyListeners();
  }

  /// Checks user document in Firestore: `isPremium: boolean` (or `planStatus: 'active'`)
  /// and updates subscription state.
  Future<void> syncUserSubscriptionFromFirestore([String? userId]) async {
    final uid = userId ?? _currentUser?.id;
    if (uid == null || uid.isEmpty || uid == 'guest') return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final bool isPrem = data['isPremium'] == true ||
            data['is_premium'] == true ||
            (data['planStatus']?.toString().toLowerCase() == 'active') ||
            (data['plan_status']?.toString().toLowerCase() == 'active');
        final String? planStat = (data['planStatus'] ?? data['plan_status'])?.toString();
        final String? planTier = (data['planTier'] ?? data['plan_tier'])?.toString();

        if (_currentUser != null && _currentUser!.id == uid) {
          final updatedStatus = _currentUser!.accountStatusDetails.copyWith(
            isPremium: isPrem,
            planStatus: planStat,
            planTier: planTier,
          );
          _currentUser = _currentUser!.copyWith(
            accountStatusDetails: updatedStatus,
            planTier: planTier,
          );
          final idx = _profiles.indexWhere((p) => p.id == uid);
          if (idx != -1) {
            _profiles[idx] = _currentUser!;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[MockData] Error syncing subscription from Firestore: $e');
    }
  }

  String get currentUserMotherTharavad =>
      (_currentUser?.motherTharavadu ?? _currentUser?.motherTharavadName ?? '')
          .trim();
  String get currentUserFatherTharavad =>
      (_currentUser?.fatherTharavadu ?? '').trim();
  String get currentUserMoiety =>
      KurichiyarLogicEngine.getMoiety(currentUserMotherTharavad);

  SubscriptionTier? pendingCheckoutTier;
  String? pendingCheckoutPlanName;

  void setPendingCheckout(SubscriptionTier tier, [String? planName]) {
    pendingCheckoutTier = tier;
    pendingCheckoutPlanName = planName;
    notifyListeners();
  }

  void clearPendingCheckout() {
    pendingCheckoutTier = null;
    pendingCheckoutPlanName = null;
    notifyListeners();
  }

  List<UserProfile> _profiles = [];
  List<UserProfile> get profiles => _profiles;

  void removeProfile(dynamic id) {
    final targetStr = id.toString();
    _profiles.removeWhere((p) => p.id.toString() == targetStr);
    notifyListeners();
  }

  List<StatusPost> _statusPosts = [];
  List<StatusPost> get statusPosts => _statusPosts;

  List<TharavadStory> _tharavadStories = [];
  List<TharavadStory> get tharavadStories => _tharavadStories;

  List<CommunityHistory> _history = [];
  List<CommunityHistory> get history => _history;

  List<Announcement> _announcements = [];
  List<Announcement> get announcements => _announcements;

  String _dailyProverb =
      '"ഇല്ലപ്പൊരുത്തം കുലത്തിന്റെ മഹിമ; തറവാട്ടു പാരമ്പര്യം നന്മയുടെ വെളിച്ചം."';
  String get dailyProverb => _dailyProverb;

  void updateDailyProverb(String text) {
    _dailyProverb = text;
    notifyListeners();
  }

  void updateAnnouncements(List<Announcement> list) {
    _announcements = list;
    notifyListeners();
  }

  void updateHistory(List<CommunityHistory> list) {
    _history = list;
    notifyListeners();
  }

  void updateStatusPosts(List<StatusPost> list) {
    _statusPosts = list;
    notifyListeners();
  }

  void removeStatusPost(String postId) {
    _statusPosts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }

  void updateTharavadStories(List<TharavadStory> list) {
    _tharavadStories = list;
    notifyListeners();
  }

  void removeTharavadStory(String storyId) {
    _tharavadStories.removeWhere((s) => s.id == storyId);
    notifyListeners();
  }

  RealtimeChannel? _storiesChannel;
  RealtimeChannel? _userStoriesChannel;

  Future<void> fetchStoriesFromSupabase() async {
    try {
      final List<Map<String, dynamic>> combinedRows = [];
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final cutoffIso = cutoff.toUtc().toIso8601String();

      // 1. Fetch from Firestore stories collection (24-hr cutoff, limit 15)
      try {
        final fsSnap = await FirebaseFirestore.instance
            .collection('stories')
            .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
            .orderBy('created_at', descending: true)
            .limit(15)
            .get(const GetOptions(source: Source.serverAndCache));

        for (final doc in fsSnap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          combinedRows.add({
            'id': doc.id,
            'creator_id': data['user_id']?.toString() ?? data['creator_id']?.toString(),
            'clan_id': data['clan_id'] ?? data['tharavad_id'] ?? 0,
            'content': data['content'] ?? data['caption'] ?? '',
            'media_url': data['media_url'] ?? data['photo_url'],
            'created_at': data['created_at'] is Timestamp
                ? (data['created_at'] as Timestamp).toDate().toIso8601String()
                : data['created_at']?.toString(),
            'expires_at': data['expires_at']?.toString(),
          });
        }
      } catch (fse) {
        debugPrint('[MockData] Firestore stories fetch notice: $fse');
      }

      // 2. Fetch from public.user_stories (24-hr cutoff, limit 15)
      try {
        final resUser = await Supabase.instance.client
            .from('user_stories')
            .select('*')
            .gte('created_at', cutoffIso)
            .gt('expires_at', DateTime.now().toUtc().toIso8601String())
            .order('created_at', ascending: false)
            .limit(15);
        for (var row in resUser) {
          combinedRows.add({
            'id': row['id']?.toString(),
            'creator_id':
                row['user_id']?.toString() ?? row['creator_id']?.toString(),
            'clan_id': row['clan_id'] ?? row['tharavad_id'] ?? 0,
            'content': row['content'] ?? row['caption'] ?? '',
            'media_url': row['media_url'],
            'created_at': row['created_at'],
            'expires_at': row['expires_at'],
          });
        }
      } catch (e) {
        debugPrint('[MockData] user_stories fetch note: $e');
      }

      // 3. Fetch from public.tharavad_stories (24-hr cutoff, limit 15)
      try {
        final resTharavad = await Supabase.instance.client
            .from('tharavad_stories')
            .select('*')
            .gte('created_at', cutoffIso)
            .gt('expires_at', DateTime.now().toUtc().toIso8601String())
            .order('created_at', ascending: false)
            .limit(15);
        final existingIds = combinedRows
            .map((r) => r['id']?.toString())
            .toSet();
        for (var row in resTharavad) {
          final id = row['id']?.toString();
          if (id != null && !existingIds.contains(id)) {
            combinedRows.add(Map<String, dynamic>.from(row));
            existingIds.add(id);
          }
        }
      } catch (e) {
        debugPrint('[MockData] tharavad_stories fetch note: $e');
      }

      final stories = combinedRows
          .map((row) => TharavadStory.fromMap(row))
          .toList();

      _tharavadStories = stories;
      notifyListeners();
      debugPrint(
        'Fetched ${_tharavadStories.length} active tharavad/user stories from Supabase',
      );
    } catch (e) {
      debugPrint('Error fetching tharavad stories: $e');
    }
  }

  void listenToTharavadStories() {
    if (_storiesChannel != null) return;

    // Initial fetch
    fetchStoriesFromSupabase();

    try {
      // Set up Realtime listener for tharavad_stories
      _storiesChannel = Supabase.instance.client
          .channel('public:tharavad_stories')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tharavad_stories',
            callback: (payload) {
              debugPrint(
                'Realtime change in tharavad_stories: ${payload.eventType}',
              );
              fetchStoriesFromSupabase();
            },
          );
      _storiesChannel!.subscribe();

      // Set up Realtime listener for user_stories
      _userStoriesChannel = Supabase.instance.client
          .channel('public:user_stories')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_stories',
            callback: (payload) {
              debugPrint(
                'Realtime change in user_stories: ${payload.eventType}',
              );
              fetchStoriesFromSupabase();
            },
          );
      _userStoriesChannel!.subscribe();
    } catch (e) {
      debugPrint('Error setting up stories realtime listener: $e');
    }
  }

  void muteUser(String targetUserId) {
    if (_currentUser == null) return;
    final muted = List<String>.from(_currentUser!.mutedUserIds);
    if (!muted.contains(targetUserId)) {
      muted.add(targetUserId);
      _currentUser = _currentUser!.copyWith(mutedUserIds: muted);
      notifyListeners();

      // Persist to Supabase
      Supabase.instance.client
          .from('kurichiyar_profiles')
          .update({'muted_user_ids': muted})
          .eq('id', _currentUser!.id)
          .catchError((e) => debugPrint('Failed to save mute: $e'));
    }
  }

  Map<String, List<StatusPost>> get groupedStatusPosts {
    if (_currentUser == null) return {};
    final Map<String, List<StatusPost>> grouped = {};
    for (var post in _statusPosts.where(
      (p) => !p.isExpired && !_currentUser!.mutedUserIds.contains(p.creatorId),
    )) {
      if (!grouped.containsKey(post.creatorId)) {
        grouped[post.creatorId] = [];
      }
      grouped[post.creatorId]!.add(post);
    }
    return grouped;
  }

  final List<MutualAgreement> _agreements = [];
  List<MutualAgreement> get agreements => List.unmodifiable(_agreements);

  void updateAgreement(MutualAgreement agreement) {
    final idx = _agreements.indexWhere((a) => a.id == agreement.id);
    if (idx != -1) {
      _agreements[idx] = agreement;
      notifyListeners();
    }
  }

  // Settings State
  Locale _appLocale = const Locale('ml');
  Locale get appLocale => _appLocale;

  Future<void> initLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('selected_locale');
      if (savedLang != null && ['ml', 'en', 'hi'].contains(savedLang)) {
        _appLocale = Locale(savedLang);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  void setLocale(Locale locale) async {
    if (!['ml', 'en', 'hi'].contains(locale.languageCode)) return;
    _appLocale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_locale', locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;
  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  bool _hideProfile = false;
  bool get hideProfile => _hideProfile;
  void togglePrivacy(bool value) {
    _hideProfile = value;
    notifyListeners();
  }

  Future<void> updateAllowDirectMessages(bool value) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(allowDirectMessages: value);
    final idx = _profiles.indexWhere((p) => p.id == _currentUser!.id);
    if (idx != -1) {
      _profiles[idx] = _profiles[idx].copyWith(allowDirectMessages: value);
    }
    notifyListeners();

    try {
      await Supabase.instance.client
          .from('kurichiyar_profiles')
          .update({'allow_direct_messages': value})
          .eq('id', _currentUser!.id);
      debugPrint('Persisted allow_direct_messages to Supabase');
    } catch (e) {
      debugPrint('Failed to persist allow_direct_messages to Supabase: $e');
    }
  }

  Future<void> updateAllowScreenshot(bool value) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(allowScreenshot: value);
    final idx = _profiles.indexWhere((p) => p.id == _currentUser!.id);
    if (idx != -1) {
      _profiles[idx] = _profiles[idx].copyWith(allowScreenshot: value);
    }
    notifyListeners();

    // Dynamically update window flags immediately
    try {
      if (value) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      } else {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } catch (e) {
      debugPrint('[Security] Failed to dynamically update FlutterWindowManager flags: $e');
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.id)
          .set({
            'allowScreenshot': value,
            'allow_screenshot': value,
            'screenshot_blocked': !value,
          }, SetOptions(merge: true));
      debugPrint('[Security] Persisted allowScreenshot to Firestore: $value');
    } catch (e) {
      debugPrint('[Security] Failed to persist allowScreenshot to Firestore: $e');
    }

    try {
      await Supabase.instance.client
          .from('kurichiyar_profiles')
          .update({
            'allow_screenshot': value,
          })
          .eq('id', _currentUser!.id);
      debugPrint('[Security] Persisted allow_screenshot to Supabase');
    } catch (e) {
      debugPrint('[Security] Failed to persist allow_screenshot to Supabase: $e');
    }
  }

  bool _adsEnabled = false;
  bool get adsEnabled => _adsEnabled;

  Future<void> syncAdStatus() async {
    try {
      final res = await Supabase.instance.client
          .from('app_config')
          .select('config_value')
          .eq('config_key', 'ads_enabled')
          .maybeSingle();

      if (res != null) {
        _adsEnabled = res['config_value'] == 'true';
        debugPrint("Current Ad Status: $_adsEnabled");
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing ad status: $e');
    }
  }

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  int get unreadNotificationsCount {
    if (_currentUser == null) return 0;
    return _notifications
        .where(
          (n) =>
              !n.isRead && (n.userId.isEmpty || n.userId == _currentUser!.id),
        )
        .length;
  }

  // Local report log — used as admin dashboard fallback when Supabase unavailable
  final List<Map<String, dynamic>> _postReports = [];
  List<Map<String, dynamic>> get postReports => List.unmodifiable(_postReports);

  /// Appends a report record to the local mock admin log.
  void logReport(Map<String, dynamic> report) {
    _postReports.add(report);
    notifyListeners();
  }

  // Simple inbox messages storage: candidateId -> list of messages
  final Map<String, List<Map<String, dynamic>>> _chats = {};
  Map<String, List<Map<String, dynamic>>> get chats => _chats;

  // Clan Photo Submissions Admin Mock State
  final List<ClanPhotoSubmission> _clanPhotoSubmissions = [];
  List<ClanPhotoSubmission> get clanPhotoSubmissions =>
      List.unmodifiable(_clanPhotoSubmissions);

  void submitClanPhoto(
    int clanId,
    String photoUrl, {
    bool isProfilePhoto = true,
  }) {
    if (_currentUser == null) return;
    _clanPhotoSubmissions.add(
      ClanPhotoSubmission(
        id: 'photo_${DateTime.now().millisecondsSinceEpoch}',
        clanId: clanId,
        submitterId: _currentUser!.id,
        photoUrl: photoUrl,
        status: ClanPhotoStatus.approved, // Auto-approve for user uploads
        isProfilePhoto: isProfilePhoto,
        submittedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> syncClanPhotos() async {
    // 1. Local cleanup of all submissions older than 7 days (7-Day Auto-Expiry)
    final limit = DateTime.now().subtract(const Duration(days: 7));
    _clanPhotoSubmissions.removeWhere((p) => p.submittedAt.isBefore(limit));

    // 2. Fetch from Supabase tharavadu_photo_requests
    try {
      final res = await Supabase.instance.client
          .from('tharavadu_photo_requests')
          .select()
          .eq('status', 'pending');

      final List<ClanPhotoSubmission> fetched = (res as List).map((row) {
        return ClanPhotoSubmission(
          id: row['id'].toString(),
          clanId: row['clan_id'] as int,
          submitterId: row['submitter_id'] as String? ?? '',
          photoUrl: row['photo_url'] as String,
          status: ClanPhotoStatus.pending,
          isProfilePhoto: row['is_profile_photo'] as bool? ?? true,
          likesCount: row['likes_count'] as int? ?? 0,
          submittedAt:
              DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now(),
        );
      }).toList();

      _clanPhotoSubmissions.removeWhere(
        (p) => p.status == ClanPhotoStatus.pending,
      );
      _clanPhotoSubmissions.addAll(fetched);
      notifyListeners();
    } catch (e) {
      debugPrint('Sync clan photos from DB failed: $e');
    }
  }

  void approveClanPhoto(String submissionId) {
    final idx = _clanPhotoSubmissions.indexWhere((p) => p.id == submissionId);
    if (idx != -1) {
      _clanPhotoSubmissions[idx] = _clanPhotoSubmissions[idx].copyWith(
        status: ClanPhotoStatus.approved,
      );
      notifyListeners();
    }
  }

  void rejectClanPhoto(String submissionId) {
    final idx = _clanPhotoSubmissions.indexWhere((p) => p.id == submissionId);
    if (idx != -1) {
      _clanPhotoSubmissions[idx] = _clanPhotoSubmissions[idx].copyWith(
        status: ClanPhotoStatus.rejected,
      );
      notifyListeners();
    }
  }

  String? getApprovedClanPhoto(int clanId) {
    final approvedList = _clanPhotoSubmissions
        .where(
          (p) => p.clanId == clanId && p.status == ClanPhotoStatus.approved,
        )
        .toList();

    if (approvedList.isEmpty) return null;

    // 1. Prioritize photos tagged specifically as Tharavadu Profile Photo
    final taggedList = approvedList.where((p) => p.isProfilePhoto).toList();
    if (taggedList.isNotEmpty) {
      // Sort by highest likes, then most recent date
      taggedList.sort((a, b) {
        final cmp = b.likesCount.compareTo(a.likesCount);
        if (cmp != 0) return cmp;
        return b.submittedAt.compareTo(a.submittedAt);
      });
      return taggedList.first.photoUrl;
    }

    // 2. Fallback to most recent approved photo
    approvedList.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return approvedList.first.photoUrl;
  }

  void adminApproveProfile(String profileId) {
    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx != -1) {
      _profiles[idx] = _profiles[idx].copyWith(
        accountStatus: AccountStatus.approved,
        rejectionReason: null, // Clear rejection reason on approval
      );
      notifyListeners();
    }
  }

  void agentForwardProfile(String profileId) {
    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx != -1) {
      // Forward to central admin!
      _profiles[idx] = _profiles[idx].copyWith(
        accountStatus: AccountStatus.adminReview,
      );
      notifyListeners();
    }
  }

  void adminRejectProfile(String profileId, {String? reason}) {
    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx != -1) {
      _profiles[idx] = _profiles[idx].copyWith(
        accountStatus: AccountStatus.rejected,
        rejectionReason: reason,
      );
      notifyListeners();
    }
  }

  void resubmitProfile(String profileId) {
    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx != -1) {
      _profiles[idx] = _profiles[idx].copyWith(
        accountStatus: AccountStatus.pending,
        rejectionReason: null,
      );
      if (_currentUser?.id == profileId) {
        _currentUser = _profiles[idx];
      }
      notifyListeners();
    }
  }

  RealtimeChannel? _currentUserRealtimeChannel;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _currentUserFirestoreSub;

  void setupCurrentUserRealtimeSync(String userId) {
    _currentUserFirestoreSub?.cancel();
    if (userId.isNotEmpty) {
      // 1. One-time cached initial fetch from Firestore using Source.serverAndCache (Zero stream quota overhead)
      try {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.serverAndCache))
            .then((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            try {
              final data = Map<String, dynamic>.from(snapshot.data()!);
              data['id'] = data['id'] ?? snapshot.id;
              final updated = UserProfile.fromMap(data);
              syncProfileData(updated);
            } catch (e) {
              debugPrint('Firestore current user parse error: $e');
            }
          }
        }).catchError((e) {
          debugPrint('Firestore current user fetch note: $e');
        });
      } catch (e) {
        debugPrint('Firestore current user stream setup note: $e');
      }
    }

    if (_currentUserRealtimeChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_currentUserRealtimeChannel!);
      } catch (_) {}
    }

    debugPrint(
      'setupCurrentUserRealtimeSync: Setting up dedicated listener for user $userId...',
    );
    _currentUserRealtimeChannel = Supabase.instance.client
        .channel('public:kurichiyar_profiles:current_user_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'kurichiyar_profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
              'setupCurrentUserRealtimeSync callback: Received user profile update: ${payload.newRecord}',
            );
            if (payload.newRecord.isNotEmpty) {
              try {
                final updated = UserProfile.fromMap(payload.newRecord);
                syncProfileData(updated);
              } catch (e) {
                debugPrint(
                  'setupCurrentUserRealtimeSync callback parse error: $e',
                );
              }
            }
          },
        );
    _currentUserRealtimeChannel!.subscribe();
  }

  Future<void> refreshCurrentUserProfile() async {
    final uid =
        _currentUser?.id ?? Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        debugPrint(
          'refreshCurrentUserProfile: Re-fetching current user profile from database...',
        );
        final row = await Supabase.instance.client
            .from('kurichiyar_profiles')
            .select()
            .eq('id', uid)
            .maybeSingle();
        if (row != null && row.isNotEmpty) {
          final updated = UserProfile.fromMap(row);
          updateCurrentUser(updated);
          debugPrint(
            'refreshCurrentUserProfile: Re-fetched and updated profile tier: ${updated.subscriptionTier}',
          );
        }
      } catch (e) {
        debugPrint('refreshCurrentUserProfile error: $e');
      }
    }
  }

  void registerUser(UserProfile profile) {
    _currentUser = profile;
    setupCurrentUserRealtimeSync(profile.id);
    notifyListeners();
  }

  void updateCurrentUser(UserProfile profile) {
    _currentUser = profile;
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx != -1) {
      _profiles[idx] = profile;
    }
    setupCurrentUserRealtimeSync(profile.id);
    notifyListeners();
  }

  bool _isProfilesSynced = false;
  bool get isProfilesSynced => _isProfilesSynced;

  List<String> _interactedProfileIds = [];
  List<String> get interactedProfileIds => _interactedProfileIds;

  DocumentSnapshot? _lastFirestoreProfileDoc;

  Future<void> syncProfilesFromDatabase({
    int limit = 15,
    int offset = 0,
  }) async {
    try {
      final me = _currentUser;
      if (offset == 0) {
        _lastFirestoreProfileDoc = null;
      }

      if (me != null) {
        // Fetch matches to filter
        final matchesRes = await Supabase.instance.client
            .from('profile_matches')
            .select('receiver_id')
            .eq('sender_id', me.id);

        _interactedProfileIds = (matchesRes as List)
            .map((m) => m['receiver_id'].toString())
            .toList();
      }

      List<UserProfile> dbProfiles = [];

      // 1. Try paginated query from Firestore users collection (limit: 15, startAfterDocument)
      try {
        Query firestoreQuery = FirebaseFirestore.instance
            .collection('users')
            .limit(limit);

        if (_lastFirestoreProfileDoc != null) {
          firestoreQuery =
              firestoreQuery.startAfterDocument(_lastFirestoreProfileDoc!);
        }

        final firestoreSnap = await firestoreQuery.get(
          const GetOptions(source: Source.serverAndCache),
        );

        if (firestoreSnap.docs.isNotEmpty) {
          _lastFirestoreProfileDoc = firestoreSnap.docs.last;
          for (final doc in firestoreSnap.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data() as Map);
              data['id'] = data['id'] ?? doc.id;
              final p = UserProfile.fromMap(data);
              if (p.role.toLowerCase() != 'admin' &&
                  p.role.toLowerCase() != 'super_admin' &&
                  (p.isApproved || p.isCompleteAndDiscoverable)) {
                if (me == null || p.gender != me.gender) {
                  dbProfiles.add(p);
                }
              }
            } catch (_) {}
          }
        }
      } catch (fe) {
        debugPrint('[MockData] Firestore sync profiles notice: $fe');
      }

      // 2. Fallback to Supabase range query if Firestore returned empty
      if (dbProfiles.isEmpty) {
        var query = Supabase.instance.client
            .from('kurichiyar_profiles')
            .select('*')
            .neq('role', 'admin')
            .neq('role', 'super_admin')
            .neq('is_admin', true)
            .eq('is_profile_hidden', false)
            .eq('account_status', 'approved');

        if (me != null) {
          query = query.neq('gender', me.gender.name);
        }

        final response = await query.range(offset, offset + limit - 1);

        dbProfiles = (response as List)
            .map((row) {
              return UserProfile.fromMap(row as Map<String, dynamic>);
            })
            .where((p) {
              // Strictly exclude Admin users
              if (p.role.toLowerCase() == 'admin' || p.role.toLowerCase() == 'super_admin') return false;
              // Visible if approved or discoverable
              return p.isApproved || p.isCompleteAndDiscoverable;
            })
            .toList();
      }

      if (dbProfiles.isNotEmpty) {
        if (offset == 0) {
          _profiles = dbProfiles;
        } else {
          // Merge avoiding duplicates
          final existingIds = _profiles.map((p) => p.id).toSet();
          _profiles.addAll(
            dbProfiles.where((p) => !existingIds.contains(p.id)),
          );
        }
        _isProfilesSynced = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to sync profiles from database: $e');
    }
  }

  Future<void> logout() async {
    if (_currentUserRealtimeChannel != null) {
      try {
        await Supabase.instance.client.removeChannel(
          _currentUserRealtimeChannel!,
        );
      } catch (_) {}
      _currentUserRealtimeChannel = null;
    }
    _currentUserFirestoreSub?.cancel();
    _currentUser = null;
    _profiles.clear();
    _interactedProfileIds.clear();
    _isProfilesSynced = false;
    notifyListeners();
    try {
      await Supabase.instance.client.auth.signOut().timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Supabase sign out timeout/error: $e');
    }
  }

  Future<void> activateSubscription(
    SubscriptionTier tier, {
    String? planTierName,
    int? durationMonths,
  }) async {
    if (_currentUser != null) {
      _currentUser = SubscriptionService.instance.activateTier(
        _currentUser!,
        tier,
      );
      if (planTierName != null) {
        _currentUser = _currentUser!.copyWith(planTier: planTierName);
      }
      notifyListeners();

      try {
        final Map<String, dynamic> updateMap = {
          'subscription_tier': tier.name,
          'plan_tier':
              planTierName ??
              (tier == SubscriptionTier.tier3
                  ? 'platinum'
                  : (tier == SubscriptionTier.tier2
                        ? 'diamond'
                        : (tier == SubscriptionTier.tier1
                              ? 'gold'
                              : 'stealth'))),
          'subscription_start_date': _currentUser!.subscriptionStartDate
              ?.toIso8601String(),
          'subscription_end_date': _currentUser!.subscriptionEndDate
              ?.toIso8601String(),
          'plan_expiry': _currentUser!.subscriptionEndDate?.toIso8601String(),
          'is_stealth_active': tier == SubscriptionTier.stealth,
          'stealth_expiry_date': tier == SubscriptionTier.stealth
              ? _currentUser!.subscriptionEndDate?.toIso8601String()
              : null,
        };
        await Supabase.instance.client
            .from('kurichiyar_profiles')
            .update(updateMap)
            .eq('id', _currentUser!.id);
        debugPrint('Persisted upgraded subscription tier to Supabase');
      } catch (e) {
        debugPrint(
          'Failed to persist upgraded subscription tier to Supabase: $e',
        );
      }
    }
  }

  /// Records that the current user has viewed [targetProfileId] in full.
  /// Idempotent — re-viewing same profile does not consume another view slot.
  void consumeProfileView(String targetProfileId) {
    if (_currentUser == null) return;

    // 1. Update current user's viewed list
    _currentUser = SubscriptionService.instance.consumeView(
      _currentUser!,
      targetProfileId,
    );

    // If viewer has active Stealth Mode, do not record visitor for target user!
    if (_currentUser!.isStealthActiveMode) {
      notifyListeners();
      return;
    }

    // 2. Record visitor for the target user
    final targetIdx = _profiles.indexWhere((p) => p.id == targetProfileId);
    if (targetIdx != -1) {
      final target = _profiles[targetIdx];

      // Don't record multiple visits from same person in a short time if preferred,
      // but here we just add it to the list.
      final visitor = ProfileVisitor(
        visitorId: _currentUser!.id,
        visitorName: _currentUser!.name,
        visitorPhotoUrl: _currentUser!.photoUrl,
        visitorClanId: _currentUser!.fatherClanId,
        visitedAt: DateTime.now(),
      );

      final updatedVisitors = [visitor, ...target.visitors];
      _profiles[targetIdx] = target.copyWith(visitors: updatedVisitors);

      // Persist to Supabase if needed
      _persistVisitor(targetProfileId, visitor);
    }

    notifyListeners();
  }

  Future<void> _persistVisitor(
    String targetUserId,
    ProfileVisitor visitor,
  ) async {
    if (_currentUser?.isStealthActiveMode == true) return;
    try {
      await Supabase.instance.client.rpc(
        'record_profile_view',
        params: {'p_viewer_id': visitor.visitorId, 'p_viewed_id': targetUserId},
      );
      debugPrint('Persisted profile view to history backend.');
    } catch (e) {
      debugPrint('Failed to persist visitor: $e');
    }
  }

  /// Toggles favorite status. For testing purposes, set simulateMutualMatch
  /// to true to simulate the target profile also liking the user back.
  void toggleFavorite(String profileId, {bool simulateMutualMatch = false}) {
    if (_currentUser != null) {
      final favs = List<String>.from(_currentUser!.favoriteProfileIds);
      if (favs.contains(profileId)) {
        favs.remove(profileId);
      } else {
        favs.add(profileId);
      }
      _currentUser = _currentUser!.copyWith(favoriteProfileIds: favs);

      // MOCK: Simulate mutual match if requested
      if (simulateMutualMatch && favs.contains(profileId)) {
        // Find target
        final targetIdx = _profiles.indexWhere((p) => p.id == profileId);
        if (targetIdx != -1) {
          final target = _profiles[targetIdx];
          final targetFavs = List<String>.from(target.favoriteProfileIds);
          if (!targetFavs.contains(_currentUser!.id)) {
            targetFavs.add(_currentUser!.id);
            _profiles[targetIdx] = target.copyWith(
              favoriteProfileIds: targetFavs,
            );
          }
        }
      }

      notifyListeners();
    }
  }

  void recordMutualAgreement(String targetProfileId) {
    if (_currentUser == null) return;

    final agreed = List<String>.from(_currentUser!.agreedMutualMatches);
    if (!agreed.contains(targetProfileId)) {
      agreed.add(targetProfileId);
      _currentUser = _currentUser!.copyWith(agreedMutualMatches: agreed);

      // Update target profile as well
      final targetIdx = _profiles.indexWhere((p) => p.id == targetProfileId);
      if (targetIdx != -1) {
        final target = _profiles[targetIdx];
        final targetAgreed = List<String>.from(target.agreedMutualMatches);
        if (!targetAgreed.contains(_currentUser!.id)) {
          targetAgreed.add(_currentUser!.id);
          _profiles[targetIdx] = target.copyWith(
            agreedMutualMatches: targetAgreed,
          );
        }
      }

      MatchStatusSecurityService.recordMutualAcceptedInFirestore(
        currentUserId: _currentUser!.id,
        targetProfileId: targetProfileId,
      );

      notifyListeners();
    }
  }

  void addProfilePhoto(String photoPath) {
    if (_currentUser != null) {
      final updatedPhotos = List<String>.from(_currentUser!.additionalPhotos)
        ..add(photoPath);
      _currentUser = _currentUser!.copyWith(additionalPhotos: updatedPhotos);

      final idx = _profiles.indexWhere((p) => p.id == _currentUser!.id);
      if (idx != -1) {
        _profiles[idx] = _currentUser!;
      }
      notifyListeners();
    }
  }

  void updateAccountStatus(AccountStatus status) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(accountStatus: status);
      final idx = _profiles.indexWhere((p) => p.id == _currentUser!.id);
      if (idx != -1) {
        _profiles[idx] = _currentUser!;
      }
      notifyListeners();
    }
  }

  void updateProfileStatus(ProfileStatus status) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(profileStatus: status);
      final idx = _profiles.indexWhere((p) => p.id == _currentUser!.id);
      if (idx != -1) {
        _profiles[idx] = _currentUser!;
      }
      notifyListeners();
    }
  }

  void sendMessage(String profileId, String text, bool sentByMe) {
    if (!_chats.containsKey(profileId)) {
      _chats[profileId] = [];
    }
    _chats[profileId]!.add({
      'text': ChatFilter.filter(text),
      'isMe': sentByMe,
      'time': DateTime.now(),
    });
    notifyListeners();
  }

  void approveProfile(String profileId) {
    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx != -1) {
      _profiles[idx] = _profiles[idx].copyWith(
        accountStatus: AccountStatus.approved,
      );
      notifyListeners();
    }
  }

  void createStatusPost(
    String content,
    int selectedClanId, {
    String? videoUrl,
    int? videoDuration,
    String? feedPhotoUrl,
    String? feedAudioUrl,
    String? backgroundColor,
    String? textColor,
    PostType? type,
  }) {
    if (_currentUser == null) return;

    PostType postType = type ?? PostType.text;
    if (type == null) {
      if (videoUrl != null) postType = PostType.video;
      if (feedPhotoUrl != null) postType = PostType.photo;
      if (feedAudioUrl != null) postType = PostType.audio;
    }

    final newPost = StatusPost(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      creatorId: _currentUser!.id,
      clanId: selectedClanId,
      content: ChatFilter.filter(content),
      createdAt: DateTime.now(),
      likes: [],
      views: [],
      videoUrl: videoUrl,
      videoDuration: videoDuration,
      feedPhotoUrl: feedPhotoUrl,
      feedAudioUrl: feedAudioUrl,
      postType: postType,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );

    // Optimistic update
    _statusPosts.insert(0, newPost);
    notifyListeners();

    // Persist to Supabase
    StatusService.instance.createStatus(newPost).catchError((e) {
      debugPrint('Failed to persist status: $e');
    });
  }

  void viewStatusPost(String postId, UserProfile viewer) {
    final idx = _statusPosts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _statusPosts[idx];
    if (post.creatorId == viewer.id) return;

    final viewerIdHash = viewer.id;
    final alreadyViewed = post.views.any((v) => v.viewerIdHash == viewerIdHash);
    if (alreadyViewed) return;

    final viewRecord = ViewRecord(
      viewerIdHash: viewerIdHash,
      viewerClanId: viewer.fatherClanId,
      viewerGender: viewer.gender,
      viewerAge: viewer.age,
      viewerRegion: viewer.region,
      viewedAt: DateTime.now(),
    );

    _statusPosts[idx] = post.copyWith(views: [...post.views, viewRecord]);
    notifyListeners();

    // Persist to Supabase
    StatusService.instance.recordView(postId, viewRecord);
  }

  void toggleLikeStatusPost(String postId, String userId) {
    final idx = _statusPosts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _statusPosts[idx];
    final likes = List<String>.from(post.likes);

    // Persist to Supabase
    StatusService.instance.toggleLike(postId, userId, likes);

    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }
    _statusPosts[idx] = post.copyWith(likes: likes);
    notifyListeners();
  }

  // 6. Text Status with Background Color
}
