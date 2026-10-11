import '../enums.dart';

class UserAccountStatus {
  final String status;
  final AccountStatus accountStatus;
  final ProfileStatus profileStatus;
  final String registrationStatus;
  final String verificationStatus;
  final bool? isBlocked;
  final String? blockReason;
  final bool isBanned;
  final String role;
  final String? rejectionReason;
  final bool isAgent;
  final String? agentCode;
  final String? agentApprovalStatus;
  final Map<String, dynamic>? pendingProfileEdits;
  final String? idDocumentUrl;
  final bool isHidden;
  final bool isProfileHidden;
  final DateTime? hiddenUntilDate;
  final DateTime? privacyExpiryDate;
  final bool isAutoRenewalEnabled;
  final bool isNameLocked;
  final bool allowPhotoEdit;
  final bool isDummy;
  final bool isOnline;
  final bool isBrokerFlagged;
  final bool isMarketingAllowed;
  final String? adminNotes;
  final String? adminCallNotes;
  final DateTime? deleteRequestedAt;
  final bool hideContactInfo;
  final bool allowDirectMessages;
  final bool allowScreenshot;
  final bool videoCallEnabled;
  final String? planTier;
  final DateTime? planExpiry;
  final bool isPremium;
  final String? planStatus;
  final DateTime? otpGeneratedAt;
  final String? whatsappOtp;
  final String? currentScreen;
  final bool isStealthActive;
  final DateTime? stealthExpiryDate;
  final String? marriageType;
  final bool rawIsApproved;
  final String? approvalStatus;
  final bool isDeleted;

  const UserAccountStatus({
    this.status = 'PENDING',
    this.accountStatus = AccountStatus.pending,
    this.profileStatus = ProfileStatus.active,
    this.registrationStatus = 'pending',
    this.verificationStatus = 'pending',
    this.isBlocked = false,
    this.blockReason,
    this.isBanned = false,
    this.role = 'member',
    this.rejectionReason,
    this.isAgent = false,
    this.agentCode,
    this.agentApprovalStatus,
    this.pendingProfileEdits,
    this.idDocumentUrl,
    this.isHidden = false,
    this.isProfileHidden = false,
    this.hiddenUntilDate,
    this.privacyExpiryDate,
    this.isAutoRenewalEnabled = false,
    this.isNameLocked = false,
    this.allowPhotoEdit = true,
    this.isDummy = false,
    this.isOnline = false,
    this.isBrokerFlagged = false,
    this.isMarketingAllowed = false,
    this.adminNotes,
    this.adminCallNotes,
    this.deleteRequestedAt,
    this.hideContactInfo = false,
    this.allowDirectMessages = true,
    this.allowScreenshot = false,
    this.videoCallEnabled = false,
    this.planTier,
    this.planExpiry,
    this.isPremium = false,
    this.planStatus,
    this.otpGeneratedAt,
    this.whatsappOtp,
    this.currentScreen,
    this.isStealthActive = false,
    this.stealthExpiryDate,
    this.marriageType,
    this.rawIsApproved = false,
    this.approvalStatus,
    this.isDeleted = false,
  });

  bool get isActive => status == 'ACTIVE' && !(isBlocked ?? false);

  bool get isApproved {
    if (isBlocked == true || isBanned || isDeleted) return false;
    if (rawIsApproved) return true;
    final acc = accountStatus.name.toLowerCase();
    final st = status.toLowerCase();
    final ver = verificationStatus.toLowerCase();
    final reg = registrationStatus.toLowerCase();
    final app = (approvalStatus ?? '').toLowerCase();

    return acc == 'approved' ||
        acc == 'active' ||
        acc == 'live' ||
        st == 'approved' ||
        st == 'active' ||
        st == 'live' ||
        ver == 'approved' ||
        ver == 'verified' ||
        reg == 'approved' ||
        reg == 'active' ||
        reg == 'live' ||
        app == 'approved' ||
        app == 'verified';
  }

  bool get isAdmin =>
      role.toLowerCase().trim() == 'admin' ||
      role.toLowerCase().trim() == 'super_admin' ||
      role.toLowerCase().trim() == 'administrator' ||
      role.toLowerCase().trim() == 'system' ||
      role.toLowerCase().trim() == 'support';

