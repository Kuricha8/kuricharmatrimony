import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  CacheEntry(this.data, this.timestamp);

  bool get isExpired {
    return DateTime.now().difference(timestamp).inHours >= 24;
  }
}

class FirestoreService {
  FirestoreService();
  static final FirestoreService instance = FirestoreService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseFirestore get firestore => _db;

  // Local cache with TTL
  final Map<String, CacheEntry<DocumentSnapshot>> _userProfileCache = {};
  final Map<String, CacheEntry<DocumentSnapshot>> _appConfigCache = {};

  // ── Core Collection References ──────────────────────────────────────────
  CollectionReference get users => _db.collection('users');
  CollectionReference get profiles => _db.collection('profiles');
  CollectionReference get tharavaduMaster => _db.collection('tharavadu_master');
  CollectionReference get matchDeals => _db.collection('match_deals');
  CollectionReference get interests => _db.collection('interests');
  CollectionReference get matches => _db.collection('matches');
  CollectionReference get chatRooms => _db.collection('chat_rooms');
  CollectionReference get chats => _db.collection('chats');
  CollectionReference get supportChats => _db.collection('support_chats');
  CollectionReference get appConfig => _db.collection('app_config');
  CollectionReference get agents => _db.collection('agents');
  CollectionReference get clanFeed => _db.collection('clan_feed');
  CollectionReference get stories => _db.collection('stories');
  CollectionReference get subscriptions => _db.collection('subscriptions');
  CollectionReference get payments => _db.collection('payments');
  CollectionReference get cart => _db.collection('cart');
  CollectionReference get notifications => _db.collection('notifications');
  CollectionReference get visitors => _db.collection('visitors');
  CollectionReference get calls => _db.collection('calls');
  CollectionReference get verifications => _db.collection('verifications');
  CollectionReference get livenessChecks => _db.collection('liveness_checks');
  CollectionReference get adminLeads => _db.collection('admin_leads');
  CollectionReference get events => _db.collection('events');
  CollectionReference get agreements => _db.collection('agreements');
  CollectionReference get screenRegistry => _db.collection('screen_registry');
  CollectionReference get screenVisits => _db.collection('screen_visits');

  CollectionReference get kurichiyarProfiles => _db.collection('kurichiyar_profiles');

  /// Dynamic collection accessor
  CollectionReference collection(String name) => _db.collection(name);

  // ── Users Service ────────────────────────────────────────────────────────

  Future<void> saveUserProfile(String userId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();
    data['status'] ??= 'PENDING';
    data['is_deleted'] ??= false;
    data['created_at'] ??= FieldValue.serverTimestamp();
    await kurichiyarProfiles.doc(userId).set(data, SetOptions(merge: true));
    await users.doc(userId).set(data, SetOptions(merge: true));
    await profiles.doc(userId).set(data, SetOptions(merge: true));
    _userProfileCache.remove(userId);
  }

  Future<DocumentSnapshot> getUserProfile(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _userProfileCache.containsKey(userId)) {
      final entry = _userProfileCache[userId]!;
      if (!entry.isExpired) {
        return entry.data;
      } else {
        _userProfileCache.remove(userId);
      }
    }
    
