import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../core/services/global_features_service.dart';
import '../../core/services/admob_service.dart';
import '../../core/services/matching_service.dart';
import '../../core/security/window_security_service.dart';
import '../../core/security/guest_security_service.dart';
import '../../core/services/match_status_security_service.dart';
import '../../main.dart';
import 'widgets/profile_header_widget.dart';
import 'widgets/profile_family_widget.dart';
import 'widgets/profile_info_grid_widget.dart';
import 'widgets/profile_preferences_widget.dart';
import 'widgets/profile_actions_widget.dart';
import 'widgets/clan_vouch_card_widget.dart';
import 'widgets/marriage_compatibility_card_widget.dart';

class ProfileDetailPage extends StatefulWidget {
  final String profileId;
  const ProfileDetailPage({super.key, required this.profileId});
  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> with RouteAware {
  UserProfile? _profile;
  bool _loading = true,
      _isPhoneRevealed = false,
      _isShortlisted = false,
      _isMutualMatch = false;
  String? _error, _actionFetchError;
  int _actionRowsFetched = 0;
  final List<String> _profileMappingErrors = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkScreenshotSecurity();
    _syncViewerSubscriptionState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final modalRoute = ModalRoute.of(context);
      if (modalRoute is PageRoute) {
        globalRouteObserver.subscribe(this, modalRoute);
      }
    });
  }

  Future<void> _syncViewerSubscriptionState() async {
    final me = MockData().currentUser;
    if (me != null && me.id.isNotEmpty && me.id != 'guest') {
      await MockData().syncUserSubscriptionFromFirestore(me.id);
    }
  }

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSecuritySubscription;

  @override
  void dispose() {
    _profileSecuritySubscription?.cancel();
    _profileSecuritySubscription = null;
    WindowSecurityService.reapplyCurrentUserSecurity();
    globalRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    _profileSecuritySubscription?.pause();
    WindowSecurityService.reapplyCurrentUserSecurity();
  }

  @override
  void didPopNext() {
    _profileSecuritySubscription?.resume();
    _checkScreenshotSecurity();
  }

  Future<void> _checkScreenshotSecurity() async {
    // 1. Identify whether the current viewer is a Guest (unauthenticated / anonymous).
    final isViewerGuest = GuestSecurityService.isGuest(MockData().currentUser);

    // 2. Screenshot Restriction for Guests:
    // If the user is a Guest, NEVER allow screenshots under any circumstance
    if (isViewerGuest) {
      debugPrint('[Security] Viewer is GUEST. Strictly ENFORCING FLAG_SECURE across profile detail.');
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      return;
    }

    // 3. Conditional Profile View Override for Authenticated Users:
    // Listen to the target profile's Firestore document stream in real time
    _profileSecuritySubscription?.cancel();
    try {
      _profileSecuritySubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profileId)
          .snapshots()
          .listen((snapshot) async {
        final data = snapshot.data();
        bool allowScreenshot = false;
        if (data != null) {
          if (data.containsKey('allow_screenshot')) {
            allowScreenshot = data['allow_screenshot'] == true;
          } else if (data.containsKey('screenshot_blocked')) {
            allowScreenshot = data['screenshot_blocked'] == false;
          } else if (data.containsKey('allowScreenshot')) {
            allowScreenshot = data['allowScreenshot'] == true;
          }
        }

        if (allowScreenshot) {
          debugPrint('[Security] allow_screenshot == true for ${widget.profileId}. Clearing FLAG_SECURE dynamically.');
          await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
        } else {
          debugPrint('[Security] allow_screenshot is FALSE or NULL for ${widget.profileId}. Adding FLAG_SECURE dynamically.');
          await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        }
      });
    } catch (e) {
      debugPrint('[Security] Error setting up profile screenshot subscription: $e');
    }
  }

  Future<void> _loadProfile() async {
    _actionFetchError = null;
    _profileMappingErrors.clear();
    final cached = MockData().profiles.firstWhere(
      (p) => p.id == widget.profileId,
      orElse: () => UserProfile.guest(),
    );
    if (cached.id.isNotEmpty && cached.id != 'guest') {
      setState(() {
        _profile = cached;
        _actionRowsFetched = 1;
        _loading = false;
      });
      return;
    }
    try {
      final res = await Supabase.instance.client
          .from('kurichiyar_profiles')
          .select()
          .eq('id', widget.profileId)
          .maybeSingle();
      _actionRowsFetched = res != null ? 1 : 0;
      if (res != null) {
        setState(() {
          _profile = UserProfile.fromMap(res);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Profile not found';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _actionFetchError = e.toString();
        _error = e.toString();
        _loading = false;
      });
    }
    _checkMutualMatchStatus();
  }

  Future<void> _checkMutualMatchStatus() async {
    final me = MockData().currentUser;
    if (me == null || GuestSecurityService.isGuest(me)) {
      if (mounted) setState(() => _isMutualMatch = false);
      return;
    }

    try {
      final isMutual = await MatchStatusSecurityService.isMutualAcceptedWithApproval(
        currentUserId: me.id,
        targetProfileId: widget.profileId,
        currentUser: me,
      );
      if (mounted) {
        setState(() => _isMutualMatch = isMutual);
      }
    } catch (_) {}
  }

  int _clanAdsWatched = 0;

  void _onWatchClanAd() {
    AdMobService.instance.showRewardedAd(
      onUserEarnedReward: () {
        if (!mounted) return;
        setState(() {
          _clanAdsWatched++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _clanAdsWatched >= 3
                  ? '🎉 തറവാട് വിവരങ്ങൾ അൺലോക്ക് ചെയ്തു!'
                  : 'പരസ്യം കണ്ടു ($_clanAdsWatched/3). ഇനിയും ${3 - _clanAdsWatched} പരസ്യങ്ങൾ ബാക്കി.',
            ),
            backgroundColor: _clanAdsWatched >= 3 ? Colors.green : Colors.blue,
          ),
        );
      },
    );
  }

  void _showUpgradeDialog() {
    Navigator.pushNamed(context, '/subscriptions');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
  { return const Scaffold(body: Center(child: CircularProgressIndicator())); }
    if (_error != null && _profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error!)),
      );
    }
    final profile = _profile!;

    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, _) {
        final me = MockData().currentUser;

        // Direct Profile View / URL Guard:
        // If a user attempts to open an incompatible/restricted profile directly via ID or link,
        // completely block details, photos, and contact info, and show the clean polite message.
        if (me != null && !me.isAdmin && me.id != profile.id) {
          final isCompatible = MatchingService.isMatchEligible(me, profile);
          if (!isCompatible) {
            return Scaffold(
              backgroundColor: const Color(0xFFF9F7F3),
              appBar: AppBar(
                title: const Text('പ്രൊഫൈൽ ലഭ്യമല്ല'),
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 56,
                          color: Colors.amber.shade800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'ഈ പ്രൊഫൈൽ താങ്കളുടെ മാട്രിമോണിയൽ മാനദണ്ഡങ്ങളുമായി പൊരുത്തപ്പെടുന്നില്ല.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ഗോത്ര ആചാരങ്ങളും പരസ്പര കുടുംബ നിയന്ത്രണങ്ങളും (Moiety & Kinship Rules) അനുസരിച്ച് ഈ പ്രൊഫൈലിലെ വിവരങ്ങൾ ലഭ്യമാക്കിയിട്ടില്ല.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000080),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('തിരികെ പോകുക'),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }

        final isGuest = me == null || me.role == 'guest';
        // Check user subscription state: isPremium or planStatus == 'active'
        // If viewer is Paid/Premium, Admin, or viewing own profile -> Unlocked
        final isViewerPremium = me != null && (me.isPremium || me.isAdmin || me.id == profile.id);
        final isLocked = !isViewerPremium;
        final isClanUnlocked = !isGuest;

        return Scaffold(
          appBar: AppBar(title: Text(profile.name)),
          body: SingleChildScrollView(
            child: Column(
              children: [
                ProfileHeaderWidget(
                  profile: profile,
                  me: me,
                  isShortlisted: _isShortlisted,
                  onToggleShortlist: () =>
                      setState(() => _isShortlisted = !_isShortlisted),
                ),
                const SizedBox(height: 16),
                ClanVouchCardWidget(
                  profile: profile,
                  me: me,
                  onVouchSubmitted: () {
                    _loadProfile();
                  },
                ),
                const SizedBox(height: 16),
                ProfileFamilyWidget(
                  profile: profile,
                  isGuest: isGuest,
                  isUnlocked: isClanUnlocked,
                  adViewsCount: _clanAdsWatched,
                  onWatchAdToUnlock: _onWatchClanAd,
                  onUpgrade: _showUpgradeDialog,
                ),
                const SizedBox(height: 16),
                MarriageCompatibilityCardWidget(profile: profile, me: me),
                const SizedBox(height: 16),
                ProfileInfoGridWidget(
                  profile: profile,
                  isGuest: isGuest,
                  isLocked: isLocked,
                  isPhoneRevealed: _isPhoneRevealed,
                  isMutualAccepted: _isMutualMatch,
                  onUpgrade: _showUpgradeDialog,
                  onRevealPhone: () => setState(() => _isPhoneRevealed = true),
                ),
                const SizedBox(height: 16),
                if (GlobalFeaturesService.instance.compatibilityQuiz)
                  ProfilePreferencesWidget(profile: profile),
                const SizedBox(height: 16),
                ProfileActionsWidget(
                  profile: profile,
                  me: me,
                  isMutualMatch: _isMutualMatch,
                  actionFetchError: _actionFetchError,
                  actionRowsFetched: _actionRowsFetched,
                  profileMappingErrors: _profileMappingErrors,
                  onRetryFetch: _loadProfile,
                  onRequestHouseVisit: () {},
                  onCheckMutualMatchStatus: _checkMutualMatchStatus,
                  onContactViaAdmin: (context, profile) {},
                  onOneTimePhotoView: (context, photoUrl) {},
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
