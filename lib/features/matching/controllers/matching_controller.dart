import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/mock_data.dart';
import '../../../core/services/matching_service.dart';
import '../../subscriptions/subscription_service.dart';
import '../../clan_feed/tharavadu_list.dart';

class MatchingController extends ChangeNotifier {
  final Set<String> _shortlistedIds = {};
  final Set<String> _incomingInterestUserIds = {};
  final List<UserProfile> _skippedProfilesStack = [];
  final Map<String, DateTime> _skippedTimestamps = {};

  List<UserProfile> _allMatches = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _goldTrustOnly = false;
  String _searchQuery = '';
  String? _selectedClanFilter;
  DocumentSnapshot? _lastFirestoreDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  RealtimeChannel? _matchesStatusChannel;
  RealtimeChannel? _matchesFeedChannel;
  MatchingPoolCategory _poolCategory = MatchingPoolCategory.primaryStandard;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreMatchesSub;

  Set<String> get shortlistedIds => _shortlistedIds;
  Set<String> get incomingInterestUserIds => _incomingInterestUserIds;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get goldTrustOnly => _goldTrustOnly;
  String get searchQuery => _searchQuery;
  String? get selectedClanFilter => _selectedClanFilter;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  MatchingPoolCategory get poolCategory => _poolCategory;

  void setPoolCategory(MatchingPoolCategory category) {
    if (_poolCategory != category) {
      _poolCategory = category;
      _allMatches.clear();
      _lastFirestoreDoc = null;
      _hasMore = true;
      notifyListeners();
      refreshMatches();
    }
  }