    final doc = await users.doc(userId).get(const GetOptions(source: Source.serverAndCache));
    if (doc.exists) {
      _userProfileCache[userId] = CacheEntry(doc, DateTime.now());
    }
    return doc;
  }

  Future<void> updateUserStatus(String userId, String status) async {
    await users.doc(userId).update({'registration_status': status});
    _userProfileCache.remove(userId);
  }

  /// Paginated users fetch enforcing limit and startAfterDocument pagination
  Future<QuerySnapshot> getPaginatedUsers({
    DocumentSnapshot? lastDocument,
    int limit = 15,
  }) async {
    Query query = users
        .where('account_status', isEqualTo: 'approved')
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    return await query.get(const GetOptions(source: Source.serverAndCache));
  }

  /// Paginated stories fetch strictly within last 24 hours
  Future<QuerySnapshot> getActiveStories({
    DocumentSnapshot? lastDocument,
    int limit = 15,
  }) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    Query query = stories
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    return await query.get(const GetOptions(source: Source.serverAndCache));
  }

  // ── Tharavadu Master Service ─────────────────────────────────────────────

  Future<QuerySnapshot> getTharavaduList({DocumentSnapshot? lastDocument, int limit = 10}) async {
    Query query = tharavaduMaster
        .where('is_approved', isEqualTo: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    return await query.get(const GetOptions(source: Source.serverAndCache));
  }

  Future<void> addTharavadu(Map<String, dynamic> tharavaduData) async {
    tharavaduData['createdAt'] = FieldValue.serverTimestamp();
    await tharavaduMaster.add(tharavaduData);
  }

  // ── Matching & Interests Service ─────────────────────────────────────────

  Future<void> sendInterest(String fromUserId, String toUserId) async {
    await interests.add({
      'from_user': fromUserId,
      'to_user': toUserId,
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<QuerySnapshot> getIncomingInterests(String userId, {DocumentSnapshot? lastDocument, int limit = 10}) async {
    Query query = interests
        .where('to_user', isEqualTo: userId)
        .where('status', isEqualTo: 'PENDING')
        .limit(limit);
        
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    return await query.get(const GetOptions(source: Source.serverAndCache));
  }

  // ── Chat Rooms Service ───────────────────────────────────────────────────

  Future<String> createOrGetChatRoom(String user1, String user2) async {
    String roomId = user1.compareTo(user2) < 0
        ? '${user1}_$user2'
        : '${user2}_$user1';

    final roomDoc = await chatRooms.doc(roomId).get(const GetOptions(source: Source.serverAndCache));
    if (!roomDoc.exists) {
      await chatRooms.doc(roomId).set({
        'users': [user1, user2],
        'is_approved_by_admin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return roomId;
  }

  Stream<QuerySnapshot> streamChatMessages(String roomId, {int limit = 50}) {
    return chatRooms
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<void> sendMessage(String roomId, String senderId, String text) async {
    await chatRooms.doc(roomId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // ── Admin & Governance ───────────────────────────────────────────────────

  Future<void> approveRegistration(String userId) async {
    await users.doc(userId).update({
      'is_approved': true,
      'registration_status': 'ACTIVE',
    });
    _userProfileCache.remove(userId);
  }

  Future<void> approveChatRoom(String roomId) async {
    await chatRooms.doc(roomId).update({'is_approved_by_admin': true});
  }

  Future<DocumentSnapshot> getAppConfig({bool forceRefresh = false}) async {
    const configId = 'global_settings';
    
    if (!forceRefresh && _appConfigCache.containsKey(configId)) {
      final entry = _appConfigCache[configId]!;
      if (!entry.isExpired) {
        return entry.data;
      } else {
        _appConfigCache.remove(configId);
      }
    }
    
    final doc = await appConfig.doc(configId).get(const GetOptions(source: Source.serverAndCache));
    if (doc.exists) {
      _appConfigCache[configId] = CacheEntry(doc, DateTime.now());
    }
    return doc;
  }

  Future<void> createMatchDeal(
    String fromUser,
    String toUser,
    double amount,
  ) async {
    await matchDeals.add({
      'from_user': fromUser,
      'to_user': toUser,
      'amount': amount,
      'status': 'AWAITING_PAYMENT',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Screen Directory Synchronizer & Telemetry ─────────────────────────────

  /// Automatically registers all screens with metadata to Firestore `screen_registry`
  Future<void> syncScreenRegistry(List<Map<String, dynamic>> screens) async {
    try {
      final batch = _db.batch();
      for (final screen in screens) {
        final docId = (screen['id'] as String?) ??
            (screen['title'] as String).toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
        final docRef = screenRegistry.doc(docId);
        batch.set(docRef, {
          ...screen,
          'last_synced_at': FieldValue.serverTimestamp(),
          'updated_at': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('Firestore: Successfully synced ${screens.length} screens to `screen_registry`');
    } catch (e) {
      debugPrint('Firestore syncScreenRegistry error: $e');
    }
  }

  /// Logs a screen navigation event directly into Firestore `screen_visits`
  Future<void> logScreenVisit({
    required String screenName,
    required String route,
    String? category,
    String? firestoreCollection,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      await screenVisits.add({
        'screen_name': screenName,
        'route': route,
        'category': category ?? 'general',
        'collection': firestoreCollection ?? 'general',
        'user_id': currentUser?.id ?? 'anonymous',
        'user_email': currentUser?.email,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      debugPrint('Firestore logScreenVisit notice: $e');
    }
  }

  /// Quick test write to test/verify connection for any screen collection
  Future<bool> testCollectionWrite(String collectionName, {Map<String, dynamic>? sampleData}) async {
    try {
      final docRef = _db.collection(collectionName).doc('ping_${DateTime.now().millisecondsSinceEpoch}');
      await docRef.set({
        'ping': true,
        'collection': collectionName,
        'test_time': DateTime.now().toIso8601String(),
        'server_timestamp': FieldValue.serverTimestamp(),
        ...?sampleData,
      });
      return true;
    } catch (e) {
      debugPrint('Firestore testCollectionWrite [$collectionName] error: $e');
      return false;
    }
  }

  /// Listen to real-time updates for any collection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(String collectionName, {int limit = 20}) {
    return _db.collection(collectionName).limit(limit).snapshots();
  }
}