  factory UserAccountStatus.fromMap(Map<String, dynamic> row) {
    AccountStatus parseAccountStatus(dynamic v) {
      if (v == null) return AccountStatus.pending;
      final str = v.toString().toLowerCase().trim();
      return AccountStatus.values.firstWhere((e) => e.name.toLowerCase() == str, orElse: () => AccountStatus.pending);
    }

    ProfileStatus parseProfileStatus(dynamic v) {
      if (v == null) return ProfileStatus.active;
      final str = v.toString().toLowerCase().trim();
      return ProfileStatus.values.firstWhere((e) => e.name.toLowerCase() == str, orElse: () => ProfileStatus.active);
    }

    final accStatus = parseAccountStatus(row['account_status'] ?? row['accountStatus']);
    final profStatus = parseProfileStatus(row['profile_status'] ?? row['profileStatus']);
    final regStatus = (row['registration_status'] ?? row['registrationStatus'] ?? 'pending').toString();
    final verStatus = (row['verification_status'] ?? row['verificationStatus'] ?? 'pending').toString();
    final banned = row['is_banned'] == true || row['isBanned'] == true;
    final blocked = row['is_blocked'] == true || row['isBlocked'] == true || banned;
    final bool rawApproved = row['is_approved'] == true ||
        row['is_approved']?.toString().toLowerCase() == 'true' ||
        row['isApproved'] == true ||
        row['isApproved']?.toString().toLowerCase() == 'true';
    final String apprStatus = (row['approval_status'] ?? row['approvalStatus'] ?? '').toString();
    final bool deleted = row['is_deleted'] == true ||
        row['is_deleted']?.toString().toLowerCase() == 'true' ||
        row['isDeleted'] == true;

    String computedStatus = (row['status'] ?? '').toString().toUpperCase();
    if (computedStatus.isEmpty) {
      final isApproved = rawApproved ||
          accStatus == AccountStatus.approved ||
          regStatus.toLowerCase() == 'active' ||
          regStatus.toLowerCase() == 'approved' ||
          verStatus.toLowerCase() == 'approved' ||
          apprStatus.toLowerCase() == 'approved';
      computedStatus = (isApproved && !blocked) ? 'ACTIVE' : 'PENDING';
    }

    DateTime? parseDate(dynamic v) => v == null ? null : (v is DateTime ? v : DateTime.tryParse(v.toString()));

    return UserAccountStatus(
      status: computedStatus,
      accountStatus: accStatus,
      profileStatus: profStatus,
      registrationStatus: regStatus,
      verificationStatus: verStatus,
      isBlocked: blocked,
      blockReason: row['block_reason']?.toString(),
      isBanned: banned,
      role: (row['role'] ?? 'member').toString(),
      rejectionReason: row['rejection_reason']?.toString(),
      isAgent: row['is_agent'] == true || row['isAgent'] == true,
      agentCode: row['agent_code']?.toString(),
      agentApprovalStatus: row['agent_approval_status']?.toString(),
      pendingProfileEdits: row['pending_profile_edits'] as Map<String, dynamic>?,
      idDocumentUrl: row['id_document_url']?.toString(),
      isHidden: row['is_hidden'] == true || row['isHidden'] == true,
      isProfileHidden: row['is_profile_hidden'] == true || row['isProfileHidden'] == true,
      hiddenUntilDate: parseDate(row['hidden_until_date']),
      privacyExpiryDate: parseDate(row['privacy_expiry_date']),
      isAutoRenewalEnabled: row['is_auto_renewal_enabled'] == true,
      isNameLocked: row['is_name_locked'] == true,
      allowPhotoEdit: row['allow_photo_edit'] != false,
      isDummy: row['is_dummy'] == true,
      isOnline: row['is_online'] == true,
      isBrokerFlagged: row['is_broker_flagged'] == true,
      isMarketingAllowed: row['is_marketing_allowed'] == true,
      adminNotes: row['admin_notes']?.toString(),
      adminCallNotes: row['admin_call_notes']?.toString(),
      deleteRequestedAt: parseDate(row['delete_requested_at']),
      hideContactInfo: row['hide_contact_info'] == true,
      allowDirectMessages: row['allow_direct_messages'] != false,
      allowScreenshot: row['allow_screenshot'] == true ||
          (row.containsKey('screenshot_blocked') &&
              row['screenshot_blocked'] == false) ||
          row['allowScreenshot'] == true,
      videoCallEnabled: row['video_call_enabled'] == true,
      planTier: row['plan_tier']?.toString() ?? row['planTier']?.toString(),
      planExpiry: parseDate(row['plan_expiry'] ?? row['planExpiry']),
      isPremium: row['is_premium'] == true ||
          row['isPremium'] == true ||
          (row['plan_status']?.toString().toLowerCase() == 'active') ||
          (row['planStatus']?.toString().toLowerCase() == 'active'),
      planStatus: (row['plan_status'] ?? row['planStatus'])?.toString(),
      otpGeneratedAt: parseDate(row['otp_generated_at']),
      whatsappOtp: row['whatsapp_otp']?.toString(),
      currentScreen: row['current_screen']?.toString(),
      isStealthActive: row['is_stealth_active'] == true,
      stealthExpiryDate: parseDate(row['stealth_expiry_date']),
      marriageType: row['marriage_type']?.toString(),
      rawIsApproved: rawApproved,
      approvalStatus: apprStatus.isNotEmpty ? apprStatus : null,
      isDeleted: deleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'account_status': accountStatus.name,
      'profile_status': profileStatus.name,
      'registration_status': registrationStatus,
      'verification_status': verificationStatus,
      'is_blocked': isBlocked,
      'block_reason': blockReason,
      'is_banned': isBanned,
      'role': role,
      'rejection_reason': rejectionReason,
      'is_agent': isAgent,
      'agent_code': agentCode,
      'agent_approval_status': agentApprovalStatus,
      'pending_profile_edits': pendingProfileEdits,
      'id_document_url': idDocumentUrl,
      'is_hidden': isHidden,
      'is_profile_hidden': isProfileHidden,
      'hidden_until_date': hiddenUntilDate?.toIso8601String(),
      'privacy_expiry_date': privacyExpiryDate?.toIso8601String(),
      'is_auto_renewal_enabled': isAutoRenewalEnabled,
      'is_name_locked': isNameLocked,
      'allow_photo_edit': allowPhotoEdit,
      'is_dummy': isDummy,
      'is_online': isOnline,
      'is_broker_flagged': isBrokerFlagged,
      'is_marketing_allowed': isMarketingAllowed,
      'admin_notes': adminNotes,
      'admin_call_notes': adminCallNotes,
      'delete_requested_at': deleteRequestedAt?.toIso8601String(),
      'hide_contact_info': hideContactInfo,
      'allow_direct_messages': allowDirectMessages,
      'allowScreenshot': allowScreenshot,
      'allow_screenshot': allowScreenshot,
      'screenshot_blocked': !allowScreenshot,
      'video_call_enabled': videoCallEnabled,
      'plan_tier': planTier,
      'planTier': planTier,
      'plan_expiry': planExpiry?.toIso8601String(),
      'is_premium': isPremium,
      'isPremium': isPremium,
      'plan_status': planStatus,
      'planStatus': planStatus,
      'otp_generated_at': otpGeneratedAt?.toIso8601String(),
      'whatsapp_otp': whatsappOtp,
      'current_screen': currentScreen,
      'is_stealth_active': isStealthActive,
      'stealth_expiry_date': stealthExpiryDate?.toIso8601String(),
      'marriage_type': marriageType,
      'is_approved': rawIsApproved || isApproved,
      'approval_status': approvalStatus,
      'is_deleted': isDeleted,
    };
  }

