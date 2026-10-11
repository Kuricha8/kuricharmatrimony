import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../clan_feed/tharavadu_list.dart';
import '../../core/widgets/interstitial_ad_manager.dart';
import '../subscriptions/subscription_service.dart';
import '../subscriptions/subscription_page.dart';
import '../../core/widgets/native_ad_card.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';
import '../matching/flash_match_stack.dart';
import 'package:shake/shake.dart';
import '../../core/widgets/community_widgets.dart';
import '../../core/widgets/skeleton_loaders.dart';
import '../match_agreement/match_agreement_page.dart';
import '../../core/widgets/universal_profile_card.dart';
import '../profile_detail/profile_detail_page.dart';
import '../../core/services/personalized_feed_service.dart';
import '../../core/widgets/sponsored_banner_card.dart';
import '../family_tree/family_tree_navigation_helper.dart';

// ---------------------------------------------------------------------------
// Malayalam UI strings for HomeTab
// ---------------------------------------------------------------------------
const _kVerifiedMatches     = 'സ്ഥിരീകരിച്ച പൊരുത്തങ്ങൾ';
const _kViewFull            = 'പൂർണ്ണ വിവരങ്ങൾ';  // "Full details"
const _kHideDetails         = 'മറയ്ക്കുക';           // "Hide"
const _kConnect             = 'ബന്ധപ്പെടുക / ചാറ്റ്';
const _kNoMatches           = 'ഇപ്പോൾ പൊരുത്തമുള്ള പ്രൊഫൈലുകൾ ഒന്നും ലഭ്യമല്ല.';
const _kNoMatchesSub        = 'ദൈനംദിനം പ്രൊഫൈലുകൾ പരിശോധിക്കുന്നു. ദയവായി പിന്നീട് പരിശോധിക്കുക!';
const _kFatherClan          = 'പിതൃ ഗോത്രം';
const _kMotherClan          = 'മാതൃ ഗോത്രം';
const _kSecondMarriage      = 'രണ്ടാം വിവാഹം';
const _kHasChildren         = 'കുട്ടികളുണ്ട്';
const _kNoChildren          = 'കുട്ടികളില്ല';
const _kVipBadge            = '👑 VIP ആജീവനാന്ത';
const _kTier2Badge          = '⭐ ടയർ 2';
const _kTier1Badge          = '🔶 ടയർ 1';
const _kInCaste             = 'ഗോത്ര-ബദ്ധ';
const _kOutOfCaste          = 'ഗോത്ര-ഭേദ';
const _kPhone               = 'ഫോൺ';
const _kEmail               = 'ഇ-മെയിൽ';
const _kJob                 = 'തൊഴിൽ';
const _kRegion              = 'പ്രദേശം';

class HomeTab extends StatefulWidget {
  final UserProfile currentUser;
  final VoidCallback onNavigateToChat;

  const HomeTab({
    super.key,
    required this.currentUser,
    required this.onNavigateToChat,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final Set<String> _expandedProfiles = {}; // Profiles fully viewed and expanded
  final Set<String> _boostedProfileIds = {}; // Mutual Interest Profiles
  ShakeDetector? _shakeDetector;

  @override
  void initState() {
    super.initState();
    _loadExclusions();
    _fetchMutualViews();
    MockData().addListener(_onMockDataChanged);
    _subscribeToProfileChanges();
    _scrollController.addListener(_onScroll);
    
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) => _handleShakeToChange(),
      shakeThresholdGravity: 2.7,
    );
  }

