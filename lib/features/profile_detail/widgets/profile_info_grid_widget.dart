import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../widgets/profile/locked_phone_number_widget.dart';
import '../../../widgets/profile/paywall_privacy_lock_card.dart';
import '../../../core/widgets/navigate_to_house_button.dart';

class ProfileInfoGridWidget extends StatelessWidget {
  final UserProfile profile;
  final bool isGuest;
  final bool isLocked;
  final bool isPhoneRevealed;
  final bool isMutualAccepted;
  final VoidCallback onUpgrade;
  final VoidCallback onRevealPhone;

  const ProfileInfoGridWidget({
    super.key,
    required this.profile,
    required this.isGuest,
    required this.isLocked,
    required this.isPhoneRevealed,
    this.isMutualAccepted = false,
    required this.onUpgrade,
    required this.onRevealPhone,
  });

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isLockedRow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: isLockedRow ? onUpgrade : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            isLockedRow
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        'ലഭ്യമാകാൻ പ്ലാൻ അപ്‌ഗ്രേഡ് ചെയ്യുക',
                        style: TextStyle(
                          color: Colors.amber,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Details (അടിസ്ഥാന വിവരങ്ങൾ)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF000080),
              ),
            ),
            _buildDetailRow(
              'Marital Status',
              profile.maritalStatus.name.toUpperCase(),
            ),
            _buildDetailRow(
              'Education (വിദ്യാഭ്യാസം)',
              profile.educationLevel ?? 'N/A',
            ),
            _buildDetailRow(
              'Height / Weight (ഉയരം / ഭാരം)',
              '${profile.height ?? "-"} / ${profile.weight ?? "-"}',
            ),
            _buildDetailRow(
              'Blood Group (രക്തഗ്രൂപ്പ്)',
              profile.bloodGroup ?? '-',
            ),
            _buildDetailRow(
              'Physical Status',
              profile.physicalStatus,
            ),
            if (profile.marriageType != null &&
                profile.marriageType!.isNotEmpty)
              _buildDetailRow('Marriage Type', profile.marriageType!),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Annual Income / Job (തൊഴിൽ)',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Row(
                    children: [
                      Text(
                        profile.annualIncome?.isNotEmpty == true
                            ? profile.annualIncome!
                            : (profile.profession?.isNotEmpty == true
                                ? profile.profession!
                                : 'N/A'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (profile.isJobVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Paywall & Privacy Lock section for Contact & Precise Location
            if (isLocked) ...[
              const SizedBox(height: 12),
              PaywallPrivacyLockCard(
                onUpgrade: onUpgrade,
              ),
            ] else ...[
              const Divider(height: 24),
              const Text(
                'Location & Address (വിലാസ വിവരങ്ങൾ)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF000080),
                ),
              ),
              const SizedBox(height: 6),
              _buildDetailRow(
                'Native Place / Region (സ്വദേശം / പ്രദേശം)',
                profile.region.isNotEmpty ? profile.region : 'Wayanad',
              ),
              if (profile.houseName != null && profile.houseName!.isNotEmpty)
                _buildDetailRow(
                  'House Name / Address (വീട്ടുപേര് / വിലാസം)',
                  profile.houseName!,
                ),
              // Navigate to House (Google Maps) Button (Subject to mutual consent/approval)
              NavigateToHouseButton(
                profile: profile,
                isMutualAcceptedOverride: isMutualAccepted,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
              ),
            ],

            if (profile.hasFamilyRestriction) ...[
              const Divider(height: 16),
              const Text(
                'Family Restrictions (കുടുംബ നിയന്ത്രണങ്ങൾ)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Mother\'s Tarawad',
                profile.mothersTarawad ?? 'N/A',
              ),
              _buildDetailRow(
                'Restricted Families',
                profile.restrictedFamilies.isNotEmpty
                    ? profile.restrictedFamilies.join(', ')
                    : 'None',
              ),
            ],

            if (profile.maritalStatus != MaritalStatus.first) ...[
              const Divider(height: 16),
              const Text(
                'Second Marriage Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Has Children',
                profile.hasChildren ? 'Yes' : 'No',
              ),
              if (profile.hasChildren)
                _buildDetailRow(
                  'Accepts Children',
                  profile.readyToAcceptChildren ? 'Yes' : 'No',
                ),
              if (profile.acceptChildrenStatus != null &&
                  profile.acceptChildrenStatus!.isNotEmpty)
                _buildDetailRow(
                  'Children Status',
                  profile.acceptChildrenStatus!,
                ),
              if (profile.adoptionPreference != null &&
                  profile.adoptionPreference!.isNotEmpty)
                _buildDetailRow(
                  'Adoption Preference',
                  profile.adoptionPreference!,
                ),
            ] else ...[
              if (profile.firstMarriageOpenToRemarriage != null ||
                  profile.firstMarriageAdoptChildren != null) ...[
                const Divider(height: 16),
                const Text(
                  'Marriage Preferences',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 8),
                if (profile.firstMarriageOpenToRemarriage != null &&
                    profile.firstMarriageOpenToRemarriage!.isNotEmpty)
                  _buildDetailRow(
                    'Open to Remarriage?',
                    profile.firstMarriageOpenToRemarriage!,
                  ),
                if (profile.firstMarriageAdoptChildren != null &&
                    profile.firstMarriageAdoptChildren!.isNotEmpty)
                  _buildDetailRow(
                    'Adoption Preference',
                    profile.firstMarriageAdoptChildren!,
                  ),
                if (profile.firstMarriageMaxChildren != null &&
                    profile.firstMarriageMaxChildren!.isNotEmpty)
                  _buildDetailRow(
                    'Max Children Pref.',
                    profile.firstMarriageMaxChildren!,
                  ),
              ],
            ],

            if (profile.groomStayWifeHouse != null ||
                profile.brideHusbandStayHome != null) ...[
              const Divider(height: 16),
              const Text(
                'Post-Marriage Living Arrangements',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              if (profile.gender == Gender.male &&
                  profile.groomStayWifeHouse != null &&
                  profile.groomStayWifeHouse!.isNotEmpty)
                _buildDetailRow(
                  'Stay at Wife\'s House?',
                  profile.groomStayWifeHouse!,
                ),
              if (profile.gender == Gender.female &&
                  profile.brideHusbandStayHome != null &&
                  profile.brideHusbandStayHome!.isNotEmpty)
                _buildDetailRow(
                  'Husband Stay at Home?',
                  profile.brideHusbandStayHome!,
                ),
            ],

            if (!isLocked) ...[
              const Divider(height: 24),
              LockedPhoneNumberWidget(
                targetUserId: profile.id,
                phoneNumber: profile.gender == Gender.female
                    ? (profile.guardianPhone?.isNotEmpty == true
                          ? profile.guardianPhone
                          : profile.publicDisplayNumber)
                    : (profile.publicDisplayNumber?.isNotEmpty == true
                          ? profile.publicDisplayNumber
                          : profile.guardianPhone),
                isAlreadyUnlocked: true,
                label: profile.gender == Gender.female
                    ? 'Guardian Phone (രക്ഷാധികാരിയുടെ ഫോൺ)'
                    : 'Phone Number (ഫോൺ നമ്പർ)',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
