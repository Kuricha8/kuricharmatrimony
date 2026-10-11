import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../registration/public_hub_cashfree_paywall_sheet.dart';
import '../family_tree/family_tree_navigation_helper.dart';
import '../moiety_checker/checker_screen.dart';
import '../../core/widgets/guest_profile_card.dart';
import '../../core/widgets/notification_bell_icon.dart';
import '../settings/guest_settings_screen.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/services/personalized_feed_service.dart';
import '../../core/widgets/sponsored_banner_card.dart';
import '../clan_feed/widgets/tharavadu_story_tray.dart';

class PublicHubScreen extends StatefulWidget {
  const PublicHubScreen({super.key});

  @override
  State<PublicHubScreen> createState() => _PublicHubScreenState();
}

class _PublicHubScreenState extends State<PublicHubScreen> {
  int _currentIndex = 0;
  final List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastFirestoreDoc;
  int _supabaseOffset = 0;
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchProfilesPage(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      if (!_isLoadingMore && _hasMore) {
        _fetchProfilesPage(refresh: false);
      }
    }
  }

  Future<void> _openSettings(BuildContext context) async {
    final isLockEnabled = await BiometricAuthService.instance.isAppLockEnabled();
    if (isLockEnabled) {
      final authenticated = await BiometricAuthService.instance.authenticate(
        localizedReason: 'തുടരാൻ ഫോൺ ലോക്ക് അല്ലെങ്കിൽ വിരലടയാളം ഉപയോഗിക്കുക',
      );
      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ആധികാരികത ഉറപ്പാക്കൽ പരാജയപ്പെട്ടു (Authentication failed).'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const GuestSettingsScreen(),
        ),
      );
    }
  }

  bool _isApprovedProfile(Map<String, dynamic> p) {
    final String role = (p['role'] ?? '').toString().toLowerCase();
    if (role == 'admin' || role == 'super_admin' || p['is_admin'] == true) {
      return false;
    }
    final bool isApproved = p['is_approved'] == true ||
        p['is_approved']?.toString().toLowerCase() == 'true' ||
        p['isApproved'] == true ||
        p['isApproved']?.toString().toLowerCase() == 'true' ||
        (p['registration_status'] ?? '').toString().toLowerCase() == 'approved' ||
        (p['registration_status'] ?? '').toString().toLowerCase() == 'active' ||
        (p['registration_status'] ?? '').toString().toLowerCase() == 'live' ||
        (p['account_status'] ?? '').toString().toLowerCase() == 'approved' ||
        (p['account_status'] ?? '').toString().toLowerCase() == 'active' ||
        (p['account_status'] ?? '').toString().toLowerCase() == 'live' ||
        (p['verification_status'] ?? '').toString().toLowerCase() == 'approved' ||
        (p['verification_status'] ?? '').toString().toLowerCase() == 'verified' ||
        (p['approval_status'] ?? '').toString().toLowerCase() == 'approved' ||
        (p['approval_status'] ?? '').toString().toLowerCase() == 'verified' ||
        (p['status'] ?? '').toString().toLowerCase() == 'approved' ||
        (p['status'] ?? '').toString().toLowerCase() == 'active' ||
        (p['status'] ?? '').toString().toLowerCase() == 'live';
    final bool isDeleted =
        p['is_deleted'] == true || p['is_deleted']?.toString().toLowerCase() == 'true';
    final bool isBlocked =
        p['is_blocked'] == true || p['is_blocked']?.toString().toLowerCase() == 'true';
    final bool isBanned =
        p['is_banned'] == true || p['is_banned']?.toString().toLowerCase() == 'true';
    final bool isHidden = p['is_profile_hidden'] == true || p['is_hidden'] == true;
    return isApproved && !isDeleted && !isBlocked && !isBanned && !isHidden;
  }

  Future<void> _fetchProfilesPage({bool refresh = false}) async {
    if (_isLoadingMore) return;
    if (!refresh && !_hasMore) return;

    if (refresh) {
      setState(() {
        _isLoading = true;
        _hasMore = true;
        _supabaseOffset = 0;
        _lastFirestoreDoc = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      List<Map<String, dynamic>> newItems = [];

      // 1. First attempt paginated query from Firestore profiles collection
      try {
        Query firestoreQuery = FirebaseFirestore.instance
            .collection('profiles')
            .where('is_approved', isEqualTo: true)
            .limit(_pageSize);

        if (_lastFirestoreDoc != null) {
          firestoreQuery = firestoreQuery.startAfterDocument(_lastFirestoreDoc!);
        }

        final snap = await firestoreQuery.get(
          const GetOptions(source: Source.serverAndCache),
        );

        if (snap.docs.isNotEmpty) {
          _lastFirestoreDoc = snap.docs.last;
          for (final doc in snap.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data() as Map);
              data['id'] = data['id'] ?? doc.id;
              if (_isApprovedProfile(data)) {
                newItems.add(data);
              }
            } catch (_) {}
          }
        }
      } catch (fe) {
        debugPrint('Firestore profiles page notice: $fe');
      }

      // 2. Fallback to Supabase paginated range if Firestore returned empty
      if (newItems.isEmpty) {
        try {
          final data = await Supabase.instance.client
              .from('kurichiyar_profiles')
              .select()
              .neq('role', 'admin')
              .neq('is_admin', true)
              .order('created_at', ascending: false)
              .range(_supabaseOffset, _supabaseOffset + _pageSize - 1);

          final List<Map<String, dynamic>> approvedProfiles =
              List<Map<String, dynamic>>.from(data).where(_isApprovedProfile).toList();

          newItems = approvedProfiles;
          _supabaseOffset += _pageSize;
          _hasMore = data.length >= _pageSize;
        } catch (se) {
          debugPrint('Supabase profiles page notice: $se');
        }
      } else {
        _hasMore = newItems.length >= _pageSize;
      }

      final personalizedList =
          PersonalizedFeedService.instance.sortFeed(newItems);

      if (mounted) {
        setState(() {
          if (refresh) {
            _profiles.clear();
            _profiles.addAll(personalizedList);
          } else {
            final existingIds = _profiles.map((p) => p['id']?.toString()).toSet();
            _profiles.addAll(
              personalizedList.where((p) => !existingIds.contains(p['id']?.toString())),
            );
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profiles page: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Navy Blue Header
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.white),
        title: const Text(
          "Kurichiyar Matrimony",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
            ),
          ),
          const SizedBox(width: 4),
          const NotificationBellIcon(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'ക്രമീകരണങ്ങൾ (Settings)',
            onPressed: () => _openSettings(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "പേരോ തറവാടോ തിരയുക...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Dynamic WhatsApp / Instagram-style Tharavadu Stories Tray ──
            const TharavaduStoryTray(isGuest: true),
            const SizedBox(height: 14),

            // Top Feature Cards (Green Family Tree & Register)
            Row(
              children: [
                // 1. കുടുംബ വൃക്ഷം & വംശാവലി (Green Card)
                Expanded(
                  child: InkWell(
                    onTap: () => handleFamilyTreeNavigation(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 105,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E), // Vibrant Green
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.park, color: Colors.white, size: 30),
                          SizedBox(height: 8),
                          Text(
                            "കുടുംബ വൃക്ഷം &\nവംശാവലി",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. രജിസ്റ്റർ ചെയ്യുക Card
                Expanded(
                  child: InkWell(
                    onTap: () {
                      PublicHubCashfreePaywallSheet.show(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 105,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "രജിസ്റ്റർ ചെയ്യുക",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3 Small Desks (Moiety, Matches, Events)
            Row(
              children: [
                _buildSmallDesk(
                  title: "Moiety\nChecker",
                  color: const Color(0xFFFFE4E6),
                  icon: Icons.favorite,
                  iconColor: Colors.pink,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MoietyCheckerScreen(isGuest: true),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _buildSmallDesk(
                  title: "Matches\nDesk",
                  color: const Color(0xFFE0F2FE),
                  icon: Icons.groups,
                  iconColor: Colors.blue,
                  onTap: () => PublicHubCashfreePaywallSheet.show(context),
                ),
                const SizedBox(width: 10),
                _buildSmallDesk(
                  title: "Events\nGuide",
                  color: const Color(0xFFFEF3C7),
                  icon: Icons.calendar_month,
                  iconColor: Colors.amber.shade800,
                  onTap: () => PublicHubCashfreePaywallSheet.show(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Register / Login Bar
            InkWell(
              onTap: () {
                PublicHubCashfreePaywallSheet.show(context);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "രജിസ്റ്റർ ചെയ്യുക / Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "സ്ഥിരീകരിച്ച പൊരുത്തങ്ങൾ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),

            // Matrimony Match Card with Green Border
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF22C55E),
                  width: 2.2,
                ), // Green Border
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "സുരേഷ് പി.",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Age: 30 | Location: Padinjarathara",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          "Clan: പന്തി ശാഖ തറവാട് (Cross-Cousin Match)",
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kinship Relationship Title
            const Text(
              "Kinship Relationship",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // ₹29 Lifetime Unlock Golden/Amber Paywall Card
            InkWell(
              onTap: () {
                // Trigger Cashfree ₹29 Payment SDK
                PublicHubCashfreePaywallSheet.show(context);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFD97706,
                  ).withValues(alpha: 0.2), // Amber/Brown shade
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFD97706),
                    width: 1.2,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, color: Color(0xFFB45309), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "₹29 അടച്ച് അൺലോക്ക് ചെയ്യാം",
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Section Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "പൊതു പ്രൊഫൈലുകൾ (Public Profiles)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoading && _profiles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (!_isLoading && _profiles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    "അപ്രൂവ് ചെയ്ത പ്രൊഫൈലുകൾ ലഭ്യമല്ല",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              Builder(
                builder: (context) {
                  final list = _profiles;
                  final bannerCount = list.length ~/ 4;
                  final totalCount = list.length + bannerCount + (_isLoadingMore ? 1 : 0);

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      // Bottom infinite scroll loading indicator
                      if (_isLoadingMore && index == totalCount - 1) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      // In-feed sponsored banner card every 4 or 5 profiles
                      if ((index + 1) % 5 == 0) {
                        return SponsoredBannerCard(
                          itemIndex: index,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        );
                      }

                      final profileIndex = index - ((index + 1) ~/ 5);
                      if (profileIndex >= list.length) {
                        return const SizedBox.shrink();
                      }
                      return PublicProfileCard(profile: list[profileIndex]);
                    },
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        onTap: (idx) {
          setState(() => _currentIndex = idx);
          if (idx == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MoietyCheckerScreen(isGuest: true),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: "Public Hub",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Checker"),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            label: "Direct Ads",
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDesk({
    required String title,
    required Color color,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 75,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.black87,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PublicProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const PublicProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final bool isApproved =
        profile['is_approved'] == true ||
        profile['is_approved']?.toString().toLowerCase() == 'true' ||
        (profile['registration_status'] ?? '').toString().toLowerCase() ==
            'approved' ||
        (profile['account_status'] ?? '').toString().toLowerCase() ==
            'approved' ||
        (profile['verification_status'] ?? '').toString().toLowerCase() ==
            'approved' ||
        (profile['approval_status'] ?? '').toString().toLowerCase() ==
            'approved';

    // 🔴 Hide completely if not approved
    if (!isApproved) {
      return const SizedBox.shrink();
    }

    return UniversalProfileCard(
      rawProfileData: profile,
      isGuest: true,
      onRegisterLogin: () {
        handleFamilyTreeNavigation(context);
      },
    );
  }
}
