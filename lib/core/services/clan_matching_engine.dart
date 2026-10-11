import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../../features/clan_feed/tharavadu_list.dart';
import 'global_features_service.dart';

/// Dual-Parent Lineage Composite Types
enum LineageGroupType {
  /// Standard cross lineage: Father Bandhu + Mother Panthi, or Father Panthi + Mother Bandhu
  standardCross,

  /// Dual-Same Lineage: Father Panthi + Mother Panthi
  dualPanthi,

  /// Dual-Same Lineage: Father Bandhu + Mother Bandhu
  dualBandhu,

  /// Incomplete or unknown parent data (treated as standard matrilineal)
  unknown,
}

/// Matching Pool Categories for presentation & filtering
enum MatchingPoolCategory {
  /// Primary standard matches (Traditional Cross-Lineage)
  primaryStandard,

  /// Recalculation pool for Dual-Same lineage (both parents Panthi or both Bandhu)
  dualSameRecalculation,
}

/// Kinship Pool Categories (Two Isolated Universes)
enum KinshipPoolType {
  /// Category A: Parents strictly follow traditional opposite-moiety marriage (Bandhu ↔ Panthi).
  /// Can ONLY view, match, and marry candidates who are strictly PURE_YES_MATCH and belong to the opposite clan. Zero exceptions.
  pureYesMatch,

  /// Category B: Parents belong to the same moiety (Bandhu+Bandhu OR Panthi+Panthi) OR isOutOfCaste == true.
  /// FULL FREEDOM within their pool without clan/moiety restrictions.
  noMatchPool,
}

/// Centralized Moiety & Clan Matching Engine for Kurichiyar Matrimony
/// Enforces Kurichiyar Exogamy Rules (പന്തി 1 / Moiety A ↔ പന്തി 2 / Moiety B)
/// and Dual-Parent Lineage Recalculation Pools.
class ClanMatchingEngine {
  ClanMatchingEngine._();
  static final ClanMatchingEngine instance = ClanMatchingEngine._();

  /// Categorizes profile into Category A ('PURE_YES_MATCH') or Category B ('NO_MATCH_POOL')
  KinshipPoolType getKinshipPool(UserProfile? profile) {
    if (profile == null) return KinshipPoolType.pureYesMatch;
    if (profile.isOutOfCaste) return KinshipPoolType.noMatchPool;

    final f = getFatherMoiety(profile);
    final m = getMotherMoiety(profile);

    // If both parents belong to the same moiety (Panthi+Panthi or Bandhu+Bandhu)
    if ((f == 'PANDI' && m == 'PANDI') || (f == 'BANDHU' && m == 'BANDHU')) {
      return KinshipPoolType.noMatchPool;
    }

    return KinshipPoolType.pureYesMatch;
  }

  /// Resolve Moiety ('PANDI' or 'BANDHU') for a clan ID, Clan object, or type string
  String getMoietyForClan(dynamic input) {
    if (input == null) return 'UNKNOWN';

    int? clanId;
    String? typeStr;
    String? nameStr;

    if (input is Clan) {
      final g = input.groupName.toLowerCase().trim();
      final t = input.type.toLowerCase().trim();
      if (g.contains('ബന്ധു') || t.contains('bandhu')) return 'BANDHU';
      if (g.contains('പന്തി') || t.contains('pandi') || t.contains('panthi')) {
        return 'PANDI';
      }
      clanId = input.id;
      typeStr = input.type;
      nameStr = input.name;
    } else if (input is int) {
      clanId = input;
      final found = getClanById(input);
      if (found != null) {
        typeStr = found.type;
        nameStr = found.name;
      }
    } else if (input is String) {
      final parsed = int.tryParse(input);
      if (parsed != null) {
        return getMoietyForClan(parsed);
      }
      typeStr = input;
      final found = getClanByName(input);
      if (found != null) {
        clanId = found.id;
        typeStr = found.type;
        nameStr = found.name;
      }
    }

    // 1. Dynamic Check via TharavaduService / allClans
    if (clanId != null && clanId > 0) {
      final clanObj = getClanById(clanId);
      if (clanObj != null) {
        final t = clanObj.type.toLowerCase().trim();
        final g = clanObj.groupName.toLowerCase().trim();
        if (t.contains('bandhu') || g.contains('ബന്ധു')) return 'BANDHU';
        if (t.contains('pandi') || t.contains('panthi') || g.contains('പന്തി')) {
          return 'PANDI';
        }
      }
    }

    // 2. Type String Normalization Check
    final normType = (typeStr ?? '').toLowerCase().trim();
    final normName = (nameStr ?? '').toLowerCase().trim();

    if (normType.contains('pandi') ||
        normType.contains('panthi') ||
        normType.contains('പന്തി') ||
        normName.contains('pandi') ||
        normName.contains('panthi') ||
        normName.contains('പന്തി')) {
      return 'PANDI';
    }
    if (normType.contains('bandhu') ||
        normType.contains('ബന്ധു') ||
        normName.contains('bandhu') ||
        normName.contains('ബന്ധു')) {
      return 'BANDHU';
    }

    // 3. Parity fallback (Odd IDs = Pandi, Even IDs = Bandhu in standard Kurichiyar 57 list)
    if (clanId != null && clanId > 0) {
      return (clanId % 2 != 0) ? 'PANDI' : 'BANDHU';
    }

    return 'UNKNOWN';
  }

