import 'enums.dart';
import 'profile/user_education_career.dart';
import 'profile/user_family_details.dart';
import 'profile/user_lineage_details.dart';
import 'profile/user_account_status.dart';
import 'profile/user_profile_compatibility.dart';
import 'profile/user_profile_serialization.dart';
import 'profile/view_record.dart';

export 'profile/user_education_career.dart';
export 'profile/user_family_details.dart';
export 'profile/user_lineage_details.dart';
export 'profile/user_account_status.dart';
export 'profile/view_record.dart';

class UserProfile with UserProfileCompatibilityMixin {
  final String id;
  final String email;
  final String name;
  final int age;
  final String photoUrl;
  final String? fullLengthPhotoUrl;
  final List<String> additionalPhotos;
  final Gender gender;
  final MaritalStatus maritalStatus;
  final String? bio;
  final DateTime? dob;
  final DateTime? dateOfBirth;
  final SubscriptionTier subscriptionTier;
  final List<String> viewedProfileIds;
  final List<String> favoriteProfileIds;
  final List<String> agreedMutualMatches;
  final List<String> mutedUserIds;
  final List<ProfileVisitor> visitors;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final Map<String, dynamic> lifestyleAnswers;
  final List<String> hobbies;
  final bool isElder;
  final int elderVouchesCount;
  final int memberVouchesCount;
  final String trustBadge;
  final DateTime? boostedUntil;

  // Subscription & privacy fields
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final int profileViewsUsed;
  final int viewQuota;

