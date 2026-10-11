import 'package:flutter/material.dart';

class KinshipResult {
  final bool isCrossCousinMatch;
  final bool isExogamyValid;
  final String relationshipMalayalam;
  final String description;
  final Color badgeColor;

  KinshipResult({
    required this.isCrossCousinMatch,
    required this.isExogamyValid,
    required this.relationshipMalayalam,
    required this.description,
    required this.badgeColor,
  });
}

/// Kinship & Kin Cross-Cousin Matching Resolver Engine for Kurichiyar Community
class KinshipMatchResolver {
  /// Maps relationship terms dynamically based on clan pairings and gender
  static KinshipResult resolveKinship({
    required String userGender,
    required String targetGender,
    required String userMaternalClan,
    required String targetMaternalClan,
    required String userPaternalClan,
    required String targetPaternalClan,
    required bool isCommunityMember,
  }) {
    // 1. Exogamy Gate: Non-community profiles are excluded and lineage is terminated
    if (!isCommunityMember) {
      return KinshipResult(
        isCrossCousinMatch: false,
        isExogamyValid: false,
        relationshipMalayalam: 'സമുദായംഗമല്ല',
        description:
            'കുറിച്ച്യർ സമുദായത്തിന് പുറത്തുള്ള വ്യക്തി (Exogamy Terminated)',
        badgeColor: Colors.grey,
      );
    }

    // 2. Same Maternal Clan Check (Sagothara Clan - Strict Prohibition)
    if (userMaternalClan.isNotEmpty &&
        targetMaternalClan.isNotEmpty &&
        userMaternalClan.trim().toLowerCase() ==
            targetMaternalClan.trim().toLowerCase()) {
      return KinshipResult(
        isCrossCousinMatch: false,
        isExogamyValid: false,
        relationshipMalayalam: 'സഹോദര കുലം (Prohibited)',
        description: 'ഒരേ തറവാട് / മാതൃ കുലം. പരമ്പരാഗതമായി വിവാഹം അസാധുവാണ്.',
        badgeColor: Colors.red.shade700,
      );
    }

    // 3. Cross-Cousin Match (Ammavan/Ammai Child Pairing)
    // Mother's Clan matches Target's Father Clan or vice versa
    final bool isCrossCousin =
        (userMaternalClan.isNotEmpty &&
            userMaternalClan.trim().toLowerCase() ==
                targetPaternalClan.trim().toLowerCase()) ||
        (userPaternalClan.isNotEmpty &&
            userPaternalClan.trim().toLowerCase() ==
                targetMaternalClan.trim().toLowerCase());

    if (isCrossCousin) {
      final term = targetGender.toLowerCase() == 'female'
          ? 'മച്ചിനിച്ചി'
          : 'മച്ചിനൻ';
      return KinshipResult(
        isCrossCousinMatch: true,
        isExogamyValid: true,
        relationshipMalayalam: '$term (Cross-Cousin)',
        description:
            'അമ്മാവന്റെ / അമ്മായിയുടെ മകൾ/മകൻ. പരമ്പരാഗതമായി ഏറ്റവും അനുയോജ്യമായ വിവാഹബന്ധം.',
        badgeColor: Colors.green.shade700,
      );
    }

    // 4. In-Law / Brother-in-Law Linkage
    if (userPaternalClan.isNotEmpty &&
        targetPaternalClan.isNotEmpty &&
        userPaternalClan.trim().toLowerCase() ==
            targetPaternalClan.trim().toLowerCase()) {
      final term = targetGender.toLowerCase() == 'female'
          ? 'സഹോദരി / നാത്തൂൻ'
          : 'അളിയൻ';
      return KinshipResult(
        isCrossCousinMatch: false,
        isExogamyValid: true,
        relationshipMalayalam: term,
        description: 'പിതൃ തറവാട് ബന്ധമുള്ള കണ്ണി (In-law Lineage)',
        badgeColor: Colors.blue.shade700,
      );
    }

    // 5. General Exogamous Match
    return KinshipResult(
      isCrossCousinMatch: false,
      isExogamyValid: true,
      relationshipMalayalam: 'ബന്ധു കുലം',
      description: 'സാധുവായ ബാന്ധവ തറവാട് അനുയോജ്യത.',
      badgeColor: Colors.teal.shade700,
    );
  }
}
