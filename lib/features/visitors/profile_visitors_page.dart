import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../core/services/admob_service.dart';
import '../../core/services/matching_service.dart';
import '../profile_detail/profile_detail_page.dart';

class ProfileVisitorsPage extends StatefulWidget {
  const ProfileVisitorsPage({super.key});

  @override
  State<ProfileVisitorsPage> createState() => _ProfileVisitorsPageState();
}

class _ProfileVisitorsPageState extends State<ProfileVisitorsPage> {
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _adsWatched = 0;
  List<UserProfile> _visitors = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastFirestoreDoc;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadVisitors();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore && !_loading) {
        _loadVisitors(loadMore: true);
      }
    }
  }

  Future<void> _loadVisitors({bool loadMore = false}) async {
    final me = MockData().currentUser;
    if (me == null) return;

    if (loadMore) {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    } else {
      _lastFirestoreDoc = null;
      _hasMore = true;
      setState(() => _loading = true);
    }

    try {
      final List<UserProfile> newVisitors = [];

      // 1. Fetch from Firestore visitors collection with strict pagination (limit 20)
      try {
        Query query = FirebaseFirestore.instance
            .collection('visitors')
            .where('viewed_id', isEqualTo: me.id)
            .limit(_pageSize);

        if (loadMore && _lastFirestoreDoc != null) {
          query = query.startAfterDocument(_lastFirestoreDoc!);
        }

        final snap = await query.get(const GetOptions(source: Source.serverAndCache));
        if (snap.docs.isNotEmpty) {
          _lastFirestoreDoc = snap.docs.last;
          for (final doc in snap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['visitor_profile'] != null) {
              final p = UserProfile.fromMap(data['visitor_profile'] as Map<String, dynamic>);
              if (!p.isStealthActiveMode && MatchingService.isMatchEligible(me, p)) {
                newVisitors.add(p);
              }
            }
          }
        }
      } catch (fErr) {
        debugPrint('Firestore visitors fetch note: $fErr');
      }

      // 2. Fallback / supplementary fetch from Supabase with range limit
      if (newVisitors.isEmpty) {
        final offset = loadMore ? _visitors.length : 0;
        final res = await Supabase.instance.client
            .from('profile_views_history_explicit')
            .select(
              'viewer_id, last_viewed_at, view_count, kurichiyar_profiles!profile_views_history_viewer_id_fkey(*)',
            )
            .eq('viewed_id', me.id)
            .order('last_viewed_at', ascending: false)
            .range(offset, offset + _pageSize - 1);

        for (var row in res) {
          if (row['kurichiyar_profiles'] != null) {
            final p = UserProfile.fromMap(row['kurichiyar_profiles']);
            if (!p.isStealthActiveMode && MatchingService.isMatchEligible(me, p)) {
              newVisitors.add(p);
            }
          }
        }
      }

      if (newVisitors.length < _pageSize) {
        _hasMore = false;
      }

      if (mounted) {
        setState(() {
          if (loadMore) {
            final existingIds = _visitors.map((v) => v.id).toSet();
            _visitors.addAll(newVisitors.where((v) => !existingIds.contains(v.id)));
          } else {
            _visitors = newVisitors;
          }
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading visitors: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _watchAd() {
    AdMobService.instance.showRewardedAd(
      onUserEarnedReward: () {
        if (!mounted) return;
        setState(() {
          _adsWatched++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _adsWatched >= 3
                  ? '🎉 പ്രൊഫൈൽ സന്ദർശകരുടെ ലിസ്റ്റ് അൺലോക്ക് ചെയ്തു!'
                  : 'പരസ്യം കണ്ടു ($_adsWatched/3). ഇനിയും ${3 - _adsWatched} പരസ്യങ്ങൾ ബാക്കി.',
            ),
            backgroundColor: _adsWatched >= 3 ? Colors.green : Colors.blue,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = MockData().currentUser;
    final bool isUnlocked =
        (me != null && me.isPremiumUser) || _adsWatched >= 3;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Visitors (സന്ദർശകർ)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !isUnlocked
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(0xFFE8F0FE),
                        child: Icon(
                          Icons.remove_red_eye,
                          size: 36,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ആരൊക്കെ നിങ്ങളുടെ പ്രൊഫൈൽ സന്ദർശിച്ചു എന്ന് അറിയാം!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '3 പരസ്യങ്ങൾ കണ്ടോ അല്ലെങ്കിൽ പ്ലാൻ അപ്‌ഗ്രേഡ് ചെയ്തോ മുഴുവൻ സന്ദർശകരെയും കാണുക.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _watchAd,
                        icon: const Icon(Icons.play_circle_fill),
                        label: Text('3 പരസ്യങ്ങൾ കാണുക ($_adsWatched/3 Ads)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000080),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/subscriptions'),
                        icon: const Icon(Icons.star, color: Colors.amber),
                        label: const Text(
                          'പ്ലാൻ അപ്‌ഗ്രേഡ് ചെയ്യുക (Upgrade Plan)',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5C3E00),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : _visitors.isEmpty
          ? const Center(
              child: Text(
                'No one has visited your profile recently.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _visitors.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _visitors.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final p = _visitors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: p.photoUrl.startsWith('http')
                          ? NetworkImage(p.photoUrl)
                          : const AssetImage('assets/images/default_avatar.png')
                                as ImageProvider,
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${p.age} Yrs • ${p.job.isNotEmpty ? p.job : "No Job"}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileDetailPage(profileId: p.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