  /// Resolve Father's moiety ('PANDI', 'BANDHU', or 'UNKNOWN')
  String getFatherMoiety(UserProfile? profile) {
    if (profile == null) return 'UNKNOWN';
    if (profile.fatherClanId > 0) {
      final m = getMoietyForClan(profile.fatherClanId);
      if (m != 'UNKNOWN') return m;
    }
    final dadName = (profile.fatherTharavadu ?? '').trim();
    if (dadName.isNotEmpty) {
      final m = getMoietyForClan(dadName);
      if (m != 'UNKNOWN') return m;
    }
    if (profile.fatherIllamId != null && profile.fatherIllamId! > 0) {
      final m = getMoietyForClan(profile.fatherIllamId!);
      if (m != 'UNKNOWN') return m;
    }
    return 'UNKNOWN';
  }

  /// Resolve Mother's moiety ('PANDI', 'BANDHU', or 'UNKNOWN')
  String getMotherMoiety(UserProfile? profile) {
    if (profile == null) return 'UNKNOWN';
    if (profile.motherClanId > 0) {
      final m = getMoietyForClan(profile.motherClanId);
      if (m != 'UNKNOWN') return m;
    }
    final momName = (profile.motherTharavadu ??
            profile.mothersTarawad ??
            profile.tharavaduName)
        .trim();
    if (momName.isNotEmpty) {
      final m = getMoietyForClan(momName);
      if (m != 'UNKNOWN') return m;
    }
    if (profile.ownIllamId != null && profile.ownIllamId! > 0) {
      final m = getMoietyForClan(profile.ownIllamId!);
      if (m != 'UNKNOWN') return m;
    }
    if (profile.motherIllamId != null && profile.motherIllamId! > 0) {
      final m = getMoietyForClan(profile.motherIllamId!);
      if (m != 'UNKNOWN') return m;
    }
    return 'UNKNOWN';
  }

  /// Get primary moiety for a user profile based on Mother's Tharavadu (matrilineal rule)
  String getMoietyForProfile(UserProfile? profile) {
    if (profile == null) return 'UNKNOWN';
    final momMoiety = getMotherMoiety(profile);
    if (momMoiety != 'UNKNOWN') return momMoiety;

    // Fallback to father's clan opposite moiety if mother clan is unassigned
    final dadMoiety = getFatherMoiety(profile);
    if (dadMoiety == 'PANDI') return 'BANDHU';
    if (dadMoiety == 'BANDHU') return 'PANDI';

    return 'UNKNOWN';
  }