  void _handleShakeToChange() {
    if (!mounted || _cachedMatches.isEmpty) return;
    
    // Find the first visible profile index based on scroll position, or just remove the first item in the list
    // Actually, just dismiss the very first item in _cachedMatches for simplicity, or the one currently on screen.
    setState(() {
      final dismissedId = _cachedMatches.first.id;
      _cachedMatches.removeAt(0);
      _lastProfileCount--;
      // Optional: Add to interacted to prevent it coming back
      MockData().interactedProfileIds.add(dismissedId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Shaken! Next Profile Loading...'),
      duration: Duration(seconds: 1),
    ));
  }

  Future<void> _fetchMutualViews() async {
    final me = widget.currentUser;
    try {
      final res = await Supabase.instance.client
          .from('profile_views_history')
          .select('viewed_id, view_count')
          .eq('viewer_id', me.id)
          .gte('view_count', 2);
      
      final Set<String> boosted = {};
      for (var row in res) {
        boosted.add(row['viewed_id'] as String);
      }
      
      if (mounted) {
        setState(() {
          _boostedProfileIds.clear();
          _boostedProfileIds.addAll(boosted);
          // Invalidate cache
          _lastProfileCount = -1; 
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch mutual views: $e');
    }
  }

  final _sub = SubscriptionService.instance;
  
  // Search state
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  List<Map<String, dynamic>> _tharavadExclusions = [];
  bool _loadingExclusions = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // Supabase Realtime channel — fires when any profile row changes so the
  // matching pool automatically reflects admin corrections without restart.
  RealtimeChannel? _profileChannel;

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && MockData().isProfilesSynced) {
        _loadMoreProfiles();
      }
    }
  }

  Future<void> _loadMoreProfiles() async {
    setState(() => _isLoadingMore = true);
    final currentOffset = MockData().profiles.length;
    await MockData().syncProfilesFromDatabase(limit: 15, offset: currentOffset);
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _subscribeToProfileChanges() {
    try {
      _profileChannel = Supabase.instance.client
          .channel('public:profiles:home_tab')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'kurichiyar_profiles',
            callback: (payload) {
              debugPrint('HomeTab: Profile realtime event — refreshing match pool');
              _loadExclusions(); // re-fetch exclusions
              if (mounted) setState(() {}); // rebuild matching pool immediately
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('HomeTab: Realtime subscription failed (non-fatal): $e');
    }
  }

  Future<void> _loadExclusions() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('tharavadu_exclusions')
          .select('tharavad_id_1, tharavad_id_2');
      if (mounted) {
        setState(() {
          _tharavadExclusions = List<Map<String, dynamic>>.from(response);
          _loadingExclusions = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load tharavad exclusions: $e');
      if (mounted) {
        setState(() {
          _loadingExclusions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _profileChannel?.unsubscribe();
    MockData().removeListener(_onMockDataChanged);
    super.dispose();
  }

  void _onMockDataChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  List<UserProfile> _cachedMatches = [];
  String _lastSearchQuery = '';
  int _lastProfileCount = 0;

  // ── Matching pool with priority sort ──────────────────────────────────────
  List<UserProfile> _getMatchingPool(MockData data) {
    final me = widget.currentUser;
    
    // Memoization check
    if (_cachedMatches.isNotEmpty && 
        _lastSearchQuery == _searchQuery && 
        _lastProfileCount == data.profiles.length) {
      return _cachedMatches;
    }

    final filtered = data.profiles.where((profile) {
      if (data.interactedProfileIds.contains(profile.id)) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final nameMatches = profile.name.toLowerCase().contains(q);
        final fatherClanMatches = profile.fatherTharavadu?.toLowerCase().contains(q) ?? false;
        final motherClanMatches = profile.motherTharavadu?.toLowerCase().contains(q) ?? false;
        if (!nameMatches && !fatherClanMatches && !motherClanMatches) {
          return false;
        }
      }

      if (profile.accountStatus != AccountStatus.approved) return false;
      if (profile.profileStatus == ProfileStatus.married) return false;
      if (profile.gender == me.gender) return false;
      // Group and moiety checks
      final meIsFirst = me.maritalStatus == MaritalStatus.first;
      final targetIsFirst = profile.maritalStatus == MaritalStatus.first;
      
      final myMotherClan = getClanById(me.motherClanId);
      final targetMotherClan = getClanById(profile.motherClanId);

      // Flow / Group Isolation Checks
      if (meIsFirst) {
        if (me.isOutOfCaste) {
          // Group 2: Out of Caste - First Marriage. Can only see other Group 2 profiles.
          if (!targetIsFirst || !profile.isOutOfCaste) return false;
        } else {
          // Group 1: S-Match - First Marriage. Can only see other Group 1 profiles.
          if (!targetIsFirst || profile.isOutOfCaste) return false;
        }
      } else {
        if (me.isOutOfCaste) {
          // Group 4: Out of Caste - Second Marriage. Can only see other Group 4 profiles.
          if (targetIsFirst || !profile.isOutOfCaste) return false;
        } else {
          // Group 3: S-Match - Second Marriage. Can see Group 3 (Second In-Caste) or Group 1 (First In-Caste).
          if (profile.isOutOfCaste) return false;
        }
      }

      // Traditional Clan Rules Check (S-Match: Groups 1 and 3)
      if (!me.isOutOfCaste && !profile.isOutOfCaste) {
        if (myMotherClan != null && targetMotherClan != null) {
          if (myMotherClan.type == targetMotherClan.type) return false; // Must be opposite moieties
        }
        if (me.motherClanId == profile.motherClanId) return false; // Must not be the same clan
      } else {
        // Out of caste bypasses opposite moiety check but still cannot marry within the exact same tharavadu
        if (me.motherClanId == profile.motherClanId) return false;
      }

      // Children Acceptance Logic (Only for Second Marriage: Groups 3 & 4)
      if (me.gender == Gender.female) {
        if (me.hasChildren) {
          if (!profile.readyToAcceptChildren) return false;
        }
      } else {
        if (profile.hasChildren) {
          if (!me.readyToAcceptChildren) return false;
        }
      }
      
      // Tharavadu Exclusions check (Step 2 & 3)
      final myMotherClanId = me.motherClanId;
      final targetMotherClanId = profile.motherClanId;
      final isExcluded = _tharavadExclusions.any((exclusion) {
        final id1 = exclusion['tharavad_id_1'] as int;
        final id2 = exclusion['tharavad_id_2'] as int;
        return (id1 == myMotherClanId && id2 == targetMotherClanId) ||
               (id1 == targetMotherClanId && id2 == myMotherClanId);
      });
      if (isExcluded) return false;
      
      // Age matching
      if (profile.age < me.prefAgeMin || profile.age > me.prefAgeMax) return false;
      
      // Habits matching
      if (me.prefHabits == 'Strictly No') {
        if (profile.smokingHabit == 'Regularly' || profile.drinkingHabit == 'Regularly') return false;
      }
      
      // Relocation matching
      if (me.gender == Gender.female) {
        // Bride wants groom to relocate, but groom said No
        if (me.prefRelocateToBrideHome == true && profile.prefRelocateToBrideHome == false) return false;
      } else {
        // Groom is unwilling to relocate, but bride wants relocation
        if (me.prefRelocateToBrideHome == false && profile.prefRelocateToBrideHome == true) return false;
      }

      // Education matching
      if (me.prefEducation != null && me.prefEducation != 'Any') {
         if (profile.educationLevel != me.prefEducation) return false;
      }

      // Career matching
      if (me.prefCareer != null && me.prefCareer != 'Any') {
         if (profile.careerSector != me.prefCareer) return false;
      }

      // Income matching
      if (me.prefIncome != null && me.prefIncome != 'Any') {
        // Simple string matching based on the defined tiers
        // In a real app, this should be parsed into ints, but since these are fixed strings:
        final tierValues = {
          'Below 2 Lakhs': 0,
          '2 Lakhs+': 2,
          '5 Lakhs+': 5,
          '10 Lakhs+': 10,
        };
        final reqTier = tierValues[me.prefIncome] ?? 0;
        final actualTier = tierValues[profile.annualIncome] ?? 0;
        if (actualTier < reqTier) return false;
      }

      return true;
    }).toList();

    // Priority sort: Tier3 always pinned at absolute top
    _cachedMatches = _sub.sortByPriority(filtered);
    
    // TWO-WAY INTERACTION BOOST & PERSONALIZED RECOMMENDATION ALGORITHM
    // 1. Mutual interest (view_count >= 2) at top
    // 2. High personalized relevance score from liked profiles prioritized
    final personalizedService = PersonalizedFeedService.instance;
    _cachedMatches.sort((a, b) {
      final aBoost = _boostedProfileIds.contains(a.id);
      final bBoost = _boostedProfileIds.contains(b.id);
      if (aBoost && !bBoost) return -1;
      if (!aBoost && bBoost) return 1;

      // Personalized recommendation scoring (+3 job, +2 location, +1 education)
      final scoreA = personalizedService.calculateScore(a);
      final scoreB = personalizedService.calculateScore(b);
      if (scoreB != scoreA) {
        return scoreB.compareTo(scoreA);
      }

      return 0; // preserve previous sorting (Tier3 on top, etc.) if both boosted or neither
    });

    _lastSearchQuery = _searchQuery;
    _lastProfileCount = data.profiles.length;
    
    return _cachedMatches;
  }

  // ── View gate: attempt to open full profile details ────────────────────
  void _tryOpenFullDetails(MockData mockData, UserProfile candidate) {
    final me = mockData.currentUser!;

    // Already expanded — just collapse
    if (_expandedProfiles.contains(candidate.id)) {
      setState(() => _expandedProfiles.remove(candidate.id));
      return;
    }

    // Already viewed before — re-open free (no quota cost)
    if (me.viewedProfileIds.contains(candidate.id)) {
      setState(() => _expandedProfiles.add(candidate.id));
      return;
    }

    // Check subscription gate
    if (!_sub.canViewProfile(me, candidate.id)) {
      _showPaywall(me);
      return;
    }

    // Consume view and expand
    InterstitialAdManager().showAdIfAvailable(
      onComplete: () {
        mockData.consumeProfileView(candidate.id);
        setState(() => _expandedProfiles.add(candidate.id));
      },
    );
  }

  // ── Paywall dialog (Malayalam) ─────────────────────────────────────────
  void _showPaywall(UserProfile me) {
    final isExpired = !me.isSubscriptionActive && me.subscriptionTier != SubscriptionTier.free;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_outline,
                color: isExpired ? Colors.red : Colors.amber.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isExpired
                    ? 'സബ്‌സ്ക്രിപ്ഷൻ അവസാനിച്ചു'
                    : 'പ്രൊഫൈൽ കാഴ്ച പരിധി തീർന്നു',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          isExpired ? kSubscriptionLapsedMsg : kQuotaExhaustedMsg,
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('റദ്ദാക്കുക'), // Cancel
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showUpgradeSheet();
            },
            icon: const Icon(Icons.upgrade),
            label: Text(kUpgradeNow),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C3E00),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Open Premium Packages Page ───────────────────────────────────────────
  void _showUpgradeSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionPage(currentUser: widget.currentUser),
      ),
    );
  }

  void _triggerLikeNotification(UserProfile candidate) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.currentUser.name} നിങ്ങളുടെ പ്രൊഫൈലിൽ താൽപ്പര്യം പ്രകടിപ്പിച്ചു!',
        ),
        backgroundColor: const Color(0xFF000080),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Action Cards (Family Tree & Events) ────────────────────────────────
  Widget _buildActionCards(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => handleFamilyTreeNavigation(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.nature_people, color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      loc?.kudumbaVriksham ?? '\u0D15\u0D41\u0D21\u0D41\u0D02\u0D2C \u0D35\u0D43\u0D15\u0D4D\u0D37\u0D02',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      loc?.vamshavali ?? '\u0D35\u0D02\u0D36\u0D3E\u0D35\u0D32\u0D3F',
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1E1E1E), // Premium dark theme
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (ctx) => _buildEventsSheet(ctx),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle, // Circular container as requested
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      loc?.eventsTitle ?? '\u0D07\u0D35\u0D28\u0D4D\u0D31\u0D41\u0D15\u0D33\u0D4D',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      loc?.upcomingEvents ?? '\u0D35\u0D30\u0D3E\u0D28\u0D3F\u0D35\u0D3F\u0D15\u0D4D\u0D15\u0D41\u0D28\u0D4D\u0D28\u0D35',
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSheet(BuildContext context) {
    // Mock events list since no DB table is available yet
    final events = [
      {'title': 'Annual Clan Gathering', 'date': '15 Aug 2026', 'location': 'Main Tharavadu'},
      {'title': 'Matrimony Meetup', 'date': '20 Sep 2026', 'location': 'Community Hall'},
    ];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 16, left: 150, right: 150),
            decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
          ),
          const Text(
            'Upcoming Events',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No upcoming events currently.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            )
          else
            ...events.map((e) => Card(
              color: const Color(0xFF2C2C2C),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.redAccent),
                title: Text(e['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${e['date']} • ${e['location']}', style: const TextStyle(color: Colors.white70)),
              ),
            )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Tier badge widget ──────────────────────────────────────────────────
  Widget? _tierBadge(UserProfile profile) {
    switch (profile.subscriptionTier) {
      case SubscriptionTier.tier3:
        return _badgeChip(_kVipBadge, const Color(0xFFB8860B), Colors.white);
      case SubscriptionTier.tier2:
        return _badgeChip(_kTier2Badge, Colors.blue.shade700, Colors.white);
      case SubscriptionTier.tier1:
        return _badgeChip(_kTier1Badge, Colors.amber.shade800, Colors.white);
      case SubscriptionTier.free:
      case SubscriptionTier.stealth:
        return null;
    }
  }

  Widget _badgeChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 6)],
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, child) {
        final mockData = MockData();
        final me = mockData.currentUser ?? widget.currentUser;
        
        final isLoading = _loadingExclusions || (!mockData.isProfilesSynced && mockData.profiles.isEmpty);
        final matches = isLoading ? <UserProfile>[] : _getMatchingPool(mockData);

        return Column(
          children: [
            // ── Free tier / upgrade banner ───────────────────────────────
            if (me.subscriptionTier == SubscriptionTier.free)
              GestureDetector(
                onTap: _showUpgradeSheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.amber.shade700,
                  width: double.infinity,
                  child: const Row(
                    children: [
                      Icon(Icons.star, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'സൗജന്യ അംഗം. പ്ലാൻ അപ്‌ഗ്രേഡ് ചെയ്ത് പ്രൊഫൈൽ വിവരങ്ങൾ കാണുക.',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),

            // ── Quota counter ────────────────────────────────────────────
            const SizedBox(height: 8),
            // ── Dashboard Action Cards ───────────────────────────────────
            _buildActionCards(context),
            const SizedBox(height: 8),

            // ── Search Bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'പേരോ തറവാടോ തിരയുക...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Color(0xFF000080)),
                  const SizedBox(width: 8),
                  Text(
                    '$_kVerifiedMatches (${matches.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5C3E00),
                    ),
                  ),
                ],
              ),
            ),

            // ── Matches list ─────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const SkeletonList()
                  : matches.isEmpty && mockData.announcements.isEmpty && mockData.history.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text(
                                  _kNoMatches,
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  _kNoMatchesSub,
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: matches.length + (matches.length ~/ 5) + 3 + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == matches.length + (matches.length ~/ 5) + 3) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                        if (index == 0) {
                          return AnnouncementsSection(announcements: mockData.announcements);
                        }
                        if (index == 1) {
                          return HistorySection(history: mockData.history);
                        }
                        if (index == 2) {
                          final flashCandidates = matches.take(5).toList();
                          return FlashMatchStack(candidates: flashCandidates);
                        }
                        
                        final adjustedIndex = index - 3;
                        if (adjustedIndex > 0 && adjustedIndex % 6 == 5) {
                          final bool isSponsoredBanner =
                              ((adjustedIndex ~/ 6) % 2 == 0);
                          if (isSponsoredBanner) {
                            return SponsoredBannerCard(
                              itemIndex: index,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            );
                          }
                          return const NativeAdCard(isStatusLayout: false);
                        }
                        final profileIndex = adjustedIndex - (adjustedIndex ~/ 6);
                        // Skip the first 5 profiles as they are in the FlashMatchStack
                        final actualProfileIndex = profileIndex + 5;
                        if (actualProfileIndex >= matches.length) return const SizedBox.shrink();
                        final profile = matches[actualProfileIndex];
                        final isFavorite = me.favoriteProfileIds
                            .contains(profile.id);
                        final fatherClan = getClanById(profile.fatherClanId);
                        final motherClan = getClanById(profile.motherClanId);
                        final isExpanded =
                            _expandedProfiles.contains(profile.id);
                        final alreadyViewed =
                            me.viewedProfileIds.contains(profile.id);
                        final badge = _tierBadge(profile);

                        return UniversalProfileCard(
                          profile: profile,
                          isVip: profile.isVip,
                          margin: const EdgeInsets.only(bottom: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProfileDetailPage(profileId: profile.id),
                              ),
                            );
                          },
                          topLeadingBadge: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield,
                                    color: Colors.green, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  profile.isOutOfCaste
                                      ? _kOutOfCaste
                                      : _kInCaste,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          topTrailingBadge: badge,
                          extraDetails: [
                            Text(
                              '$_kFatherClan: ${fatherClan?.type ?? (profile.isOutOfCaste ? "BANDHU" : "PANDI")} (${fatherClan?.name ?? profile.fatherTharavadu ?? "—"})',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              '$_kMotherClan: ${motherClan?.type ?? (profile.isOutOfCaste ? "PANDI" : "BANDHU")} (${motherClan?.name ?? profile.motherTharavadu ?? "—"})',
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (profile.maritalStatus != MaritalStatus.first) ...[
                              const SizedBox(height: 4),
                              Text(
                                '$_kSecondMarriage • ${profile.hasChildren ? _kHasChildren : _kNoChildren}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.pink.shade800),
                              ),
                              if (profile.acceptChildrenStatus != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Accepting Children: ${profile.acceptChildrenStatus == 'YES_WILLING' ? 'Yes' : 'No'}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              if (profile.adoptionPreference != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    'Adoption: ${profile.adoptionPreference!.replaceAll('_', ' ')}',
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '$_kRegion: ${profile.region}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            ),

                            // ── Full details panel (gated) ────────
                            if (isExpanded) ...[
                              const Divider(height: 20),
                              _detailRow(Icons.work, _kJob, profile.job),
                              _detailRow(Icons.email, _kEmail, profile.email),
                              _detailRow(Icons.phone, _kPhone, '(Premium ആക്ടിവ് ആകുമ്പോൾ ലഭ്യം)'),
                            ],
                          ],
                          actionFooter: Row(
                            children: [
                              // Like button
                              IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  String? commentText;
                                  if (!isFavorite) {
                                    final commentController = TextEditingController();
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(AppLocalizations.of(context)!.confirmLikeTitle),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(AppLocalizations.of(context)!.confirmLikeMessage),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: commentController,
                                              decoration: const InputDecoration(
                                                hintText: 'അവർക്ക് എന്തെങ്കിലും പറയാൻ താല്പര്യമുണ്ടോ? (Optional)',
                                                border: OutlineInputBorder(),
                                              ),
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, null),
                                            child: Text(AppLocalizations.of(context)!.thalperyamilla),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, commentController.text.trim()),
                                            child: Text(AppLocalizations.of(context)!.thalperyamundu),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (result == null) return;
                                    commentText = result;
                                  }

                                  mockData.toggleFavorite(profile.id, simulateMutualMatch: true);
                                  if (!isFavorite) {
                                    // Record liked features for personalized recommendation engine
                                    PersonalizedFeedService.instance
                                        .recordLikedProfileFeatures(
                                      job: profile.job.isNotEmpty
                                          ? profile.job
                                          : profile.careerSector,
                                      location: profile.region.isNotEmpty
                                          ? profile.region
                                          : profile.familyDetails.prefDistrict,
                                      education: profile.educationLevel ??
                                          profile.educationOtherText,
                                    );
                                    _triggerLikeNotification(profile);
                                    
                                    // Save like interaction to Supabase
                                    try {
                                      final me = mockData.currentUser;
                                      if (me != null) {
                                        await Supabase.instance.client.from('profile_matches').insert({
                                          'sender_id': me.id,
                                          'receiver_id': profile.id,
                                          'status': 'LIKED',
                                          if (commentText != null && commentText.isNotEmpty) 'interaction_comment': commentText,
                                        });
                                      }
                                    } catch (e) {
                                      debugPrint('Failed to save like interaction: $e');
                                    }
                                    
                                    // Check for mutual match
                                    final updatedTarget = mockData.profiles.firstWhere((p) => p.id == profile.id);
                                    final updatedMe = mockData.currentUser!;
                                    if (updatedTarget.favoriteProfileIds.contains(updatedMe.id) && 
                                        updatedMe.favoriteProfileIds.contains(updatedTarget.id)) {
                                      InterstitialAdManager().showAdIfAvailable(
                                        onComplete: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MatchAgreementPage(
                                                currentUser: updatedMe,
                                                targetProfile: updatedTarget,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: 4),

                              // View full details button (view gate)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _tryOpenFullDetails(
                                          mockData, profile),
                                  icon: Icon(
                                    isExpanded
                                        ? Icons.visibility_off
                                        : (alreadyViewed
                                            ? Icons.visibility
                                            : Icons.lock_open),
                                    size: 16,
                                  ),
                                  label: Text(
                                    isExpanded
                                        ? _kHideDetails
                                        : _kViewFull,
                                    style: const TextStyle(
                                        fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: alreadyViewed
                                        ? Colors.green.shade700
                                        : const Color(0xFF5C3E00),
                                    side: BorderSide(
                                      color: alreadyViewed
                                          ? Colors.green.shade700
                                          : const Color(0xFF5C3E00),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Chat button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (me.isPremium) {
                                      widget.onNavigateToChat();
                                    } else {
                                      _showUpgradeSheet();
                                    }
                                  },
                                  icon: const Icon(Icons.chat,
                                      size: 16),
                                  label: Text(_kConnect,
                                      style: const TextStyle(
                                          fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF000080),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
