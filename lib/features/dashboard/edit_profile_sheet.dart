import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/services/photo_quality_validator_service.dart';
import 'edit_profile_state_mixin.dart';
import 'widgets/edit_profile/personal_details_section.dart';
import 'widgets/edit_profile/physical_details_section.dart';
import 'widgets/edit_profile/family_restricted_section.dart';
import 'widgets/edit_profile/partner_preferences_section.dart';
import '../clan_feed/tharavadu_list.dart';

class EditProfileSheet extends StatefulWidget {
  final UserProfile user;
  const EditProfileSheet({super.key, required this.user});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet>
    with EditProfileStateMixin<EditProfileSheet> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TharavaduService.instance,
      builder: (context, _) {
        if (isLoading) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final uniqueClansMap = <int, Clan>{};
        for (final clan in allClans) {
          uniqueClansMap[clan.id] = clan;
        }
        final uniqueClans = uniqueClansMap.values.toList();

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF9F7F3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Edit Profile Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5C3E00),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Update your profile, tharavad, bio, and contact information.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        if (pendingRequests.isNotEmpty &&
                            pendingRequests.any(
                              (r) =>
                                  (r['status'] ?? '')
                                      .toString()
                                      .toLowerCase() ==
                                  'pending',
                            )) ...[
                          const SizedBox(height: 16),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.amber.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.pending_actions,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'അഡ്മിൻ അനുമതിക്കായി കാത്തിരിക്കുന്നു (Pending Admin Approval)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF5C3E00),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${pendingRequests.length} തിരുത്തൽ അപേക്ഷകൾ അഡ്മിൻ പരിശോധിച്ചുവരുന്നു.',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Three Photo Slots:
                        // 1. Close-up Avatar
                        // 2. Dedicated Full-Length Photo (3:4 ratio - Mandatory)
                        // 3. Additional Photo (Optional)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'പ്രൊഫൈൽ ചിത്രങ്ങൾ (3 Slots)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5C3E00),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: currentFullLengthPhotoUrl.isNotEmpty
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: currentFullLengthPhotoUrl.isNotEmpty
                                            ? Colors.green.shade300
                                            : Colors.red.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          currentFullLengthPhotoUrl.isNotEmpty
                                              ? Icons.check_circle
                                              : Icons.warning_amber_rounded,
                                          size: 13,
                                          color: currentFullLengthPhotoUrl.isNotEmpty
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          currentFullLengthPhotoUrl.isNotEmpty
                                              ? 'ഫുൾ ഫോട്ടോ ചേർത്തു'
                                              : 'ഫുൾ ഫോട്ടോ നിർബന്ധം',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: currentFullLengthPhotoUrl.isNotEmpty
                                                ? Colors.green.shade800
                                                : Colors.red.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Slot 1: Close-up Photo
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        const Text(
                                          'ക്ലോസ്-അപ്പ്\n(Close-Up)',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5C3E00),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        AspectRatio(
                                          aspectRatio: 3 / 4,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.amber.shade400,
                                                width: 1.5,
                                              ),
                                              image: currentPhotoUrl.isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        currentPhotoUrl,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                if (currentPhotoUrl.isEmpty)
                                                  const Icon(
                                                    Icons.face,
                                                    size: 34,
                                                    color: Colors.grey,
                                                  ),
                                                if (isUploadingPhoto)
                                                  Container(
                                                    color: Colors.black45,
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Color(0xFFD4AF37),
                                                      ),
                                                    ),
                                                  ),
                                                Positioned(
                                                  bottom: 6,
                                                  right: 6,
                                                  child: InkWell(
                                                    onTap: isUploadingPhoto
                                                        ? null
                                                        : pickAndUploadPhoto,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        6,
                                                      ),
                                                      decoration:
                                                          const BoxDecoration(
                                                        color:
                                                            Color(0xFF000080),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.camera_alt,
                                                        color: Colors.white,
                                                        size: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'മുഖം നേരെ നോക്കുന്ന ചിത്രം',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Slot 2: Dedicated Full-Length Photo Slot (3:4 ratio - Mandatory)
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'ഫുൾ സൈസ് *',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFB71C1C),
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'നിർബന്ധം',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        AspectRatio(
                                          aspectRatio: 3 / 4,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: currentFullLengthPhotoUrl
                                                        .isNotEmpty
                                                    ? Colors.green.shade600
                                                    : Colors.red.shade500,
                                                width: currentFullLengthPhotoUrl
                                                        .isNotEmpty
                                                    ? 1.8
                                                    : 2.2,
                                              ),
                                              image: currentFullLengthPhotoUrl
                                                      .isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        currentFullLengthPhotoUrl,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                if (currentFullLengthPhotoUrl
                                                    .isEmpty)
                                                  InkWell(
                                                    onTap:
                                                        isUploadingFullLengthPhoto
                                                            ? null
                                                            : pickAndUploadFullLengthPhoto,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .accessibility_new,
                                                          size: 32,
                                                          color: Colors
                                                              .red.shade700,
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        const Text(
                                                          'ഫുൾ ഫോട്ടോ\n(3:4 portrait)',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .red.shade50,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              4,
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            '+ ചേർക്കുക',
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              color: Colors.red,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (isUploadingFullLengthPhoto)
                                                  Container(
                                                    color: Colors.black45,
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            Color(0xFFD4AF37),
                                                      ),
                                                    ),
                                                  ),
                                                // Deletion button for full-length photo (when exists)
                                                if (currentFullLengthPhotoUrl
                                                    .isNotEmpty)
                                                  Positioned(
                                                    top: 6,
                                                    right: 6,
                                                    child: InkWell(
                                                      onTap:
                                                          deleteFullLengthPhoto,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                          4,
                                                        ),
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.red,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.delete_outline,
                                                          color: Colors.white,
                                                          size: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                // Change photo button
                                                Positioned(
                                                  bottom: 6,
                                                  right: 6,
                                                  child: InkWell(
                                                    onTap:
                                                        isUploadingFullLengthPhoto
                                                            ? null
                                                            : pickAndUploadFullLengthPhoto,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        6,
                                                      ),
                                                      decoration:
                                                          const BoxDecoration(
                                                        color:
                                                            Color(0xFF000080),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.camera_alt,
                                                        color: Colors.white,
                                                        size: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'മുട്ടിനു താഴെ കാണുന്ന ചിത്രം (3:4 or 9:16)',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFF5C3E00),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Slot 3: Additional Photo (Optional)
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'അധിക ചിത്രം',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'ഐച്ഛികം',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        AspectRatio(
                                          aspectRatio: 3 / 4,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                                width: 1.2,
                                              ),
                                              image: currentAdditionalPhotoUrl
                                                      .isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        currentAdditionalPhotoUrl,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                if (currentAdditionalPhotoUrl
                                                    .isEmpty)
                                                  InkWell(
                                                    onTap:
                                                        isUploadingAdditionalPhoto
                                                            ? null
                                                            : pickAndUploadAdditionalPhoto,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .add_photo_alternate_outlined,
                                                          size: 30,
                                                          color: Colors
                                                              .grey.shade600,
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        const Text(
                                                          '+ ചിത്രം',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (isUploadingAdditionalPhoto)
                                                  Container(
                                                    color: Colors.black45,
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            Color(0xFFD4AF37),
                                                      ),
                                                    ),
                                                  ),
                                                // Delete button for additional photo
                                                if (currentAdditionalPhotoUrl
                                                    .isNotEmpty)
                                                  Positioned(
                                                    top: 6,
                                                    right: 6,
                                                    child: InkWell(
                                                      onTap:
                                                          deleteAdditionalPhoto,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                          4,
                                                        ),
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.red,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.delete_outline,
                                                          color: Colors.white,
                                                          size: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                // Change additional photo button
                                                Positioned(
                                                  bottom: 6,
                                                  right: 6,
                                                  child: InkWell(
                                                    onTap:
                                                        isUploadingAdditionalPhoto
                                                            ? null
                                                            : pickAndUploadAdditionalPhoto,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        6,
                                                      ),
                                                      decoration:
                                                          const BoxDecoration(
                                                        color:
                                                            Color(0xFF000080),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.camera_alt,
                                                        color: Colors.white,
                                                        size: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'മറ്റ് ചിത്രങ്ങൾ (Optional)',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (currentFullLengthPhotoUrl.isEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.red.shade300,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          PhotoQualityValidatorService
                                              .kFullLengthMissingMsg,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB71C1C),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverToBoxAdapter(
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PersonalDetailsSection(
                              user: widget.user,
                              nameController: nameController,
                              dobController: dobController,
                              ageController: ageController,
                              selectedGender: selectedGender,
                              selectedFatherClanId: selectedFatherClanId,
                              selectedMotherClanId: selectedMotherClanId,
                              uniqueClans: uniqueClans,
                              onRefresh: () => fetchPendingRequests(),
                              emailController: emailController,
                              bioController: bioController,
                              locationController: locationController,
                              educationController: educationController,
                              occupationController: occupationController,
                              phoneController: phoneController,
                              publicDisplayNumberController:
                                  publicDisplayNumberController,
                            ),
                            const SizedBox(height: 24),
                            PhysicalDetailsSection(
                              fatherNameController: fatherNameController,
                              isFatherDeceased: isFatherDeceased,
                              onFatherDeceasedChanged: (v) =>
                                  setState(() => isFatherDeceased = v ?? false),
                              motherNameController: motherNameController,
                              isMotherDeceased: isMotherDeceased,
                              onMotherDeceasedChanged: (v) =>
                                  setState(() => isMotherDeceased = v ?? false),
                              houseNameController: houseNameController,
                              heightController: heightController,
                              weightController: weightController,
                              bloodGroupController: bloodGroupController,
                              physicalStatusController:
                                  physicalStatusController,
                            ),
                            const SizedBox(height: 24),
                            FamilyRestrictedSection(
                              hasFamilyRestriction: hasFamilyRestriction,
                              onRestrictionChanged: (v) => setState(
                                () => hasFamilyRestriction = v ?? false,
                              ),
                              uniqueClans: uniqueClans,
                              mothersTarawadController:
                                  mothersTarawadController,
                              selectedRestrictedFamilies:
                                  selectedRestrictedFamilies,
                              onFamilyRemoved: (clan) {
                                setState(
                                  () => selectedRestrictedFamilies.remove(clan),
                                );
                              },
                              onFamilyAdded: (v) {
                                if (v != null) {
                                  setState(
                                    () => selectedRestrictedFamilies.add(v),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 0,
                              color: Colors.amber.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SwitchListTile(
                                title: const Text(
                                  'Allow photo in promotional ads',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Allow photo for app promotion & marketing',
                                  style: TextStyle(fontSize: 11),
                                ),
                                value: allowPhotoInAds,
                                activeTrackColor: const Color(0xFFD4AF37),
                                onChanged: (val) =>
                                    setState(() => allowPhotoInAds = val),
                              ),
                            ),
                            const SizedBox(height: 16),
                            PartnerPreferencesSection(
                              prefAgeMinController: prefAgeMinController,
                              prefAgeMaxController: prefAgeMaxController,
                              prefEducationController: prefEducationController,
                              prefLocationController: prefLocationController,
                              prefOccupationController:
                                  prefOccupationController,
                            ),
                            const SizedBox(height: 24),
                            if (currentFullLengthPhotoUrl.trim().isEmpty) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.red.shade400,
                                    width: 1.2,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        PhotoQualityValidatorService
                                            .kFullLengthMissingMsg,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      if (currentFullLengthPhotoUrl
                                          .trim()
                                          .isEmpty) {
                                        showPhotoValidationError(
                                          PhotoQualityValidatorService
                                              .kFullLengthMissingMsg,
                                        );
                                        return;
                                      }
                                      saveChanges();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    currentFullLengthPhotoUrl.isNotEmpty
                                        ? const Color(0xFFD4AF37)
                                        : Colors.red.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (currentFullLengthPhotoUrl.isEmpty) ...[
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
