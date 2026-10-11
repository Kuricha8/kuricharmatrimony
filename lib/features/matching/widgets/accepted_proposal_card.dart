import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/watermarked_image.dart';
import '../../../core/widgets/navigate_to_house_button.dart';
import '../../clan_feed/tharavadu_list.dart';

/// "Accepted Proposals" Card View
/// Displays the mutually accepted proposal with candidate details and the conditional
/// "Navigate to House (Google Maps)" button.
class AcceptedProposalCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onTap;
  final VoidCallback? onChat;

  const AcceptedProposalCard({
    super.key,
    required this.profile,
    this.onTap,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final fatherClan = getClanById(profile.fatherClanId);
    final motherClan = getClanById(profile.motherClanId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF1B8C4E), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Acceptance Header Banner ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B8C4E), Color(0xFF2E7D32)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: const Row(
              children: [
                Icon(Icons.handshake, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'പരസ്പരം സ്വീകരിച്ച വിവാഹാലോചന (Accepted Proposal)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.verified, color: Colors.amberAccent, size: 18),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Candidate Photo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 90,
                        height: 105,
                        child: profile.photoUrl.isNotEmpty
                            ? WatermarkedImage(
                                imageUrl: profile.photoUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Candidate Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile.name}, ${profile.age} വയസ്സ്',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF000080),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'പിതാവ്: ${fatherClan?.type ?? "PANDI"} (${fatherClan?.name ?? profile.fatherTharavadu ?? "—"})\nമാതാവ്: ${motherClan?.type ?? "BANDHU"} (${motherClan?.name ?? profile.motherTharavadu ?? "—"})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  profile.region.isNotEmpty
                                      ? profile.region
                                      : 'Wayanad',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (profile.houseName != null &&
                              profile.houseName!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.home,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    profile.houseName!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // ── Google Maps Direction Action Button ──
                NavigateToHouseButton(
                  profile: profile,
                  isMutualAcceptedOverride: true,
                  margin: const EdgeInsets.only(bottom: 8),
                ),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap ??
                            () {
                              Navigator.pushNamed(
                                context,
                                '/profile_detail',
                                arguments: profile.id,
                              );
                            },
                        icon: const Icon(Icons.person, size: 16),
                        label: const Text(
                          'പ്രൊഫൈൽ കാണുക',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF000080),
                          side: const BorderSide(color: Color(0xFF000080)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (onChat != null) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: onChat,
                        icon: const Icon(Icons.chat, color: Color(0xFF1B8C4E)),
                        tooltip: 'ചാറ്റ് ചെയ്യുക',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8C4E).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
