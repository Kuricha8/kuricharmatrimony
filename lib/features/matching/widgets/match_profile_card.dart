import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/mock_data.dart';
import '../../../core/services/matching_service.dart';
import '../../../core/widgets/fullscreen_image_viewer.dart';
import '../../../core/widgets/interest_toggle_button.dart';
import '../../clan_feed/tharavadu_list.dart';
import '../controllers/matching_controller.dart';
import '../../../core/widgets/navigate_to_house_button.dart';
import '../../../core/services/kinship_service.dart';
import '../../../core/widgets/kinship_compatibility_badge.dart';
import '../../../core/widgets/universal_profile_card.dart';

class MatchProfileCard extends StatelessWidget {
  final UserProfile profile;
  final MatchingController controller;

  const MatchProfileCard({
    super.key,
    required this.profile,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final me = MockData().currentUser!;
    final fatherClan = getClanById(profile.fatherClanId);
    final motherClan = getClanById(profile.motherClanId);
    final matchScore = MatchingService.calculateMatchScore(me, profile);
    final kinshipResult =
        KinshipService.instance.checkMoietyCompatibility(me, profile);

    return UniversalProfileCard(
      profile: profile,
      isVip: profile.isVip,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      topLeadingBadge: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user,
              color: Colors.greenAccent,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              profile.isOutOfCaste
                  ? 'Out of Caste Compatible'
                  : 'In-Caste Compatible',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      topTrailingBadge: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.pinkAccent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              '$matchScore% Match',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      trailingNameWidget: IconButton(
        icon: Icon(
          controller.shortlistedIds.contains(profile.id)
              ? Icons.star
              : Icons.star_border,
          color: Colors.amber,
          size: 28,
        ),
        onPressed: () => controller.toggleShortlist(context, profile),
      ),
      extraDetails: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildAgeDiffTag(me.age, profile.age),
            _buildMaritalStatusTag(profile),
          ],
        ),
        if (profile.isGoldTrust)
          _buildGoldTrustBadge(profile.elderVouchesCount)
        else if (profile.isSilverTrust)
          _buildSilverTrustBadge(profile.elderVouchesCount),
        const SizedBox(height: 6),
        KinshipCompatibilityBadge(
          result: kinshipResult,
          isCompact: true,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    KinshipCompatibilityBadge(
                      result: kinshipResult,
                      isCompact: false,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.account_balance,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Father: ${(fatherClan?.displayName ?? fatherClan?.name ?? profile.fatherTharavadu ?? "").trim().isNotEmpty ? (fatherClan?.displayName ?? fatherClan?.name ?? profile.fatherTharavadu!).trim() : "—"} | Mother: ${(motherClan?.displayName ?? motherClan?.name ?? profile.motherTharavadu ?? profile.mothersTarawad ?? "").trim().isNotEmpty ? (motherClan?.displayName ?? motherClan?.name ?? profile.motherTharavadu ?? profile.mothersTarawad!).trim() : "—"}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.school, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              profile.job.isNotEmpty
                  ? '${profile.educationLevel ?? ''} (${profile.job})'
                  : (profile.educationLevel ?? 'Education N/A'),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
      actionFooter: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.handleSkip(context, profile),
                  icon: const Icon(
                    Icons.skip_next,
                    size: 18,
                    color: Colors.grey,
                  ),
                  label: const Text(
                    '⏭️ അടുത്ത പ്രൊഫൈൽ / സ്കിപ്പ്',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/profile_detail',
                      arguments: profile.id,
                    );
                  },
                  icon: const Icon(
                    Icons.visibility,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'വിശദാംശങ്ങൾ കാണുക',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InterestToggleButton(targetProfile: profile, fullWidth: true),
          NavigateToHouseButton(profile: profile),
        ],
      ),
      onTap: () {
        final url = profile.photoUrl.isNotEmpty
            ? profile.photoUrl
            : 'https://placehold.co/150';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => FullscreenImageViewer(
              imageUrls: [url, ...profile.additionalPhotos],
              initialIndex: 0,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgeDiffTag(int myAge, int candAge) {
    final ageDiff = (myAge - candAge).abs();
    final String text;
    final Color color;
    if (myAge == candAge) {
      text = 'Same Age';
      color = Colors.teal.shade700;
    } else if (candAge < myAge) {
      text = '$ageDiff Years Younger';
      color = Colors.green.shade700;
    } else {
      text = '$ageDiff Years Older';
      color = Colors.blue.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMaritalStatusTag(UserProfile profile) {
    final String text;
    final Color color;
    if (profile.maritalStatus == MaritalStatus.first) {
      text = 'Never Married';
      color = Colors.blueGrey.shade700;
    } else {
      color = Colors.pink.shade700;
      text = profile.hasChildren
          ? 'Remarriage (With Children)'
          : 'Remarriage (No Children)';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGoldTrustBadge(int elderCount) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 13, color: Color(0xFF5C3E00)),
          const SizedBox(width: 4),
          Text(
            '🥇 ഗോൾഡ് ട്രസ്റ്റ് (${elderCount > 0 ? elderCount : 5} മൂപ്പന്മാർ)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
              color: Color(0xFF5C3E00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSilverTrustBadge(int elderCount) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEEEEE), Color(0xFFBDBDBD)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield, size: 13, color: Color(0xFF424242)),
          const SizedBox(width: 4),
          Text(
            '🥈 സിൽവർ ട്രസ്റ്റ് ($elderCount/5 മൂപ്പന്മാർ)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
