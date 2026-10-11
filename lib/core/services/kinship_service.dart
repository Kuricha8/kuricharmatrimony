import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../data/tharavadu_data.dart';
import '../../features/clan_feed/tharavadu_list.dart';

/// Structured result of Kurichiyar Kinship & Moiety (ബന്ധു - പന്തി പൊരുത്തം) check
class KinshipCompatibilityResult {
  /// Whether the marriage between the two tharavadus is permitted under Kurichiyar exogamy & kinship laws
  final bool isAllowed;

  /// Full prominent Malayalam badge text matching Admin panel exact specification
  final String badgeText;

  /// Short headline title for quick status display
  final String statusTitle;

  /// Primary color of the status badge (Green for allowed, Red for prohibited)
  final Color badgeColor;

  /// Background color for badge pill/card container
  final Color badgeBackgroundColor;

  /// Border color for badge pill/card container
  final Color badgeBorderColor;

  /// Groom's resolved tharavadu name
  final String groomTharavaduName;

  /// Groom's moiety group: 'ബന്ധു' or 'പന്തി'
  final String groomClanGroup;

  /// Bride's resolved tharavadu name
  final String brideTharavaduName;

  /// Bride's moiety group: 'ബന്ധു' or 'പന്തി'
  final String brideClanGroup;

  /// Whether both candidates belong to the same moiety (ബന്ധു x ബന്ധു or പന്തി x പന്തി)
  final bool isSameMoiety;

  /// Whether an ancestral or lineage restriction (ആചാരപരമായ വിലക്ക്) was violated
  final bool isRestricted;

  /// In-depth reason explaining the outcome in authentic Malayalam
  final String detailedReason;

  /// Breakdown of the individual customary kinship rules evaluated
  final List<String> ruleBreakdown;

  const KinshipCompatibilityResult({
    required this.isAllowed,
    required this.badgeText,
    required this.statusTitle,
    required this.badgeColor,
    required this.badgeBackgroundColor,
    required this.badgeBorderColor,
    required this.groomTharavaduName,
    required this.groomClanGroup,
    required this.brideTharavaduName,
    required this.brideClanGroup,
    required this.isSameMoiety,
    required this.isRestricted,
    required this.detailedReason,
    required this.ruleBreakdown,
  });
}

/// Centralized Kinship & Moiety Service matching the Admin Panel logic
/// Enforces:
/// 1. Dual-Moiety Exogamy Rule: Marriage allowed ONLY between different moieties (ബന്ധു x പന്തി = MATCH)
/// 2. Same Clan Prohibition: Marriage within same moiety (ബന്ധു x ബന്ധു or പന്തി x പന്തി = NOT ALLOWED)
/// 3. Restricted Tharavadus: Prohibited if either tharavadu is in the other's restricted lineage list
class KinshipService {
  KinshipService._() {
    _initFromLocalSources();
    TharavaduService.instance.addListener(() {
      for (final clan in TharavaduService.allClans) {
        _indexClan(clan);
      }
    });
  }
  static final KinshipService instance = KinshipService._();

  final Map<String, Clan> _tharavadMap = {};
  bool _isInitialized = false;

  void _initFromLocalSources() {
    // 1. Index from static TharavaduData master list (all 57 authentic clans)
    for (final map in TharavaduData.tharavadList) {
      final clan = Clan.fromMap(map);
      _indexClan(clan);
    }
    // 2. Index from TharavaduService.allClans if available
    for (final clan in TharavaduService.allClans) {
      _indexClan(clan);
    }
    _isInitialized = _tharavadMap.isNotEmpty;
    debugPrint('KinshipService: Initialized ${_tharavadMap.length} tharavadu keys from local master.');
  }

