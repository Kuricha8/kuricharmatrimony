import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/mock_data.dart';
import '../../../core/widgets/watermarked_image.dart';
import '../../../core/widgets/app_footer.dart';
import '../../clan_feed/admin_custom_ad_widget.dart';
import '../../clan_feed/audio_player_widget.dart';
import '../../../core/widgets/native_ad_card.dart';
import '../../../core/widgets/logo_widget.dart';
import '../../clan_feed/tharavadu_list.dart';
import '../../family_tree/family_tree_navigation_helper.dart';
import 'guest_auth_bottom_sheet.dart';
import '../../../core/services/registration_route_helper.dart';
import '../../../core/widgets/universal_profile_card.dart';
import '../../../core/services/personalized_feed_service.dart';
import '../../../core/widgets/sponsored_banner_card.dart';
import '../../clan_feed/widgets/tharavadu_story_tray.dart';

class GuestPublicHubFeedTab extends StatefulWidget {
  final VoidCallback? onNavigateToChecker;
  final bool isPendingApproval;
  const GuestPublicHubFeedTab({
    super.key,
    this.onNavigateToChecker,
    this.isPendingApproval = false,
  });

  @override
  State<GuestPublicHubFeedTab> createState() => _GuestPublicHubFeedTabState();
}

class _GuestPublicHubFeedTabState extends State<GuestPublicHubFeedTab> {
  List<UserProfile> _previewProfiles = [];
  bool _isLoadingProfiles = true;
  int? _selectedFilterClanId;
  String _selectedContentType = 'ALL';
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Clan> _clans = [];
  List<StatusPost> _dbPublicPosts = [];

