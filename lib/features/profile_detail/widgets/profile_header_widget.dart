import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/services/matching_service.dart';
import '../../../core/widgets/watermarked_image.dart';
import '../../../core/widgets/fullscreen_image_viewer.dart';
import '../../../core/security/guest_security_service.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final UserProfile profile;
  final UserProfile? me;
  final bool isShortlisted;
  final VoidCallback onToggleShortlist;

  const ProfileHeaderWidget({
    super.key,
    required this.profile,
    required this.me,
    required this.isShortlisted,
    required this.onToggleShortlist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGuest = GuestSecurityService.isGuest(me);
    final isLoggedIn = !isGuest;
    final allPhotos = [profile.photoUrl, ...profile.additionalPhotos];

    final screenWidth = MediaQuery.of(context).size.width;
    final photoWidth = screenWidth > 500 ? 400.0 : screenWidth * 0.9;
    final photoHeight = photoWidth * 1.25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (me != null && me!.id != profile.id && me!.gender != profile.gender)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.pink.shade200),
                ),
                child: Text(
                  'Match Score: ${MatchingService.calculateSoftMatchScore(me!.gender == Gender.male ? me! : profile, me!.gender == Gender.male ? profile : me!)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Hero(
                tag: 'avatar_${profile.id}',
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => FullscreenImageViewer(
                          imageUrls: allPhotos,
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: photoWidth,
                    height: photoHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: profile.photoUrl.startsWith('http')
                          ? WatermarkedImage(
                              imageUrl: profile.photoUrl,
                              width: photoWidth,
                              height: photoHeight,
                            )
                          : Image.asset(
                              'assets/images/default_avatar.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ),
              if (isLoggedIn && me!.id != profile.id)
                Positioned(
                  top: -10,
                  right: -10,
                  child: FloatingActionButton.small(
                    heroTag: 'cart_btn_${profile.id}',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.amber,
                    elevation: 4,
                    onPressed: onToggleShortlist,
                    child: Icon(
                      isShortlisted ? Icons.star : Icons.star_border,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (profile.additionalPhotos.isNotEmpty) ...[
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: profile.additionalPhotos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => FullscreenImageViewer(
                          imageUrls: allPhotos,
                          initialIndex: index + 1,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: WatermarkedImage(
                        imageUrl: profile.additionalPhotos[index],
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Text(
                profile.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF333333),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'ID: KM-${profile.id.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildTrustBadgeChip(profile),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cake,
                        size: 20,
                        color: Color(0xFF5C3E00),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${profile.age} Yrs',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF5C3E00),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.work,
                        size: 20,
                        color: Color(0xFF5C3E00),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          profile.job.isNotEmpty ? profile.job : "No Job",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF5C3E00),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    profile.region.isNotEmpty ? profile.region : "Wayanad",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadgeChip(UserProfile profile) {
    if (profile.isGoldTrust) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, size: 16, color: Color(0xFF5C3E00)),
            const SizedBox(width: 6),
            Text(
              '🥇 ഗോൾഡ് ട്രസ്റ്റ് മുദ്ര (Verified by ${profile.elderVouchesCount > 0 ? profile.elderVouchesCount : 5} Elders)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5C3E00),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    } else if (profile.isSilverTrust) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEEEEEE), Color(0xFFBDBDBD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield, size: 16, color: Color(0xFF424242)),
            const SizedBox(width: 6),
            Text(
              '🥈 സിൽവർ ട്രസ്റ്റ് (${profile.elderVouchesCount}/5 മൂപ്പൻ സാക്ഷ്യം)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      );
    } else {
      final elderCount = profile.elderVouchesCount;
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_outlined,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              '$elderCount/5 മൂപ്പന്മാരുടെ സാക്ഷ്യപത്രം',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }
  }
}
