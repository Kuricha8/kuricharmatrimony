import '../enums.dart';
import '../user_profile.dart';

class UserProfileSerialization {
  static UserProfile guest() {
    return UserProfile(
      id: 'guest',
      email: 'guest@kurichiyarmatrimony.com',
      name: 'Guest User',
      age: 21,
      photoUrl: '',
      gender: Gender.male,
      maritalStatus: MaritalStatus.first,
      educationCareer: const UserEducationCareer(),
      familyDetails: const UserFamilyDetails(),
      lineageDetails: const UserLineageDetails(),
      accountStatusDetails: const UserAccountStatus(
        status: 'ACTIVE',
        accountStatus: AccountStatus.approved,
        profileStatus: ProfileStatus.active,
        registrationStatus: 'live',
        verificationStatus: 'approved',
        role: 'guest',
        rawIsApproved: true,
      ),
    );
  }

  static UserProfile fromMap(Map<String, dynamic> row) {
    int parseInt(dynamic val, [int fallback = 0]) =>
        val is int ? val : int.tryParse(val?.toString() ?? '') ?? fallback;

    DateTime? parseDate(dynamic v) =>
        v == null ? null : (v is DateTime ? v : DateTime.tryParse(v.toString()));

    Gender parseGender(dynamic g) {
      final s = g?.toString().toLowerCase();
      return (s == 'female') ? Gender.female : Gender.male;
    }

    MaritalStatus parseMaritalStatus(dynamic m) {
      final s = m?.toString().toLowerCase();
      if (s == 'remarriage2nd') return MaritalStatus.remarriage2nd;
      if (s == 'remarriage3rdplus') return MaritalStatus.remarriage3rdPlus;
      return MaritalStatus.first;
    }

    SubscriptionTier parseSubscription(dynamic s) {
      if (s == null) return SubscriptionTier.free;
      final str = s.toString().toLowerCase();
      return SubscriptionTier.values.firstWhere((e) => e.name.toLowerCase() == str, orElse: () => SubscriptionTier.free);
    }

    List<String> parseStringList(dynamic l) {
      if (l is List) return l.map((e) => e.toString()).toList();
      return [];
    }

    final id = (row['id'] ?? '').toString();
    final email = (row['email'] ?? '').toString();
    final rawName = row['full_name'] ??
        row['fullName'] ??
        row['display_name'] ??
        row['displayName'] ??
        row['name'] ??
        row['candidate_name'] ??
        row['candidateName'] ??
        row['user_name'] ??
        row['userName'] ??
        row['member_name'] ??
        row['memberName'] ??
        row['first_name'] ??
        row['firstName'];
    final nameStr = rawName?.toString().trim();
    final name = (nameStr != null &&
            nameStr.isNotEmpty &&
            nameStr.toLowerCase() != 'unknown' &&
            nameStr.toLowerCase() != 'null')
        ? nameStr
        : 'അംഗം';
    final age = parseInt(row['age'], 21);
    final photoUrl = (row['photo_url'] ?? row['photoUrl'] ?? '').toString();
    final fullLengthPhotoUrl = (row['full_length_photo_url'] ?? row['fullLengthPhotoUrl'] ?? row['full_size_photo_url'])?.toString();
    final additionalPhotos = parseStringList(row['additional_photos'] ?? row['additionalPhotos']);
    final subscriptionStartDate = parseDate(row['subscription_start_date'] ?? row['subscriptionStartDate']);
    final subscriptionEndDate = parseDate(row['subscription_end_date'] ?? row['subscriptionEndDate']);
    final profileViewsUsed = parseInt(row['profile_views_used'] ?? row['profileViewsUsed'], 0);
    final viewQuota = parseInt(row['view_quota'] ?? row['viewQuota'], 50);

    return UserProfile(
      id: id,
      email: email,
      name: name,
      age: age,
      photoUrl: photoUrl,
      fullLengthPhotoUrl: fullLengthPhotoUrl,
      additionalPhotos: additionalPhotos,
      gender: parseGender(row['gender']),
      maritalStatus: parseMaritalStatus(row['marital_status'] ?? row['maritalStatus']),
      bio: row['bio']?.toString(),
      dob: parseDate(row['dob']),
      dateOfBirth: parseDate(row['date_of_birth'] ?? row['dateOfBirth']),
      subscriptionTier: parseSubscription(row['subscription_tier'] ?? row['subscriptionTier']),
      viewedProfileIds: parseStringList(row['viewed_profile_ids'] ?? row['viewedProfileIds']),
      favoriteProfileIds: parseStringList(row['favorite_profile_ids'] ?? row['favoriteProfileIds']),
      agreedMutualMatches: parseStringList(row['agreed_mutual_matches'] ?? row['agreedMutualMatches']),
      mutedUserIds: parseStringList(row['muted_user_ids'] ?? row['mutedUserIds']),
      visitors: (row['visitors'] is List)
          ? (row['visitors'] as List).whereType<Map<String, dynamic>>().map((v) => ProfileVisitor.fromMap(v)).toList()
          : [],
      createdAt: parseDate(row['created_at']),
      lastSeen: parseDate(row['last_seen']),
      lifestyleAnswers: (row['lifestyle_answers'] is Map) ? Map<String, dynamic>.from(row['lifestyle_answers']) : const {},
      hobbies: parseStringList(row['hobbies']),
      isElder: row['is_elder'] == true,
      elderVouchesCount: parseInt(row['elder_vouches_count'], 0),
      memberVouchesCount: parseInt(row['member_vouches_count'], 0),
      trustBadge: (row['trust_badge'] ?? 'standard').toString(),
      boostedUntil: parseDate(row['boosted_until']),
      subscriptionStartDate: subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate,
      profileViewsUsed: profileViewsUsed,
      viewQuota: viewQuota,
      educationCareer: UserEducationCareer.fromMap(row),
      familyDetails: UserFamilyDetails.fromMap(row),
      lineageDetails: UserLineageDetails.fromMap(row),
      accountStatusDetails: UserAccountStatus.fromMap(row),
    );
  }

