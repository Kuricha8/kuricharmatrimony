import 'package:flutter/material.dart';
import '../../core/utils/mock_data.dart';
import '../../core/models/models.dart';
import 'profile_review_card.dart';

class ReviewQueueTab extends StatefulWidget {
  const ReviewQueueTab({super.key});

  @override
  State<ReviewQueueTab> createState() => _ReviewQueueTabState();
}

class _ReviewQueueTabState extends State<ReviewQueueTab> {
  @override
  Widget build(BuildContext context) {
    final agent = MockData().currentUser;
    if (agent == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, _) {
        final bool isAdmin = agent.isAdmin || agent.role == 'admin' || agent.role == 'super_admin';
        final pendingProfiles = MockData().profiles
            .where(
              (p) =>
                  isAdmin
                      ? (p.accountStatus == AccountStatus.agentReview ||
                         p.accountStatus == AccountStatus.adminReview ||
                         p.accountStatus == AccountStatus.pending)
                      : (p.accountStatus == AccountStatus.agentReview &&
                         p.agentCode == agent.agentCode),
            )
            .toList();

        if (pendingProfiles.isEmpty) {
          return const Center(
            child: Text(
              'No profiles pending review in your queue.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingProfiles.length,
          itemBuilder: (context, index) {
            final p = pendingProfiles[index];
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
                subtitle: Text('ID: \${p.id} • Assigned to: \${p.agentCode}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileReviewCard(profile: p),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
