import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../profile_detail/profile_detail_page.dart';

typedef ShortlistScreen = MyCartPage;

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  bool _loading = true;
  List<UserProfile> _cartProfiles = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final me = MockData().currentUser;
    if (me == null) return;
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? me.id;

    final List<UserProfile> profiles = [];

    try {
      final res = await Supabase.instance.client
          .from('user_shortlists')
          .select(
            'shortlisted_profile_id, kurichiyar_profiles!shortlisted_profile_id(*)',
          )
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      for (var row in res) {
        if (row['kurichiyar_profiles'] != null) {
          profiles.add(UserProfile.fromMap(row['kurichiyar_profiles']));
        }
      }
    } catch (e) {
      debugPrint('Error loading user_shortlists: $e');
    }

    if (profiles.isEmpty) {
      try {
        final res2 = await Supabase.instance.client
            .from('shortlists')
            .select(
              'shortlisted_user_id, kurichiyar_profiles!shortlisted_user_id(*)',
            )
            .eq('user_id', currentUserId)
            .order('created_at', ascending: false);

        for (var row in res2) {
          if (row['kurichiyar_profiles'] != null) {
            profiles.add(UserProfile.fromMap(row['kurichiyar_profiles']));
          }
        }
      } catch (e) {
        debugPrint('Error loading shortlists table: $e');
      }
    }

    setState(() {
      _cartProfiles = profiles;
      _loading = false;
    });
  }

  Future<void> _removeFromCart(String savedProfileId) async {
    final me = MockData().currentUser;
    if (me == null) return;
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? me.id;

    try {
      await Supabase.instance.client
          .from('user_shortlists')
          .delete()
          .eq('user_id', currentUserId)
          .eq('shortlisted_profile_id', savedProfileId);

      await Supabase.instance.client
          .from('shortlists')
          .delete()
          .eq('user_id', currentUserId)
          .eq('shortlisted_user_id', savedProfileId)
          .catchError((_) {});

      setState(() {
        _cartProfiles.removeWhere((p) => p.id == savedProfileId);
      });
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Shortlist')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cartProfiles.isEmpty
          ? const Center(
              child: Text(
                'Your shortlist is empty.\nTap the star icon on a profile to save it here!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cartProfiles.length,
              itemBuilder: (context, index) {
                final p = _cartProfiles[index];
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
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeFromCart(p.id),
                    ),
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