  static Map<String, dynamic> toMap(UserProfile p) {
    return {
      'id': p.id,
      'email': p.email,
      'name': p.name,
      'age': p.age,
      'photo_url': p.photoUrl,
      'full_length_photo_url': p.fullLengthPhotoUrl,
      'full_size_photo_url': p.fullLengthPhotoUrl,
      'additional_photos': p.additionalPhotos,
      'gender': p.gender.name,
      'marital_status': p.maritalStatus.name,
      'bio': p.bio,
      'dob': p.dob?.toIso8601String(),
      'date_of_birth': p.dateOfBirth?.toIso8601String(),
      'subscription_tier': p.subscriptionTier.name,
      'viewed_profile_ids': p.viewedProfileIds,
      'favorite_profile_ids': p.favoriteProfileIds,
      'agreed_mutual_matches': p.agreedMutualMatches,
      'muted_user_ids': p.mutedUserIds,
      'visitors': p.visitors.map((v) => v.toMap()).toList(),
      'created_at': p.createdAt?.toIso8601String(),
      'last_seen': p.lastSeen?.toIso8601String(),
      'lifestyle_answers': p.lifestyleAnswers,
      'hobbies': p.hobbies,
      'is_elder': p.isElder,
      'elder_vouches_count': p.elderVouchesCount,
      'member_vouches_count': p.memberVouchesCount,
      'trust_badge': p.trustBadge,
      'boosted_until': p.boostedUntil?.toIso8601String(),
      'subscription_start_date': p.subscriptionStartDate?.toIso8601String(),
      'subscription_end_date': p.subscriptionEndDate?.toIso8601String(),
      'profile_views_used': p.profileViewsUsed,
      'view_quota': p.viewQuota,
      ...p.educationCareer.toMap(),
      ...p.familyDetails.toMap(),
      ...p.lineageDetails.toMap(),
      ...p.accountStatusDetails.toMap(),
    };
  }

  static UserProfile copyWith(
    UserProfile p, {
    String? id,
    String? email,
    String? name,
    int? age,
    String? photoUrl,
    String? fullLengthPhotoUrl,
    List<String>? additionalPhotos,
    Gender? gender,
    MaritalStatus? maritalStatus,
    String? bio,
    DateTime? dob,
    DateTime? dateOfBirth,
    SubscriptionTier? subscriptionTier,
    List<String>? viewedProfileIds,
    List<String>? favoriteProfileIds,
    List<String>? agreedMutualMatches,
    List<String>? mutedUserIds,
    List<ProfileVisitor>? visitors,
    DateTime? createdAt,
    DateTime? lastSeen,
    Map<String, dynamic>? lifestyleAnswers,
    List<String>? hobbies,
    bool? isElder,
    int? elderVouchesCount,
    int? memberVouchesCount,
    String? trustBadge,
    DateTime? boostedUntil,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    int? profileViewsUsed,
    int? viewQuota,
    UserEducationCareer? educationCareer,
    UserFamilyDetails? familyDetails,
    UserLineageDetails? lineageDetails,
    UserAccountStatus? accountStatusDetails,
    // Direct Clan / Tharavadu:
    dynamic fatherClanId,
    dynamic motherClanId,
    String? fatherTharavadu,
    String? motherTharavadu,
    bool? isOutOfCaste,
    // Direct Account / Status:
    dynamic accountStatus,
    dynamic profileStatus,
    String? rejectionReason,
    String? planTier,
    bool? isPremium,
    String? planStatus,
    bool? allowDirectMessages,
    bool? allowScreenshot,
    bool? isStealthActiveMode,
    // Direct Preferences:
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
    double? homeLat,
    double? homeLng,
    String? digipin,
  }) {
    final baseLineage = lineageDetails ?? p.lineageDetails;
    final updatedLineage = (fatherClanId != null ||
            motherClanId != null ||
            fatherTharavadu != null ||
            motherTharavadu != null ||
            isOutOfCaste != null)
        ? baseLineage.copyWith(
            fatherClanId: fatherClanId != null
                ? (fatherClanId is int ? fatherClanId : int.tryParse(fatherClanId.toString()))
                : null,
            motherClanId: motherClanId != null
                ? (motherClanId is int ? motherClanId : int.tryParse(motherClanId.toString()))
                : null,
            fatherTharavadu: fatherTharavadu,
            motherTharavadu: motherTharavadu,
            isOutOfCaste: isOutOfCaste,
          )
        : baseLineage;

    final baseFamily = familyDetails ?? p.familyDetails;
    final updatedFamily = (prefJointFamily != null ||
            prefRelocate != null ||
            prefManageJobFamily != null ||
            prefDirectTalk != null ||
            prefNuclearFamily != null ||
            prefShareFinances != null ||
            prefNightShift != null ||
            prefConsultDecisions != null ||
            prefDiscloseDebts != null ||
            prefTravelSocialize != null ||
            homeLat != null ||
            homeLng != null ||
            digipin != null)
        ? baseFamily.copyWith(
            prefJointFamily: prefJointFamily,
            prefRelocate: prefRelocate,
            prefManageJobFamily: prefManageJobFamily,
            prefDirectTalk: prefDirectTalk,
            prefNuclearFamily: prefNuclearFamily,
            prefShareFinances: prefShareFinances,
            prefNightShift: prefNightShift,
            prefConsultDecisions: prefConsultDecisions,
            prefDiscloseDebts: prefDiscloseDebts,
            prefTravelSocialize: prefTravelSocialize,
            homeLat: homeLat,
            homeLng: homeLng,
            digipin: digipin,
          )
        : baseFamily;

    final baseAccount = accountStatusDetails ?? p.accountStatusDetails;
    AccountStatus? parsedAccountStatus;
    if (accountStatus is AccountStatus) {
      parsedAccountStatus = accountStatus;
    } else if (accountStatus is String) {
      final s = accountStatus.toLowerCase().trim();
      parsedAccountStatus = AccountStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == s,
        orElse: () => baseAccount.accountStatus,
      );
    }

