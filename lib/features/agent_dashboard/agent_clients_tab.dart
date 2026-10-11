import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/mock_data.dart';
import '../profile_detail/profile_detail_page.dart';

class AgentClientsTab extends StatefulWidget {
  const AgentClientsTab({super.key});

  @override
  State<AgentClientsTab> createState() => _AgentClientsTabState();
}

class _AgentClientsTabState extends State<AgentClientsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    final agentCode = MockData().currentUser?.agentCode;
    if (agentCode == null) return;

    try {
      final res = await Supabase.instance.client
          .from('kurichiyar_profiles')
          .select('*')
          .eq('agent_code', agentCode);

      setState(() {
        _clients = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clients.isEmpty) {
      return const Center(child: Text('You have no clients yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        final name = client['full_name'] ?? 'Unknown Client';
        final photo = client['photo_url'];
        final status = client['account_status'] ?? 'PENDING_LEAD';

        final isMissingInfo =
            photo == null ||
            photo.toString().isEmpty ||
            name == 'Unknown Client';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null ? const Icon(Icons.person) : null,
            ),
            title: Text(name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $status'),
                if (isMissingInfo)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '⚠️ INCOMPLETE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              final id = client['id']?.toString();
              if (id != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileDetailPage(profileId: id),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
