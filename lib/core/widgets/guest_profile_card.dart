import 'package:flutter/material.dart';
import '../models/models.dart';
import 'universal_profile_card.dart';

export 'universal_profile_card.dart';

/// Legacy alias / wrapper pointing to [UniversalProfileCard] in guest mode.
class GuestProfileCard extends StatelessWidget {
  final UserProfile? profile;
  final Map<String, dynamic>? rawProfileData;
  final bool isGrid;
  final VoidCallback? onRegisterLogin;

  const GuestProfileCard({
    super.key,
    this.profile,
    this.rawProfileData,
    this.isGrid = false,
    this.onRegisterLogin,
  }) : assert(
         profile != null || rawProfileData != null,
         'Either profile or rawProfileData must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return UniversalProfileCard(
      profile: profile,
      rawProfileData: rawProfileData,
      isGuest: true,
      isGrid: isGrid,
      onRegisterLogin: onRegisterLogin,
    );
  }
}
