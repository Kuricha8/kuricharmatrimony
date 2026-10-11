import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AgentRewardWalletPage extends StatefulWidget {
  const AgentRewardWalletPage({super.key});

  @override
  State<AgentRewardWalletPage> createState() => _AgentRewardWalletPageState();
}

class _AgentRewardWalletPageState extends State<AgentRewardWalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  num _totalPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final res = await _supabase
          .from('agent_rewards')
          .select('total_points')
          .eq('agent_id', user.id)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _totalPoints = res['total_points'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching wallet: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestCashout() async {
    final TextEditingController pointsController = TextEditingController();

    // Assume 1 point = ₹1 for now
    final double conversionRate = 1.0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Request Cashout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the number of points you want to redeem:'),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Points',
                  border: const OutlineInputBorder(),
                  helperText: 'Max available: $_totalPoints',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Currently, payouts are processed manually to your registered bank account.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pointsStr = pointsController.text.trim();
                final pointsToRedeem = num.tryParse(pointsStr);

                if (pointsToRedeem == null || pointsToRedeem <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                    ),
                  );
                  return;
                }

                if (pointsToRedeem > _totalPoints) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Insufficient points')),
                  );
                  return;
                }

                // Call Supabase RPC
                Navigator.pop(dialogContext); // Close dialog
                setState(() => _isLoading = true);

                try {
                  final user = _supabase.auth.currentUser;
                  final cashValue = pointsToRedeem * conversionRate;

                  await _supabase.rpc(
                    'request_agent_cashout',
                    params: {
                      'p_agent_id': user!.id,
                      'p_points_redeemed': pointsToRedeem,
                      'p_cash_value': cashValue,
                    },
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cashout requested successfully!'),
                      ),
                    );
                    _fetchWalletData(); // Refresh
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error requesting cashout: $e')),
                    );
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reward Wallet'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildWalletHeader(),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.indigo.shade900,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.indigo.shade900,
                  tabs: const [
                    Tab(text: 'Points History'),
                    Tab(text: 'Cashout Requests'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHistoryList(),
                      _buildCashoutRequestsList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWalletHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        border: Border(bottom: BorderSide(color: Colors.indigo.shade100)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'Available Balance',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          Text(
            '$_totalPoints Points',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade900,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _totalPoints > 0 ? _requestCashout : null,
            icon: const Icon(Icons.payments),
            label: const Text('Convert to Cash'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase
          .from('agent_reward_history')
          .select()
          .eq('agent_id', user.id)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return const Center(child: Text('No transaction history yet.'));
        }

        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            final isCredit = item['transaction_type'] == 'CREDIT';
            final dateStr = item['created_at'] != null
                ? DateFormat(
                    'dd MMM yyyy, hh:mm a',
                  ).format(DateTime.parse(item['created_at']).toLocal())
                : '';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isCredit
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              title: Text(item['description'] ?? 'Transaction'),
              subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
              trailing: Text(
                '${isCredit ? '+' : '-'}${item['points']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCashoutRequestsList() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase
          .from('agent_cashout_requests')
          .select()
          .eq('agent_id', user.id)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text('No cashout requests yet.'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final status = req['status'] as String? ?? 'PENDING';
            final dateStr = req['created_at'] != null
                ? DateFormat(
                    'dd MMM yyyy',
                  ).format(DateTime.parse(req['created_at']).toLocal())
                : '';

            Color statusColor = Colors.orange;
            if (status == 'APPROVED') statusColor = Colors.green;
            if (status == 'REJECTED') statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Cashout: ₹${req['cash_value']}'),
                subtitle: Text(
                  'Redeemed ${req['points_redeemed']} points on $dateStr',
                ),
                trailing: Chip(
                  label: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: statusColor,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
