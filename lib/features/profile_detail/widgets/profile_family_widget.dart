import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../clan_feed/tharavadu_list.dart';

class ProfileFamilyWidget extends StatelessWidget {
  final UserProfile profile;
  final bool isGuest;
  final bool isUnlocked;
  final int adViewsCount;
  final VoidCallback onWatchAdToUnlock;
  final VoidCallback onUpgrade;

  const ProfileFamilyWidget({
    super.key,
    required this.profile,
    required this.isGuest,
    this.isUnlocked = false,
    this.adViewsCount = 0,
    required this.onWatchAdToUnlock,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TharavaduService.instance,
      builder: (context, _) {
        final fatherClan =
            getClanById(profile.fatherClanId) ??
            (profile.fatherTharavadu != null &&
                    profile.fatherTharavadu!.isNotEmpty
                ? getClanByName(profile.fatherTharavadu!)
                : null);
        final motherClan =
            getClanById(profile.motherClanId) ??
            (profile.motherTharavadu != null &&
                    profile.motherTharavadu!.isNotEmpty
                ? getClanByName(profile.motherTharavadu!)
                : null);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lineage Details (തറവാട് വിവരങ്ങൾ)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF000080),
                      ),
                    ),
                    if (!isUnlocked && !isGuest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 12, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'Locked',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Divider(height: 24),
                if (isGuest) ...[
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.lock, color: Colors.grey, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Sign In to view lineage details',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ] else if (profile.verificationStatus != 'approved') ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.lock, color: Colors.orange, size: 30),
                          SizedBox(height: 10),
                          Text(
                            "അഡ്മിൻ പരിശോധനയ്ക്ക് ശേഷം മാത്രം ലഭ്യമാകും",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (!isUnlocked) ...[
                  // Free user locked Tharavadu state
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lock_clock,
                          size: 32,
                          color: Color(0xFF5C3E00),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'തറവാട് വിവരങ്ങൾ ലഭ്യമാകാൻ പ്ലാൻ അപ്‌ഗ്രേഡ് ചെയ്യുക',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF5C3E00),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'അല്ലെങ്കിൽ 3 പരസ്യങ്ങൾ കണ്ടു സൗജന്യമായി ഈ പ്രൊഫൈലിന്റെ തറവാട് കാണാം:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: onWatchAdToUnlock,
                                icon: const Icon(
                                  Icons.play_circle_fill,
                                  size: 16,
                                ),
                                label: Text(
                                  '3 പരസ്യങ്ങൾ കാണുക ($adViewsCount/3 Ads)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF000080),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: onUpgrade,
                          icon: const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          label: const Text(
                            'പ്ലാൻ അപ്‌ഗ്രേഡ് ചെയ്യുക (Upgrade Plan)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5C3E00),
                            side: const BorderSide(color: Color(0xFF5C3E00)),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F0FE),
                      child: Icon(Icons.man, color: Color(0xFF000080)),
                    ),
                    title: const Text(
                      'Father\'s Name & Clan',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fatherName != null &&
                                  profile.fatherName!.isNotEmpty
                              ? profile.fatherName!
                              : 'രേഖപ്പെടുത്തിയിട്ടില്ല',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          fatherClan != null
                              ? '${fatherClan.type.toUpperCase()} (${fatherClan.nameMl.isNotEmpty ? fatherClan.nameMl : fatherClan.name})'
                              : (profile.fatherTharavadu != null &&
                                        profile.fatherTharavadu!.isNotEmpty
                                    ? profile.fatherTharavadu!
                                    : 'രേഖപ്പെടുത്തിയിട്ടില്ല'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000080),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFCE8E6),
                      child: Icon(Icons.woman, color: Colors.redAccent),
                    ),
                    title: const Text(
                      'Mother\'s Name & Clan',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.motherName != null &&
                                  profile.motherName!.isNotEmpty
                              ? profile.motherName!
                              : 'രേഖപ്പെടുത്തിയിട്ടില്ല',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          motherClan != null
                              ? '${motherClan.type.toUpperCase()} (${motherClan.nameMl.isNotEmpty ? motherClan.nameMl : motherClan.name})'
                              : (profile.motherTharavadu != null &&
                                        profile.motherTharavadu!.isNotEmpty
                                    ? profile.motherTharavadu!
                                    : 'രേഖപ്പെടുത്തിയിട്ടില്ല'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