  /// Determine user's composite lineage classification based on BOTH parents
  LineageGroupType getCompositeLineageType(UserProfile? profile) {
    if (profile == null) return LineageGroupType.unknown;
    final f = getFatherMoiety(profile);
    final m = getMotherMoiety(profile);

    if (f == 'PANDI' && m == 'PANDI') {
      return LineageGroupType.dualPanthi;
    }
    if (f == 'BANDHU' && m == 'BANDHU') {
      return LineageGroupType.dualBandhu;
    }
    if ((f == 'PANDI' && m == 'BANDHU') || (f == 'BANDHU' && m == 'PANDI')) {
      return LineageGroupType.standardCross;
    }
    if (m != 'UNKNOWN') {
      return LineageGroupType.standardCross;
    }
    return LineageGroupType.unknown;
  }

  /// Checks if a profile belongs to the Dual-Same Lineage Group (both parents Panthi or both Bandhu)
  bool isDualSameLineage(UserProfile? profile) {
    final type = getCompositeLineageType(profile);
    return type == LineageGroupType.dualPanthi ||
        type == LineageGroupType.dualBandhu;
  }

  /// Comprehensive compatibility check between two profiles or clans
  MoietyMatchResult checkCompatibility({
    UserProfile? groomProfile,
    UserProfile? brideProfile,
    dynamic groomClanInput,
    dynamic brideClanInput,
    MatchingPoolCategory? poolCategory,
  }) {
    // Determine Moieties
    String groomMoiety = 'UNKNOWN';
    String brideMoiety = 'UNKNOWN';
    int groomMotherClanId = 0;
    int brideMotherClanId = 0;
    int groomFatherClanId = 0;
    int brideFatherClanId = 0;

    LineageGroupType groomLineage = LineageGroupType.unknown;
    LineageGroupType brideLineage = LineageGroupType.unknown;

    if (groomProfile != null) {
      groomMoiety = getMotherMoiety(groomProfile);
      if (groomMoiety == 'UNKNOWN') {
        groomMoiety = getMoietyForProfile(groomProfile);
      }
      groomMotherClanId = groomProfile.motherClanId;
      groomFatherClanId = groomProfile.fatherClanId;
      groomLineage = getCompositeLineageType(groomProfile);
    } else if (groomClanInput != null) {
      groomMoiety = getMoietyForClan(groomClanInput);
      if (groomClanInput is Clan) groomMotherClanId = groomClanInput.id;
      if (groomClanInput is int) groomMotherClanId = groomClanInput;
    }

    if (brideProfile != null) {
      brideMoiety = getMotherMoiety(brideProfile);
      if (brideMoiety == 'UNKNOWN') {
        brideMoiety = getMoietyForProfile(brideProfile);
      }
      brideMotherClanId = brideProfile.motherClanId;
      brideFatherClanId = brideProfile.fatherClanId;
      brideLineage = getCompositeLineageType(brideProfile);
    } else if (brideClanInput != null) {
      brideMoiety = getMoietyForClan(brideClanInput);
      if (brideClanInput is Clan) brideMotherClanId = brideClanInput.id;
      if (brideClanInput is int) brideMotherClanId = brideClanInput;
    }

    // Check exogamy toggle setting
    final bool isEngineActive =
        GlobalFeaturesService.instance.panthiBandhuCheck;

    bool isMatch = false;
    String titleMl = '';
    String explanationMl = '';
    String voiceMessageMl = '';
    String code = '';
    MatchingPoolCategory resolvedCategory =
        poolCategory ?? MatchingPoolCategory.primaryStandard;

    // Strict Isolation: Category A ('PURE_YES_MATCH') vs Category B ('NO_MATCH_POOL')
    if (groomProfile != null && brideProfile != null) {
      final groomPool = getKinshipPool(groomProfile);
      final bridePool = getKinshipPool(brideProfile);

      if (groomPool != bridePool) {
        return MoietyMatchResult(
          isCompatible: false,
          groomMoiety: groomMoiety,
          brideMoiety: brideMoiety,
          code: 'POOL_ISOLATION_MISMATCH',
          titleMl: 'പൊരുത്തമില്ല (വിഭാഗ വ്യത്യാസം)',
          explanationMl:
              'പരമ്പരാഗത പ്രാഥമിക പൂളും (Category A) നോ-മാച്ച് പൂളും (Category B) പരസ്പരം പൊരുത്തപ്പെടുന്നതല്ല.',
          voiceMessageMl: 'വിഭാഗ വ്യത്യാസം കാരണം വിവാഹം അനുവദനീയമല്ല.',
          poolCategory: groomPool == KinshipPoolType.noMatchPool
              ? MatchingPoolCategory.dualSameRecalculation
              : MatchingPoolCategory.primaryStandard,
        );
      }

      if (groomPool == KinshipPoolType.noMatchPool) {
        // Category B ('NO_MATCH_POOL'):
        // FULL FREEDOM within their pool without clan/moiety restrictions.
        return MoietyMatchResult(
          isCompatible: true,
          groomMoiety: groomMoiety,
          brideMoiety: brideMoiety,
          code: 'NO_MATCH_POOL_FREEDOM',
          titleMl: 'വിവാഹ പൊരുത്തമുണ്ട് (പൂൾ ബി - പൂർണ്ണ സ്വാതന്ത്ര്യം)',
          explanationMl:
              'നോ-മാച്ച് പൂളിൽ (Category B) ഉൾപ്പെട്ടവർക്ക് കൂട്ടത്തിൽ ആരുമായും വിവാഹം അനുവദനീയമാണ്.',
          voiceMessageMl: 'നോ-മാച്ച് പൂളിൽ വിവാഹം അനുവദനീയമാണ്.',
          poolCategory: MatchingPoolCategory.dualSameRecalculation,
        );
      }
    }

    if (!isEngineActive) {
      isMatch = true;
      code = 'CHECK_DISABLED';
      titleMl = 'പൊരുത്തമുണ്ട് (വിവാഹ യോഗ്യം)';
      explanationMl =
          'ഇല്ലപ്പൊരുത്ത പരിശോധന താത്കാലികമായി നിഷ്‌ക്രിയമാക്കിയിരിക്കുന്നു.';
      voiceMessageMl = explanationMl;
    } else if (groomMotherClanId > 0 &&
        brideMotherClanId > 0 &&
        groomMotherClanId == brideMotherClanId) {
      // 1. Exact Same Mother Tharavadu
      isMatch = false;
      code = 'SAME_THARAVADU';
      titleMl = 'നിഷിദ്ധം (പൊരുത്തമില്ല)';
      explanationMl =
          'രണ്ടുപേരും ഒരേ തറവാട്ടിൽ നിന്നുള്ളവരാണ്. കുറിച്ച്യർ പാരമ്പര്യ നിയമപ്രകാരം ഒരേ തറവാട്ടുകാർ തമ്മിലുള്ള വിവാഹം നിഷിദ്ധമാണ്.';
      voiceMessageMl = explanationMl;
    } else if (groomProfile != null &&
        brideProfile != null &&
        groomProfile.tharavaduId > 0 &&
        brideProfile.tharavaduId > 0 &&
        groomProfile.tharavaduId == brideProfile.tharavaduId) {
      // Exact same tharavadu ID
      isMatch = false;
      code = 'SAME_THARAVADU';
      titleMl = 'നിഷിദ്ധം (പൊരുത്തമില്ല)';
      explanationMl =
          'രണ്ടുപേരും ഒരേ തറവാട്ടിൽ നിന്നുള്ളവരാണ്. ഒരേ തറവാട്ടുകാർ തമ്മിലുള്ള വിവാഹം നിഷിദ്ധമാണ്.';
      voiceMessageMl = explanationMl;
    } else if (groomProfile != null &&
        brideProfile != null &&
        (groomProfile.restrictedTharavads.contains(brideMotherClanId) ||
            groomProfile.restrictedTharavads.contains(brideFatherClanId) ||
            groomProfile.restrictedTharavads
                .contains(brideProfile.tharavaduId) ||
            brideProfile.restrictedTharavads.contains(groomMotherClanId) ||
            brideProfile.restrictedTharavads.contains(groomFatherClanId) ||
            brideProfile.restrictedTharavads
                .contains(groomProfile.tharavaduId))) {
      // Custom Mutual Restricted Tharavadu Constraint
      isMatch = false;
      code = 'RESTRICTED_THARAVADU';
      titleMl = 'നിഷിദ്ധം (കുടുംബ വിലക്ക്)';
      explanationMl =
          'പരസ്പര കുടുംബ നിയന്ത്രണങ്ങൾ കാരണം ഈ പ്രൊഫൈലുകൾ തമ്മിൽ വിവാഹം അനുവദനീയമല്ല.';
      voiceMessageMl = 'കുടുംബ വിലക്ക് കാരണം ഈ വിവാഹം അനുവദനീയമല്ല.';
    } else if (groomProfile != null &&
        brideProfile != null &&
        (isDualSameLineage(groomProfile) || isDualSameLineage(brideProfile))) {
      // ── DUAL-SAME LINEAGE HANDLING (Re-calculation Pool) ─────────────────
      final bool groomIsDual = isDualSameLineage(groomProfile);
      final bool brideIsDual = isDualSameLineage(brideProfile);

      if (groomIsDual && brideIsDual) {
        resolvedCategory = MatchingPoolCategory.dualSameRecalculation;

        if (poolCategory == MatchingPoolCategory.primaryStandard) {
          // Keep primary standard matches in default Primary Matches feed
          isMatch = false;
          code = 'DUAL_POOL_SEPARATION';
          titleMl = 'പുനർനിർണ്ണയ പൂളിൽ ഉൾപ്പെട്ടത്';
          explanationMl =
              'ഈ പ്രൊഫൈൽ ഇരട്ട-പാരമ്പര്യ പുനർനിർണ്ണയ പൂളിൽ (Dual-Lineage Pool) ലഭ്യമാണ്.';
          voiceMessageMl = explanationMl;
        } else {
          // Check reciprocal compatibility in Dual-Lineage Recalculation Pool
          if (groomFatherClanId > 0 &&
              brideMotherClanId > 0 &&
              groomFatherClanId == brideMotherClanId) {
            isMatch = false;
            code = 'PATERNAL_CONFLICT';
            titleMl = 'നിഷിദ്ധം (അച്ഛന്റെ തറവാട് പൊരുത്തക്കേട്)';
            explanationMl =
                'വരന്റെ അച്ഛന്റെ തറവാടും വധുവിന്റെ അമ്മയുടെ തറവാടും ഒന്നാണ്.';
            voiceMessageMl = explanationMl;
          } else if (brideFatherClanId > 0 &&
              groomMotherClanId > 0 &&
              brideFatherClanId == groomMotherClanId) {
            isMatch = false;
            code = 'PATERNAL_CONFLICT';
            titleMl = 'നിഷിദ്ധം (അച്ഛന്റെ തറവാട് പൊരുത്തക്കേട്)';
            explanationMl =
                'വധുവിന്റെ അച്ഛന്റെ തറവാടും വരന്റെ അമ്മയുടെ തറവാടും ഒന്നാണ്.';
            voiceMessageMl = explanationMl;
          } else if (groomFatherClanId > 0 &&
              brideFatherClanId > 0 &&
              groomFatherClanId == brideFatherClanId) {
            isMatch = false;
            code = 'SAME_FATHER_CLAN';
            titleMl = 'നിഷിദ്ധം (ഒരേ പിതൃതറവാട്)';
            explanationMl = 'വരന്റെയും വധുവിന്റെയും അച്ഛന്റെ തറവാട് ഒന്നാണ്.';
            voiceMessageMl = explanationMl;
          } else {
            // Valid Reciprocal Match:
            // Dual-Panthi ↔ Dual-Bandhu is the ideal reciprocal pair;
            // or distinct clans within recalculation pool.
            final bool isOppositeDual = (groomLineage ==
                        LineageGroupType.dualPanthi &&
                    brideLineage == LineageGroupType.dualBandhu) ||
                (groomLineage == LineageGroupType.dualBandhu &&
                    brideLineage == LineageGroupType.dualPanthi);

            isMatch = true;
            code = isOppositeDual
                ? 'COMPATIBLE_DUAL_RECIPROCAL'
                : 'COMPATIBLE_DUAL_POOL';
            titleMl = 'പുനർനിർണ്ണയ പൊരുത്തമുണ്ട് (പൊരുത്തം സാധ്യം)';
            explanationMl = isOppositeDual
                ? 'ഇരുവർക്കും ഇരട്ട-പാരമ്പര്യ പരസ്പര പൂരക പൊരുത്തമുണ്ട് (Dual-Lineage Reciprocal Match: പന്തി ↔ ബന്ധു).'
                : 'ഇരട്ട-പാരമ്പര്യ പുനർനിർണ്ണയ പൂൾ പ്രകാരം വിവാഹ പൊരുത്തം സാധ്യമാണ്.';
            voiceMessageMl = 'പുനർനിർണ്ണയ പൂൾ പ്രകാരം വിവാഹ പൊരുത്തമുണ്ട്.';
          }
        }
      } else {
        // One is Dual-Same, the other is Standard Cross
        // Do not mix across categories to prevent disruption of traditional primary rules
        isMatch = false;
        code = 'LINEAGE_CATEGORY_MISMATCH';
        titleMl = 'പൊരുത്തമില്ല (വിഭാഗ വ്യത്യാസം)';
        explanationMl =
            'പരമ്പരാഗത പ്രാഥമിക പൊരുത്തങ്ങളും ഇരട്ട-പാരമ്പര്യ പുനർനിർണ്ണയ പൂളും പരസ്പരം വ്യത്യാസപ്പെട്ടിരിക്കുന്നു.';
        voiceMessageMl = explanationMl;
      }
    } else {
      // ── STANDARD CROSS-LINEAGE MATCHING (Primary Matches) ─────────────────
      resolvedCategory = MatchingPoolCategory.primaryStandard;

      if (poolCategory == MatchingPoolCategory.dualSameRecalculation) {
        isMatch = false;
        code = 'STANDARD_POOL_SEPARATION';
        titleMl = 'പ്രാഥമിക പൂളിൽ ഉൾപ്പെട്ടത്';
        explanationMl =
            'ഈ പ്രൊഫൈൽ പ്രാഥമിക പൊരുത്തങ്ങളുടെ (Primary Matches) പട്ടികയിൽ ലഭ്യമാണ്.';
        voiceMessageMl = explanationMl;
      } else if (groomFatherClanId > 0 &&
          brideMotherClanId > 0 &&
          groomFatherClanId == brideMotherClanId) {
        // Paternal Lineage Conflict (Groom Father's Tharavadu == Bride Mother's Tharavadu)
        isMatch = false;
        code = 'PATERNAL_CONFLICT';
        titleMl = 'നിഷിദ്ധം (അച്ഛന്റെ തറവാട് പൊരുത്തക്കേട്)';
        explanationMl =
            'വരന്റെ അച്ഛന്റെ തറവാടും വധുവിന്റെ അമ്മയുടെ തറവാടും ഒന്നാണ്. ഇത് പാരമ്പര്യ പൊരുത്തക്കേടായി കണക്കാക്കുന്നു.';
        voiceMessageMl = explanationMl;
      } else if (brideFatherClanId > 0 &&
          groomMotherClanId > 0 &&
          brideFatherClanId == groomMotherClanId) {
        // Paternal Lineage Conflict (Bride Father's Tharavadu == Groom Mother's Tharavadu)
        isMatch = false;
        code = 'PATERNAL_CONFLICT';
        titleMl = 'നിഷിദ്ധം (അച്ഛന്റെ തറവാട് പൊരുത്തക്കേട്)';
        explanationMl =
            'വധുവിന്റെ അച്ഛന്റെ തറവാടും വരന്റെ അമ്മയുടെ തറവാടും ഒന്നാണ്. ഇത് പാരമ്പര്യ പൊരുത്തക്കേടായി കണക്കാക്കുന്നു.';
        voiceMessageMl = explanationMl;
      } else if (groomMoiety != 'UNKNOWN' &&
          brideMoiety != 'UNKNOWN' &&
          groomMoiety == brideMoiety) {
        // Same Moiety (Pandi ↔ Pandi or Bandhu ↔ Bandhu)
        isMatch = false;
        code = 'SAME_MOIETY';
        titleMl = 'നിഷിദ്ധം (പൊരുത്തമില്ല)';
        explanationMl =
            'വരനും വധുവും ഒരേ കൂട്ടത്തിൽ പെട്ടവരായതിനാൽ (ഒരേ ഇല്ലം / ഒരേ പന്തി) ഈ വിവാഹം അനുവദനീയമല്ല.';
        voiceMessageMl =
            'പൊരുത്തമില്ല, ഇത് നിഷിദ്ധമാണ്. വരനും വധുവും ഒരേ കൂട്ടത്തിൽ പെട്ടവരായതിനാൽ വിവാഹം അനുവദനീയമല്ല.';
      } else if ((groomMoiety == 'PANDI' && brideMoiety == 'BANDHU') ||
          (groomMoiety == 'BANDHU' && brideMoiety == 'PANDI')) {
        // Opposite Moieties (Pandi ↔ Bandhu) — Perfect Standard Exogamous Match
        isMatch = true;
        code = 'COMPATIBLE';
        titleMl = 'വിവാഹ പൊരുത്തമുണ്ട് (അനുവദനീയം)';
        explanationMl =
            'വരനും വധുവും വ്യത്യസ്ത കൂട്ടങ്ങളിൽ (ബന്ധു ↔ പന്തി) പെട്ടവരായതിനാൽ ഈ വിവാഹം അനുവദനീയമാണ്.';
        voiceMessageMl =
            'വിവാഹ പൊരുത്തമുണ്ട്. വരനും വധുവും ബന്ധു, പന്തി കൂട്ടങ്ങളിൽ പെട്ടവരായതിനാൽ ഈ വിവാഹം അനുവദനീയമാണ്.';
      } else {
        isMatch = true;
        code = 'UNKNOWN_COMPATIBLE';
        titleMl = 'പൊരുത്തമുണ്ട് (അനുവദനീയം)';
        explanationMl =
            'ഇല്ലപ്പൊരുത്ത പരിശോധനയിൽ തടസ്സങ്ങളൊന്നും കണ്ടെത്തിയില്ല.';
        voiceMessageMl = explanationMl;
      }
    }

    debugPrint(
      "Matching Check -> Groom Moiety: $groomMoiety | Bride Moiety: $brideMoiety | Pool: $resolvedCategory -> Compatible: $isMatch ($code)",
    );

    return MoietyMatchResult(
      isCompatible: isMatch,
      groomMoiety: groomMoiety,
      brideMoiety: brideMoiety,
      titleMl: titleMl,
      explanationMl: explanationMl,
      voiceMessageMl: voiceMessageMl,
      code: code,
      poolCategory: resolvedCategory,
      groomLineageType: groomLineage,
      brideLineageType: brideLineage,
    );
  }

