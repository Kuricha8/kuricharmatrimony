class UserFamilyDetails {
  final String? fatherName;
  final String? motherName;
  final bool isFatherDeceased;
  final bool isMotherDeceased;
  final String? houseName;
  final String region;
  final String? guardianPhone;
  final String? publicDisplayNumber;
  final int childrenCount;
  final List<Map<String, dynamic>> childrenDetails;
  final bool hasChildren;
  final bool readyToAcceptChildren;
  final String? acceptChildrenStatus;
  final String? adoptionPreference;
  final String? groomStayWifeHouse;
  final String? brideHusbandStayHome;
  final String? firstMarriageOpenToRemarriage;
  final String? firstMarriageAdoptChildren;
  final String? firstMarriageMaxChildren;
  final String? residencePreference;
  final String? parentCarePreference;
  final String? profileFor;
  final String? timeline;
  final bool willingToStayAtBrideHome;
  final bool filterByBrideHomeWillingness;
  final bool prefRelocateToBrideHome;

  // Preferences & Habits
  final int prefAgeMin;
  final int prefAgeMax;
  final String? prefDistrict;
  final String? prefHabits;
  final bool? prefJointFamily;
  final bool? prefRelocate;
  final bool? prefManageJobFamily;
  final bool? prefDirectTalk;
  final bool? prefNuclearFamily;
  final bool? prefShareFinances;
  final bool? prefNightShift;
  final bool? prefConsultDecisions;
  final bool? prefDiscloseDebts;
  final bool? prefTravelSocialize;
  final String? prefLocation;

  // Physical & Health
  final String? height;
  final String? weight;
  final int? heightCm;
  final int? weightKg;
  final String? bloodGroup;
  final String physicalStatus;
  final String? smokingHabit;
  final String? drinkingHabit;
  final String? confidentialPhotoUrl;
  final bool adminOnlyMediator;

  // GPS & Location Coordinates
  final double? homeLat;
  final double? homeLng;
  final String? digipin;

  const UserFamilyDetails({
    this.fatherName,
    this.motherName,
    this.isFatherDeceased = false,
    this.isMotherDeceased = false,
    this.houseName,
    this.region = '',
    this.guardianPhone,
    this.publicDisplayNumber,
    this.childrenCount = 0,
    this.childrenDetails = const [],
    this.hasChildren = false,
    this.readyToAcceptChildren = false,
    this.acceptChildrenStatus,
    this.adoptionPreference,
    this.groomStayWifeHouse,
    this.brideHusbandStayHome,
    this.firstMarriageOpenToRemarriage,
    this.firstMarriageAdoptChildren,
    this.firstMarriageMaxChildren,
    this.residencePreference,
    this.parentCarePreference,
    this.profileFor,
    this.timeline,
    this.willingToStayAtBrideHome = false,
    this.filterByBrideHomeWillingness = false,
    this.prefRelocateToBrideHome = false,
    this.prefAgeMin = 20,
    this.prefAgeMax = 50,
    this.prefDistrict,
    this.prefHabits,
    this.prefJointFamily,
    this.prefRelocate,
    this.prefManageJobFamily,
    this.prefDirectTalk,
    this.prefNuclearFamily,
    this.prefShareFinances,
    this.prefNightShift,
    this.prefConsultDecisions,
    this.prefDiscloseDebts,
    this.prefTravelSocialize,
    this.prefLocation,
    this.height,
    this.weight,
    this.heightCm,
    this.weightKg,
    this.bloodGroup,
    this.physicalStatus = 'Normal / Fit',
    this.smokingHabit,
    this.drinkingHabit,
    this.confidentialPhotoUrl,
    this.adminOnlyMediator = false,
    this.homeLat,
    this.homeLng,
    this.digipin,
  });

  factory UserFamilyDetails.fromMap(Map<String, dynamic> row) {
    int parseInt(dynamic val, [int fallback = 0]) =>
        val is int ? val : int.tryParse(val?.toString() ?? '') ?? fallback;

    return UserFamilyDetails(
      fatherName: row['father_name']?.toString(),
      motherName: row['mother_name']?.toString(),
      isFatherDeceased: row['is_father_deceased'] == true || row['is_father_deceased']?.toString().toLowerCase() == 'true',
      isMotherDeceased: row['is_mother_deceased'] == true || row['is_mother_deceased']?.toString().toLowerCase() == 'true',
      houseName: row['house_name']?.toString(),
      region: row['region']?.toString() ?? row['location']?.toString() ?? '',
      guardianPhone: row['guardian_phone']?.toString(),
      publicDisplayNumber: row['public_display_number']?.toString(),
      childrenCount: parseInt(row['children_count']),
      childrenDetails: (row['children_details'] is List)
          ? (row['children_details'] as List).whereType<Map<String, dynamic>>().toList()
          : const [],
      hasChildren: row['has_children'] == true || row['has_children']?.toString().toLowerCase() == 'true',
      readyToAcceptChildren: row['ready_to_accept_children'] == true || row['ready_to_accept_children']?.toString().toLowerCase() == 'true',
      acceptChildrenStatus: row['accept_children_status']?.toString(),
      adoptionPreference: row['adoption_preference']?.toString(),
      groomStayWifeHouse: row['groom_stay_wife_house']?.toString(),
      brideHusbandStayHome: row['bride_husband_stay_home']?.toString(),
      firstMarriageOpenToRemarriage: row['first_marriage_open_to_remarriage']?.toString(),
      firstMarriageAdoptChildren: row['first_marriage_adopt_children']?.toString(),
      firstMarriageMaxChildren: row['first_marriage_max_children']?.toString(),
      residencePreference: row['residence_preference']?.toString(),
      parentCarePreference: row['parent_care_preference']?.toString(),
      profileFor: row['profile_for']?.toString(),
      timeline: row['timeline']?.toString(),
      willingToStayAtBrideHome: row['willing_to_stay_at_bride_home'] == true || row['willing_to_stay_at_bride_home']?.toString().toLowerCase() == 'true',
      filterByBrideHomeWillingness: row['filter_by_bride_home_willingness'] == true || row['filter_by_bride_home_willingness']?.toString().toLowerCase() == 'true',
      prefRelocateToBrideHome: row['pref_relocate_to_bride_home'] == true || row['pref_relocate_to_bride_home']?.toString().toLowerCase() == 'true',
      prefAgeMin: parseInt(row['pref_age_min'], 20),
      prefAgeMax: parseInt(row['pref_age_max'], 50),
      prefDistrict: row['pref_district']?.toString(),
      prefHabits: row['pref_habits']?.toString(),
      prefJointFamily: row['pref_joint_family'] as bool?,
      prefRelocate: row['pref_relocate'] as bool?,
      prefManageJobFamily: row['pref_manage_job_family'] as bool?,
      prefDirectTalk: row['pref_direct_talk'] as bool?,
      prefNuclearFamily: row['pref_nuclear_family'] as bool?,
      prefShareFinances: row['pref_share_finances'] as bool?,
      prefNightShift: row['pref_night_shift'] as bool?,
      prefConsultDecisions: row['pref_consult_decisions'] as bool?,
      prefDiscloseDebts: row['pref_disclose_debts'] as bool?,
      prefTravelSocialize: row['pref_travel_socialize'] as bool?,
      prefLocation: row['pref_location']?.toString(),
      height: row['height']?.toString(),
      weight: row['weight']?.toString(),
      heightCm: row['height_cm'] != null ? parseInt(row['height_cm']) : null,
      weightKg: row['weight_kg'] != null ? parseInt(row['weight_kg']) : null,
      bloodGroup: row['blood_group']?.toString(),
      physicalStatus: (row['physical_status'] ?? 'Normal / Fit').toString(),
      smokingHabit: row['smoking_habit']?.toString(),
      drinkingHabit: row['drinking_habit']?.toString(),
      confidentialPhotoUrl: row['confidential_photo_url']?.toString(),
      adminOnlyMediator: row['admin_only_mediator'] == true,
      homeLat: row['home_lat'] != null
          ? double.tryParse(row['home_lat'].toString())
          : (row['homeLat'] != null
              ? double.tryParse(row['homeLat'].toString())
              : (row['latitude'] != null
                  ? double.tryParse(row['latitude'].toString())
                  : (row['lat'] != null ? double.tryParse(row['lat'].toString()) : null))),
      homeLng: row['home_lng'] != null
          ? double.tryParse(row['home_lng'].toString())
          : (row['homeLng'] != null
              ? double.tryParse(row['homeLng'].toString())
              : (row['longitude'] != null
                  ? double.tryParse(row['longitude'].toString())
                  : (row['lng'] != null ? double.tryParse(row['lng'].toString()) : null))),
      digipin: row['digipin']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'father_name': fatherName,
      'mother_name': motherName,
      'is_father_deceased': isFatherDeceased,
      'is_mother_deceased': isMotherDeceased,
      'house_name': houseName,
      'region': region,
      'guardian_phone': guardianPhone,
      'public_display_number': publicDisplayNumber,
      'children_count': childrenCount,
      'children_details': childrenDetails,
      'has_children': hasChildren,
      'ready_to_accept_children': readyToAcceptChildren,
      'accept_children_status': acceptChildrenStatus,
      'adoption_preference': adoptionPreference,
      'groom_stay_wife_house': groomStayWifeHouse,
      'bride_husband_stay_home': brideHusbandStayHome,
      'first_marriage_open_to_remarriage': firstMarriageOpenToRemarriage,
      'first_marriage_adopt_children': firstMarriageAdoptChildren,
      'first_marriage_max_children': firstMarriageMaxChildren,
      'residence_preference': residencePreference,
      'parent_care_preference': parentCarePreference,
      'profile_for': profileFor,
      'timeline': timeline,
      'willing_to_stay_at_bride_home': willingToStayAtBrideHome,
      'filter_by_bride_home_willingness': filterByBrideHomeWillingness,
      'pref_relocate_to_bride_home': prefRelocateToBrideHome,
      'pref_age_min': prefAgeMin,
      'pref_age_max': prefAgeMax,
      'pref_district': prefDistrict,
      'pref_habits': prefHabits,
      'pref_joint_family': prefJointFamily,
      'pref_relocate': prefRelocate,
      'pref_manage_job_family': prefManageJobFamily,
      'pref_direct_talk': prefDirectTalk,
      'pref_nuclear_family': prefNuclearFamily,
      'pref_share_finances': prefShareFinances,
      'pref_night_shift': prefNightShift,
      'pref_consult_decisions': prefConsultDecisions,
      'pref_disclose_debts': prefDiscloseDebts,
      'pref_travel_socialize': prefTravelSocialize,
      'pref_location': prefLocation,
      'height': height,
      'weight': weight,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'blood_group': bloodGroup,
      'physical_status': physicalStatus,
      'smoking_habit': smokingHabit,
      'drinking_habit': drinkingHabit,
      'confidential_photo_url': confidentialPhotoUrl,
      'admin_only_mediator': adminOnlyMediator,
      'home_lat': homeLat,
      'home_lng': homeLng,
      'digipin': digipin,
    };
  }

  UserFamilyDetails copyWith({
    String? fatherName,
    String? motherName,
    bool? isFatherDeceased,
    bool? isMotherDeceased,
    String? houseName,
    String? region,
    String? guardianPhone,
    String? publicDisplayNumber,
    int? childrenCount,
    List<Map<String, dynamic>>? childrenDetails,
    bool? hasChildren,
    bool? readyToAcceptChildren,
    String? acceptChildrenStatus,
    String? adoptionPreference,
    String? groomStayWifeHouse,
    String? brideHusbandStayHome,
    String? firstMarriageOpenToRemarriage,
    String? firstMarriageAdoptChildren,
    String? firstMarriageMaxChildren,
    String? residencePreference,
    String? parentCarePreference,
    String? profileFor,
    String? timeline,
    bool? willingToStayAtBrideHome,
    bool? filterByBrideHomeWillingness,
    bool? prefRelocateToBrideHome,
    int? prefAgeMin,
    int? prefAgeMax,
    String? prefDistrict,
    String? prefHabits,
    bool? prefJointFamily,
    bool? prefRelocate,
    bool? prefManageJobFamily,
    bool? prefDirectTalk,
    bool? prefNuclearFamily,
    bool? prefShareFinances,
    bool? prefNightShift,
    bool? prefConsultDecisions,
    bool? prefDiscloseDebts,
    bool? prefTravelSocialize,
    String? prefLocation,
    String? height,
    String? weight,
    int? heightCm,
    int? weightKg,
    String? bloodGroup,
    String? physicalStatus,
    String? smokingHabit,
    String? drinkingHabit,
    String? confidentialPhotoUrl,
    bool? adminOnlyMediator,
    double? homeLat,
    double? homeLng,
    String? digipin,
  }) {
    return UserFamilyDetails(
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      isFatherDeceased: isFatherDeceased ?? this.isFatherDeceased,
      isMotherDeceased: isMotherDeceased ?? this.isMotherDeceased,
      houseName: houseName ?? this.houseName,
      region: region ?? this.region,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      publicDisplayNumber: publicDisplayNumber ?? this.publicDisplayNumber,
      childrenCount: childrenCount ?? this.childrenCount,
      childrenDetails: childrenDetails ?? this.childrenDetails,
      hasChildren: hasChildren ?? this.hasChildren,
      readyToAcceptChildren: readyToAcceptChildren ?? this.readyToAcceptChildren,
      acceptChildrenStatus: acceptChildrenStatus ?? this.acceptChildrenStatus,
      adoptionPreference: adoptionPreference ?? this.adoptionPreference,
      groomStayWifeHouse: groomStayWifeHouse ?? this.groomStayWifeHouse,
      brideHusbandStayHome: brideHusbandStayHome ?? this.brideHusbandStayHome,
      firstMarriageOpenToRemarriage: firstMarriageOpenToRemarriage ?? this.firstMarriageOpenToRemarriage,
      firstMarriageAdoptChildren: firstMarriageAdoptChildren ?? this.firstMarriageAdoptChildren,
      firstMarriageMaxChildren: firstMarriageMaxChildren ?? this.firstMarriageMaxChildren,
      residencePreference: residencePreference ?? this.residencePreference,
      parentCarePreference: parentCarePreference ?? this.parentCarePreference,
      profileFor: profileFor ?? this.profileFor,
      timeline: timeline ?? this.timeline,
      willingToStayAtBrideHome: willingToStayAtBrideHome ?? this.willingToStayAtBrideHome,
      filterByBrideHomeWillingness: filterByBrideHomeWillingness ?? this.filterByBrideHomeWillingness,
      prefRelocateToBrideHome: prefRelocateToBrideHome ?? this.prefRelocateToBrideHome,
      prefAgeMin: prefAgeMin ?? this.prefAgeMin,
      prefAgeMax: prefAgeMax ?? this.prefAgeMax,
      prefDistrict: prefDistrict ?? this.prefDistrict,
      prefHabits: prefHabits ?? this.prefHabits,
      prefJointFamily: prefJointFamily ?? this.prefJointFamily,
      prefRelocate: prefRelocate ?? this.prefRelocate,
      prefManageJobFamily: prefManageJobFamily ?? this.prefManageJobFamily,
      prefDirectTalk: prefDirectTalk ?? this.prefDirectTalk,
      prefNuclearFamily: prefNuclearFamily ?? this.prefNuclearFamily,
      prefShareFinances: prefShareFinances ?? this.prefShareFinances,
      prefNightShift: prefNightShift ?? this.prefNightShift,
      prefConsultDecisions: prefConsultDecisions ?? this.prefConsultDecisions,
      prefDiscloseDebts: prefDiscloseDebts ?? this.prefDiscloseDebts,
      prefTravelSocialize: prefTravelSocialize ?? this.prefTravelSocialize,
      prefLocation: prefLocation ?? this.prefLocation,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      physicalStatus: physicalStatus ?? this.physicalStatus,
      smokingHabit: smokingHabit ?? this.smokingHabit,
      drinkingHabit: drinkingHabit ?? this.drinkingHabit,
      confidentialPhotoUrl: confidentialPhotoUrl ?? this.confidentialPhotoUrl,
      adminOnlyMediator: adminOnlyMediator ?? this.adminOnlyMediator,
      homeLat: homeLat ?? this.homeLat,
      homeLng: homeLng ?? this.homeLng,
      digipin: digipin ?? this.digipin,
    );
  }
}
