import '../../features/clan_feed/tharavadu_list.dart';
import '../../core/models/models.dart';
import '../../core/services/global_features_service.dart';
import '../../core/services/clan_matching_engine.dart';

/// Singleton that holds the current user's pre-computed compatibility set.
/// Call [init] once when the user's profile is available.
/// All public methods are synchronous — zero network calls.
class CompatibilityFilterService {
  CompatibilityFilterService._();
  static final CompatibilityFilterService instance =
      CompatibilityFilterService._();

  UserProfile? _currentUser;

  // Pre-computed sets — populated by [init]
  final Set<int> _incompatibleClanIds = {};

  // Whether the service has been initialised for the current user
  bool get isReady => _currentUser != null;

  /// Pre-compute the incompatible clan set for [me].
  /// Call this once per user session (e.g. when the tharavad chat feed opens).
  void init(UserProfile me) {
    if (_currentUser?.id == me.id) return; // already up to date
    _currentUser = me;
    _incompatibleClanIds.clear();

    if (!GlobalFeaturesService.instance.panthiBandhuCheck) return;

    for (final clan in allClans) {
      final syntheticProfile = UserProfile(
        id: 'compat_check_${clan.id}',
        name: clan.name,
        age: 25,
        gender: me.gender == Gender.male ? Gender.female : Gender.male,
        email: '',
        photoUrl: '',
        fatherClanId: clan.id,
        motherClanId: clan.id,
        isOutOfCaste: false,
        maritalStatus: MaritalStatus.first,
      );

      if (!ClanMatchingEngine.instance.areProfilesCompatible(
        me,
        syntheticProfile,
      )) {
        _incompatibleClanIds.add(clan.id);
      }
    }
  }

  /// Returns true if [clanId] is compatible with the current user.
  /// Falls back to true (show) when not yet initialised.
  bool isClanCompatible(int clanId) {
    if (!isReady) return true;
    return !_incompatibleClanIds.contains(clanId);
  }

  /// Returns true if [profile] is compatible with the current user.
  bool isProfileCompatible(UserProfile profile) {
    if (!isReady) return true;
    return ClanMatchingEngine.instance.areProfilesCompatible(
      _currentUser!,
      profile,
    );
  }

  /// Reset when the user logs out.
  void clear() {
    _currentUser = null;
    _incompatibleClanIds.clear();
  }
}
