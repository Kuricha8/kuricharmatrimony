import '../../../features/clan_feed/tharavadu_list.dart';
import '../../kurichiyar_clan_engine.dart';

class UserLineageDetails {
  final int fatherClanId;
  final int motherClanId;
  final String? fatherTharavadu;
  final String? motherTharavadu;
  final String? mothersTarawad;
  final int? ownIllamId;
  final int? fatherIllamId;
  final int? motherIllamId;
  final bool isOutOfCaste;
  final bool hasFamilyRestriction;
  final List<String> restrictedFamilies;
  final List<int> restrictedTharavads;
  final String? gotram;
  final String? moiety;

  const UserLineageDetails({
    this.fatherClanId = 0,
    this.motherClanId = 0,
    this.fatherTharavadu,
    this.motherTharavadu,
    this.mothersTarawad,
    this.ownIllamId,
    this.fatherIllamId,
    this.motherIllamId,
    this.isOutOfCaste = false,
    this.hasFamilyRestriction = false,
    this.restrictedFamilies = const [],
    this.restrictedTharavads = const [],
    this.gotram,
    this.moiety,
  });

  String get tharavaduName => (motherTharavadu?.isNotEmpty == true)
      ? motherTharavadu!
      : (fatherTharavadu?.isNotEmpty == true
          ? fatherTharavadu!
          : (mothersTarawad ?? ''));

  int get tharavaduId => motherClanId != 0
      ? motherClanId
      : (fatherClanId != 0
          ? fatherClanId
          : (ownIllamId ?? motherIllamId ?? fatherIllamId ?? 0));

  String get maternalGroup {
    final String motherStr = (motherTharavadu ?? mothersTarawad ?? '').trim();
    if (motherStr.isNotEmpty) {
      return KurichiyarClanEngine.getMoiety(motherStr).toLowerCase();
    }
    if (motherClanId > 0) {
      final clan = getClanById(motherClanId);
      if (clan != null) {
        return KurichiyarClanEngine.getMoiety(clan.name).toLowerCase();
      }
    }
    return (motherClanId % 2 == 0) ? 'bandhu' : 'panthi';
  }

  List<String> get eligibleTharavadsList {
    final String motherStr = (motherTharavadu ?? mothersTarawad ?? '').trim();
    final String oppositeMoiety = KurichiyarClanEngine.getOppositeTargetMoiety(motherStr);
    final matches = allClans.where((c) {
      if (!c.isActive || c.id == 9999) return false;
      if (motherClanId > 0 && c.id == motherClanId) return false;
      if (fatherClanId > 0 && c.id == fatherClanId) return false;
      if (restrictedTharavads.isNotEmpty && restrictedTharavads.contains(c.id)) return false;
      final cMoiety = KurichiyarClanEngine.getMoiety(c.name);
      return cMoiety == oppositeMoiety;
    }).toList();
    return matches.map((c) => c.nameMl.isNotEmpty ? c.nameMl : c.name).toList();
  }

  bool get hasValidTharavadu {
    final f = (fatherTharavadu ?? '').trim();
    final m = (motherTharavadu ?? mothersTarawad ?? '').trim();
    final hasFather = (f.isNotEmpty && f != '—' && f != '-' && f != 'null') || fatherClanId > 0;
    final hasMother = (m.isNotEmpty && m != '—' && m != '-' && m != 'null') || motherClanId > 0;
    return hasFather && hasMother;
  }

  factory UserLineageDetails.fromMap(Map<String, dynamic> row) {
    int parseInt(dynamic val) => val is int ? val : int.tryParse(val?.toString() ?? '') ?? 0;
    return UserLineageDetails(
      fatherClanId: parseInt(row['father_clan_id'] ?? row['fatherClanId']),
      motherClanId: parseInt(row['mother_clan_id'] ?? row['motherClanId']),
      fatherTharavadu: row['father_tharavadu']?.toString() ?? row['fatherTharavadu']?.toString(),
      motherTharavadu: row['mother_tharavadu']?.toString() ?? row['motherTharavadu']?.toString(),
      mothersTarawad: row['mothers_tarawad']?.toString() ?? row['mothersTarawad']?.toString(),
      ownIllamId: row['own_illam_id'] != null ? parseInt(row['own_illam_id']) : null,
      fatherIllamId: row['father_illam_id'] != null ? parseInt(row['father_illam_id']) : null,
      motherIllamId: row['mother_illam_id'] != null ? parseInt(row['mother_illam_id']) : null,
      isOutOfCaste: row['is_out_of_caste'] == true || row['isOutOfCaste'] == true,
      hasFamilyRestriction: row['has_family_restriction'] == true || row['hasFamilyRestriction'] == true,
      restrictedFamilies: (row['restricted_families'] is List)
          ? (row['restricted_families'] as List).map((e) => e.toString()).toList()
          : const [],
      restrictedTharavads: (row['restricted_tharavads'] is List)
          ? (row['restricted_tharavads'] as List).map((e) => parseInt(e)).toList()
          : ((row['restricted_tharavadu_ids'] is List)
              ? (row['restricted_tharavadu_ids'] as List).map((e) => parseInt(e)).toList()
              : ((row['restrictedTharavaduIds'] is List)
                  ? (row['restrictedTharavaduIds'] as List).map((e) => parseInt(e)).toList()
                  : const [])),
      gotram: row['gotram']?.toString(),
      moiety: row['moiety']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'father_clan_id': fatherClanId,
      'mother_clan_id': motherClanId,
      'father_tharavadu': fatherTharavadu,
      'mother_tharavadu': motherTharavadu,
      'mothers_tarawad': mothersTarawad,
      'own_illam_id': ownIllamId,
      'father_illam_id': fatherIllamId,
      'mother_illam_id': motherIllamId,
      'is_out_of_caste': isOutOfCaste,
      'has_family_restriction': hasFamilyRestriction,
      'restricted_families': restrictedFamilies,
      'restricted_tharavads': restrictedTharavads,
      'restricted_tharavadu_ids': restrictedTharavads,
      'gotram': gotram,
      'moiety': moiety,
    };
  }

  UserLineageDetails copyWith({
    int? fatherClanId,
    int? motherClanId,
    String? fatherTharavadu,
    String? motherTharavadu,
    String? mothersTarawad,
    int? ownIllamId,
    int? fatherIllamId,
    int? motherIllamId,
    bool? isOutOfCaste,
    bool? hasFamilyRestriction,
    List<String>? restrictedFamilies,
    List<int>? restrictedTharavads,
    String? gotram,
    String? moiety,
  }) {
    return UserLineageDetails(
      fatherClanId: fatherClanId ?? this.fatherClanId,
      motherClanId: motherClanId ?? this.motherClanId,
      fatherTharavadu: fatherTharavadu ?? this.fatherTharavadu,
      motherTharavadu: motherTharavadu ?? this.motherTharavadu,
      mothersTarawad: mothersTarawad ?? this.mothersTarawad,
      ownIllamId: ownIllamId ?? this.ownIllamId,
      fatherIllamId: fatherIllamId ?? this.fatherIllamId,
      motherIllamId: motherIllamId ?? this.motherIllamId,
      isOutOfCaste: isOutOfCaste ?? this.isOutOfCaste,
      hasFamilyRestriction: hasFamilyRestriction ?? this.hasFamilyRestriction,
      restrictedFamilies: restrictedFamilies ?? this.restrictedFamilies,
      restrictedTharavads: restrictedTharavads ?? this.restrictedTharavads,
      gotram: gotram ?? this.gotram,
      moiety: moiety ?? this.moiety,
    );
  }
}