  List<UserProfile> get matches {
    final me = MockData().currentUser;
    var filtered = _allMatches
        .where((p) => !MockData().interactedProfileIds.contains(p.id))
        .toList();

    if (_goldTrustOnly) {
      filtered = filtered.where((p) => p.isGoldTrust).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.job.toLowerCase().contains(q) ||
            p.region.toLowerCase().contains(q) ||
            (p.motherTharavadu?.toLowerCase().contains(q) ?? false) ||
            (p.fatherTharavadu?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (_selectedClanFilter != null && _selectedClanFilter!.isNotEmpty) {
      filtered = filtered.where((p) {
        final fClan = getClanById(p.fatherClanId)?.name ?? p.fatherTharavadu ?? '';
        final mClan = getClanById(p.motherClanId)?.name ?? p.motherTharavadu ?? '';
        return fClan.contains(_selectedClanFilter!) || mClan.contains(_selectedClanFilter!);
      }).toList();
    }

    if (me != null) {
      final candidatesMaps = filtered.map((e) => e.toMap()).toList();
      final filteredMaps = _filterStrictMatches(
        currentUser: me.toMap(),
        candidates: candidatesMaps,
        category: _poolCategory,
      );
      final filteredIds = filteredMaps.map((e) => e['id']?.toString()).toSet();
      filtered = filtered.where((e) => filteredIds.contains(e.id)).toList();
    }

    return filtered;
  }

  void initialize() {
    TharavaduService.instance.fetchDisplayLabels();
    final me = MockData().currentUser;
    if (me != null) {
      if (MatchingService.isDualSameLineage(me)) {
        _poolCategory = MatchingPoolCategory.dualSameRecalculation;
      }
      _shortlistedIds.addAll(me.favoriteProfileIds);
      _setupRealtimeStatusListener(me.id);
      _setupMatchesFeedListener(me.id);
    }

    // Broad collection('users').snapshots() listener removed to prevent high Firebase billing & quota exhaustion.

    refreshStatusAndProfile();
    refreshMatches();
  }

  void setGoldTrustOnly(bool value) {
    _goldTrustOnly = value;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setClanFilter(String? clan) {
    _selectedClanFilter = clan;
    notifyListeners();
  }

  bool isApprovedStatus(dynamic profileOrRow) {
    if (profileOrRow == null) return false;

    String accStatus = '';
    String statusVal = '';
    String regStatus = '';
    String apprStatus = '';
    String roleVal = '';
    bool isVerified = false;

    if (profileOrRow is UserProfile) {
      accStatus = profileOrRow.accountStatus.name;
      statusVal = profileOrRow.verificationStatus;
      regStatus = profileOrRow.registrationStatus;
      roleVal = profileOrRow.role;
    } else if (profileOrRow is Map) {
      accStatus = (profileOrRow['account_status'] ?? '').toString();
      statusVal =
          (profileOrRow['status'] ?? profileOrRow['verification_status'] ?? '')
              .toString();
      regStatus = (profileOrRow['registration_status'] ?? '').toString();
      apprStatus = (profileOrRow['approval_status'] ?? '').toString();
      roleVal = (profileOrRow['role'] ?? '').toString();
      isVerified =
          profileOrRow['is_verified'] == true ||
          profileOrRow['is_verified']?.toString().toLowerCase() == 'true';
    }

    final accUpper = accStatus.trim().toUpperCase();
    final statusUpper = statusVal.trim().toUpperCase();
    final regUpper = regStatus.trim().toUpperCase();
    final apprUpper = apprStatus.trim().toUpperCase();
    final roleUpper = roleVal.trim().toUpperCase();

    return (accUpper == 'APPROVED' ||
        accUpper == 'ACTIVE' ||
        accUpper == 'LIVE' ||
        statusUpper == 'APPROVED' ||
        statusUpper == 'ACTIVE' ||
        statusUpper == 'LIVE' ||
        regUpper == 'APPROVED' ||
        regUpper == 'ACTIVE' ||
        regUpper == 'LIVE' ||
        apprUpper == 'APPROVED' ||
        apprUpper == 'ACTIVE' ||
        apprUpper == 'LIVE' ||
        roleUpper == 'USER' ||
        roleUpper == 'MEMBER' ||
        roleUpper == 'ADMIN' ||
        roleUpper == 'SUPER_ADMIN' ||
        isVerified);
  }

  void _setupRealtimeStatusListener(String userId) {
    _matchesStatusChannel?.unsubscribe();
    _matchesStatusChannel = Supabase.instance.client
        .channel('public:kurichiyar_profiles:matches_gate:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'kurichiyar_profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              final updated = UserProfile.fromMap(payload.newRecord);
              MockData().updateCurrentUser(updated);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  void _setupMatchesFeedListener(String userId) {
    _matchesFeedChannel?.unsubscribe();
    _matchesFeedChannel = Supabase.instance.client
        .channel('public:kurichiyar_profiles:matches')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'kurichiyar_profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final currentMe = MockData().currentUser;

            if (newRecord.isNotEmpty && currentMe != null && newRecord['id'] == currentMe.id) {
              final String? newGenderStr = newRecord['gender']?.toString().toLowerCase();
              final Gender newGender = newGenderStr == 'female' ? Gender.female : Gender.male;
              final int? newMotherClanId = newRecord['mother_clan_id'] != null
                  ? int.tryParse(newRecord['mother_clan_id'].toString())
                  : null;

              final bool changed = currentMe.gender != newGender || currentMe.motherClanId != newMotherClanId;
              MockData().updateCurrentUser(UserProfile.fromMap(newRecord));
              if (changed) {
                refreshMatches();
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> refreshStatusAndProfile([BuildContext? context]) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();

    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      final currentUserId = authUser?.id ?? MockData().currentUser?.id;
      final currentEmail = authUser?.email ?? MockData().currentUser?.email;

      Map<String, dynamic>? freshRow;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        try {
          freshRow = await Supabase.instance.client
              .from('kurichiyar_profiles')
              .select()
              .eq('id', currentUserId)
              .maybeSingle();
        } catch (_) {}
      }

      if (freshRow == null && currentEmail != null && currentEmail.isNotEmpty) {
        try {
          freshRow = await Supabase.instance.client
              .from('kurichiyar_profiles')
              .select()
              .eq('email', currentEmail)
              .maybeSingle();
        } catch (_) {}
      }

      if (freshRow != null) {
        final updatedProfile = UserProfile.fromMap(freshRow);
        MockData().updateCurrentUser(updatedProfile);
        final bool approved = isApprovedStatus(freshRow);

        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                approved
                    ? 'Verification Approved! Access granted to Matches.'
                    : 'Current Status: ${freshRow['account_status'] ?? freshRow['status'] ?? freshRow['approval_status'] ?? 'Pending'}',
              ),
              backgroundColor: approved ? Colors.green : Colors.orangeAccent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshMatches() async {
    _isLoading = true;
    notifyListeners();

    try {
      final me = MockData().currentUser;
      if (me == null) {
        _allMatches = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final List<UserProfile> finalFeed = [];

      // 1. Fetch targeted, limited batch from Firestore users collection
      try {
        Query query = FirebaseFirestore.instance.collection('users');
        if (me.gender == Gender.male) {
          query = query.where('gender', isEqualTo: 'female');
        } else if (me.gender == Gender.female) {
          query = query.where('gender', isEqualTo: 'male');
        }
        query = query.limit(20);

        final snapshot = await query.get(const GetOptions(source: Source.serverAndCache));
        if (snapshot.docs.isNotEmpty) {
          _lastFirestoreDoc = snapshot.docs.last;
          _hasMore = snapshot.docs.length >= 20;
        } else {
          _hasMore = false;
        }

        for (final doc in snapshot.docs) {
          final pId = doc.id;
          if (pId == Supabase.instance.client.auth.currentUser?.id || pId == me.id) {
            continue;
          }

          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          data['id'] = data['id'] ?? pId;
          final candProfile = UserProfile.fromMap(data);

          if (!candProfile.isActive &&
              candProfile.accountStatus != AccountStatus.approved &&
              candProfile.registrationStatus.toLowerCase() != 'active' &&
              candProfile.registrationStatus.toLowerCase() != 'approved' &&
              candProfile.verificationStatus.toLowerCase() != 'approved') {
            continue;
          }

          if (candProfile.gender == me.gender) continue;
          if (!MatchingService.isMatchEligible(
            me,
            candProfile,
            poolCategory: _poolCategory,
          )) {
            continue;
          }

          finalFeed.add(candProfile);
        }
      } catch (e) {
        debugPrint('Firestore users fetch in matches error: $e');
      }

      // 2. Fallback to Supabase kurichiyar_profiles
      if (finalFeed.isEmpty) {
        final response = await Supabase.instance.client
            .from('kurichiyar_profiles')
            .select()
            .limit(20);

        for (final p in response) {
          final pId = p['id']?.toString() ?? '';
          if (pId == Supabase.instance.client.auth.currentUser?.id || pId == me.id) {
            continue;
          }

          final candProfile = UserProfile.fromMap(p);
          if (candProfile.gender == me.gender) continue;
          if (!MatchingService.isMatchEligible(
            me,
            candProfile,
            poolCategory: _poolCategory,
          )) {
            continue;
          }

          finalFeed.add(candProfile);
        }
      }

      finalFeed.sort((a, b) {
        final scoreA = MatchingService.calculateMatchScore(me, a);
        final scoreB = MatchingService.calculateMatchScore(me, b);
        return scoreB.compareTo(scoreA);
      });

      try {
        final shortlistRes = await Supabase.instance.client
            .from('user_shortlists')
            .select('shortlisted_profile_id')
            .eq('user_id', me.id);

        final incomingRes = await Supabase.instance.client
            .from('profile_interests')
            .select('sender_id')
            .eq('receiver_id', me.id)
            .eq('status', 'pending');

        _shortlistedIds.clear();
        for (final row in shortlistRes) {
          _shortlistedIds.add(row['shortlisted_profile_id'] as String);
        }

        _incomingInterestUserIds.clear();
        for (final row in (incomingRes as List)) {
          _incomingInterestUserIds.add(row['sender_id'].toString());
        }
      } catch (_) {}

      _allMatches = SubscriptionService.instance.sortByPriority(finalFeed);
    } catch (e) {
      debugPrint('Error loading matches dynamically: $e');
      _allMatches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Paginated fetch for additional matches
  Future<void> loadMoreMatches() async {
    if (_isLoadingMore || !_hasMore) return;
    final me = MockData().currentUser;
    if (me == null || _lastFirestoreDoc == null) {
      _hasMore = false;
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      Query query = FirebaseFirestore.instance.collection('users');
      if (me.gender == Gender.male) {
        query = query.where('gender', isEqualTo: 'female');
      } else if (me.gender == Gender.female) {
        query = query.where('gender', isEqualTo: 'male');
      }
      query = query.startAfterDocument(_lastFirestoreDoc!).limit(20);

      final snapshot = await query.get(const GetOptions(source: Source.serverAndCache));
      if (snapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastFirestoreDoc = snapshot.docs.last;
        _hasMore = snapshot.docs.length >= 20;

        final List<UserProfile> moreFeed = [];
        for (final doc in snapshot.docs) {
          final pId = doc.id;
          if (pId == Supabase.instance.client.auth.currentUser?.id || pId == me.id) continue;
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          data['id'] = data['id'] ?? pId;
          final candProfile = UserProfile.fromMap(data);
          if (candProfile.gender == me.gender) continue;
          if (!MatchingService.isMatchEligible(
            me,
            candProfile,
            poolCategory: _poolCategory,
          )) {
            continue;
          }
          moreFeed.add(candProfile);
        }
        final existingIds = _allMatches.map((p) => p.id).toSet();
        _allMatches.addAll(moreFeed.where((p) => !existingIds.contains(p.id)));
      }
    } catch (e) {
      debugPrint('Load more matches error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void handleSkip(BuildContext context, UserProfile target) {
    HapticFeedback.selectionClick();
    _skippedTimestamps[target.id] = DateTime.now();
    _skippedProfilesStack.add(target);
    MockData().interactedProfileIds.add(target.id);
    notifyListeners();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('അടുത്ത പ്രൊഫൈലിലേക്ക് മാറ്റി: ${target.name}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '↩️ അൺഡൂ (Undo)',
          textColor: Colors.amberAccent,
          onPressed: () => undoLastSkip(context),
        ),
      ),
    );
  }

  void undoLastSkip(BuildContext context) {
    if (_skippedProfilesStack.isEmpty) return;
    final lastSkipped = _skippedProfilesStack.removeLast();
    final skippedAt = _skippedTimestamps[lastSkipped.id];

    if (skippedAt != null &&
        DateTime.now().difference(skippedAt) <= const Duration(minutes: 10)) {
      HapticFeedback.mediumImpact();
      MockData().interactedProfileIds.remove(lastSkipped.id);
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${lastSkipped.name}-ന്റെ പ്രൊഫൈൽ പുനഃസ്ഥാപിച്ചു (Restored)',
          ),
          backgroundColor: Colors.blue.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('10 മിനിറ്റ് സമയം കഴിഞ്ഞതിനാൽ അൺഡൂ ചെയ്യാനാകില്ല.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> toggleShortlist(BuildContext context, UserProfile profile) async {
    final me = MockData().currentUser;
    if (me == null) return;
    final isCurrentlyShortlisted = _shortlistedIds.contains(profile.id);

    if (isCurrentlyShortlisted) {
      _shortlistedIds.remove(profile.id);
    } else {
      _shortlistedIds.add(profile.id);
    }
    notifyListeners();

    try {
      if (isCurrentlyShortlisted) {
        await Supabase.instance.client.from('user_shortlists').delete().match({
          'user_id': me.id,
          'shortlisted_profile_id': profile.id,
        });
        await Supabase.instance.client
            .from('shortlists')
            .delete()
            .match({'user_id': me.id, 'shortlisted_user_id': profile.id})
            .catchError((_) {});

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shortlist-ൽ നിന്ന് നീക്കി'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await Supabase.instance.client.from('user_shortlists').insert({
          'user_id': me.id,
          'shortlisted_profile_id': profile.id,
        });
        await Supabase.instance.client
            .from('shortlists')
            .insert({'user_id': me.id, 'shortlisted_user_id': profile.id})
            .catchError((_) {});

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ഷോർട്ട്ലിസ്റ്റിൽ ചേർത്തു ⭐'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (isCurrentlyShortlisted) {
        _shortlistedIds.add(profile.id);
      } else {
        _shortlistedIds.remove(profile.id);
      }
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _filterStrictMatches({
    required Map<String, dynamic> currentUser,
    required List<Map<String, dynamic>> candidates,
    MatchingPoolCategory? category,
  }) {
    final me = UserProfile.fromMap(currentUser);
    final targetCategory = category ?? _poolCategory;

    final filtered = candidates.where((candidate) {
      try {
        final profile = UserProfile.fromMap(candidate);
        return MatchingService.isMatchEligible(
          me,
          profile,
          poolCategory: targetCategory,
        );
      } catch (e) {
        return false;
      }
    }).toList();

    filtered.sort((a, b) {
      try {
        final profileA = UserProfile.fromMap(a);
        final profileB = UserProfile.fromMap(b);

        if (profileA.isBoosted && !profileB.isBoosted) return -1;
        if (!profileA.isBoosted && profileB.isBoosted) return 1;

        final scoreA = MatchingService.calculateMatchScore(me, profileA);
        final scoreB = MatchingService.calculateMatchScore(me, profileB);
        return scoreB.compareTo(scoreA);
      } catch (_) {
        return 0;
      }
    });

    return filtered;
  }

  @override
  void dispose() {
    _firestoreMatchesSub?.cancel();
    _matchesStatusChannel?.unsubscribe();
    _matchesFeedChannel?.unsubscribe();
    super.dispose();
  }
}