  // Pagination states
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _pageSize = 15;
  bool _hasMoreProfiles = true;
  bool _isFetchingMore = false;
  DocumentSnapshot? _lastFirestoreDoc;
  RealtimeChannel? _profileRealtimeChannel;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCachedProfiles();
    _fetchProfilesPage(refresh: true);
    _setupRealtimeProfileListener();
    _fetchClans();
    _fetchPublicTharavaduPosts();
  }

  Future<void> _fetchPublicTharavaduPosts() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final res = await Supabase.instance.client
          .from('tharavadu_posts')
          .select()
          .gte('created_at', cutoff.toUtc().toIso8601String())
          .or('visibility.eq.PUBLIC,visibility.is.null')
          .order('created_at', ascending: false)
          .limit(15);

      final List<StatusPost> parsed = [];
      for (var row in res) {
        final text = (row['text'] ?? row['content'] ?? '').toString();
        final mediaUrl = row['media_url'] as String?;
        final isVideo = row['is_video'] == true;
        final clanId = (row['clan_id'] as int?) ?? 1;
        final createdAt =
            DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now();

        parsed.add(
          StatusPost(
            id: row['id'].toString(),
            creatorId: (row['user_id'] ?? 'user').toString(),
            clanId: clanId,
            content: text,
            feedPhotoUrl: isVideo ? null : mediaUrl,
            videoUrl: isVideo ? mediaUrl : null,
            postType: mediaUrl != null && mediaUrl.isNotEmpty
                ? (isVideo ? PostType.video : PostType.photo)
                : PostType.text,
            createdAt: createdAt,
            creatorName: row['sender_name'] ?? 'അംഗം',
            creatorPhotoUrl: row['sender_photo'] ?? '',
            reactions: const {},
          ),
        );
      }

      if (mounted) {
        setState(() {
          _dbPublicPosts = parsed;
        });
      }
    } catch (e) {
      debugPrint('Error fetching public tharavadu posts for public hub: $e');
    }
  }

  @override
  void dispose() {
    _profileRealtimeChannel?.unsubscribe();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupRealtimeProfileListener() {
    try {
      _profileRealtimeChannel?.unsubscribe();
      _profileRealtimeChannel = Supabase.instance.client
          .channel('public:kurichiyar_profiles:guest_hub')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'kurichiyar_profiles',
            callback: (payload) {
              debugPrint(
                'Guest Public Hub: Realtime profile update (${payload.eventType}). Refreshing feed...',
              );
              _fetchProfilesPage(refresh: true);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Guest Public Hub: Realtime listener setup error: $e');
    }
  }

  bool _isApprovedRawMap(Map<String, dynamic> row) {
    final role = (row['role'] ?? '').toString().toLowerCase();
    if (role == 'admin' || role == 'super_admin' || row['is_admin'] == true) {
      return false;
    }
    final isBlocked = row['is_blocked'] == true || row['isBlocked'] == true;
    final isBanned = row['is_banned'] == true || row['isBanned'] == true;
    final isDeleted = row['is_deleted'] == true || row['isDeleted'] == true;
    if (isBlocked || isBanned || isDeleted) return false;

    final isApprovedBool = row['is_approved'] == true ||
        row['is_approved']?.toString().toLowerCase() == 'true' ||
        row['isApproved'] == true ||
        row['isApproved']?.toString().toLowerCase() == 'true';
    if (isApprovedBool) return true;

    final status = (row['status'] ?? '').toString().toLowerCase();
    final approvalStatus =
        (row['approval_status'] ?? row['approvalStatus'] ?? '').toString().toLowerCase();
    final accountStatus =
        (row['account_status'] ?? row['accountStatus'] ?? '').toString().toLowerCase();
    final verificationStatus =
        (row['verification_status'] ?? row['verificationStatus'] ?? '')
            .toString()
            .toLowerCase();
    final registrationStatus =
        (row['registration_status'] ?? row['registrationStatus'] ?? '')
            .toString()
            .toLowerCase();

    const approvedKeywords = {'approved', 'active', 'live', 'verified'};

    return approvedKeywords.contains(status) ||
        approvedKeywords.contains(approvalStatus) ||
        approvedKeywords.contains(accountStatus) ||
        approvedKeywords.contains(verificationStatus) ||
        approvedKeywords.contains(registrationStatus);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchProfilesPage(refresh: false);
    }
  }

  Future<void> _loadCachedProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_guest_profiles');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final List decoded = jsonDecode(cachedStr);
        final List<UserProfile> cached = decoded
            .map((m) => UserProfile.fromMap(m))
            .where((p) => p.isApproved || p.isCompleteAndDiscoverable)
            .toList();
        if (cached.isNotEmpty && mounted) {
          setState(() {
            _previewProfiles = cached;
            _isLoadingProfiles = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading cached guest profiles: $e');
    }
  }

  Future<void> _fetchProfilesPage({bool refresh = false}) async {
    if (_isFetchingMore) return;
    if (!refresh && !_hasMoreProfiles) return;

    if (refresh) {
      setState(() {
        _currentPage = 0;
        _lastFirestoreDoc = null;
        _hasMoreProfiles = true;
        _isLoadingProfiles = _previewProfiles.isEmpty;
      });
    } else {
      setState(() {
        _isFetchingMore = true;
      });
    }

    try {
      final start = _currentPage * _pageSize;
      final end = start + _pageSize - 1;

      List<UserProfile> fetched = [];
      int rawFetchedCount = 0;

      try {
        final res = await Supabase.instance.client
            .from('kurichiyar_profiles')
            .select()
            .neq('role', 'admin')
            .order('created_at', ascending: false)
            .range(start, end);

        rawFetchedCount = res.length;
        for (final m in res) {
          try {
            final mapData = Map<String, dynamic>.from(m as Map);
            if (_isApprovedRawMap(mapData)) {
              fetched.add(UserProfile.fromMap(mapData));
            }
          } catch (_) {}
        }
      } catch (se) {
        debugPrint('Error fetching guest profiles from Supabase: $se');
      }

      // 1. Fallback to Firestore users collection with startAfterDocument pagination
      if (fetched.isEmpty) {
        try {
          Query firestoreQuery = FirebaseFirestore.instance
              .collection('users')
              .limit(_pageSize);

          if (_lastFirestoreDoc != null) {
            firestoreQuery =
                firestoreQuery.startAfterDocument(_lastFirestoreDoc!);
          }

          final firestoreSnap = await firestoreQuery.get(
            const GetOptions(source: Source.serverAndCache),
          );

          if (firestoreSnap.docs.isNotEmpty) {
            _lastFirestoreDoc = firestoreSnap.docs.last;
            rawFetchedCount = firestoreSnap.docs.length;
            for (final doc in firestoreSnap.docs) {
              try {
                final data = Map<String, dynamic>.from(doc.data() as Map);
                data['id'] = data['id'] ?? doc.id;
                if (_isApprovedRawMap(data)) {
                  fetched.add(UserProfile.fromMap(data));
                }
              } catch (_) {}
            }
          }
        } catch (fe) {
          debugPrint('Firestore fallback error in guest hub: $fe');
        }
      }

      // 2. Fallback to MockData if still empty on first page
      if (fetched.isEmpty && _currentPage == 0 && MockData().profiles.isNotEmpty) {
        fetched = MockData().profiles
            .where((p) => (p.isApproved || p.isCompleteAndDiscoverable) && p.role != 'admin')
            .toList();
      }

      if (mounted) {
        setState(() {
          if (refresh) {
            _previewProfiles = fetched;
          } else {
            final existingIds = _previewProfiles.map((p) => p.id).toSet();
            _previewProfiles.addAll(
              fetched.where((p) => !existingIds.contains(p.id)),
            );
          }
          _isLoadingProfiles = false;
          _isFetchingMore = false;
          _hasMoreProfiles = rawFetchedCount >= _pageSize;
          if (_hasMoreProfiles) {
            _currentPage++;
          }
        });

        // Disk caching: store the first batch in SharedPreferences
        if (refresh || _currentPage == 1) {
          final prefs = await SharedPreferences.getInstance();
          final listToCache = _previewProfiles
              .take(30)
              .map((p) => p.toMap())
              .toList();
          await prefs.setString(
            'cached_guest_profiles',
            jsonEncode(listToCache),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching guest profiles: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfiles = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  Future<void> _fetchClans() async {
    if (allClans.isEmpty) {
      await TharavaduService.instance.syncClans();
    }
    if (mounted) {
      setState(() {
        _clans = allClans;
      });
    }
  }

  Clan? _getClanObj(int clanId) {
    try {
      return _clans.firstWhere((c) => c.id == clanId);
    } catch (_) {
      return null;
    }
  }

  void _showRegistrationBottomSheet(BuildContext context) async {
    final isRegistered = await RegistrationRouteHelper.isUserRegisteredOrPending();
    if (!context.mounted) return;

    if (isRegistered) {
      Navigator.pushNamed(context, '/verification_pending');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const GuestAuthBottomSheet(
          isSignUpMode: true,
          isMalayalam: true,
        );
      },
    );
  }

  Widget _getClanAvatar(Clan? clan) {
    if (clan == null) return const CircleAvatar(child: Icon(Icons.person));
    final isPandi = clan.type == 'PANDI';
    final color = isPandi ? Colors.teal : Colors.indigo;
    final iconData = isPandi
        ? Icons.shield_outlined
        : Icons.diversity_3_outlined;
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(iconData, color: color),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    UserProfile profile, {
    bool isGrid = false,
  }) {
    // 🔴 Hide completely if not approved / not discoverable
    if (!profile.isApproved && !profile.isCompleteAndDiscoverable) {
      return const SizedBox.shrink();
    }

    return UniversalProfileCard(
      profile: profile,
      isGuest: true,
      isGrid: isGrid,
      onRegisterLogin: () => _showRegistrationBottomSheet(context),
    );
  }

  Widget _buildPostContent(BuildContext context, StatusPost post) {
    final String raw = post.content.trim();

    if (raw.startsWith('{') && raw.endsWith('}')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final Map<String, dynamic>? audioOverlay =
              decoded['audio_overlay'] is Map<String, dynamic>
              ? decoded['audio_overlay'] as Map<String, dynamic>
              : (decoded['audio'] is Map<String, dynamic>
                    ? decoded['audio'] as Map<String, dynamic>
                    : null);

          final String? audioUrl =
              audioOverlay?['url']?.toString() ??
              audioOverlay?['audio_url']?.toString() ??
              decoded['audio_url']?.toString() ??
              post.feedAudioUrl;

          final String caption =
              decoded['caption']?.toString() ??
              decoded['text']?.toString() ??
              decoded['content']?.toString() ??
              '';

          final String title =
              audioOverlay?['title']?.toString() ??
              decoded['title']?.toString() ??
              'Kurichiyar Audio Story';

          final String artist =
              audioOverlay?['artist']?.toString() ??
              decoded['artist']?.toString() ??
              'Kurichiyar Music';

          List<Color> bgGradientColors = [
            const Color(0xFF1E3C72),
            const Color(0xFF2A5298),
          ];
          final rawGrad =
              audioOverlay?['bg_gradient'] ?? decoded['bg_gradient'];
          if (rawGrad is List && rawGrad.isNotEmpty) {
            try {
              final parsedColors = rawGrad.map((c) {
                final hex = c.toString().replaceAll('#', '');
                return Color(int.parse('FF$hex', radix: 16));
              }).toList();
              if (parsedColors.length >= 2) {
                bgGradientColors = parsedColors;
              }
            } catch (_) {}
          }

          if (audioUrl != null && audioUrl.isNotEmpty) {
            return Container(
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bgGradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        radius: 18,
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              artist,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AudioPlayerWidget(
                    audioUrl: audioUrl,
                    accentColor: Colors.amber,
                  ),
                  if (caption.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          if (caption.isNotEmpty) {
            return Text(
              caption,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.3,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error parsing status post JSON in Public Hub: $e');
      }
    }

    return Text(
      raw,
      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3),
    );
  }

  Widget _buildStatusPostCard(BuildContext context, StatusPost post) {
    final clan = _getClanObj(post.clanId);
    final hoursRemaining = post.timeRemaining.inHours;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showRegistrationBottomSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getClanAvatar(clan),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'തറവാട് അപ്‌ഡേറ്റ് - ${clan?.name ?? "തറവാട്"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF000080),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'അവസാനിക്കാൻ: $hoursRemaining മണിക്കൂർ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.style, size: 12, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildPostContent(context, post),
              if (post.postType == PostType.photo &&
                  post.feedPhotoUrl != null &&
                  post.feedPhotoUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: WatermarkedImage(
                    imageUrl: post.feedPhotoUrl!,
                    height: 180,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _showRegistrationBottomSheet(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite_border,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.reactions.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showCommentsSheetForPost(context, post),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 17,
                                color: Color(0xFF000080),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Comment',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF000080),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: TextButton.icon(
                      onPressed: () => _showRegistrationBottomSheet(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        Icons.lock_outline,
                        size: 13,
                        color: Color(0xFF000080),
                      ),
                      label: const Text(
                        'പൂർണ്ണ വിവരങ്ങൾക്ക് പ്രവേശിക്കുക',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF000080),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommentsSheetForPost(BuildContext context, StatusPost post) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Comments (അഭിപ്രായങ്ങൾ)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF000080),
                ),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mark_chat_read_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ആദ്യ കമന്റ് രേഖപ്പെടുത്തൂ!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  controller: commentController,
                  readOnly: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRegistrationBottomSheet(context);
                  },
                  decoration: InputDecoration(
                    hintText: 'കമന്റ് എഴുതാൻ രജിസ്റ്റർ/ലോഗിൻ ചെയ്യുക...',
                    hintStyle: const TextStyle(fontSize: 13),
                    suffixIcon: const Icon(
                      Icons.send,
                      color: Color(0xFF000080),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, child) {
        final mockData = MockData();

        var statusPosts = [
          ..._dbPublicPosts,
          ...mockData.statusPosts.where((p) => !p.isExpired),
        ];
        if (_selectedFilterClanId != null) {
          statusPosts = statusPosts
              .where((p) => p.clanId == _selectedFilterClanId)
              .toList();
        }
        if (_searchQuery.isNotEmpty) {
          statusPosts = statusPosts
              .where(
                (p) => p.content.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
        }

        // Guest Feed Scope (No Filters / No Matching Logic):
        // 1. Unified feed of ALL active approved profiles
        // 2. No gender-based segregation (do not split into bride/groom)
        // 3. No clan kinship matching logic (hide all "Yes Match / No Match / Bandhu / Panthi" indicators)
        var profiles = _previewProfiles.isNotEmpty
            ? _previewProfiles
            : mockData.profiles
                .where((p) => p.isApproved || p.isCompleteAndDiscoverable)
                .toList();

        // Personalized recommendation scoring: sort by relevance score descending, then createdAt
        profiles = PersonalizedFeedService.instance.sortFeed(profiles);

        // Search in guest mode: strictly matches name ONLY (occupation and region hidden)
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          profiles = profiles
              .where((p) => p.name.toLowerCase().contains(q))
              .toList();
        }

        List<Widget> feedWidgets = [];

        // Header Banner CTA
        feedWidgets.add(
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF000080), Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    LogoWidget(width: 44, height: 44),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'കുറിച്ച്യർ മാട്രിമോണി പൊതു ഹബ്ബ്',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ബന്ധങ്ങൾ കണ്ടെത്താനും തറവാട് സ്റ്റാറ്റസുകൾ കാണാനും രജിസ്റ്റർ ചെയ്യൂ!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRegistrationBottomSheet(context),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text(
                          'Register',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        icon: const Icon(Icons.login, size: 16),
                        label: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        // ── Dynamic WhatsApp / Instagram-style Tharavadu Stories Tray ──
        feedWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
            child: TharavaduStoryTray(
              isGuest: true,
              onAddStatus: () => _showRegistrationBottomSheet(context),
            ),
          ),
        );

        // Search Bar & Content Filter Chips
        feedWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search profiles...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF000080),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text(
                                'All Content (സമ്പൂർണ്ണം)',
                                style: TextStyle(fontSize: 12),
                              ),
                              selected: _selectedContentType == 'ALL',
                              onSelected: (_) =>
                                  setState(() => _selectedContentType = 'ALL'),
                              selectedColor: const Color(0xFF000080),
                              labelStyle: TextStyle(
                                color: _selectedContentType == 'ALL'
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text(
                                'Profiles (പ്രൊഫൈലുകൾ)',
                                style: TextStyle(fontSize: 12),
                              ),
                              selected: _selectedContentType == 'PROFILES',
                              onSelected: (_) =>
                                  setState(() => _selectedContentType = 'PROFILES'),
                              selectedColor: const Color(0xFF000080),
                              labelStyle: TextStyle(
                                color: _selectedContentType == 'PROFILES'
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text(
                                'Status Updates (സ്റ്റാറ്റസുകൾ)',
                                style: TextStyle(fontSize: 12),
                              ),
                              selected: _selectedContentType == 'UPDATES',
                              onSelected: (_) =>
                                  setState(() => _selectedContentType = 'UPDATES'),
                              selectedColor: const Color(0xFF000080),
                              labelStyle: TextStyle(
                                color: _selectedContentType == 'UPDATES'
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text(
                                'Direct Ads (പരസ്യങ്ങൾ)',
                                style: TextStyle(fontSize: 12),
                              ),
                              selected: _selectedContentType == 'ADS',
                              onSelected: (_) =>
                                  setState(() => _selectedContentType = 'ADS'),
                              selectedColor: Colors.amber.shade800,
                              labelStyle: TextStyle(
                                color: _selectedContentType == 'ADS'
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedContentType == 'PROFILES' || _selectedContentType == 'ALL') ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          color: const Color(0xFF000080),
                          size: 22,
                        ),
                        tooltip: _isGridView ? 'List View' : 'Grid View',
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );

        feedWidgets.add(const SizedBox(height: 8));
        feedWidgets.add(const Divider(height: 16));
        if (!widget.isPendingApproval) {
          // Moiety Compatibility Shortcut Card
          feedWidgets.add(
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: const Color(0xFFFFF8E1),
              child: InkWell(
                onTap: widget.onNavigateToChecker,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF000080),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Moiety Compatibility Checker',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF000080),
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'നിങ്ങളുടെ തറവാടുകൾ തമ്മിൽ വിവാഹബന്ധം സാധ്യമാണോ എന്ന് പരിശോധിക്കുക',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade800,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF000080),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          // Family Tree / Lineage Shortcut Card
          feedWidgets.add(
            const FamilyTreeGuideCardWidget(),
          );
        }

        int profileIdx = 0;
        int statusIdx = 0;
        int cardCounter = 0;

        List<Widget> streamCards = [];

        if (_selectedContentType == 'PROFILES' && profiles.isEmpty) {
          streamCards.add(
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'അംഗീകൃത പ്രൊഫൈലുകൾ ഒന്നും കണ്ടെത്തിയില്ല',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No approved profiles found.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (_selectedContentType == 'PROFILES') {
          for (final profile in profiles) {
            streamCards.add(_buildProfileCard(context, profile));
            cardCounter++;
            if (cardCounter % 5 == 0) {
              streamCards.add(
                SponsoredBannerCard(
                  itemIndex: cardCounter,
                  margin: const EdgeInsets.only(bottom: 16.0),
                ),
              );
            } else if (cardCounter % 3 == 0) {
              streamCards.add(
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: AdminCustomAdWidget(),
                ),
              );
            }
          }
        } else if (_selectedContentType == 'UPDATES') {
          for (final post in statusPosts) {
            streamCards.add(_buildStatusPostCard(context, post));
            cardCounter++;
            if (cardCounter % 3 == 0) {
              streamCards.add(
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: NativeAdCard(isStatusLayout: true),
                ),
              );
            }
          }
        } else if (_selectedContentType == 'ADS') {
          streamCards.add(
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: AdminCustomAdWidget(),
            ),
          );
          streamCards.add(
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: NativeAdCard(),
            ),
          );
        } else {
          while (profileIdx < profiles.length ||
              statusIdx < statusPosts.length) {
            for (int i = 0; i < 2 && profileIdx < profiles.length; i++) {
              final profile = profiles[profileIdx++];
              streamCards.add(_buildProfileCard(context, profile));
              cardCounter++;

              if (cardCounter > 0 && cardCounter % 5 == 0) {
                streamCards.add(
                  SponsoredBannerCard(
                    itemIndex: cardCounter,
                    margin: const EdgeInsets.only(bottom: 16.0),
                  ),
                );
              } else if (cardCounter > 0 && cardCounter % 3 == 0) {
                final bool isGoogleAd = ((cardCounter ~/ 3) % 2 != 0);
                streamCards.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: isGoogleAd
                        ? const NativeAdCard()
                        : const AdminCustomAdWidget(),
                  ),
                );
              }
            }

            if (statusIdx < statusPosts.length) {
              final post = statusPosts[statusIdx++];
              streamCards.add(_buildStatusPostCard(context, post));
              cardCounter++;

              if (cardCounter > 0 && cardCounter % 3 == 0) {
                final bool isGoogleAd = ((cardCounter ~/ 3) % 2 != 0);
                streamCards.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: isGoogleAd
                        ? const NativeAdCard(isStatusLayout: true)
                        : const AdminCustomAdWidget(),
                  ),
                );
              }
            }
          }
        }

        feedWidgets.addAll(streamCards);
        feedWidgets.add(const AppFooter());

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: _isLoadingProfiles
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF000080)),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchProfilesPage(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: feedWidgets.length + (_isFetchingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == feedWidgets.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF000080),
                            ),
                          ),
                        );
                      }
                      return feedWidgets[index];
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF000080),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            onPressed: () => _showRegistrationBottomSheet(context),
            icon: const Icon(Icons.person_add),
            label: const Text(
              'രജിസ്റ്റർ ചെയ്യുക / Login',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget buildStatusList(List<dynamic> statusList) {
    if (statusList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'സ്റ്റാറ്റസുകൾ ലഭ്യമല്ല',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statusList.length,
      itemBuilder: (context, index) {
        final item = statusList[index];

        // ക്രാഷ് ആവാതിരിക്കാൻ കാർഡിനെ സുരക്ഷിതമാക്കുന്നു
        try {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.amber.shade100,
                child: const Icon(Icons.person, color: Colors.amber),
              ),
              title: Text(
                item['title'] ??
                    item['name'] ??
                    item['sender_name'] ??
                    'Status',
              ),
              subtitle: Text(item['created_at']?.toString() ?? ''),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink(); // ഏതെങ്കിലും കാർഡിൽ തെറ്റുണ്ടെങ്കിൽ ആപ്പ് വൈറ്റ് ആവാതെ ഒഴിവാക്കും
        }
      },
    );
  }
}
