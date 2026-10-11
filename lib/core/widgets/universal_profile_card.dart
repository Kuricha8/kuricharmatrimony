import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../security/guest_security_service.dart';
import '../services/guest_favorites_service.dart';
import '../../features/profile_detail/profile_detail_page.dart';
import 'watermarked_image.dart';

/// Universal Standardized Profile Card across the entire app.
///
/// Features:
/// 1. Card Container:
///    - Rounded corners: BorderRadius.circular(20)
///    - Subtle soft shadow: BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
///    - Clean margins and padding
///    - VIP styling support (golden border if VIP)
/// 2. Image Section (Top):
///    - ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))
///    - AspectRatio: 3 / 4 (or 4 / 5)
///    - WatermarkedImage / Image.network with fit: BoxFit.cover and alignment: Alignment.topCenter
///    - Subtle dark top gradient overlay to make top action badges clearly legible without obscuring faces
///    - Customizable topLeadingBadge and topTrailingBadge (or default lock badge if isGuest: true)
///    - Interactive guest-friendly Heart / Favorite button overlay (❤️)
/// 3. Info Section (Bottom):
///    - Light beige / warm white background (Color(0xFFFFFBF5))
///    - Bold large name: checks all candidate name fields, never defaults to Unknown
///    - Subtitle line: Home icon (Icons.home_outlined), Age with "(.. Yrs)", Tharavadu / Clan name,
///      and Location separated by bullets (•)
///    - Action Row: Guest-friendly Like button (with active toggle state) and Share button
class UniversalProfileCard extends StatelessWidget {
  final UserProfile? profile;
  final Map<String, dynamic>? rawProfileData;
  final bool isGuest;
  final bool isGrid;
  final double aspectRatio;
  final EdgeInsetsGeometry margin;
  final Widget? topLeadingBadge;
  final Widget? topTrailingBadge;
  final Widget? trailingNameWidget;
  final List<Widget>? extraDetails;
  final Widget? actionFooter;
  final VoidCallback? onTap;
  final VoidCallback? onRegisterLogin;
  final bool? isVip;
  final Color backgroundColor;
  final bool showLikeOverlay;
  final bool showDefaultActionRow;

  const UniversalProfileCard({
    super.key,
    this.profile,
    this.rawProfileData,
    this.isGuest = false,
    this.isGrid = false,
    this.aspectRatio = 3 / 4,
    this.margin = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.topLeadingBadge,
    this.topTrailingBadge,
    this.trailingNameWidget,
    this.extraDetails,
    this.actionFooter,
    this.onTap,
    this.onRegisterLogin,
    this.isVip,
    this.backgroundColor = const Color(0xFFFFFBF5),
    this.showLikeOverlay = true,
    this.showDefaultActionRow = true,
  }) : assert(
          profile != null || rawProfileData != null,
          'Either profile or rawProfileData must be provided',
        );

  bool get _isVipUser =>
      isVip ??
      profile?.isVip ??
      rawProfileData?['is_vip'] == true ||
      rawProfileData?['is_vip']?.toString().toLowerCase() == 'true';

  String get _profileId {
    if (profile != null && profile!.id.isNotEmpty) return profile!.id;
    return (rawProfileData?['id'] ??
            rawProfileData?['profile_id'] ??
            rawProfileData?['user_id'] ??
            rawProfileData?['uuid'] ??
            '')
        .toString();
  }

  String get _name {
    final List<dynamic> candidates = [
      profile?.fullName,
      profile?.name,
      rawProfileData?['full_name'],
      rawProfileData?['fullName'],
      rawProfileData?['display_name'],
      rawProfileData?['displayName'],
      rawProfileData?['name'],
      rawProfileData?['candidate_name'],
      rawProfileData?['candidateName'],
      rawProfileData?['user_name'],
      rawProfileData?['userName'],
      rawProfileData?['member_name'],
      rawProfileData?['memberName'],
      rawProfileData?['first_name'],
      rawProfileData?['firstName'],
    ];

    for (final c in candidates) {
      if (c == null) continue;
      final s = c.toString().trim();
      final lower = s.toLowerCase();
      if (s.isNotEmpty &&
          lower != 'unknown' &&
          lower != 'null' &&
          lower != 'അംഗം' &&
          lower != 'undefined' &&
          lower != 'guest' &&
          lower != 'guest user') {
        return s;
      }
    }

    return 'അംഗം';
  }

  String get _age {
    final candidateAge = profile?.age.toString() ??
        rawProfileData?['age']?.toString();

    if (candidateAge != null &&
        candidateAge.trim().isNotEmpty &&
        candidateAge != '0' &&
        candidateAge != 'null') {
      return candidateAge.trim();
    }
    return '25';
  }

