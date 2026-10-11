import '../models/user_profile.dart';
import '../models/enums.dart';
import '../kurichiyar_logic_engine.dart';
import '../kurichiyar_clan_engine.dart';
import '../../features/clan_feed/tharavadu_list.dart';
import 'clan_matching_engine.dart';

export 'clan_matching_engine.dart'
    show
        LineageGroupType,
        MatchingPoolCategory,
        MoietyMatchResult,
        KinshipPoolType;

class MatchingService {
  /// Resolves the kinship pool ('pureYesMatch' or 'noMatchPool') for a profile
  static KinshipPoolType getKinshipPool(UserProfile user) =>
      ClanMatchingEngine.instance.getKinshipPool(user);
  /// Dynamically resolves moiety group ('panthi' or 'bandhu') from live Tharavadu records
  static String getMoietyGroup(String tharavaduName, {int? clanId}) {
    if (clanId != null && clanId > 0) {
      final clan = getClanById(clanId);
      if (clan != null) {
        final isBandhu = clan.type.toLowerCase() == 'bandhu' ||
            clan.groupName.contains('ബന്ധു') ||
            clan.groupName.toLowerCase().contains('bandhu');
        return isBandhu ? 'bandhu' : 'panthi';
      }
    }

    final clean = tharavaduName.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (clean.isEmpty) return 'unknown';

    // 1. Direct match by name/alias/Malayalam in live 57 Tharavadu master list
    final clanByName = getClanByName(tharavaduName);
    if (clanByName != null) {
      final isBandhu = clanByName.type.toLowerCase() == 'bandhu' ||
          clanByName.groupName.contains('ബന്ധു') ||
          clanByName.groupName.toLowerCase().contains('bandhu');
      return isBandhu ? 'bandhu' : 'panthi';
    }

    // 2. Logic engines
    final engineMoiety = KurichiyarLogicEngine.getMoiety(
      tharavaduName,
    ).toLowerCase();
    if (engineMoiety == 'panthi' || engineMoiety == 'bandhu') {
      return engineMoiety;
    }

    final clanEngineMoiety = KurichiyarClanEngine.getMoiety(
      tharavaduName,
    ).toLowerCase();
    if (clanEngineMoiety == 'panthi' || clanEngineMoiety == 'bandhu') {
      return clanEngineMoiety;
    }

    // 3. Fallback keywords
    if (clean.contains('bandhu') || clean.contains('ബന്ധു')) {
      return 'bandhu';
    }
    if (clean.contains('panthi') ||
        clean.contains('pandi') ||
        clean.contains('പന്തി')) {
      return 'panthi';
    }

    return 'unknown';
  }

  /// Resolves the strict matrilineal moiety group ('bandhu' or 'panthi') for a user profile
  static String resolveUserMoiety(UserProfile profile) {
    // 1. Check motherClanId
    if (profile.motherClanId > 0) {
      final m = getMoietyGroup('', clanId: profile.motherClanId);
      if (m == 'bandhu' || m == 'panthi') return m;
    }

    // 2. Check motherTharavadu / mothersTarawad
    final motherName =
        (profile.motherTharavadu ?? profile.mothersTarawad ?? '').trim();
    if (motherName.isNotEmpty) {
      final m = getMoietyGroup(motherName);
      if (m == 'bandhu' || m == 'panthi') return m;
    }

    // 3. Check tharavaduName
    if (profile.tharavaduName.trim().isNotEmpty) {
      final m = getMoietyGroup(profile.tharavaduName);
      if (m == 'bandhu' || m == 'panthi') return m;
    }

    // 4. Check maternalGroup getter
    final mg = profile.maternalGroup.trim().toLowerCase();
    if (mg == 'bandhu' || mg == 'panthi') return mg;

    // 5. Check ownIllamId / motherIllamId
    final illamId = profile.ownIllamId ?? profile.motherIllamId;
    if (illamId != null && illamId > 0) {
      final m = getMoietyGroup('', clanId: illamId);
      if (m == 'bandhu' || m == 'panthi') return m;
    }

    return 'unknown';
  }