  /// Syncs and caches all tharavadus from local sources without unnecessary Firestore reads
  Future<void> syncTharavadsFromFirestore({bool forceRefresh = false}) async {
    // Ensure in-memory local clans are always indexed first
    if (!_isInitialized || _tharavadMap.isEmpty) {
      _initFromLocalSources();
    } else {
      for (var clan in TharavaduService.allClans) {
        _indexClan(clan);
      }
    }

    // Skip Firestore completely if we already have the complete 57 clans indexed
    if (!forceRefresh && _isInitialized && _tharavadMap.isNotEmpty) {
      debugPrint('KinshipService: In-memory tharavadu index already complete (${_tharavadMap.length} keys). 0 Firestore reads used.');
      return;
    }

    try {
      // 1. Fetch from Firestore 'tharavads' collection
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('tharavads')
          .get(const GetOptions(source: Source.serverAndCache));

      // 2. Fallback to 'tharavadus' collection if empty
      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('tharavadus')
            .get(const GetOptions(source: Source.serverAndCache));
      }

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final parsedId = data['id'] is int
              ? data['id'] as int
              : (int.tryParse(data['id']?.toString() ?? '') ??
                  (int.tryParse(doc.id) ?? 0));
          data['id'] = parsedId;
          final clan = Clan.fromMap(data);
          _indexClan(clan);
        }
      }

      // Also ensure TharavaduService in-memory clans are indexed
      for (var clan in TharavaduService.allClans) {
        _indexClan(clan);
      }

      _isInitialized = true;
      debugPrint('KinshipService: Indexed ${_tharavadMap.length} tharavadu keys.');
    } catch (e) {
      debugPrint('KinshipService sync note: $e');
      _initFromLocalSources();
    }
  }

  void _indexClan(Clan clan) {
    if (clan.id > 0) {
      _tharavadMap['id_${clan.id}'] = clan;
    }
    if (clan.tharavaduNumber != null && clan.tharavaduNumber! > 0) {
      _tharavadMap['num_${clan.tharavaduNumber}'] = clan;
    }
    final nameKey = clan.name.trim().toLowerCase();
    if (nameKey.isNotEmpty) {
      _tharavadMap['name_$nameKey'] = clan;
    }
    final nameMlKey = clan.nameMl.trim().toLowerCase();
    if (nameMlKey.isNotEmpty) {
      _tharavadMap['name_$nameMlKey'] = clan;
    }
    final subKey = clan.subName.trim().toLowerCase();
    if (subKey.isNotEmpty) {
      _tharavadMap['name_$subKey'] = clan;
    }
    final dispKey = clan.displayName.trim().toLowerCase();
    if (dispKey.isNotEmpty) {
      _tharavadMap['name_$dispKey'] = clan;
    }
    // Also index single-word aliases for backward compatibility
    if (clan.id == 57 || clan.displayName == 'പെരിഞ്ചോല പെരിഞ്ചോല') {
      _tharavadMap['name_പെരിഞ്ചോല'] = clan;
      _tharavadMap['name_perinjola'] = clan;
    }
  }

  /// Resolves any clan/tharavadu representation (Clan, UserProfile, ID, number, name, or Map)
  Clan? resolveTharavadu(dynamic input) {
    if (!_isInitialized && _tharavadMap.isEmpty) {
      for (var c in TharavaduService.allClans) {
        _indexClan(c);
      }
    }

    if (input == null) return null;

    if (input is Clan) return input;

    if (input is UserProfile) {
      // Prioritize mother's clan (Matrilineal root in Kurichiyar culture)
      if (input.motherClanId > 0) {
        final c = getClanById(input.motherClanId) ?? _tharavadMap['id_${input.motherClanId}'];
        if (c != null) return c;
      }
      if (input.tharavaduId > 0) {
        final c = getClanById(input.tharavaduId) ?? _tharavadMap['id_${input.tharavaduId}'];
        if (c != null) return c;
      }
      if (input.motherTharavadu != null && input.motherTharavadu!.isNotEmpty) {
        final c = resolveTharavadu(input.motherTharavadu);
        if (c != null) return c;
      }
      if (input.tharavaduName.isNotEmpty) {
        final c = resolveTharavadu(input.tharavaduName);
        if (c != null) return c;
      }
      if (input.fatherClanId > 0) {
        final c = getClanById(input.fatherClanId) ?? _tharavadMap['id_${input.fatherClanId}'];
        if (c != null) return c;
      }
      return null;
    }

    if (input is int) {
      return getClanById(input) ??
          _tharavadMap['id_$input'] ??
          _tharavadMap['num_$input'];
    }

    if (input is Map<String, dynamic>) {
      return Clan.fromMap(input);
    }

    if (input is String) {
      final clean = input.trim();
      if (clean.isEmpty) return null;

      final asInt = int.tryParse(clean);
      if (asInt != null) {
        final c = getClanById(asInt) ?? _tharavadMap['id_$asInt'] ?? _tharavadMap['num_$asInt'];
        if (c != null) return c;
      }

      final byName = getClanByName(clean);
      if (byName != null) return byName;

      final lower = clean.toLowerCase();
      if (_tharavadMap.containsKey('name_$lower')) {
        return _tharavadMap['name_$lower'];
      }

      for (var c in TharavaduService.allClans) {
        if (c.name.toLowerCase().contains(lower) ||
            lower.contains(c.name.toLowerCase()) ||
            c.nameMl.contains(clean) ||
            clean.contains(c.nameMl) ||
            (c.subName.isNotEmpty && (c.subName.toLowerCase().contains(lower) || lower.contains(c.subName.toLowerCase()))) ||
            c.displayName.toLowerCase().contains(lower) ||
            lower.contains(c.displayName.toLowerCase()) ||
            ((clean.contains('ചായമൽ') || clean.contains('ചയിമ്മൽ')) &&
                c.nameMl.contains('പുച്ചിയേരി'))) {
          return c;
        }
      }
    }

    return null;
  }

  /// Extracts the exact moiety group ('ബന്ധു' or 'പന്തി') for any input
  String extractMoietyGroup(dynamic input) {
    if (input == null) return 'പന്തി';

    Clan? clan;
    if (input is Clan) {
      clan = input;
    } else {
      clan = resolveTharavadu(input);
    }

    if (clan != null) {
      final cg = clan.clanGroup.toLowerCase().trim();
      final gn = clan.groupName.toLowerCase().trim();
      final tp = clan.type.toLowerCase().trim();

      // Check Bandhu first
      if (cg.contains('ബന്ധു') ||
          cg.contains('bandhu') ||
          gn.contains('ബന്ധു') ||
          gn.contains('bandhu') ||
          tp.contains('ബന്ധു') ||
          tp.contains('bandhu') ||
          clan.isBandhu) {
        return 'ബന്ധു';
      }

      // Check Panthi
      if (cg.contains('പന്തി') ||
          cg.contains('panthi') ||
          cg.contains('pandi') ||
          gn.contains('പന്തി') ||
          gn.contains('panthi') ||
          gn.contains('pandi') ||
          tp.contains('പന്തി') ||
          tp.contains('panthi') ||
          tp.contains('pandi') ||
          clan.isPanthi) {
        return 'പന്തി';
      }

      // Traditional 57 Tharavadu division ID check:
      // 1 to 27 are Panthi, 28 to 57 are Bandhu
      if (clan.id > 0) {
        if (clan.id <= 27) return 'പന്തി';
        if (clan.id >= 28 && clan.id <= 57) return 'ബന്ധു';
      }
      if (clan.tharavaduNumber != null && clan.tharavaduNumber! > 0) {
        if (clan.tharavaduNumber! <= 27) return 'പന്തി';
        if (clan.tharavaduNumber! >= 28 && clan.tharavaduNumber! <= 57) return 'ബന്ധു';
      }
    }

    final str = input.toString().toLowerCase().trim();
    if (str.contains('bandhu') || str.contains('ബന്ധു')) {
      return 'ബന്ധു';
    }
    if (str.contains('panthi') || str.contains('pandi') || str.contains('പന്തി')) {
      return 'പന്തി';
    }

    return 'പന്തി'; // Safe fallback
  }

  /// Checks if two tharavadus have an ancestral restriction (ആചാരപരമായ വിലക്ക്)
  bool checkIsRestricted(
    Clan? groomClan,
    Clan? brideClan, [
    List<dynamic>? groomProfileRestrictions,
    List<dynamic>? brideProfileRestrictions,
  ]) {
    if (groomClan == null || brideClan == null) return false;

    // 1. Check Groom Tharavadu's own restricted list
    if (_matchesRestrictedList(groomClan.restrictedTharavads, brideClan)) {
      debugPrint(
        '[KinshipService] Restriction matched: Bride clan ${brideClan.displayName} is in Groom clan ${groomClan.displayName} restricted list: ${groomClan.restrictedTharavads}',
      );
      return true;
    }

    // 2. Check Bride Tharavadu's own restricted list
    if (_matchesRestrictedList(brideClan.restrictedTharavads, groomClan)) {
      debugPrint(
        '[KinshipService] Restriction matched: Groom clan ${groomClan.displayName} is in Bride clan ${brideClan.displayName} restricted list: ${brideClan.restrictedTharavads}',
      );
      return true;
    }

    // 3. Check profile-level custom family restrictions
    if (groomProfileRestrictions != null &&
        _matchesRestrictedList(groomProfileRestrictions, brideClan)) {
      debugPrint(
        '[KinshipService] Profile restriction matched: Bride clan in groom profile restrictions',
      );
      return true;
    }
    if (brideProfileRestrictions != null &&
        _matchesRestrictedList(brideProfileRestrictions, groomClan)) {
      debugPrint(
        '[KinshipService] Profile restriction matched: Groom clan in bride profile restrictions',
      );
      return true;
    }

    return false;
  }

  bool _matchesRestrictedList(List<dynamic> restrictions, Clan target) {
    if (restrictions.isEmpty) return false;

    final int targetId = target.id;
    final int? targetNum = target.tharavaduNumber;
    final String targetNameMl = target.nameMl.trim().toLowerCase();
    final String targetNameEn = target.name.trim().toLowerCase();
    final String targetSub = target.subName.trim().toLowerCase();

    for (var item in restrictions) {
      if (item == null) continue;

      // 1. Integer ID match (strictly > 0)
      if (item is int) {
        if (item > 0) {
          if (targetId > 0 && item == targetId) return true;
          if (targetNum != null && targetNum > 0 && item == targetNum) return true;
        }
        continue;
      }

      // 2. Map item from Firestore / custom schema
      if (item is Map) {
        final mapId = item['id'] ?? item['tharavadu_number'] ?? item['tharavaduNumber'];
        if (mapId is int && mapId > 0) {
          if (targetId > 0 && mapId == targetId) return true;
          if (targetNum != null && targetNum > 0 && mapId == targetNum) return true;
        } else if (mapId != null) {
          final p = int.tryParse(mapId.toString().trim());
          if (p != null && p > 0) {
            if (targetId > 0 && p == targetId) return true;
            if (targetNum != null && targetNum > 0 && p == targetNum) return true;
          }
        }
        final mapName = (item['name'] ?? item['name_ml'] ?? item['tharavadu_name'])
            ?.toString()
            .trim()
            .toLowerCase();
        if (mapName != null && mapName.isNotEmpty && mapName.length >= 3) {
          if (targetNameMl.isNotEmpty && mapName == targetNameMl) return true;
          if (targetNameEn.isNotEmpty && mapName == targetNameEn) return true;
        }
        continue;
      }

      // 3. String item
      final s = item.toString().trim().toLowerCase();
      // Ignore placeholders, booleans, empty strings, null indicators
      if (s.isEmpty ||
          s == '0' ||
          s == 'null' ||
          s == 'none' ||
          s == 'nil' ||
          s == '-' ||
          s == 'false' ||
          s == 'true' ||
          s == '[]' ||
          s == '{}') {
        continue;
      }

      // Numeric string
      final parsed = int.tryParse(s);
      if (parsed != null) {
        if (parsed > 0) {
          if (targetId > 0 && parsed == targetId) return true;
          if (targetNum != null && targetNum > 0 && parsed == targetNum) return true;
        }
        continue;
      }

      // Exact name matches
      if (targetNameMl.isNotEmpty && s == targetNameMl) return true;
      if (targetNameEn.isNotEmpty && s == targetNameEn) return true;
      if (targetSub.isNotEmpty && s == targetSub) return true;

      // Substring match only for distinct clan names (length >= 4)
      if (s.length >= 4) {
        if (targetNameMl.isNotEmpty && (targetNameMl == s || targetNameMl.startsWith(s))) {
          return true;
        }
        if (targetNameEn.isNotEmpty && (targetNameEn == s || targetNameEn.startsWith(s))) {
          return true;
        }
      }
    }

    return false;
  }

  /// Main Kinship & Moiety Evaluation Function
  /// Evaluates Groom Tharavadu vs Bride Tharavadu according to exact Kurichiyar Customary Laws
  KinshipCompatibilityResult checkMoietyCompatibility(
    dynamic groomTharavadu,
    dynamic brideTharavadu,
  ) {
    Clan? groomClan;
    if (groomTharavadu is Clan) {
      groomClan = groomTharavadu;
    } else {
      groomClan = resolveTharavadu(groomTharavadu);
    }

    Clan? brideClan;
    if (brideTharavadu is Clan) {
      brideClan = brideTharavadu;
    } else {
      brideClan = resolveTharavadu(brideTharavadu);
    }

    // Profile-level restrictions if UserProfiles were passed
    List<dynamic>? groomRestrictions;
    List<dynamic>? brideRestrictions;
    if (groomTharavadu is UserProfile) {
      groomRestrictions = groomTharavadu.restrictedTharavads;
    }
    if (brideTharavadu is UserProfile) {
      brideRestrictions = brideTharavadu.restrictedTharavads;
    }

    final String groomName = groomClan != null
        ? groomClan.displayName
        : (groomTharavadu is UserProfile
            ? (groomTharavadu.motherTharavadu ?? groomTharavadu.tharavaduName)
            : groomTharavadu?.toString() ?? 'അജ്ഞാതം');

    final String brideName = brideClan != null
        ? brideClan.displayName
        : (brideTharavadu is UserProfile
            ? (brideTharavadu.motherTharavadu ?? brideTharavadu.tharavaduName)
            : brideTharavadu?.toString() ?? 'അജ്ഞാതം');

    final String groomMoiety = extractMoietyGroup(groomClan ?? groomTharavadu);
    final String brideMoiety = extractMoietyGroup(brideClan ?? brideTharavadu);

    final String gNorm = groomMoiety.toLowerCase().trim();
    final String bNorm = brideMoiety.toLowerCase().trim();

    final bool isGroomBandhu = gNorm.contains('ബന്ധു') || gNorm.contains('bandhu');
    final bool isBrideBandhu = bNorm.contains('ബന്ധു') || bNorm.contains('bandhu');
    final bool isGroomPanthi = gNorm.contains('പന്തി') || gNorm.contains('panthi') || gNorm.contains('pandi');
    final bool isBridePanthi = bNorm.contains('പന്തി') || bNorm.contains('panthi') || bNorm.contains('pandi');

    // Marriage is prohibited within the same moiety (Bandhu x Bandhu or Panthi x Panthi)
    final bool isSameMoiety = (isGroomBandhu && isBrideBandhu) ||
        (isGroomPanthi && isBridePanthi) ||
        (gNorm == bNorm && gNorm != 'unknown');

    final bool isRestricted = checkIsRestricted(
      groomClan,
      brideClan,
      groomRestrictions,
      brideRestrictions,
    );

    debugPrint('[KinshipService] ─── CHECK MOIETY COMPATIBILITY ───');
    debugPrint(
      '[KinshipService] Groom: $groomName | Moiety: $groomMoiety (Bandhu: $isGroomBandhu, Panthi: $isGroomPanthi, ID: ${groomClan?.id})',
    );
    debugPrint(
      '[KinshipService] Bride: $brideName | Moiety: $brideMoiety (Bandhu: $isBrideBandhu, Panthi: $isBridePanthi, ID: ${brideClan?.id})',
    );
    debugPrint(
      '[KinshipService] isSameMoiety: $isSameMoiety | isRestricted: $isRestricted -> isAllowed: ${!isSameMoiety && !isRestricted}',
    );

    // ─── RULE 1: SAME MOIETY PROHIBITION ───
    if (isSameMoiety) {
      return KinshipCompatibilityResult(
        isAllowed: false,
        badgeText: 'വിവാഹം ആചാരപ്രകാരം അനുവദനീയമല്ല (ഒരേ കൂട്ടം / വിലക്കുള്ള തറവാട്)',
        statusTitle: 'ആചാരപരമായ വിലക്ക് (സഹോദര തുല്യം)',
        badgeColor: const Color(0xFFB91C1C), // Red 700
        badgeBackgroundColor: const Color(0xFFFEF2F2), // Red 50
        badgeBorderColor: const Color(0xFFFECACA), // Red 200
        groomTharavaduName: groomName,
        groomClanGroup: groomMoiety,
        brideTharavaduName: brideName,
        brideClanGroup: brideMoiety,
        isSameMoiety: true,
        isRestricted: isRestricted,
        detailedReason:
            'വരനും വധുവും ഒരേ കൂട്ടത്തിൽ ($groomMoiety x $brideMoiety) പെട്ടവരായതിനാൽ കുറിച്ച്യർ ഗോത്രാചാരപ്രകാരം വിവാഹം കർശനമായി വിലക്കപ്പെട്ടിരിക്കുന്നു (സഹോദര തുല്യം).',
        ruleBreakdown: [
          'ഗോത്ര നിയമം: ഒരേ കൂട്ടങ്ങൾ തമ്മിൽ വിവാഹം പാടില്ല (ബന്ധു x ബന്ധു / പന്തി x പന്തി നിഷിദ്ധം) ✗',
          'വരന്റെ കൂട്ടം: $groomMoiety ($groomName)',
          'വധുവിന്റെ കൂട്ടം: $brideMoiety ($brideName)',
          if (isRestricted) 'ആചാരപരമായ തറവാട് വിലക്ക് നിലനിൽക്കുന്നു ✗',
        ],
      );
    }

    // ─── RULE 2: RESTRICTED THARAVADU CHECK ───
    if (isRestricted) {
      return KinshipCompatibilityResult(
        isAllowed: false,
        badgeText: 'വിവാഹം ആചാരപ്രകാരം അനുവദനീയമല്ല (ഒരേ കൂട്ടം / വിലക്കുള്ള തറവാട്)',
        statusTitle: 'ആചാരപരമായ വിലക്ക് (Restricted Lineage)',
        badgeColor: const Color(0xFFB91C1C), // Red 700
        badgeBackgroundColor: const Color(0xFFFEF2F2), // Red 50
        badgeBorderColor: const Color(0xFFFECACA), // Red 200
        groomTharavaduName: groomName,
        groomClanGroup: groomMoiety,
        brideTharavaduName: brideName,
        brideClanGroup: brideMoiety,
        isSameMoiety: false,
        isRestricted: true,
        detailedReason:
            'വരനും വധുവും വിരുദ്ധ കൂട്ടങ്ങളിൽ ($groomMoiety ↔ $brideMoiety) ഉൾപ്പെടുന്നുവെങ്കിലും, ഇവരുടെ തറവാടുകൾ തമ്മിൽ പരമ്പരാഗത ആചാരപരമായ വിലക്ക് (Restricted Lineage) നിലനിൽക്കുന്നതിനാൽ വിവാഹം അനുവദനീയമല്ല.',
        ruleBreakdown: [
          'ഗോത്ര നിയമം: വ്യത്യസ്ത കൂട്ടങ്ങൾ ($groomMoiety ↔ $brideMoiety) ✓',
          'ആചാര വിലക്ക്: വിലക്കപ്പെട്ട തറവാട് ലിസ്റ്റിൽ ഉൾപ്പെടുന്നു ✗',
          'വരന്റെ തറവാട്: $groomName ($groomMoiety)',
          'വധുവിന്റെ തറവാട്: $brideName ($brideMoiety)',
        ],
      );
    }

    // ─── RULE 3: FULL EXOGAMY MATCH (100% ALLOWED) ───
    return KinshipCompatibilityResult(
      isAllowed: true,
      badgeText: 'വിവാഹം അനുവദനീയം (ബന്ധു ↔ പന്തി പൊരുത്തമുണ്ട്)',
      statusTitle: 'വിവാഹം അനുവദനീയം (100% പൊരുത്തം)',
      badgeColor: const Color(0xFF15803D), // Green 700
      badgeBackgroundColor: const Color(0xFFF0FDF4), // Green 50
      badgeBorderColor: const Color(0xFFBBF7D0), // Green 200
      groomTharavaduName: groomName,
      groomClanGroup: groomMoiety,
      brideTharavaduName: brideName,
      brideClanGroup: brideMoiety,
      isSameMoiety: false,
      isRestricted: false,
      detailedReason:
          'വരൻ $groomMoiety കൂട്ടത്തിലും വധു $brideMoiety കൂട്ടത്തിലും ഉൾപ്പെടുന്നതിനാലും പരസ്പര തറവാട് വിലക്കുകൾ ഇല്ലാത്തതിനാലും കുറിച്ച്യർ ഗോത്രാചാരപ്രകാരം വിവാഹം പൂർണ്ണമായി അനുവദനീയമാണ്.',
      ruleBreakdown: [
        'ഗോത്ര നിയമം: വിരുദ്ധ കൂട്ടങ്ങൾ ($groomMoiety ↔ $brideMoiety) പൊരുത്തപ്പെടുന്നു ✓',
        'ആചാര വിലക്ക്: തറവാടുകൾ തമ്മിൽ വിലക്കുകൾ ഒന്നും തന്നെയില്ല ✓',
        'വരൻ: $groomName ($groomMoiety)',
        'വധു: $brideName ($brideMoiety)',
      ],
    );
  }
}

/// Top-level convenience function for checking moiety compatibility directly
KinshipCompatibilityResult checkMoietyCompatibility(
  dynamic groomTharavadu,
  dynamic brideTharavadu,
) {
  return KinshipService.instance.checkMoietyCompatibility(
    groomTharavadu,
    brideTharavadu,
  );
}
