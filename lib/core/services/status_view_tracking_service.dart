import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/status_view_model.dart';
import '../utils/mock_data.dart';
import '../security/guest_security_service.dart';
import 'guest_permission_service.dart';

/// Central service handling WhatsApp-style status view tracking,
/// analytics updates in Firestore, guest installation UUID resolution,
/// and live view streams.
class StatusViewTrackingService extends ChangeNotifier {
  static final StatusViewTrackingService instance =
      StatusViewTrackingService._();
  StatusViewTrackingService._();

  static const String _kGuestInstallationIdKey = 'guest_installation_id';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory cache for ultra-responsive 0ms latency UI updates and offline resilience
  final Map<String, StatusViewData> _localCache = {};
  final Map<String, StreamController<StatusViewData>> _controllers = {};

  /// Retrieves or generates a persistent unique Guest installation UUID.
  Future<String> getOrCreateGuestInstallationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString(_kGuestInstallationIdKey);
      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
        await prefs.setString(_kGuestInstallationIdKey, id);
        debugPrint('[StatusViewTrackingService] Generated new Guest UUID: $id');
      }
      return id;
    } catch (e) {
      debugPrint('[StatusViewTrackingService] Error resolving guest UUID: $e');
      return 'guest_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Checks if the current user is a guest session.
  bool get isCurrentUserGuest {
    if (GuestPermissionService.isGuest) return true;
    if (GuestSecurityService.isGuest()) return true;

    final me = MockData().currentUser;
    if (me == null ||
        me.role.toLowerCase() == 'guest' ||
        me.id == 'guest' ||
        me.id.isEmpty) {
      return true;
    }

    return false;
  }

  /// Checks if the current logged-in user is the author/owner of the status.
  bool isStatusOwner(String? authorId) {
    if (authorId == null || authorId.isEmpty) return false;

    // 1. Check MockData currentUser
    final mockUser = MockData().currentUser;
    if (mockUser != null &&
        mockUser.id.isNotEmpty &&
        (mockUser.id == authorId ||
            (mockUser.role.toLowerCase() != 'guest' &&
                authorId.toLowerCase() == 'me'))) {
      return true;
    }

    // 2. Check Firebase Auth user
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && fbUser.uid == authorId) {
        return true;
      }
    } catch (_) {}

    // 3. Check Supabase Auth user
    try {
      final supaUser = Supabase.instance.client.auth.currentUser;
      if (supaUser != null && supaUser.id == authorId) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Get current cached or default view data for a status.
  StatusViewData getCachedViewData(String statusId) {
    return _localCache[statusId] ?? const StatusViewData();
  }

  /// Fetches latest status view data from Firestore or local cache.
  Future<StatusViewData> getStatusViewData(
    String statusId, {
    String collection = 'statuses',
  }) async {
    if (statusId.isEmpty) return const StatusViewData();

    try {
      // 1. Try specified collection
      var doc = await _firestore.collection(collection).doc(statusId).get();
      if (!doc.exists && collection == 'statuses') {
        // Fallback check in 'stories' collection
        doc = await _firestore.collection('stories').doc(statusId).get();
      }

      if (doc.exists && doc.data() != null) {
        final data = StatusViewData.fromMap(doc.data()!);
        _updateLocalCache(statusId, data);
        return data;
      }
    } catch (e) {
      debugPrint('[StatusViewTrackingService] Fetch view data error: $e');
    }

    return getCachedViewData(statusId);
  }

  /// Broadcast stream providing real-time Firestore updates for a status document.
  Stream<StatusViewData> streamStatusViewData(
    String statusId, {
    String collection = 'statuses',
  }) {
    if (statusId.isEmpty) {
      return Stream.value(const StatusViewData());
    }

    // Create or reuse controller
    // ignore: close_sinks
    final controller = _controllers.putIfAbsent(
      statusId,
      () => StreamController<StatusViewData>.broadcast(),
    );

    // Seed controller with current cache if available
    final cached = _localCache[statusId];
    if (cached != null) {
      controller.add(cached);
    }

    // Subscribe to Firestore doc
    final subscription = _firestore
        .collection(collection)
        .doc(statusId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              final data = StatusViewData.fromMap(snapshot.data()!);
              _updateLocalCache(statusId, data);
            }
          },
          onError: (e) {
            debugPrint('[StatusViewTrackingService] Stream error for $statusId: $e');
          },
        );

    controller.onCancel = () {
      subscription.cancel();
      _controllers.remove(statusId);
    };

    return controller.stream;
  }

  void _updateLocalCache(String statusId, StatusViewData data) {
    _localCache[statusId] = data;
    if (_controllers.containsKey(statusId)) {
      _controllers[statusId]!.add(data);
    }
    notifyListeners();
  }

  /// Records a status view event according to WhatsApp-style tracking rules.
  ///
  /// Logic:
  /// - Check if current user UID (or guest UUID from SharedPreferences) is in `viewed_by_ids`.
  /// - If not present:
  ///   * Registered User: Add `{uid: user.uid, name: user.name, photo_url: user.photoUrl, viewed_at: Timestamp.now()}`
  ///     to `viewers`, add `uid` to `viewed_by_ids`, increment `view_count` by 1.
  ///   * Guest User: Add guest UUID to `viewed_by_ids`, increment `guest_view_count` by 1, increment `view_count` by 1.
  Future<void> recordStatusView({
    required String statusId,
    String? authorId,
    String collection = 'statuses',
  }) async {
    if (statusId.isEmpty) return;

    // Do not record views for empty/test status
    final isGuest = isCurrentUserGuest;
    String viewerId;
    String viewerName = 'അംഗം';
    String viewerPhoto = '';

    if (isGuest) {
      viewerId = await getOrCreateGuestInstallationId();
    } else {
      final currentUser = MockData().currentUser;
      final fbUser = FirebaseAuth.instance.currentUser;
      final supaUser = Supabase.instance.client.auth.currentUser;

      viewerId = currentUser?.id ??
          fbUser?.uid ??
          supaUser?.id ??
          await getOrCreateGuestInstallationId();

      viewerName = currentUser?.name.isNotEmpty == true
          ? currentUser!.name
          : (fbUser?.displayName?.isNotEmpty == true
              ? fbUser!.displayName!
              : 'രജിസ്റ്റർ ചെയ്ത അംഗം');

      viewerPhoto = currentUser?.photoUrl ?? fbUser?.photoURL ?? '';
    }

    // 1. Optimistic local check & update (0ms latency UI responsiveness)
    final currentData = getCachedViewData(statusId);
    if (currentData.viewedByIds.contains(viewerId)) {
      // Already viewed by this user/guest! Skip duplicate view.
      return;
    }

    final newViewedByIds = List<String>.from(currentData.viewedByIds)..add(viewerId);
    final newViewCount = currentData.viewCount + 1;
    final newGuestCount = isGuest
        ? currentData.guestViewCount + 1
        : currentData.guestViewCount;

    final newViewers = List<StatusViewer>.from(currentData.viewers);
    if (!isGuest) {
      newViewers.add(
        StatusViewer(
          uid: viewerId,
          name: viewerName,
          photoUrl: viewerPhoto,
          viewedAt: DateTime.now(),
        ),
      );
    }

    final updatedLocalData = StatusViewData(
      viewCount: newViewCount,
      guestViewCount: newGuestCount,
      viewedByIds: newViewedByIds,
      viewers: newViewers,
    );
    _updateLocalCache(statusId, updatedLocalData);

    // 2. Atomic write to Firestore
    try {
      await _syncViewToFirestore(
        collection: collection,
        statusId: statusId,
        viewerId: viewerId,
        isGuest: isGuest,
        viewerName: viewerName,
        viewerPhoto: viewerPhoto,
      );

      // If document might be in 'stories' collection instead of 'statuses', also sync there if present
      if (collection == 'statuses') {
        try {
          final storyDoc = await _firestore.collection('stories').doc(statusId).get();
          if (storyDoc.exists) {
            await _syncViewToFirestore(
              collection: 'stories',
              statusId: statusId,
              viewerId: viewerId,
              isGuest: isGuest,
              viewerName: viewerName,
              viewerPhoto: viewerPhoto,
            );
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[StatusViewTrackingService] Firestore transaction notice: $e');
    }
  }

  Future<void> _syncViewToFirestore({
    required String collection,
    required String statusId,
    required String viewerId,
    required bool isGuest,
    required String viewerName,
    required String viewerPhoto,
  }) async {
    final docRef = _firestore.collection(collection).doc(statusId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        // Document does not exist in Firestore yet: initialize it with default schema + this view
        final initialMap = <String, dynamic>{
          'view_count': 1,
          'guest_view_count': isGuest ? 1 : 0,
          'viewed_by_ids': [viewerId],
          'viewers': isGuest
              ? []
              : [
                  {
                    'uid': viewerId,
                    'name': viewerName,
                    'photo_url': viewerPhoto,
                    'viewed_at': Timestamp.now(),
                  }
                ],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };

        transaction.set(docRef, initialMap, SetOptions(merge: true));
        return;
      }

      final data = snapshot.data() ?? {};
      final List<dynamic> viewedByIds = List.from(data['viewed_by_ids'] ?? []);

      if (viewedByIds.contains(viewerId)) {
        // Idempotent: already recorded
        return;
      }

      viewedByIds.add(viewerId);
      final int currentViewCount =
          (data['view_count'] as num?)?.toInt() ?? 0;
      final int currentGuestCount =
          (data['guest_view_count'] as num?)?.toInt() ?? 0;

      final updates = <String, dynamic>{
        'view_count': currentViewCount + 1,
        'viewed_by_ids': viewedByIds,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (isGuest) {
        updates['guest_view_count'] = currentGuestCount + 1;
      } else {
        final List<dynamic> viewers = List.from(data['viewers'] ?? []);
        viewers.add({
          'uid': viewerId,
          'name': viewerName,
          'photo_url': viewerPhoto,
          'viewed_at': Timestamp.now(),
        });
        updates['viewers'] = viewers;
      }

      transaction.update(docRef, updates);
    });
  }
}