  /// Returns the set of all forbidden Tharavadu IDs for this user based on cultural rules & restrictions
  static Set<int> getForbiddenTharavaduIds(
    UserProfile user, {
    bool includeEntireMoiety = true,
  }) {
    final forbidden = <int>{};
    if (includeEntireMoiety) {
      final userMoiety = resolveUserMoiety(user);
      if (userMoiety == 'bandhu') {
        for (final c in TharavaduService.bandhuClans) {
          forbidden.add(c.id);
        }
      } else if (userMoiety == 'panthi') {
        for (final c in TharavaduService.pandiClans) {
          forbidden.add(c.id);
        }
      }
    }

    // 2. User's own Mother Clan
    if (user.motherClanId > 0) forbidden.add(user.motherClanId);
    if (user.motherIllamId != null && user.motherIllamId! > 0) {
      forbidden.add(user.motherIllamId!);
    }
    if (user.ownIllamId != null && user.ownIllamId! > 0) {
      forbidden.add(user.ownIllamId!);
    }
    final momClan =
        getClanByName(user.motherTharavadu ?? user.mothersTarawad ?? '');
    if (momClan != null) forbidden.add(momClan.id);

    // 3. User's own Father Clan
    if (user.fatherClanId > 0) forbidden.add(user.fatherClanId);
    if (user.fatherIllamId != null && user.fatherIllamId! > 0) {
      forbidden.add(user.fatherIllamId!);
    }
    final dadClan = getClanByName(user.fatherTharavadu ?? '');
    if (dadClan != null) forbidden.add(dadClan.id);

    // 4. User's explicitly restricted / excluded Tharavadus (specified during registration or edit)
    forbidden.addAll(user.restrictedTharavads);
    for (final famName in user.restrictedFamilies) {
      final c = getClanByName(famName);
      if (c != null) forbidden.add(c.id);
    }

    return forbidden;
  }

  /// Returns the set of forbidden Tharavadu names/strings (normalized) for this user
  static Set<String> getForbiddenTharavaduNames(
    UserProfile user, {
    bool includeEntireMoiety = true,
  }) {
    final forbiddenNames = <String>{};
    if (includeEntireMoiety) {
      final userMoiety = resolveUserMoiety(user);
      if (userMoiety == 'bandhu') {
        for (final c in TharavaduService.bandhuClans) {
          if (c.name.isNotEmpty) forbiddenNames.add(c.name.trim().toLowerCase());
          if (c.nameMl.isNotEmpty) {
            forbiddenNames.add(c.nameMl.trim().toLowerCase());
          }
          if (c.nameEn.isNotEmpty) {
            forbiddenNames.add(c.nameEn.trim().toLowerCase());
          }
        }
      } else if (userMoiety == 'panthi') {
        for (final c in TharavaduService.pandiClans) {
          if (c.name.isNotEmpty) forbiddenNames.add(c.name.trim().toLowerCase());
          if (c.nameMl.isNotEmpty) {
            forbiddenNames.add(c.nameMl.trim().toLowerCase());
          }
          if (c.nameEn.isNotEmpty) {
            forbiddenNames.add(c.nameEn.trim().toLowerCase());
          }
        }
      }
    }

    // 2. User's own Mother Clan names
    final momName =
        (user.motherTharavadu ?? user.mothersTarawad ?? user.tharavaduName)
            .trim()
            .toLowerCase();
    if (momName.isNotEmpty) forbiddenNames.add(momName);

    // 3. User's own Father Clan names
    final dadName = (user.fatherTharavadu ?? '').trim().toLowerCase();
    if (dadName.isNotEmpty) forbiddenNames.add(dadName);

    // 4. User's explicitly restricted families
    for (final fam in user.restrictedFamilies) {
      final f = fam.trim().toLowerCase();
      if (f.isNotEmpty) forbiddenNames.add(f);
      final c = getClanByName(fam);
      if (c != null) {
        if (c.name.isNotEmpty) forbiddenNames.add(c.name.trim().toLowerCase());
        if (c.nameMl.isNotEmpty) {
          forbiddenNames.add(c.nameMl.trim().toLowerCase());
        }
      }
    }
    for (final id in user.restrictedTharavads) {
      final c = getClanById(id);
      if (c != null) {
        if (c.name.isNotEmpty) forbiddenNames.add(c.name.trim().toLowerCase());
        if (c.nameMl.isNotEmpty) {
          forbiddenNames.add(c.nameMl.trim().toLowerCase());
        }
      }
    }

    return forbiddenNames;
  }

