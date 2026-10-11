import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../clan_feed/tharavadu_list.dart';

class ProfileReviewCard extends StatelessWidget {
  final UserProfile profile;

  const ProfileReviewCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final fatherClan = getClanById(profile.fatherClanId);
    final motherClan = getClanById(profile.motherClanId);
    final isOutCaste = profile.isOutOfCaste;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Profile'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photos Header
            SizedBox(
              height: 250,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPhoto(profile.photoUrl),
                  ...profile.additionalPhotos.map((url) => _buildPhoto(url)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Identity Section
            _buildSectionHeader('Identity & Basics'),
            _buildDetailRow('Name', profile.name),
            _buildDetailRow('Age', '${profile.age} years'),
            _buildDetailRow('Gender', profile.gender.name.toUpperCase()),
            _buildDetailRow('Contact', profile.email),

            const Divider(height: 32),

            // Lineage Section
            _buildSectionHeader('Lineage (Tharavadu)'),
            _buildDetailRow(
              'Father Clan',
              '${fatherClan?.type ?? "PANDI"} (${fatherClan?.name ?? profile.fatherTharavadu ?? "Unknown"})',
            ),
            _buildDetailRow(
              'Mother Clan',
              '${motherClan?.type ?? "BANDHU"} (${motherClan?.name ?? profile.motherTharavadu ?? "Unknown"})',
            ),
            if (isOutCaste)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'WARNING: Out-of-Caste rules apply. Both clans belong to the same Moiety (PANDI/BANDHU).',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lineage Valid: Cross-Moiety requirements met.',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 32),

            // Document Verification
            _buildSectionHeader('Submitted Documents'),
            if (profile.idDocumentUrl != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.badge, color: Colors.indigo),
                  title: const Text('Government ID'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // Would open document viewer
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Document...')),
                    );
                  },
                ),
              )
            else
              const Text(
                'No documents attached',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),

            const SizedBox(height: 40),

            // Action Buttons
            ElevatedButton.icon(
              icon: const Icon(Icons.verified_user),
              label: const Text(
                'Verify & Forward to Admin',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                _showConfirmDialog(context);
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Note: Only Central Admin can reject profiles. By forwarding this, you confirm that the Tharavadu details and Identity match reality.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url, width: 200, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo.shade900,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Verification'),
        content: const Text(
          'Are you sure you want to verify this profile? It will be removed from your queue and forwarded to the Central Admin Panel for final activation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              MockData().agentForwardProfile(profile.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Profile successfully forwarded to Central Admin',
                  ),
                ),
              );
            },
            child: const Text('Confirm Forward'),
          ),
        ],
      ),
    );
  }
}
