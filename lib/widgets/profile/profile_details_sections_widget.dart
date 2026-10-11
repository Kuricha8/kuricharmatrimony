import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../features/clan_feed/tharavadu_list.dart';
import 'locked_phone_number_widget.dart';

class ProfileDetailsSectionsWidget extends StatelessWidget {
  final UserProfile me;

  const ProfileDetailsSectionsWidget({super.key, required this.me});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Personal & Physical Details
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      'Personal & Physical Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (me.fatherName != null && me.fatherName!.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F0FE),
                      child: Icon(Icons.man, color: Color(0xFF000080)),
                    ),
                    title: const Text(
                      'Father\'s Name',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      me.fatherName!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                if (me.motherName != null && me.motherName!.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFCE8E6),
                      child: Icon(Icons.woman, color: Colors.redAccent),
                    ),
                    title: const Text(
                      'Mother\'s Name',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      me.motherName!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                if (me.houseName != null && me.houseName!.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'House Name',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      me.houseName!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (me.height != null || me.weight != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Height / Weight',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      '${me.height ?? "-"} / ${me.weight ?? "-"}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (me.bloodGroup != null ||
                    me.physicalStatus != 'Normal / Fit')
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Blood Group / Physical Status',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      '${me.bloodGroup ?? "-"} / ${me.physicalStatus}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (me.job.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Occupation',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      me.job,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (me.bio != null && me.bio!.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'About Me',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      me.bio!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Locked Clan Information Card
        ListenableBuilder(
          listenable: TharavaduService.instance,
          builder: (context, _) {
            final String fatherSubtitle =
                (me.fatherTharavadu != null &&
                    me.fatherTharavadu!.trim().isNotEmpty)
                ? me.fatherTharavadu!.trim()
                : 'രേഖപ്പെടുത്തിയിട്ടില്ല';

            final String motherSubtitle =
                (me.motherTharavadu != null &&
                    me.motherTharavadu!.trim().isNotEmpty)
                ? me.motherTharavadu!.trim()
                : 'രേഖപ്പെടുത്തിയിട്ടില്ല';

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Locked Lineage Info',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Father and Mother clans cannot be changed after registration as they alter the exogamy matching rules and out-of-caste status.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 24),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F0FE),
                        child: Icon(Icons.shield, color: Color(0xFF000080)),
                      ),
                      title: const Text(
                        'Father\'s Clan',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      subtitle: Text(
                        fatherSubtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000080),
                        ),
                      ),
                    ),

                    const Divider(height: 16),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFCE8E6),
                        child: Icon(Icons.shield, color: Colors.redAccent),
                      ),
                      title: const Text(
                        'Mother\'s Clan',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      subtitle: Text(
                        motherSubtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        if (me.maritalStatus != MaritalStatus.first) ...[
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.family_restroom,
                        size: 18,
                        color: Colors.indigo,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Marital & Family Preferences',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (me.gender == Gender.female)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Has Children',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      subtitle: Text(
                        me.hasChildren ? 'Yes (${me.childrenCount})' : 'No',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Willing to Accept Partner\'s Children',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      me.acceptChildrenStatus == 'YES_WILLING' ? 'Yes' : 'No',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (me.adoptionPreference != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Adoption Preference',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      subtitle: Text(
                        me.adoptionPreference!.replaceAll('_', ' '),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        LockedPhoneNumberWidget(
          targetUserId: me.id,
          phoneNumber: me.gender == Gender.female
              ? (me.guardianPhone?.isNotEmpty == true
                    ? me.guardianPhone
                    : me.publicDisplayNumber)
              : (me.publicDisplayNumber?.isNotEmpty == true
                    ? me.publicDisplayNumber
                    : me.guardianPhone),
        ),
      ],
    );
  }
}