  /// Calculates dynamic match percentage: Clan compatibility (50%) + 10 Preference Questions match (50%)
  static int calculateMatchScore(
    UserProfile me,
    UserProfile candidate, {
    List<Map<String, dynamic>>? tharavadExclusions,
  }) {
    if (!isMatchEligible(
      me,
      candidate,
      tharavadExclusions: tharavadExclusions,
    )) {
      return 0;
    }

    const int clanScore = 50;

    // 2. 10 Questions / Expectations Match (50% Maximum)
    final List<bool?> answersA = [
      me.prefJointFamily,
      me.prefRelocate,
      me.prefManageJobFamily,
      me.prefDirectTalk,
      me.prefNuclearFamily,
      me.prefShareFinances,
      me.prefNightShift,
      me.prefConsultDecisions,
      me.prefDiscloseDebts,
      me.prefTravelSocialize,
    ];

    final List<bool?> answersB = [
      candidate.prefJointFamily,
      candidate.prefRelocate,
      candidate.prefManageJobFamily,
      candidate.prefDirectTalk,
      candidate.prefNuclearFamily,
      candidate.prefShareFinances,
      candidate.prefNightShift,
      candidate.prefConsultDecisions,
      candidate.prefDiscloseDebts,
      candidate.prefTravelSocialize,
    ];

    int prefScore = 0;
    for (int i = 0; i < 10; i++) {
      if (answersA[i] != null && answersB[i] != null) {
        if (answersA[i] == answersB[i]) {
          prefScore += 5; // 5% per matching answer (10 x 5 = 50%)
        }
      } else if (answersA[i] == null && answersB[i] == null) {
        prefScore += 4; // Unset default
      } else {
        prefScore += 3; // Partial default
      }
    }

    final totalScore = clanScore + prefScore;
    return totalScore.clamp(0, 100);
  }

  static int calculateSoftMatchScore(
    UserProfile me,
    UserProfile candidate, {
    List<Map<String, dynamic>>? tharavadExclusions,
  }) {
    return calculateMatchScore(
      me,
      candidate,
      tharavadExclusions: tharavadExclusions,
    );
  }

