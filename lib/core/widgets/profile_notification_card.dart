import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/models.dart';
import '../../features/clan_feed/tharavadu_list.dart';

class ProfileNotificationCard extends StatelessWidget {
  final UserProfile profile;

  const ProfileNotificationCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    // Determine the Deep-Link URL
    final String deepLinkUrl = profile.id.isNotEmpty
        ? 'https://kuricharmatrimony.vercel.app/profile/${profile.id}'
        : 'https://kuricharmatrimony.vercel.app';

    // Get Mother's Taravad Name (Fallback gracefully if null or empty)
    final motherClan = getClanById(profile.motherClanId);
    final String motherTharavadName =
        (profile.motherTharavadu != null &&
            profile.motherTharavadu!.trim().isNotEmpty)
        ? profile.motherTharavadu!.trim()
        : ((motherClan != null &&
                  motherClan.name != 'Unknown' &&
                  motherClan.name.isNotEmpty)
              ? motherClan.name
              : 'Kurichiyar');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.amber.shade700, width: 4),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'kurichiyar matrimony',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Photo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: profile.photoUrl.isNotEmpty
                  ? NetworkImage(profile.photoUrl)
                  : null,
              child: profile.photoUrl.isEmpty
                  ? Icon(
                      profile.gender == Gender.male ? Icons.man : Icons.woman,
                      size: 64,
                      color: Colors.grey.shade400,
                    )
                  : null,
            ),
          ),

          // Details
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${profile.age} YRS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            motherTharavadName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          // Eligible Clans Info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              children: [
                const Text(
                  'വിവാഹബന്ധം അനുവദനീയമായ തറവാടുകൾ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C3E00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  motherClan != null &&
                          motherClan.type.toLowerCase().contains('pandi')
                      ? 'ബന്ധു ഇല്ലങ്ങൾ'
                      : 'പന്തി ഇല്ലങ്ങൾ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // QR Code
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: QrImageView(
              data: deepLinkUrl,
              version: QrVersions.auto,
              size: 100.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