  /// Synchronous boolean helper to check profile compatibility
  bool areProfilesCompatible(
    UserProfile? a,
    UserProfile? b, {
    MatchingPoolCategory? poolCategory,
  }) {
    if (a == null || b == null) return true;
    return checkCompatibility(
      groomProfile: a,
      brideProfile: b,
      poolCategory: poolCategory,
    ).isCompatible;
  }

  /// Synchronous boolean helper to check clan compatibility
  bool areClansCompatible(dynamic clanA, dynamic clanB) {
    return checkCompatibility(
      groomClanInput: clanA,
      brideClanInput: clanB,
    ).isCompatible;
  }
}

/// Compatibility result data model
class MoietyMatchResult {
  final bool isCompatible;
  final String groomMoiety;
  final String brideMoiety;
  final String titleMl;
  final String explanationMl;
  final String voiceMessageMl;
  final String code;
  final MatchingPoolCategory poolCategory;
  final LineageGroupType? groomLineageType;
  final LineageGroupType? brideLineageType;

  const MoietyMatchResult({
    required this.isCompatible,
    this.groomMoiety = 'UNKNOWN',
    this.brideMoiety = 'UNKNOWN',
    required this.titleMl,
    required this.explanationMl,
    required this.voiceMessageMl,
    required this.code,
    this.poolCategory = MatchingPoolCategory.primaryStandard,
    this.groomLineageType,
    this.brideLineageType,
  });
}
