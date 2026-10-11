import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class LocalCacheService {
  static final LocalCacheService instance = LocalCacheService._internal();
  LocalCacheService._internal();

  static const String _clanFeedBox = 'clan_feeds';
  static const String _profilesBox = 'kurichiyar_profiles';
  static const String _pendingActionsBox = 'pending_actions';
  static const String _settingsBox = 'app_settings';
  static const String _deletedStatusesBox = 'deleted_statuses_blacklist';
  static const String _statusCacheBox = 'cached_status_posts';

  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_clanFeedBox);
    await Hive.openBox(_profilesBox);
    await Hive.openBox(_pendingActionsBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_deletedStatusesBox);
    await Hive.openBox(_statusCacheBox);
    debugPrint('Hive Local Cache Initialized');
  }

  // --- Device ID ---
  String getOrCreateDeviceId() {
    final box = Hive.box(_settingsBox);
    String? deviceId = box.get('device_id');
    if (deviceId == null) {
      // Generate a simple UUID-like string
      final random = Random();
      deviceId =
          '${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1000000)}';
      box.put('device_id', deviceId);
    }
    return deviceId;
  }

  // --- Clan Feed Cache ---
  Future<void> cacheClanFeeds(List<Map<String, dynamic>> feeds) async {
    final box = Hive.box(_clanFeedBox);
    await box.clear();
    for (int i = 0; i < feeds.length; i++) {
      await box.put(i, feeds[i]);
    }
  }

  List<Map<String, dynamic>> getCachedClanFeeds() {
    final box = Hive.box(_clanFeedBox);
    return box.values.cast<Map<String, dynamic>>().toList();
  }

  // --- Status Blacklist & Cache Management ---
  Future<void> markStatusDeleted(String statusId) async {
    final box = Hive.box(_deletedStatusesBox);
    await box.put(statusId, DateTime.now().toIso8601String());
  }

  Set<String> getDeletedStatusIds() {
    final box = Hive.box(_deletedStatusesBox);
    return box.keys.map((k) => k.toString()).toSet();
  }

  Future<void> cacheStatuses(List<Map<String, dynamic>> statuses) async {
    final box = Hive.box(_statusCacheBox);
    await box.clear();
    for (int i = 0; i < statuses.length; i++) {
      await box.put(i, statuses[i]);
    }
  }

  List<Map<String, dynamic>> getCachedStatuses() {
    final box = Hive.box(_statusCacheBox);
    return box.values.cast<Map<String, dynamic>>().toList();
  }

  Future<void> purgeStatusFromCache(String statusId) async {
    final box = Hive.box(_statusCacheBox);
    final keysToDelete = <dynamic>[];
    for (final key in box.keys) {
      final val = box.get(key);
      if (val is Map && val['id']?.toString() == statusId) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  // --- Write Action Queueing (Offline Mode) ---
  Future<void> queueAction(
    String actionType,
    Map<String, dynamic> payload,
  ) async {
    final box = Hive.box(_pendingActionsBox);
    await box.add({
      'type': actionType,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  List<Map<dynamic, dynamic>> getPendingActions() {
    final box = Hive.box(_pendingActionsBox);
    return box.values.cast<Map<dynamic, dynamic>>().toList();
  }

  Future<void> clearPendingActions() async {
    final box = Hive.box(_pendingActionsBox);
    await box.clear();
  }
}
