import 'package:flutter/material.dart';
import '../../core/utils/mock_data.dart';
import 'review_queue_tab.dart';
import 'forwarded_profiles_tab.dart';
import 'agent_qr_scanner_screen.dart';
import 'agent_fast_registration_screen.dart';
import 'agent_clients_tab.dart';
import 'agent_reference_viewer_tab.dart';
import 'agent_reward_wallet_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/admin_config.dart';

class AgentDashboardShell extends StatefulWidget {
  const AgentDashboardShell({super.key});

  @override
  State<AgentDashboardShell> createState() => _AgentDashboardShellState();
}

class _AgentDashboardShellState extends State<AgentDashboardShell> {
  int _currentIndex = 0;
  String _noticeText = '';

  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotice();
    _fetchWalletPoints();
  }

  Future<void> _fetchWalletPoints() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final res = await Supabase.instance.client
          .from('agent_rewards')
          .select('total_points')
          .eq('agent_id', user.id)
          .maybeSingle();
      if (res != null && mounted) {
        setState(() => _totalPoints = res['total_points'] ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _fetchNotice() async {
    try {
      final res = await Supabase.instance.client
          .from('agent_notices')
          .select('message')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1);
      if (res.isNotEmpty) {
        setState(() => _noticeText = res.first['message']);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final agent = MockData().currentUser;
    final bool isAdmin = agent?.isAdmin == true ||
        agent?.role == 'admin' ||
        agent?.role == 'super_admin' ||
        AdminConfig.isSuperAdmin(
          phone: agent?.guardianPhone ?? agent?.publicDisplayNumber,
          email: agent?.email,
        );

    if (agent == null || (!agent.isAgent && !isAdmin)) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    final pages = [
      const ReviewQueueTab(),
      const ForwardedProfilesTab(),
      const AgentClientsTab(),
      const AgentReferenceViewerTab(),
      _buildAgentProfileTab(agent),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Dashboard: ${agent.name}' : 'Agent Dashboard: ${agent.name}'),
        backgroundColor: isAdmin ? const Color(0xFF000080) : Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              tooltip: 'Go to Matrimony App',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await MockData().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_noticeText.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.amber.shade200,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _noticeText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo.shade900,
        unselectedItemColor: Colors.grey.shade600,
        iconSize: 22,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: 'Review Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified),
            label: 'Forwarded',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Clients'),
          BottomNavigationBarItem(
            icon: Icon(Icons.screen_search_desktop),
            label: 'Viewer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'My Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildAgentProfileTab(dynamic agent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(agent.photoUrl),
            ),
            const SizedBox(height: 16),
            Text(
              agent.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Agent Code: ${agent.agentCode}',
              style: const TextStyle(fontSize: 18, color: Colors.indigo),
            ),
            const SizedBox(height: 32),
            const Card(
              child: ListTile(
                leading: Icon(Icons.analytics),
                title: Text('Profiles Verified This Month'),
                trailing: Text(
                  '14',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.amber.shade100,
              child: ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.orange,
                ),
                title: const Text('My Reward Wallet'),
                subtitle: Text(
                  'Total Points: $_totalPoints',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AgentRewardWalletPage(),
                      ),
                    ).then((_) => _fetchWalletPoints());
                  },
                  child: const Text('Points History'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AgentFastRegistrationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Create Profile for Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AgentQrScannerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan User QR Code directly'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade900,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