  String? get _clanOrTharavadu {
    String? clan = (profile?.tharavaduName.isNotEmpty == true ? profile?.tharavaduName : null) ??
        profile?.clan ??
        profile?.motherTharavadu ??
        profile?.fatherTharavadu ??
        rawProfileData?['tharavadu']?.toString() ??
        rawProfileData?['tharavad']?.toString() ??
        rawProfileData?['mother_tharavadu']?.toString() ??
        rawProfileData?['father_tharavadu']?.toString() ??
        rawProfileData?['clan_name']?.toString() ??
        rawProfileData?['clan']?.toString();

    if (clan != null &&
        clan.trim().isNotEmpty &&
        clan.trim().toLowerCase() != 'null' &&
        clan.trim().toLowerCase() != 'unknown') {
      return clan.trim();
    }
    return null;
  }

  String? get _location {
    String? loc = (profile?.region.isNotEmpty == true ? profile?.region : null) ??
        profile?.familyDetails.prefDistrict ??
        rawProfileData?['district']?.toString() ??
        rawProfileData?['native_district']?.toString() ??
        rawProfileData?['location']?.toString() ??
        rawProfileData?['region']?.toString() ??
        rawProfileData?['native_place']?.toString() ??
        rawProfileData?['place']?.toString();

    if (loc != null &&
        loc.trim().isNotEmpty &&
        loc.trim().toLowerCase() != 'null' &&
        loc.trim().toLowerCase() != 'unknown') {
      return loc.trim();
    }
    return null;
  }

  String get _subtitleDetails {
    final parts = <String>[];
    parts.add('$_age വയസ്സ് ($_age Yrs)');

    final clan = _clanOrTharavadu;
    if (clan != null && clan.isNotEmpty) {
      parts.add(clan);
    }

    final loc = _location;
    if (loc != null && loc.isNotEmpty) {
      parts.add(loc);
    } else if (clan == null) {
      parts.add('വയനാട് (Wayanad)');
    }

    return parts.join(' • ');
  }

  String get _photoUrl {
    if (profile != null && profile!.photoUrl.isNotEmpty) {
      return profile!.photoUrl;
    }
    return (rawProfileData?['photo_url'] ??
            rawProfileData?['profile_photo'] ??
            rawProfileData?['media_url'] ??
            rawProfileData?['photo'] ??
            '')
        .toString();
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }

    if (isGuest) {
      GuestSecurityService.showGuestProfileAccessModal(
        context,
        onRegisterLogin: onRegisterLogin,
      );
      return;
    }

