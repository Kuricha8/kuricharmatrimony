import 'enums.dart';

class Clan {
  final int id;
  final String _englishName;
  final String nameMl;
  final String nameEn;
  final String subName; // Secondary sub-branch name (e.g. "ചായമൽ" / "ചയിമ്മൽ")
  final String type; // 'bandhu' or 'pandi'
  final String groupName;
  final String? description;
  final String? location;
  final String? imageUrl;
  final bool isActive;

  final String clanGroup; // 'ബന്ധു' or 'പന്തി'
  final List<dynamic> restrictedTharavads;
  final int? tharavaduNumber;

  bool get isBandhu =>
      clanGroup.contains('ബന്ധു') ||
      type.toLowerCase().contains('bandhu') ||
      groupName.contains('ബന്ധു');

  bool get isPanthi => !isBandhu;

  String get name {
    if (nameMl.isNotEmpty) return nameMl.trim();
    if (_englishName.isNotEmpty) return _englishName.trim();
    return nameEn.trim();
  }

  const Clan({
    required this.id,
    String name = '',
    this.nameMl = '',
    this.nameEn = '',
    this.subName = '',
    this.type = '',
    this.groupName = '',
    this.description,
    this.location,
    this.imageUrl,
    this.isActive = true,
    this.clanGroup = '',
    this.restrictedTharavads = const [],
    this.tharavaduNumber,
  }) : _englishName = name;

  Map<String, dynamic> toMap() {
    final normType =
        type.toLowerCase().contains('bandhu') || groupName.contains('ബന്ധു')
        ? 'bandhu'
        : 'pandi';
    return {
      'id': id,
      'name_ml': nameMl.isNotEmpty ? nameMl : name,
      'name_en': nameEn.isNotEmpty ? nameEn : _englishName,
      'name': _englishName.isNotEmpty
          ? _englishName
          : (nameEn.isNotEmpty ? nameEn : nameMl),
      'sub_name': subName,
      'subName': subName,
      'type': normType,
      'group_name': groupName.isNotEmpty
          ? groupName
          : (normType == 'bandhu' ? 'ബന്ധു ഗ്രൂപ്പ്' : 'പന്തി ഗ്രൂപ്പ്'),
      'description': description,
      'location': location ?? (subName.isNotEmpty ? subName : extractedLocation),
      'image_url': imageUrl,
      'is_active': isActive,
      'clanGroup': clanGroup.isNotEmpty ? clanGroup : (normType == 'bandhu' ? 'ബന്ധു' : 'പന്തി'),
      'restrictedTharavads': restrictedTharavads,
      'tharavaduNumber': tharavaduNumber,
    };
  }

