import 'package:flutter/material.dart';
import '../services/agent_client_service.dart';

class ClientApprovalDialog extends StatelessWidget {
  final String requestId;
  final String clientId;
  final Map<String, dynamic> updatedData;

  const ClientApprovalDialog({
    super.key,
    required this.requestId,
    required this.clientId,
    required this.updatedData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('പ്രൊഫൈൽ മാറ്റങ്ങൾ അപ്രൂവ് ചെയ്യുക'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ഏജന്റ് നിങ്ങളുടെ പ്രൊഫൈലിൽ താഴെ പറയുന്ന മാറ്റങ്ങൾ വരുത്തിയിട്ടുണ്ട്:'),
          const SizedBox(height: 10),
          ...updatedData.entries.map((entry) => Text(
                '${entry.key}: ${entry.value}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: () async {
            await AgentClientService().approveEditByClient(
              requestId: requestId,
              clientProfileId: clientId,
              updatedData: updatedData,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Approve'),
        ),
      ],
    );
  }
}
