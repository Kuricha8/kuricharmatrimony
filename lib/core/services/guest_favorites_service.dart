import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/mock_data.dart';
import '../models/models.dart';
import 'personalized_feed_service.dart';

/// Manages guest and authenticated user favorites / likes.
///
/// Ensures guest users can freely like and save profiles locally in
/// [SharedPreferences] without encountering blocking paywalls or login modals.
/// Automatically synchronizes with account favorites if the user logs in.
class GuestFavoritesService extends ChangeNotifier {
  static final GuestFavoritesService _instance =
      GuestFavoritesService._internal();
  static GuestFavoritesService get instance => _instance;

  GuestFavoritesService._internal() {
    _loadFavorites();
  }

  static const String _storageKey = 'guest_favorite_profile_ids';
  final Set<String> _favoriteIds = {};
  bool _isInitialized = false;

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  bool get isInitialized => _isInitialized;

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_storageKey);
      if (savedList != null) {
        _favoriteIds.addAll(savedList);
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading guest favorites: $e');
    }
  }

  bool isFavorite(String profileId) {
    if (profileId.isEmpty) return false;

    // Check MockData currentUser favorites if logged in
    final currentUser = MockData().currentUser;
    if (currentUser != null &&
        currentUser.favoriteProfileIds.contains(profileId)) {
      return true;
    }

    return _favoriteIds.contains(profileId);
  }

  Future<bool> toggleFavorite(
    String profileId, {
    String? profileName,
    String? job,
    String? location,
    String? education,
    UserProfile? profile,
    Map<String, dynamic>? rawProfile,
  }) async {
    if (profileId.isEmpty) return false;

    final currentlyLiked = isFavorite(profileId);
    final nextState = !currentlyLiked;

    if (nextState) {
      _favoriteIds.add(profileId);
      // Track personalized preference features
      final resolvedJob = job ??
          profile?.job ??
          rawProfile?['job']?.toString() ??
          rawProfile?['occupation']?.toString();
      final resolvedLoc = location ??
          profile?.region ??
          rawProfile?['region']?.toString() ??
          rawProfile?['district']?.toString() ??
          rawProfile?['location']?.toString();
      final resolvedEdu = education ??
          profile?.educationLevel ??
          rawProfile?['education_level']?.toString() ??
          rawProfile?['education']?.toString();

      PersonalizedFeedService.instance.recordLikedProfileFeatures(
        job: resolvedJob,
        location: resolvedLoc,
        education: resolvedEdu,
      );
    } else {
      _favoriteIds.remove(profileId);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _favoriteIds.toList());
    } catch (e) {
      debugPrint('Error saving guest favorite: $e');
    }

    // Sync with MockData and Supabase if logged in
    final currentUser = MockData().currentUser;
    if (currentUser != null) {
      MockData().toggleFavorite(profileId);
      try {
        if (nextState) {
          await Supabase.instance.client.from('profile_matches').insert({
            'sender_id': currentUser.id,
            'receiver_id': profileId,
            'status': 'LIKED',
          });
        } else {
          await Supabase.instance.client
              .from('profile_matches')
              .delete()
              .eq('sender_id', currentUser.id)
              .eq('receiver_id', profileId);
        }
      } catch (e) {
        debugPrint('Error syncing match interaction with Supabase: $e');
      }
    }

    notifyListeners();
    return nextState;
  }

  /// Push any guest likes to the user account upon login.
  Future<void> syncWithUserAccount() async {
    final currentUser = MockData().currentUser;
    if (currentUser == null || _favoriteIds.isEmpty) return;

    for (final id in _favoriteIds) {
      if (!currentUser.favoriteProfileIds.contains(id)) {
        MockData().toggleFavorite(id);
      }
    }
    notifyListeners();
  }
}