  @override
  final UserEducationCareer educationCareer;
  @override
  final UserFamilyDetails familyDetails;
  @override
  final UserLineageDetails lineageDetails;
  @override
  final UserAccountStatus accountStatusDetails;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    required this.photoUrl,
    this.fullLengthPhotoUrl,
    this.additionalPhotos = const [],
    required this.gender,
    required this.maritalStatus,
    this.bio,
    this.dob,
    this.dateOfBirth,
    this.subscriptionTier = SubscriptionTier.free,
    this.viewedProfileIds = const [],
    this.favoriteProfileIds = const [],
    this.agreedMutualMatches = const [],
    this.mutedUserIds = const [],
    this.visitors = const [],
    this.createdAt,
    this.lastSeen,
    this.lifestyleAnswers = const {},
    this.hobbies = const [],
    this.isElder = false,
    this.elderVouchesCount = 0,
    this.memberVouchesCount = 0,
    this.trustBadge = 'standard',
    this.boostedUntil,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.profileViewsUsed = 0,
    this.viewQuota = 50,
    this.educationCareer = const UserEducationCareer(),
    UserFamilyDetails familyDetails = const UserFamilyDetails(),
    UserLineageDetails lineageDetails = const UserLineageDetails(),
    UserAccountStatus accountStatusDetails = const UserAccountStatus(),
    // Direct Clan / Tharavadu parameters:
    dynamic fatherClanId,
    dynamic motherClanId,
    String? fatherTharavadu,
    String? motherTharavadu,
    bool isOutOfCaste = false,
    // Direct Subscription & Privacy / Account / Status fields:
    String? planTier,
    bool? isPremium,
    String? planStatus,
    bool isStealthActiveMode = false,
    bool allowDirectMessages = true,
    bool allowScreenshot = false,
    dynamic accountStatus,
    dynamic profileStatus,
    String? rejectionReason,
    // Direct Partner Preferences fields:
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
    // Direct Coordinates:
    double? homeLat,
    double? homeLng,
    String? digipin,
  })  : familyDetails = _buildFamilyDetails(
          familyDetails,
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
        ),
        lineageDetails = _buildLineageDetails(
          lineageDetails,
          fatherClanId: fatherClanId,
          motherClanId: motherClanId,
          fatherTharavadu: fatherTharavadu,
          motherTharavadu: motherTharavadu,
          isOutOfCaste: isOutOfCaste,
        ),
        accountStatusDetails = _buildAccountStatusDetails(
          accountStatusDetails,
          accountStatus: accountStatus,
          profileStatus: profileStatus,
          rejectionReason: rejectionReason,
          planTier: planTier,
          isPremium: isPremium,
          planStatus: planStatus,
          allowDirectMessages: allowDirectMessages,
          allowScreenshot: allowScreenshot,
          isStealthActiveMode: isStealthActiveMode,
        );

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? fallback;
  }

  static UserLineageDetails _buildLineageDetails(
    UserLineageDetails base, {
    dynamic fatherClanId,
    dynamic motherClanId,
    String? fatherTharavadu,
    String? motherTharavadu,
    bool isOutOfCaste = false,
  }) {
    if (fatherClanId == null &&
        motherClanId == null &&
        fatherTharavadu == null &&
        motherTharavadu == null &&
        !isOutOfCaste) {
      return base;
    }
    return base.copyWith(
      fatherClanId: fatherClanId != null ? _parseInt(fatherClanId, base.fatherClanId) : null,
      motherClanId: motherClanId != null ? _parseInt(motherClanId, base.motherClanId) : null,
      fatherTharavadu: fatherTharavadu ?? base.fatherTharavadu,
      motherTharavadu: motherTharavadu ?? base.motherTharavadu,
      isOutOfCaste: isOutOfCaste || base.isOutOfCaste,
    );
  }

  static UserFamilyDetails _buildFamilyDetails(
    UserFamilyDetails base, {
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
    if (prefJointFamily == null &&
        prefRelocate == null &&
        prefManageJobFamily == null &&
        prefDirectTalk == null &&
        prefNuclearFamily == null &&
        prefShareFinances == null &&
        prefNightShift == null &&
        prefConsultDecisions == null &&
        prefDiscloseDebts == null &&
        prefTravelSocialize == null &&
        homeLat == null &&
        homeLng == null &&
        digipin == null) {
      return base;
    }
    return base.copyWith(
      prefJointFamily: prefJointFamily ?? base.prefJointFamily,
      prefRelocate: prefRelocate ?? base.prefRelocate,
      prefManageJobFamily: prefManageJobFamily ?? base.prefManageJobFamily,
      prefDirectTalk: prefDirectTalk ?? base.prefDirectTalk,
      prefNuclearFamily: prefNuclearFamily ?? base.prefNuclearFamily,
      prefShareFinances: prefShareFinances ?? base.prefShareFinances,
      prefNightShift: prefNightShift ?? base.prefNightShift,
      prefConsultDecisions: prefConsultDecisions ?? base.prefConsultDecisions,
      prefDiscloseDebts: prefDiscloseDebts ?? base.prefDiscloseDebts,
      prefTravelSocialize: prefTravelSocialize ?? base.prefTravelSocialize,
      homeLat: homeLat ?? base.homeLat,
      homeLng: homeLng ?? base.homeLng,
      digipin: digipin ?? base.digipin,
    );
  }

  static UserAccountStatus _buildAccountStatusDetails(
    UserAccountStatus base, {
    dynamic accountStatus,
    dynamic profileStatus,
    String? rejectionReason,
    String? planTier,
    bool? isPremium,
    String? planStatus,
    bool? allowDirectMessages,
    bool? allowScreenshot,
    bool isStealthActiveMode = false,
  }) {
    AccountStatus? parsedAccountStatus;
    if (accountStatus is AccountStatus) {
      parsedAccountStatus = accountStatus;
    } else if (accountStatus is String) {
      final s = accountStatus.toLowerCase().trim();
      parsedAccountStatus = AccountStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == s,
        orElse: () => base.accountStatus,
      );
    }

    ProfileStatus? parsedProfileStatus;
    if (profileStatus is ProfileStatus) {
      parsedProfileStatus = profileStatus;
    } else if (profileStatus is String) {
      final s = profileStatus.toLowerCase().trim();
      parsedProfileStatus = ProfileStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == s,
        orElse: () => base.profileStatus,
      );
    }

    return base.copyWith(
      accountStatus: parsedAccountStatus,
      profileStatus: parsedProfileStatus,
      rejectionReason: rejectionReason ?? base.rejectionReason,
      planTier: planTier ?? base.planTier,
      isPremium: isPremium ?? base.isPremium,
      planStatus: planStatus ?? base.planStatus,
      allowDirectMessages: allowDirectMessages ?? base.allowDirectMessages,
      allowScreenshot: allowScreenshot ?? base.allowScreenshot,
      isStealthActive: isStealthActiveMode || base.isStealthActive,
    );
  }

  String get status => accountStatusDetails.status;
  @override
  bool? get isBlocked => accountStatusDetails.isBlocked;
  @override
  String? get blockReason => accountStatusDetails.blockReason;
  bool get isActive => status == 'ACTIVE' && !(isBlocked ?? false);

  String get phone => publicDisplayNumber ?? guardianPhone ?? '';
  List<String> get photoUrls => [if (photoUrl.isNotEmpty) photoUrl, ...additionalPhotos];
  String get tharavadu => tharavaduName;
  String get moietyGroup => maternalGroup;
  String get fullName => name;
  String? get motherTharavadName => motherTharavadu;
  String? get profession => job.isNotEmpty ? job : null;
  String? get occupation => job.isNotEmpty ? job : null;

  bool get isGoldTrust => trustBadge == 'gold' || elderVouchesCount >= 5;
  bool get isSilverTrust => trustBadge == 'silver' || (!isGoldTrust && elderVouchesCount >= 2);
  bool get isVip => subscriptionTier == SubscriptionTier.tier3;
  bool get isBoosted => boostedUntil != null && boostedUntil!.isAfter(DateTime.now());

  // Restored Getters & Methods
  bool get isPremium =>
      accountStatusDetails.isPremium ||
      accountStatusDetails.planStatus?.toLowerCase() == 'active' ||
      (planTier != null &&
          planTier!.toUpperCase() != 'FREE' &&
          planTier!.toUpperCase() != 'NONE') ||
      isSubscriptionActive ||
      subscriptionTier != SubscriptionTier.free;
  bool get isPremiumUser => isPremium;
  bool get isSubscriptionActive =>
      subscriptionEndDate != null && subscriptionEndDate!.isAfter(DateTime.now());
  bool get isApproved => accountStatusDetails.isApproved;
  bool get isDeleted => accountStatusDetails.isDeleted;

  bool get isCompleteAndDiscoverable =>
      (isApproved ||
          status.toUpperCase() == 'ACTIVE' ||
          status.toUpperCase() == 'APPROVED' ||
          verificationStatus.toUpperCase() == 'VERIFIED' ||
          verificationStatus.toUpperCase() == 'APPROVED' ||
          accountStatus == AccountStatus.approved) &&
      !(isBlocked ?? false) &&
      !(accountStatusDetails.isBanned) &&
      !isDeleted;
  int get viewsRemaining => viewQuota - profileViewsUsed;
  bool canViewProfile([String? targetProfileId]) => isPremium || viewsRemaining > 0;
  double get priorityScore => isPremium ? 100.0 : 50.0;
  bool get isStealthActiveMode => isStealthActive;

  factory UserProfile.guest() => UserProfileSerialization.guest();
  factory UserProfile.fromMap(Map<String, dynamic> row) => UserProfileSerialization.fromMap(row);
  Map<String, dynamic> toMap() => UserProfileSerialization.toMap(this);

  UserProfile copyWith({
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
  }) =>
      UserProfileSerialization.copyWith(
        this,
        id: id,
        email: email,
        name: name,
        age: age,
        photoUrl: photoUrl,
        fullLengthPhotoUrl: fullLengthPhotoUrl,
        additionalPhotos: additionalPhotos,
        gender: gender,
        maritalStatus: maritalStatus,
        bio: bio,
        dob: dob,
        dateOfBirth: dateOfBirth,
        subscriptionTier: subscriptionTier,
        viewedProfileIds: viewedProfileIds,
        favoriteProfileIds: favoriteProfileIds,
        agreedMutualMatches: agreedMutualMatches,
        mutedUserIds: mutedUserIds,
        visitors: visitors,
        createdAt: createdAt,
        lastSeen: lastSeen,
        lifestyleAnswers: lifestyleAnswers,
        hobbies: hobbies,
        isElder: isElder,
        elderVouchesCount: elderVouchesCount,
        memberVouchesCount: memberVouchesCount,
        trustBadge: trustBadge,
        boostedUntil: boostedUntil,
        subscriptionStartDate: subscriptionStartDate,
        subscriptionEndDate: subscriptionEndDate,
        profileViewsUsed: profileViewsUsed,
        viewQuota: viewQuota,
        educationCareer: educationCareer,
        familyDetails: familyDetails,
        lineageDetails: lineageDetails,
        accountStatusDetails: accountStatusDetails,
        fatherClanId: fatherClanId,
        motherClanId: motherClanId,
        fatherTharavadu: fatherTharavadu,
        motherTharavadu: motherTharavadu,
        isOutOfCaste: isOutOfCaste,
        accountStatus: accountStatus,
        profileStatus: profileStatus,
        rejectionReason: rejectionReason,
        planTier: planTier,
        isPremium: isPremium,
        planStatus: planStatus,
        allowDirectMessages: allowDirectMessages,
        allowScreenshot: allowScreenshot,
        isStealthActiveMode: isStealthActiveMode,
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
      );
}
