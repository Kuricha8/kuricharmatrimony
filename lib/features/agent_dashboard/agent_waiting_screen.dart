import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/mock_data.dart';
import '../../core/widgets/ad_banner_widget.dart';

class AgentWaitingScreen extends StatefulWidget {
  const AgentWaitingScreen({super.key});

  @override
  State<AgentWaitingScreen> createState() => _AgentWaitingScreenState();
}

class _AgentWaitingScreenState extends State<AgentWaitingScreen> {
  bool _isRefreshing = false;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _subscription = Supabase.instance.client
          .channel('public:agents')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'agents',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: user.id,
            ),
            callback: (payload) {
              final rec = payload.newRecord;
              final statusVal = (rec['approval_status'] ?? rec['status'] ?? rec['approvalStatus'])?.toString().toUpperCase();
              final isApproved = statusVal == 'APPROVED' || rec['isApproved'] == true || rec['is_approved'] == true;
              final isRejected = statusVal == 'REJECTED' || rec['isRejected'] == true;

              if (isApproved) {
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/agent_dashboard',
                    (route) => false,
                  );
                }
              } else if (isRejected) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your agent application was rejected.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  _signOut();
                }
              }
            },
          )
          .subscribe();
    }
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id;

      if (userId != null) {
        // 1. Check Supabase agents table
        final agentRecord = await Supabase.instance.client
            .from('agents')
            .select()
            .eq('id', userId)
            .maybeSingle();

        bool isApproved = false;
        bool isRejected = false;

        if (agentRecord != null) {
          final s = (agentRecord['approval_status'] ?? agentRecord['status'] ?? agentRecord['approvalStatus'])?.toString().toUpperCase();
          if (s == 'APPROVED' || agentRecord['isApproved'] == true || agentRecord['is_approved'] == true) {
            isApproved = true;
          } else if (s == 'REJECTED') {
            isRejected = true;
          }
        }

        // 2. Check Supabase users / users_core / kurichiyar_profiles
        if (!isApproved) {
          final profileRecord = await Supabase.instance.client
              .from('kurichiyar_profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

          if (profileRecord != null) {
            final s = (profileRecord['approval_status'] ?? profileRecord['status'] ?? profileRecord['account_status'])?.toString().toUpperCase();
            if (s == 'APPROVED' || profileRecord['is_approved'] == true || profileRecord['isApproved'] == true) {
              isApproved = true;
            }
          }
        }

        // 3. Check Cloud Firestore users / agents documents
        if (!isApproved) {
          try {
            final firestoreDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
            if (firestoreDoc.exists) {
              final data = firestoreDoc.data() ?? {};
              final s = (data['status'] ?? data['approvalStatus'] ?? data['approval_status'])?.toString().toUpperCase();
              if (s == 'APPROVED' || data['isApproved'] == true || data['is_approved'] == true) {
                isApproved = true;
              }
            }
          } catch (fsErr) {
            debugPrint('Firestore status check notice: $fsErr');
          }
        }

        if (isApproved) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Agent Application Approved! Welcome to Agent Portal.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/agent_dashboard',
              (route) => false,
            );
          }
          return;
        } else if (isRejected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your agent application was rejected.'),
                backgroundColor: Colors.red,
              ),
            );
            await Supabase.instance.client.auth.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error refreshing agent status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await MockData().logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agent Application'),
          automaticallyImplyLeading: false, // Hide back button
          backgroundColor: const Color(0xFF000080),
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.hourglass_empty,
                            size: 80,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Application Pending',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF000080),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your account is pending admin approval. Please wait.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),

                          ElevatedButton.icon(
                            onPressed: _isRefreshing ? null : _refreshStatus,
                            icon: _isRefreshing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: const Text('Refresh Status'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF000080),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Ad/Banner Space at the bottom (Web + Mobile)
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