    if (profile != null && profile!.id.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileDetailPage(profileId: profile!.id),
        ),
      );
    }
  }

  Future<void> _handleFavoriteToggle(BuildContext context) async {
    final pid = _profileId;
    if (pid.isEmpty) return;

    final next = await GuestFavoritesService.instance.toggleFavorite(
      pid,
      profileName: _name,
      profile: profile,
      rawProfile: rawProfileData,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                next ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  next
                      ? '$_name താല്പര്യങ്ങളിൽ ചേർത്തു (Saved to Favorites ❤️)'
                      : '$_name താല്പര്യങ്ങളിൽ നിന്ന് ഒഴിവാക്കി',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: next ? const Color(0xFFD81B60) : Colors.grey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _handleShare() {
    final clan = _clanOrTharavadu ?? 'കുറിച്ച്യർ ഗോത്രം';
    final loc = _location ?? 'കേരളം';
    final text =
        'കുറിച്ച്യർ മാട്രിമോണി പ്രൊഫൈൽ: $_name ($_age വയസ്സ്)\n'
        'തറവാട് / ഗോത്രം: $clan\n'
        'സ്ഥലം: $loc\n\n'
        'കൂടുതൽ വിവരങ്ങൾക്ക് കുറിച്ച്യർ മാട്രിമോണി ആപ്പ് സന്ദർശിക്കുക:\n'
        'https://kurichiyarmatrimony.com';

    Share.share(text, subject: '$_name - Kurichiyar Matrimony Profile');
  }

  @override
  Widget build(BuildContext context) {
    return isGrid ? _buildGridCard(context) : _buildListCard(context);
  }

  // ── 1. Standard List Card ──
  Widget _buildListCard(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: _isVipUser
            ? Border.all(color: const Color(0xFFB8860B), width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Image Section
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo
                      WatermarkedImage(
                        imageUrl: _photoUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        constraints: const BoxConstraints.expand(),
                      ),

                      // Subtle Dark Gradient Overlay at Top
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 90,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Top Leading Badge (e.g., Caste, Verification)
                      if (topLeadingBadge != null)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: topLeadingBadge!,
                        ),

                      // Top Trailing Badge (e.g., Match score, Tier badge, or Lock badge)
                      if (topTrailingBadge != null)
                        Positioned(
                          top: 14,
                          right: 14,
                          child: topTrailingBadge!,
                        )
                      else if (isGuest)
                        Positioned(
                          top: 14,
                          right: 14,
                          child: _buildLockBadge(),
                        ),

                      // Heart overlay on bottom-right of photo
                      if (showLikeOverlay && _profileId.isNotEmpty)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: _buildFloatingHeartButton(context),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Info Section
              Container(
                color: backgroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row: Bold Actual Name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailingNameWidget != null)
                          trailingNameWidget!
                        else if (isGuest)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Subtitle Row: Home Icon • Age with "(.. Yrs)" • Tharavadu/Clan • Location
                    Row(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _subtitleDetails,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Optional Extra Details (e.g., tags, compatibility)
                    if (extraDetails != null && extraDetails!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...extraDetails!,
                    ],

                    // Action Footer or Default Guest Action Row
                    if (actionFooter != null) ...[
                      const SizedBox(height: 12),
                      actionFooter!,
                    ] else if (showDefaultActionRow) ...[
                      const SizedBox(height: 12),
                      _buildDefaultActionRow(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. Standard Grid Card ──
  Widget _buildGridCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: _isVipUser
            ? Border.all(color: const Color(0xFFB8860B), width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      WatermarkedImage(
                        imageUrl: _photoUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        constraints: const BoxConstraints.expand(),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (topLeadingBadge != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: topLeadingBadge!,
                        ),
                      if (topTrailingBadge != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: topTrailingBadge!,
                        )
                      else if (isGuest)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: const Text('🔒', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      if (showLikeOverlay && _profileId.isNotEmpty)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: _buildFloatingHeartButton(context, isCompact: true),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                color: backgroundColor,
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 13,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _subtitleDetails,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (actionFooter != null) ...[
                      const SizedBox(height: 8),
                      actionFooter!,
                    ] else if (showDefaultActionRow) ...[
                      const SizedBox(height: 8),
                      _buildCompactGridActionRow(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingHeartButton(BuildContext context, {bool isCompact = false}) {
    return ListenableBuilder(
      listenable: GuestFavoritesService.instance,
      builder: (context, _) {
        final isLiked = GuestFavoritesService.instance.isFavorite(_profileId);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleFavoriteToggle(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: EdgeInsets.all(isCompact ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLiked
                      ? Colors.redAccent.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.redAccent : Colors.white,
                size: isCompact ? 16 : 20,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultActionRow(BuildContext context) {
    return ListenableBuilder(
      listenable: GuestFavoritesService.instance,
      builder: (context, _) {
        final isLiked = GuestFavoritesService.instance.isFavorite(_profileId);
        return Row(
          children: [
            // Like Button with active toggle state
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleFavoriteToggle(context),
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? const Color(0xFFD81B60) : Colors.grey.shade700,
                  size: 18,
                ),
                label: Text(
                  isLiked ? 'താല്പര്യമുണ്ട് (Liked ❤️)' : 'താല്പര്യം (Like)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isLiked ? const Color(0xFFD81B60) : Colors.grey.shade800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isLiked
                      ? const Color(0xFFD81B60).withValues(alpha: 0.08)
                      : Colors.transparent,
                  side: BorderSide(
                    color: isLiked ? const Color(0xFFD81B60) : Colors.grey.shade300,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Optional Share Button
            IconButton.outlined(
              onPressed: _handleShare,
              icon: const Icon(Icons.share_outlined, size: 18),
              color: const Color(0xFF1E3A8A),
              style: IconButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              tooltip: 'പ്രൊഫൈൽ പങ്കിടുക (Share)',
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactGridActionRow(BuildContext context) {
    return ListenableBuilder(
      listenable: GuestFavoritesService.instance,
      builder: (context, _) {
        final isLiked = GuestFavoritesService.instance.isFavorite(_profileId);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _handleFavoriteToggle(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isLiked
                        ? const Color(0xFFD81B60).withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLiked ? const Color(0xFFD81B60) : Colors.transparent,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? const Color(0xFFD81B60) : Colors.grey.shade700,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLiked ? 'Liked' : 'Like',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLiked ? const Color(0xFFD81B60) : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: _handleShare,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.share_outlined,
                  size: 14,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'കൂടുതൽ വിവരങ്ങൾക്ക് 🔒',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
