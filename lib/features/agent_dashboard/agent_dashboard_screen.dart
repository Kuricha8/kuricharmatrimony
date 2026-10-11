import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgentDashboardScreen extends StatelessWidget {
  final String currentAgentDocId;
  final String currentAgentCode;
  final List<String> myPinCodes;

  const AgentDashboardScreen({
    super.key,
    required this.currentAgentDocId,
    required this.currentAgentCode,
    required this.myPinCodes,
  });

  void _callClient(BuildContext context, String clientId) {
    // മാസ്ക് ചെയ്ത കോൾ സ്ക്രീനിലേക്ക് പോകുന്നു
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('വെർച്വൽ മാസ്ക്ഡ് കോൾ കണക്റ്റ് ചെയ്യുന്നു...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editClient(BuildContext context, String clientId) {
    // നിയമം: സ്വന്തം പ്രൊഫൈൽ എഡിറ്റ് ചെയ്യാൻ പാടില്ല
    if (clientId == currentAgentDocId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('നിങ്ങൾക്ക് നിങ്ങളുടെ സ്വന്തം പ്രൊഫൈൽ എഡിറ്റ് ചെയ്യാൻ അനുവാദമില്ല.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // മറ്റൊരു ഏജന്റിന്റെ ക്ലയന്റ് എഡിറ്റിംഗ് ഡയലോഗ്
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ക്ലയന്റ് പ്രൊഫൈൽ ($clientId) എഡിറ്റ് ചെയ്യുന്നു...'),
        backgroundColor: const Color(0xFF000080),
      ),
    );
  }

  String _formatMaskedPhone(dynamic phone) {
    if (phone == null) return 'XXXXXX0000';
    final s = phone.toString().replaceAll(RegExp(r'\D'), '');
    if (s.length >= 4) {
      return 'XXXXXX${s.substring(s.length - 4)}';
    }
    return 'XXXXXX$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ഏജന്റ് പാനൽ: $currentAgentCode'),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
      ),
      body: myPinCodes.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'നിങ്ങൾക്ക് പിൻകോഡുകൾ നൽകിയിട്ടില്ല.\nദയവായി അഡ്മിനുമായി ബന്ധപ്പെടുക.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              // നിശ്ചയിച്ച പിൻകോഡിലുള്ള, ഡിലീറ്റ് ആകാത്ത ക്ലയന്റുകളെ മാത്രം ലിസ്റ്റ് ചെയ്യുന്നു
              stream: FirebaseFirestore.instance
                  .collection('profiles')
                  .where('is_deleted', isEqualTo: false)
                  .where('pincode', whereIn: myPinCodes)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('പിശക്: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clients = snapshot.data!.docs;

                if (clients.isEmpty) {
                  return const Center(
                    child: Text(
                      'നിങ്ങളുടെ പിൻകോഡിൽ ക്ലയന്റുകൾ ലഭ്യമല്ല',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index].data() as Map<String, dynamic>;
                    final String clientId = clients[index].id;
                    final String maskedPhone = _formatMaskedPhone(client['phone']);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF000080),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          client['name'] ?? 'ക്ലയന്റ്',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'പിൻകോഡ്: ${client['pincode'] ?? 'N/A'} | ഫോൺ: $maskedPhone',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.call, color: Colors.green),
                              tooltip: 'മാസ്ക്ഡ് കോൾ',
                              onPressed: () => _callClient(context, clientId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'എഡിറ്റ് ചെയ്യുക',
                              onPressed: () => _editClient(context, clientId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
