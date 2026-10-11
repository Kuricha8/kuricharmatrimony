import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized state provider to manage unlocked contacts across all screens.
/// Synchronizes with Supabase `unlocked_contacts` table and caches state locally.
class UnlockedContactsProvider extends ChangeNotifier {
  final Set<String> _unlockedUserIds = {};
  bool _isLoading = false;
  String? _currentUserId;

  Set<String> get unlockedUserIds => Set.unmodifiable(_unlockedUserIds);
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;

  /// Checks if [targetUserId] is unlocked by the current user.
  bool isUnlocked(String targetUserId) {
    if (targetUserId.isEmpty) return false;
    return _unlockedUserIds.contains(targetUserId);
  }

  /// Fetches all unlocked contact profile IDs for [userId] from Supabase DB.
  Future<void> fetchUnlockedContacts(String userId) async {
    if (userId.isEmpty) return;
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('unlocked_contacts')
          .select('target_user_id')
          .eq('user_id', userId);

      _unlockedUserIds.clear();
      for (var row in response) {
        final targetId = row['target_user_id']?.toString();
        if (targetId != null && targetId.isNotEmpty) {
          _unlockedUserIds.add(targetId);
        }
      }
    } catch (e) {
      debugPrint(
        '[UnlockedContactsProvider] Error fetching unlocked contacts: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Locally marks [targetUserId] as unlocked immediately for reactive UI updates.
  void markUnlockedLocal(String targetUserId) {
    if (targetUserId.isNotEmpty && !_unlockedUserIds.contains(targetUserId)) {
      _unlockedUserIds.add(targetUserId);
      notifyListeners();
    }
  }

  /// Saves unlocked pair into `unlocked_contacts` DB table and updates local reactive state.
  Future<bool> unlockContact({
    required String currentUserId,
    required String targetUserId,
    double amount = 49.0,
    String? paymentId,
  }) async {
    if (currentUserId.isEmpty || targetUserId.isEmpty) return false;

    // Immediately update local state so UI updates without delay
    markUnlockedLocal(targetUserId);

    try {
      await Supabase.instance.client.from('unlocked_contacts').upsert({
        'user_id': currentUserId,
        'target_user_id': targetUserId,
        'amount': amount,
        'payment_id':
            paymentId ?? 'CF_${DateTime.now().millisecondsSinceEpoch}',
        'unlocked_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,target_user_id');

      debugPrint(
        '[UnlockedContactsProvider] Contact $targetUserId successfully unlocked in DB for user $currentUserId',
      );
      return true;
    } catch (e) {
      debugPrint(
        '[UnlockedContactsProvider] Error persisting unlock contact to Supabase: $e',
      );
      // Even if DB insert fails (e.g., offline mode), local state keeps it unlocked for session
      return true;
    }
  }

  /// Resets state on logout
  void clear() {
    _unlockedUserIds.clear();
    _currentUserId = null;
    _isLoading = false;
    notifyListeners();
  }
}