  UserAccountStatus copyWith({
    String? status,
    AccountStatus? accountStatus,
    ProfileStatus? profileStatus,
    String? registrationStatus,
    String? verificationStatus,
    bool? isBlocked,
    String? blockReason,
    bool? isBanned,
    String? role,
    String? rejectionReason,
    bool? isAgent,
    String? agentCode,
    String? agentApprovalStatus,
    Map<String, dynamic>? pendingProfileEdits,
    String? idDocumentUrl,
    bool? isHidden,
    bool? isProfileHidden,
    DateTime? hiddenUntilDate,
    DateTime? privacyExpiryDate,
    bool? isAutoRenewalEnabled,
    bool? isNameLocked,
    bool? allowPhotoEdit,
    bool? isDummy,
    bool? isOnline,
    bool? isBrokerFlagged,
    bool? isMarketingAllowed,
    String? adminNotes,
    String? adminCallNotes,
    DateTime? deleteRequestedAt,
    bool? hideContactInfo,
    bool? allowDirectMessages,
    bool? allowScreenshot,
    bool? videoCallEnabled,
    String? planTier,
    DateTime? planExpiry,
    bool? isPremium,
    String? planStatus,
    DateTime? otpGeneratedAt,
    String? whatsappOtp,
    String? currentScreen,
    bool? isStealthActive,
    DateTime? stealthExpiryDate,
    String? marriageType,
    bool? rawIsApproved,
    String? approvalStatus,
    bool? isDeleted,
  }) {
    return UserAccountStatus(
      status: status ?? this.status,
      accountStatus: accountStatus ?? this.accountStatus,
      profileStatus: profileStatus ?? this.profileStatus,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isBlocked: isBlocked ?? this.isBlocked,
      blockReason: blockReason ?? this.blockReason,
      isBanned: isBanned ?? this.isBanned,
      role: role ?? this.role,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isAgent: isAgent ?? this.isAgent,
      agentCode: agentCode ?? this.agentCode,
      agentApprovalStatus: agentApprovalStatus ?? this.agentApprovalStatus,
      pendingProfileEdits: pendingProfileEdits ?? this.pendingProfileEdits,
      idDocumentUrl: idDocumentUrl ?? this.idDocumentUrl,
      isHidden: isHidden ?? this.isHidden,
      isProfileHidden: isProfileHidden ?? this.isProfileHidden,
      hiddenUntilDate: hiddenUntilDate ?? this.hiddenUntilDate,
      privacyExpiryDate: privacyExpiryDate ?? this.privacyExpiryDate,
      isAutoRenewalEnabled: isAutoRenewalEnabled ?? this.isAutoRenewalEnabled,
      isNameLocked: isNameLocked ?? this.isNameLocked,
      allowPhotoEdit: allowPhotoEdit ?? this.allowPhotoEdit,
      isDummy: isDummy ?? this.isDummy,
      isOnline: isOnline ?? this.isOnline,
      isBrokerFlagged: isBrokerFlagged ?? this.isBrokerFlagged,
      isMarketingAllowed: isMarketingAllowed ?? this.isMarketingAllowed,
      adminNotes: adminNotes ?? this.adminNotes,
      adminCallNotes: adminCallNotes ?? this.adminCallNotes,
      deleteRequestedAt: deleteRequestedAt ?? this.deleteRequestedAt,
      hideContactInfo: hideContactInfo ?? this.hideContactInfo,
      allowDirectMessages: allowDirectMessages ?? this.allowDirectMessages,
      allowScreenshot: allowScreenshot ?? this.allowScreenshot,
      videoCallEnabled: videoCallEnabled ?? this.videoCallEnabled,
      planTier: planTier ?? this.planTier,
      planExpiry: planExpiry ?? this.planExpiry,
      isPremium: isPremium ?? this.isPremium,
      planStatus: planStatus ?? this.planStatus,
      otpGeneratedAt: otpGeneratedAt ?? this.otpGeneratedAt,
      whatsappOtp: whatsappOtp ?? this.whatsappOtp,
      currentScreen: currentScreen ?? this.currentScreen,
      isStealthActive: isStealthActive ?? this.isStealthActive,
      stealthExpiryDate: stealthExpiryDate ?? this.stealthExpiryDate,
      marriageType: marriageType ?? this.marriageType,
      rawIsApproved: rawIsApproved ?? this.rawIsApproved,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