  factory Clan.fromMap(Map<String, dynamic> map) {
    final rawType = (map['gothram'] ??
            map['type'] ??
            map['group_name'] ??
            map['category'] ??
            map['moiety'] ??
            map['moiety_group'] ??
            map['clanGroup'] ??
            map['clan_group'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();

    // Dynamically normalize group names into standard 'bandhu' or 'pandi'
    String normalizedType = 'pandi';
    String derivedGroup = 'പന്തി';
    if (rawType.contains('bandhu') ||
        (map['group_name'] ?? '').toString().contains('ബന്ധു') ||
        (map['category'] ?? '').toString().contains('ബന്ധു') ||
        (map['clanGroup'] ?? '').toString().contains('ബന്ധു') ||
        (map['clan_group'] ?? '').toString().contains('ബന്ധു') ||
        (map['type'] ?? '').toString().contains('ബന്ധു')) {
      normalizedType = 'bandhu';
      derivedGroup = 'ബന്ധു';
    } else {
      normalizedType = 'pandi';
      derivedGroup = 'പന്തി';
    }

    final rawLoc = (map['location'] ?? '').toString().trim();
    String nameMlVal =
        (map['name_ml'] ?? map['tharavadu_ml'] ?? map['name'] ?? '')
            .toString()
            .trim();
    String nameEnVal = (map['name_en'] ?? map['name'] ?? '').toString().trim();
    final descVal = (map['description'] ?? '').toString().trim();

    final rawSub = (map['subName'] ??
            map['sub_name'] ??
            map['subBranch'] ??
            map['sub_branch'] ??
            '')
        .toString()
        .trim();

    final explicitClanGroup = (map['clanGroup'] ?? map['clan_group'])?.toString().trim();
    final finalClanGroup = explicitClanGroup != null && explicitClanGroup.isNotEmpty
        ? (explicitClanGroup.contains('ബന്ധു') || explicitClanGroup.toLowerCase().contains('bandhu') ? 'ബന്ധു' : 'പന്തി')
        : derivedGroup;

    final restrictedRaw = map['restrictedTharavads'] ??
        map['restricted_tharavads'] ??
        map['restricted_families'] ??
        [];
    final List<dynamic> restrictedList =
        restrictedRaw is List ? List<dynamic>.from(restrictedRaw) : [];

    final rawNumber = map['tharavaduNumber'] ??
        map['tharavadu_number'] ??
        map['number'] ??
        map['tharavadu_no'];
    final int? tharavaduNum = rawNumber is int
        ? rawNumber
        : int.tryParse(rawNumber?.toString() ?? '');

    final int parsedId = map['id'] is int
        ? map['id'] as int
        : (int.tryParse(map['id']?.toString() ?? '') ?? 0);

    // Canonical paired title normalization for Perinjola (Clan 57)
    if (parsedId == 57 ||
        tharavaduNum == 57 ||
        nameMlVal == 'പെരിഞ്ചോല' ||
        nameMlVal == 'പെരഞ്ചോല' ||
        nameEnVal.toLowerCase() == 'perinjola') {
      nameMlVal = 'പെരിഞ്ചോല പെരിഞ്ചോല';
      nameEnVal = 'Perinjola Perinjola';
    }

    return Clan(
      id: parsedId,
      name: nameMlVal.isNotEmpty ? nameMlVal : nameEnVal,
      nameMl: nameMlVal,
      nameEn: nameEnVal,
      subName: rawSub,
      type: normalizedType,
      groupName: (map['group_name'] ?? '').toString().isNotEmpty
          ? map['group_name'].toString()
          : derivedGroup,
      description: descVal.isNotEmpty ? descVal : null,
      location: rawLoc.isNotEmpty ? rawLoc : (rawSub.isNotEmpty ? rawSub : null),
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      clanGroup: finalClanGroup,
      restrictedTharavads: restrictedList,
      tharavaduNumber: tharavaduNum,
    );
  }

  Clan copyWith({
    int? id,
    String? name,
    String? nameMl,
    String? nameEn,
    String? subName,
    String? type,
    String? groupName,
    String? description,
    String? location,
    String? imageUrl,
    bool? isActive,
    String? clanGroup,
    List<dynamic>? restrictedTharavads,
    int? tharavaduNumber,
  }) {
    return Clan(
      id: id ?? this.id,
      name: name ?? _englishName,
      nameMl: nameMl ?? this.nameMl,
      nameEn: nameEn ?? this.nameEn,
      subName: subName ?? this.subName,
      type: type ?? this.type,
      groupName: groupName ?? this.groupName,
      description: description ?? this.description,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      clanGroup: clanGroup ?? this.clanGroup,
      restrictedTharavads: restrictedTharavads ?? this.restrictedTharavads,
      tharavaduNumber: tharavaduNumber ?? this.tharavaduNumber,
    );
  }

  /// The tharavad family name
  String get tharavadName => name;

  /// The location/house name from explicit field or trailing parentheses.
  String get extractedLocation {
    if (subName.isNotEmpty) return subName.trim();
    if (location != null && location!.trim().isNotEmpty) {
      return location!.trim();
    }
    final src = nameMl.isNotEmpty ? nameMl : _englishName;
    final match = RegExp(r'\(([^)]+)\)$').firstMatch(src);
    return match?.group(1)?.trim() ?? '';
  }

  /// Formatted display name showing authoritative name with complete extension:
  String get displayName {
    if (id == 57 ||
        name == 'പെരിഞ്ചോല' ||
        nameMl == 'പെരിഞ്ചോല' ||
        name == 'പെരിഞ്ചോല പെരിഞ്ചോല' ||
        nameMl == 'പെരിഞ്ചോല പെരിഞ്ചോല' ||
        name.toLowerCase() == 'perinjola' ||
        name.toLowerCase() == 'perinjola perinjola') {
      return (nameMl.isNotEmpty && nameMl.contains('പെരിഞ്ചോല')) ||
              name.contains('പെരിഞ്ചോല')
          ? 'പെരിഞ്ചോല പെരിഞ്ചോല'
          : 'Perinjola Perinjola';
    }
    final base = name.trim();
    final sub = subName.trim();
    if (sub.isNotEmpty) {
      if (base.toLowerCase() == sub.toLowerCase()) {
        return '$base $sub';
      }
      if (!base.toLowerCase().contains(sub.toLowerCase())) {
        return '$base $sub';
      }
    }
    return base;
  }

  /// Formatted display label: delegates to displayName.
  String get displayLabel => displayName;

  /// English-only display label for fallback/search indexing.
  String get displayLabelEn => nameEn.isNotEmpty ? nameEn.trim() : name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Clan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ClanPhotoSubmission {
  final String id;
  final int clanId;
  final String submitterId;
  final String photoUrl;
  final ClanPhotoStatus status;
  final DateTime submittedAt;
  final bool isProfilePhoto;
  final int likesCount;

  const ClanPhotoSubmission({
    required this.id,
    required this.clanId,
    required this.submitterId,
    required this.photoUrl,
    this.status = ClanPhotoStatus.pending,
    required this.submittedAt,
    this.isProfilePhoto = true,
    this.likesCount = 0,
  });

  ClanPhotoSubmission copyWith({
    ClanPhotoStatus? status,
    bool? isProfilePhoto,
    int? likesCount,
  }) {
    return ClanPhotoSubmission(
      id: id,
      clanId: clanId,
      submitterId: submitterId,
      photoUrl: photoUrl,
      status: status ?? this.status,
      submittedAt: submittedAt,
      isProfilePhoto: isProfilePhoto ?? this.isProfilePhoto,
      likesCount: likesCount ?? this.likesCount,
    );
  }
}
