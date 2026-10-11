import 'package:flutter/material.dart';
import '../../core/utils/mock_data.dart';
import '../../core/models/models.dart';

class ForwardedProfilesTab extends StatelessWidget {
  const ForwardedProfilesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final agent = MockData().currentUser;
    if (agent == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, _) {
        // Find profiles that this agent previously verified, which are now either with Admin or Approved
        final forwardedProfiles = MockData().profiles
            .where(
              (p) =>
                  (p.accountStatus == AccountStatus.adminReview ||
                      p.accountStatus == AccountStatus.approved) &&
                  p.agentCode == agent.agentCode,
            )
            .toList();

        if (forwardedProfiles.isEmpty) {
          return const Center(
            child: Text(
              'No profiles have been forwarded yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: forwardedProfiles.length,
          itemBuilder: (context, index) {
            final p = forwardedProfiles[index];
            final isAdminReview = p.accountStatus == AccountStatus.adminReview;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(p.photoUrl),
                ),
                title: Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Status: ${isAdminReview ? "Pending Central Admin" : "Approved"}',
                ),
                trailing: Icon(
                  isAdminReview ? Icons.hourglass_top : Icons.check_circle,
                  color: isAdminReview ? Colors.orange : Colors.green,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