  /// Strictly determines if candidate is eligible to be shown in discovery, matching, and search
  static bool isMatchEligible(
    UserProfile me,
    UserProfile candidate, {
    List<Map<String, dynamic>>? tharavadExclusions,
    MatchingPoolCategory? poolCategory,
  }) {
    // 1. Exclude self
    if (me.id == candidate.id) return false;
    if (me.email.isNotEmpty &&
        candidate.email.isNotEmpty &&
        me.email.toLowerCase() == candidate.email.toLowerCase()) {
      return false;
    }

    // 2. Gender Filter: Strictly Opposite Gender
    if (me.gender == candidate.gender) return false;

    // 3. Pool Isolation & Two Universes Check:
    final poolMe = ClanMatchingEngine.instance.getKinshipPool(me);
    final poolCand = ClanMatchingEngine.instance.getKinshipPool(candidate);
    if (poolMe != poolCand) {
      return false; // NO_MATCH_POOL user must NEVER appear in PURE_YES_MATCH feed, and vice versa!
    }

    // Category B ('NO_MATCH_POOL'): FULL FREEDOM within their pool without clan/moiety restrictions
    if (poolMe == KinshipPoolType.noMatchPool) {
      return _checkMaritalAndResidenceCompatibility(me, candidate);
    }

    // 4. Centralized Moiety & Dual-Parent Lineage Check via ClanMatchingEngine (Category A)
    final moietyResult = ClanMatchingEngine.instance.checkCompatibility(
      groomProfile: me,
      brideProfile: candidate,
      poolCategory: poolCategory,
    );
    if (!moietyResult.isCompatible) {
      return false;
    }

    final bool isRecalculationPool =
        moietyResult.poolCategory == MatchingPoolCategory.dualSameRecalculation;

    // 5. Incompatible / Forbidden Tharavadu Exclusion:
    // Identify logged-in user's forbidden Tharavadu list
    final forbiddenIds = getForbiddenTharavaduIds(
      me,
      includeEntireMoiety: !isRecalculationPool,
    );
    final forbiddenNames = getForbiddenTharavaduNames(
      me,
      includeEntireMoiety: !isRecalculationPool,
    );

    // Check candidate's mother clan ID
    if (candidate.motherClanId > 0 &&
        forbiddenIds.contains(candidate.motherClanId)) {
      return false;
    }
    if (candidate.motherIllamId != null &&
        candidate.motherIllamId! > 0 &&
        forbiddenIds.contains(candidate.motherIllamId!)) {
      return false;
    }
    if (candidate.ownIllamId != null &&
        candidate.ownIllamId! > 0 &&
        forbiddenIds.contains(candidate.ownIllamId!)) {
      return false;
    }

    // Check candidate's mother clan name
    final candMotherClan = (candidate.motherTharavadu ??
            candidate.mothersTarawad ??
            candidate.tharavaduName)
        .trim()
        .toLowerCase();
    if (candMotherClan.isNotEmpty) {
      if (forbiddenNames.contains(candMotherClan)) return false;
      for (final fn in forbiddenNames) {
        if (fn.length > 2 &&
            (candMotherClan == fn ||
                candMotherClan.contains(fn) ||
                fn.contains(candMotherClan))) {
          return false;
        }
      }
    }

    // Check candidate's father clan against user's restrictions
    if (candidate.fatherClanId > 0 &&
        me.restrictedTharavads.contains(candidate.fatherClanId)) {
      return false;
    }
    final candFatherClan =
        (candidate.fatherTharavadu ?? '').trim().toLowerCase();
    if (candFatherClan.isNotEmpty && me.restrictedFamilies.isNotEmpty) {
      for (final rf in me.restrictedFamilies) {
        final r = rf.trim().toLowerCase();
        if (r.isNotEmpty &&
            (candFatherClan == r ||
                candFatherClan.contains(r) ||
                r.contains(candFatherClan))) {
          return false;
        }
      }
    }

    // Cross-Clan Parent Restrictions:
    // Mother clan of user cannot match father clan of candidate and vice versa
    final myMotherClan =
        (me.motherTharavadu ?? me.mothersTarawad ?? me.tharavaduName)
            .trim()
            .toLowerCase();
    final myFatherClan = (me.fatherTharavadu ?? '').trim().toLowerCase();

    if (myMotherClan.isNotEmpty && myMotherClan == candMotherClan) return false;
    if (myMotherClan.isNotEmpty &&
        candFatherClan.isNotEmpty &&
        myMotherClan == candFatherClan) {
      return false;
    }
    if (myFatherClan.isNotEmpty &&
        candMotherClan.isNotEmpty &&
        myFatherClan == candMotherClan) {
      return false;
    }

    if (me.motherClanId > 0 && me.motherClanId == candidate.motherClanId) {
      return false;
    }
    if (me.fatherClanId > 0 &&
        candidate.motherClanId > 0 &&
        me.fatherClanId == candidate.motherClanId) {
      return false;
    }
    if (candidate.fatherClanId > 0 &&
        me.motherClanId > 0 &&
        candidate.fatherClanId == me.motherClanId) {
      return false;
    }

    // Check candidate's tharavadu ID against user's forbidden and restricted lists
    if (candidate.tharavaduId > 0) {
      if (forbiddenIds.contains(candidate.tharavaduId)) return false;
      if (me.restrictedTharavads.contains(candidate.tharavaduId)) return false;
    }

    // Candidate's own forbidden list check against user
    final candForbiddenIds = getForbiddenTharavaduIds(
      candidate,
      includeEntireMoiety: !isRecalculationPool,
    );
    final candForbiddenNames = getForbiddenTharavaduNames(
      candidate,
      includeEntireMoiety: !isRecalculationPool,
    );

    if (me.motherClanId > 0 && candForbiddenIds.contains(me.motherClanId)) {
      return false;
    }
    if (me.fatherClanId > 0 &&
        (candForbiddenIds.contains(me.fatherClanId) ||
            candidate.restrictedTharavads.contains(me.fatherClanId))) {
      return false;
    }
    if (me.tharavaduId > 0 &&
        (candForbiddenIds.contains(me.tharavaduId) ||
            candidate.restrictedTharavads.contains(me.tharavaduId))) {
      return false;
    }
    if (myMotherClan.isNotEmpty && candForbiddenNames.contains(myMotherClan)) {
      return false;
    }
    if (myFatherClan.isNotEmpty && candidate.restrictedFamilies.isNotEmpty) {
      for (final rf in candidate.restrictedFamilies) {
        final r = rf.trim().toLowerCase();
        if (r.isNotEmpty &&
            (myFatherClan == r ||
                myFatherClan.contains(r) ||
                r.contains(myFatherClan))) {
          return false;
        }
      }
    }

    // 6. DB-level / Admin-level exclusions table
    if (tharavadExclusions != null && tharavadExclusions.isNotEmpty) {
      final myMomId = me.motherClanId > 0 ? me.motherClanId : me.tharavaduId;
      final candMomId = candidate.motherClanId > 0
          ? candidate.motherClanId
          : candidate.tharavaduId;
      if (myMomId > 0 && candMomId > 0) {
        final isExcluded = tharavadExclusions.any((exclusion) {
          final id1 =
              (exclusion['tharavad_id_1'] ?? exclusion['tharavad_id']) as int?;
          final id2 =
              (exclusion['tharavad_id_2'] ?? exclusion['excluded_tharavad_id'])
                  as int?;
          if (id1 == null || id2 == null) return false;
          return (id1 == myMomId && id2 == candMomId) ||
              (id1 == candMomId && id2 == myMomId);
        });
        if (isExcluded) return false;
      }
    }

    return _checkMaritalAndResidenceCompatibility(me, candidate);
  }