    ProfileStatus? parsedProfileStatus;
    if (profileStatus is ProfileStatus) {
      parsedProfileStatus = profileStatus;
    } else if (profileStatus is String) {
      final s = profileStatus.toLowerCase().trim();
      parsedProfileStatus = ProfileStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == s,
        orElse: () => baseAccount.profileStatus,
      );
    }

    final updatedAccount = (parsedAccountStatus != null ||
            parsedProfileStatus != null ||
            rejectionReason != null ||
            planTier != null ||
            isPremium != null ||
            planStatus != null ||
            allowDirectMessages != null ||
            allowScreenshot != null ||
            isStealthActiveMode != null)
        ? baseAccount.copyWith(
            accountStatus: parsedAccountStatus,
            profileStatus: parsedProfileStatus,
            rejectionReason: rejectionReason,
            planTier: planTier,
            isPremium: isPremium,
            planStatus: planStatus,
            allowDirectMessages: allowDirectMessages,
            allowScreenshot: allowScreenshot,
            isStealthActive: isStealthActiveMode,
          )
        : baseAccount;

    return UserProfile(
      id: id ?? p.id,
      email: email ?? p.email,
      name: name ?? p.name,
      age: age ?? p.age,
      photoUrl: photoUrl ?? p.photoUrl,
      fullLengthPhotoUrl: fullLengthPhotoUrl ?? p.fullLengthPhotoUrl,
      additionalPhotos: additionalPhotos ?? p.additionalPhotos,
      gender: gender ?? p.gender,
      maritalStatus: maritalStatus ?? p.maritalStatus,
      bio: bio ?? p.bio,
      dob: dob ?? p.dob,
      dateOfBirth: dateOfBirth ?? p.dateOfBirth,
      subscriptionTier: subscriptionTier ?? p.subscriptionTier,
      viewedProfileIds: viewedProfileIds ?? p.viewedProfileIds,
      favoriteProfileIds: favoriteProfileIds ?? p.favoriteProfileIds,
      agreedMutualMatches: agreedMutualMatches ?? p.agreedMutualMatches,
      mutedUserIds: mutedUserIds ?? p.mutedUserIds,
      visitors: visitors ?? p.visitors,
      createdAt: createdAt ?? p.createdAt,
      lastSeen: lastSeen ?? p.lastSeen,
      lifestyleAnswers: lifestyleAnswers ?? p.lifestyleAnswers,
      hobbies: hobbies ?? p.hobbies,
      isElder: isElder ?? p.isElder,
      elderVouchesCount: elderVouchesCount ?? p.elderVouchesCount,
      memberVouchesCount: memberVouchesCount ?? p.memberVouchesCount,
      trustBadge: trustBadge ?? p.trustBadge,
      boostedUntil: boostedUntil ?? p.boostedUntil,
      subscriptionStartDate: subscriptionStartDate ?? p.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? p.subscriptionEndDate,
      profileViewsUsed: profileViewsUsed ?? p.profileViewsUsed,
      viewQuota: viewQuota ?? p.viewQuota,
      educationCareer: educationCareer ?? p.educationCareer,
      familyDetails: updatedFamily,
      lineageDetails: updatedLineage,
      accountStatusDetails: updatedAccount,
    );
  }
}
