import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../core/services/predictive_cache_service.dart';
import '../../features/profile_detail/profile_detail_page.dart';
import '../../core/services/kinship_service.dart';
import '../../core/widgets/kinship_compatibility_badge.dart';
import '../../features/clan_feed/tharavadu_list.dart';

class TharavaduProfileCardItem extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isClanMember;
  final String currentUserId;
  final Clan clan;
  final Function(String postId, bool isLiked) onLikeToggle;
  final Function(Map<String, dynamic> msg) onCommentTap;

  const TharavaduProfileCardItem({
    super.key,
    required this.msg,
    required this.isClanMember,
    required this.currentUserId,
    required this.clan,
    required this.onLikeToggle,
    required this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    final targetId =
        (msg['shared_profile_id'] ?? msg['profile_id'] ?? msg['user_id'])
            ?.toString() ??
        '';
    final profile = MockData().profiles.firstWhere(
      (p) => p.id == targetId,
      orElse: () => UserProfile(
        id: targetId,
        email: '',
        name: msg['sender_name'] ?? 'അംഗം',
        age: (msg['age'] as int?) ?? 25,
        gender: Gender.female,
        photoUrl: (msg['sender_photo'] as String?)?.isNotEmpty == true
            ? msg['sender_photo']
            : ((msg['media_url'] as String?) ?? ''),
        fatherTharavadu: 'Kurichiyar',
        motherTharavadu: 'Kurichiyar',
        maritalStatus: MaritalStatus.first,
        fatherClanId: 0,
        motherClanId: 0,
        isOutOfCaste: false,
      ),
    );

    final String photoUrl = profile.photoUrl.isNotEmpty
        ? profile.photoUrl
        : ((msg['media_url'] as String?) ??
              (msg['sender_photo'] as String?) ??
              '');

    final String rawFatherTharavad =
        (profile.fatherTharavadu != null && profile.fatherTharavadu!.isNotEmpty)
        ? profile.fatherTharavadu!
        : ((msg['father_tharavadu'] ?? msg['father_clan'])?.toString() ??
              'Kurichiyar');

    final String rawMotherTharavad =
        (profile.motherTharavadu != null && profile.motherTharavadu!.isNotEmpty)
        ? profile.motherTharavadu!
        : ((msg['mother_tharavadu'] ??
                      msg['mother_clan'] ??
                      msg['mothers_tarawad'])
                  ?.toString() ??
              'Kurichiyar');

    final motherClan = (profile.motherClanId > 0 ? getClanById(profile.motherClanId) : null) ??
        getClanByName(rawMotherTharavad);
    final String motherTharavad = motherClan?.displayName ?? rawMotherTharavad;

    final fatherClan = (profile.fatherClanId > 0 ? getClanById(profile.fatherClanId) : null) ??
        getClanByName(rawFatherTharavad);
    final String fatherTharavad = fatherClan?.displayName ?? rawFatherTharavad;

    final String deepLinkUrl = profile.id.isNotEmpty
        ? 'https://kuricharmatrimony.vercel.app/profile/${profile.id}'
        : 'https://kuricharmatrimony.vercel.app';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111111), // Dark Charcoal/Black Background
        border: Border.all(
          color: Colors.amber.shade700,
          width: 3,
        ), // Rounded Golden Borders
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Golden Header Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'kurichiyar matrimony',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Center Avatar Image with Circular Gold Ring
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.shade600, width: 3),
            ),
            child: CircleAvatar(
              radius: 54,
              backgroundColor: Colors.grey.shade900,
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Icon(
                      profile.gender == Gender.male ? Icons.man : Icons.woman,
                      size: 54,
                      color: Colors.amber.shade600,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // Candidate Details
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.amber, // Golden Name
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${profile.age} YRS',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          // Mother's Tharavad (App Rule: തറവാട്: strictly displays Mother's Tharavad)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'തറവാട്: $motherTharavad',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amberAccent,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (MockData().currentUser != null &&
              MockData().currentUser!.id != profile.id) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: KinshipCompatibilityBadge(
                result: KinshipService.instance.checkMoietyCompatibility(
                  MockData().currentUser!,
                  profile,
                ),
                isCompact: true,
              ),
            ),
          ],
          if (fatherTharavad.isNotEmpty &&
              fatherTharavad != 'Kurichiyar' &&
              fatherTharavad != 'Not Provided') ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'പിതൃ തറവാട് (Father): $fatherTharavad',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Active Scannable/Generated QR Code Centered at the Bottom
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade400, width: 2),
            ),
            child: QrImageView(
              data: deepLinkUrl,
              version: QrVersions.auto,
              size: 90.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Interactive Likes & Comments inside Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final likedBy =
                          (msg['liked_by'] as Set<String>?) ?? <String>{};

                      final bool wasLiked = likedBy.contains(currentUserId);
                      final bool isNowLiked = !wasLiked;

                      onLikeToggle(msg['id'].toString(), isNowLiked);
                    },
                    icon: Icon(
                      ((msg['liked_by'] as Set<String>?)?.contains(
                                currentUserId,
                              ) ??
                              false)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: Text(
                      '${msg['likes'] ?? 0} Likes',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.grey.shade900,
                      foregroundColor: Colors.amber,
                      side: BorderSide(color: Colors.amber.shade700, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (ctx) {
                    final commentCount =
                        (msg['comments'] as List?)?.length ?? 0;
                    final bool hasComments = commentCount > 0;
                    return Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onCommentTap(msg),
                        icon: Icon(
                          Icons.comment_outlined,
                          size: 16,
                          color: hasComments
                              ? Colors.teal.shade300
                              : Colors.amber,
                        ),
                        label: Text(
                          '$commentCount Comments',
                          style: TextStyle(
                            fontWeight: hasComments
                                ? FontWeight.w700
                                : FontWeight.bold,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          backgroundColor: hasComments
                              ? Colors.teal.withValues(alpha: 0.15)
                              : Colors.grey.shade900,
                          foregroundColor: hasComments
                              ? Colors.teal.shade300
                              : Colors.amber,
                          side: BorderSide(
                            color: hasComments
                                ? Colors.teal.shade400
                                : Colors.amber.shade700,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // View Full Profile Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Listener(
              onPointerDown: (_) {
                if (photoUrl.isNotEmpty) {
                  PredictiveCacheService.instance.prewarmUrl(context, photoUrl);
                }
              },
              child: ElevatedButton.icon(
                onPressed: () {
                  if (targetId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileDetailPage(profileId: targetId),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.person_search, size: 18),
                label: Text(
                  AppLocalizations.of(context)?.viewFullProfile ??
                      'View Full Profile',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