  static bool _checkMaritalAndResidenceCompatibility(
    UserProfile me,
    UserProfile candidate,
  ) {
    // Marital Status & Children Logic
    final bool candIsRemarriage =
        candidate.maritalStatus != MaritalStatus.first;
    final bool meIsRemarriage = me.maritalStatus != MaritalStatus.first;

    if (candIsRemarriage) {
      if (!meIsRemarriage) {
        final optIn = me.firstMarriageOpenToRemarriage?.toUpperCase();
        if (optIn != 'YES_WILLING' && optIn != 'YES') {
          return false;
        }
      }
      if (candidate.hasChildren) {
        if (!me.readyToAcceptChildren) {
          return false;
        }
      }
    }

    if (meIsRemarriage) {
      if (candidate.maritalStatus == MaritalStatus.first) {
        final optIn = candidate.firstMarriageOpenToRemarriage?.toUpperCase();
        if (optIn != 'YES_WILLING' && optIn != 'YES') {
          return false;
        }
      }
      if (me.hasChildren) {
        if (!candidate.readyToAcceptChildren) {
          return false;
        }
      }
    }

    // Residence Preference / Bride's Home Relocation
    if (me.gender == Gender.female) {
      if (me.filterByBrideHomeWillingness) {
        if (!candidate.willingToStayAtBrideHome) {
          return false;
        }
      }
    } else {
      if (candidate.filterByBrideHomeWillingness) {
        if (!me.willingToStayAtBrideHome) {
          return false;
        }
      }
    }

    return true;
  }

  /// Composite lineage group type based on BOTH parents (Father & Mother)
  static LineageGroupType getCompositeLineageType(UserProfile user) =>
      ClanMatchingEngine.instance.getCompositeLineageType(user);

  /// Checks if a user has dual-same lineage (both parents Panthi or both Bandhu)
  static bool isDualSameLineage(UserProfile user) =>
      ClanMatchingEngine.instance.isDualSameLineage(user);

  /// Resolves father's moiety ('PANDI', 'BANDHU', or 'UNKNOWN')
  static String resolveFatherMoiety(UserProfile user) =>
      ClanMatchingEngine.instance.getFatherMoiety(user);

  /// Resolves mother's moiety ('PANDI', 'BANDHU', or 'UNKNOWN')
  static String resolveMotherMoiety(UserProfile user) =>
      ClanMatchingEngine.instance.getMotherMoiety(user);
}
