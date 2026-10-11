import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/models.dart';
import 'package:kurichiyar_matrimony/core/utils/mock_data.dart';
import '../../core/services/photo_quality_validator_service.dart';
import '../../core/widgets/portrait_image_cropper_dialog.dart';
import '../clan_feed/tharavadu_list.dart';
import 'wedding_success_page.dart';
import 'edit_profile_sheet.dart';

mixin EditProfileStateMixin<T extends StatefulWidget>
    on State<EditProfileSheet> {
  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingPhoto = false;
  bool isUploadingFullLengthPhoto = false;
  bool allowPhotoInAds = false;
  MaritalStatus? selectedMaritalStatus;
  bool isMarriedSelected = false;

  String currentPhotoUrl = '';
  final photoUrlController = TextEditingController();

  String currentFullLengthPhotoUrl = '';
  final fullLengthPhotoUrlController = TextEditingController();

  String currentAdditionalPhotoUrl = '';
  final additionalPhotoUrlController = TextEditingController();
  bool isUploadingAdditionalPhoto = false;

  final formKey = GlobalKey<FormState>();

  // Form Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  DateTime? selectedDob;
  Gender? selectedGender;

  int? selectedFatherClanId;
  int? selectedMotherClanId;

  bool hasFamilyRestriction = false;
  final mothersTarawadController = TextEditingController();
  List<Clan> selectedRestrictedFamilies = [];

  // Editable controllers
  final ageController = TextEditingController();
  final locationController = TextEditingController();
  final educationController = TextEditingController();
  final occupationController = TextEditingController();
  final phoneController = TextEditingController();
  final publicDisplayNumberController = TextEditingController();

  final fatherNameController = TextEditingController();
  final motherNameController = TextEditingController();
  final houseNameController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final physicalStatusController = TextEditingController();
  final bioController = TextEditingController();

  // Partner Preferences
  final prefAgeMinController = TextEditingController();
  final prefAgeMaxController = TextEditingController();
  final prefEducationController = TextEditingController();
  final prefLocationController = TextEditingController();
  final prefOccupationController = TextEditingController();

  bool isFatherDeceased = false;
  bool isMotherDeceased = false;

  List<Map<String, dynamic>> pendingRequests = [];
  RealtimeChannel? realtimeSyncChannel;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? firestoreUserDocSub;

  @override
  void initState() {
    super.initState();
    currentPhotoUrl = widget.user.photoUrl;
    photoUrlController.text = currentPhotoUrl;
    currentFullLengthPhotoUrl = widget.user.fullLengthPhotoUrl ?? '';
    fullLengthPhotoUrlController.text = currentFullLengthPhotoUrl;
    if (widget.user.additionalPhotos.isNotEmpty) {
      currentAdditionalPhotoUrl = widget.user.additionalPhotos.first;
      additionalPhotoUrlController.text = currentAdditionalPhotoUrl;
    }
    populateControllers(widget.user);
    fetchLatestData();
    fetchPendingRequests();
    subscribeToRealtimeSync();
  }

  Future<void> subscribeToRealtimeSync() async {
    // 1. Cached one-time fetch using Source.serverAndCache
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists && doc.data() != null && mounted && !isSaving) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = widget.user.id;
        final updated = UserProfile.fromMap(data);
        if (updated.photoUrl.isNotEmpty && updated.photoUrl != currentPhotoUrl) {
          setState(() {
            currentPhotoUrl = updated.photoUrl;
            photoUrlController.text = updated.photoUrl;
          });
        }
        final updatedFullLength = updated.fullLengthPhotoUrl ?? '';
        if (updatedFullLength.isNotEmpty && updatedFullLength != currentFullLengthPhotoUrl) {
          setState(() {
            currentFullLengthPhotoUrl = updatedFullLength;
            fullLengthPhotoUrlController.text = updatedFullLength;
          });
        }
        final updatedAdditional = updated.additionalPhotos.isNotEmpty
            ? updated.additionalPhotos.first
            : '';
        if (updatedAdditional.isNotEmpty &&
            updatedAdditional != currentAdditionalPhotoUrl) {
          setState(() {
            currentAdditionalPhotoUrl = updatedAdditional;
            additionalPhotoUrlController.text = updatedAdditional;
          });
        }
      }
    } catch (e) {
      debugPrint('Firestore edit profile fetch note: $e');
    }

    // 2. Supabase edit requests channel
    try {
      realtimeSyncChannel = Supabase.instance.client
          .channel('user_profile_edit_requests_${widget.user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'profile_edit_requests',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: widget.user.id,
            ),
            callback: (payload) {
              fetchPendingRequests();
              fetchLatestData();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime profile edit sync error: $e');
    }
  }

  Future<void> fetchPendingRequests() async {
    try {
      final res = await Supabase.instance.client
          .from('profile_edit_requests')
          .select()
          .eq('user_id', widget.user.id)
          .eq('status', 'pending')
          .timeout(const Duration(seconds: 4));

      if (mounted) {
        setState(() {
          pendingRequests = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint('Error fetching pending edit requests: $e');
    }
  }

  void populateControllers(
    UserProfile profile, [
    Map<String, dynamic>? rawResponse,
  ]) {
    nameController.text =
        (rawResponse?['full_name'] ??
                rawResponse?['name'] ??
                profile.name ??
                '')
            .toString();

    final authUser = Supabase.instance.client.auth.currentUser;
    final dbEmail = (rawResponse?['email'] ?? profile.email ?? '').toString();
    emailController.text = dbEmail.trim().isNotEmpty
        ? dbEmail.trim()
        : (authUser?.email ?? '');

    if (rawResponse?['date_of_birth'] != null) {
      selectedDob = DateTime.tryParse(rawResponse!['date_of_birth'].toString());
    } else {
      selectedDob = profile.dob;
    }
    if (selectedDob != null) {
      dobController.text =
          '${selectedDob!.day.toString().padLeft(2, '0')}/${selectedDob!.month.toString().padLeft(2, '0')}/${selectedDob!.year}';
    } else {
      dobController.text = '';
    }

    ageController.text = profile.age > 0
        ? profile.age.toString()
        : (rawResponse?['age']?.toString() ?? '');

    selectedGender = profile.gender;
    final rawGenderStr = rawResponse?['gender']?.toString().toLowerCase();
    if (rawGenderStr == 'male') selectedGender = Gender.male;
    if (rawGenderStr == 'female') selectedGender = Gender.female;

    currentPhotoUrl =
        (rawResponse?['photo_url'] ??
                rawResponse?['profile_photo'] ??
                rawResponse?['avatar_url'] ??
                profile.photoUrl ??
                '')
            .toString();
    photoUrlController.text = currentPhotoUrl;

    currentFullLengthPhotoUrl =
        (rawResponse?['full_length_photo_url'] ??
                rawResponse?['fullLengthPhotoUrl'] ??
                rawResponse?['full_size_photo_url'] ??
                profile.fullLengthPhotoUrl ??
                '')
            .toString();
    fullLengthPhotoUrlController.text = currentFullLengthPhotoUrl;

    final addList = rawResponse?['additional_photos'] ?? profile.additionalPhotos;
    if (addList is List && addList.isNotEmpty) {
      currentAdditionalPhotoUrl = addList.first.toString();
      additionalPhotoUrlController.text = currentAdditionalPhotoUrl;
    } else {
      currentAdditionalPhotoUrl = '';
      additionalPhotoUrlController.clear();
    }

    bioController.text =
        (rawResponse?['bio'] ??
                rawResponse?['about'] ??
                rawResponse?['about_me'] ??
                profile.bio ??
                '')
            .toString();

    selectedFatherClanId = (profile.fatherClanId != 0)
        ? profile.fatherClanId
        : (rawResponse?['father_clan_id'] != null
              ? int.tryParse(rawResponse!['father_clan_id'].toString())
              : null);
    if (selectedFatherClanId == null || selectedFatherClanId == 0) {
      final fName =
          rawResponse?['father_tharavadu'] ??
          rawResponse?['father_clan'] ??
          profile.fatherTharavadu;
      final match = _findMatchingClan(fName?.toString());
      if (match != null) {
        selectedFatherClanId = match.id;
      }
    }

    selectedMotherClanId = (profile.motherClanId != 0)
        ? profile.motherClanId
        : (rawResponse?['mother_clan_id'] != null
              ? int.tryParse(rawResponse!['mother_clan_id'].toString())
              : null);
    if (selectedMotherClanId == null || selectedMotherClanId == 0) {
      final mName =
          rawResponse?['mother_tharavadu'] ??
          rawResponse?['mothers_tarawad'] ??
          rawResponse?['mother_clan'] ??
          profile.motherTharavadu ??
          profile.mothersTarawad;
      final match = _findMatchingClan(mName?.toString());
      if (match != null) {
        selectedMotherClanId = match.id;
      }
    }

    locationController.text =
        (rawResponse?['region'] ??
                rawResponse?['location'] ??
                profile.region ??
                '')
            .toString();
    educationController.text =
        (rawResponse?['education_level'] ?? profile.educationLevel ?? '')
            .toString();
    occupationController.text = (rawResponse?['job'] ?? profile.job ?? '')
        .toString();
    phoneController.text =
        (rawResponse?['guardian_phone'] ?? profile.guardianPhone ?? '')
            .toString();
    publicDisplayNumberController.text =
        (rawResponse?['public_display_number'] ??
                profile.publicDisplayNumber ??
                '')
            .toString();

    fatherNameController.text =
        (rawResponse?['father_name'] ?? profile.fatherName ?? '').toString();
    if (fatherNameController.text.endsWith('(Late)')) {
      isFatherDeceased = true;
      fatherNameController.text = fatherNameController.text
          .replaceAll('(Late)', '')
          .trim();
    } else {
      isFatherDeceased = false;
    }

    motherNameController.text =
        (rawResponse?['mother_name'] ?? profile.motherName ?? '').toString();
    if (motherNameController.text.endsWith('(Late)')) {
      isMotherDeceased = true;
      motherNameController.text = motherNameController.text
          .replaceAll('(Late)', '')
          .trim();
    } else {
      isMotherDeceased = false;
    }

    houseNameController.text =
        (rawResponse?['house_name'] ?? profile.houseName ?? '').toString();
    heightController.text = (rawResponse?['height'] ?? profile.height ?? '')
        .toString();
    weightController.text = (rawResponse?['weight'] ?? profile.weight ?? '')
        .toString();
    bloodGroupController.text =
        (rawResponse?['blood_group'] ?? profile.bloodGroup ?? '').toString();
    physicalStatusController.text =
        (rawResponse?['physical_status'] ??
                profile.physicalStatus ??
                'Normal / Fit')
            .toString();

    prefAgeMinController.text = profile.prefAgeMin.toString();
    prefAgeMaxController.text = profile.prefAgeMax.toString();
    prefEducationController.text = profile.prefEducation ?? '';
    prefLocationController.text = profile.prefLocation ?? '';
    prefOccupationController.text = profile.prefOccupation ?? '';

    if (rawResponse != null) {
      allowPhotoInAds = rawResponse['allow_photo_in_ads'] ?? false;
      final dbMaritalStatus = rawResponse['marital_status'] as String?;
      if (dbMaritalStatus == 'married') {
        isMarriedSelected = true;
      } else {
        isMarriedSelected = false;
        selectedMaritalStatus = profile.maritalStatus;
      }
    } else {
      allowPhotoInAds = false;
      isMarriedSelected = profile.maritalStatus != MaritalStatus.first;
      selectedMaritalStatus = profile.maritalStatus;
    }

    hasFamilyRestriction = profile.hasFamilyRestriction;
    mothersTarawadController.text =
        (rawResponse?['mothers_tarawad'] ?? profile.mothersTarawad ?? '')
            .toString();
    if (mothersTarawadController.text.isEmpty && selectedMotherClanId != null) {
      final mClan = getClanById(selectedMotherClanId!);
      if (mClan != null) mothersTarawadController.text = mClan.name;
    }
    selectedRestrictedFamilies = allClans
        .where(
          (c) =>
              profile.restrictedFamilies.contains(c.name) ||
              profile.restrictedTharavads.contains(c.id),
        )
        .toList();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    dobController.dispose();
    photoUrlController.dispose();
    fullLengthPhotoUrlController.dispose();
    additionalPhotoUrlController.dispose();
    ageController.dispose();
    locationController.dispose();
    educationController.dispose();
    occupationController.dispose();
    phoneController.dispose();
    publicDisplayNumberController.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    houseNameController.dispose();
    heightController.dispose();
    weightController.dispose();
    bloodGroupController.dispose();
    physicalStatusController.dispose();
    bioController.dispose();
    prefAgeMinController.dispose();
    prefAgeMaxController.dispose();
    prefEducationController.dispose();
    prefLocationController.dispose();
    prefOccupationController.dispose();
    mothersTarawadController.dispose();
    firestoreUserDocSub?.cancel();
    realtimeSyncChannel?.unsubscribe();
    super.dispose();
  }

  Clan? _findMatchingClan(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return null;
    final t = rawName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    // 1. Try exact normalized match
    for (final c in allClans) {
      final cName = c.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final cNameMl = c.nameMl.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final cSub = c.subName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final cLabel = c.displayName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      if (cName == t || cNameMl == t || (cSub.isNotEmpty && cSub == t) || cLabel == t) {
        return c;
      }
    }

    // 2. Try contains/substring match
    for (final c in allClans) {
      final cName = c.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final cNameMl = c.nameMl.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final cSub = c.subName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      if (cName.contains(t) ||
          t.contains(cName) ||
          cNameMl.contains(t) ||
          t.contains(cNameMl) ||
          (cSub.isNotEmpty && (cSub.contains(t) || t.contains(cSub))) ||
          ((t.contains('ചായമൽ') || t.contains('ചയിമ്മൽ')) && cNameMl.contains('പുച്ചിയേരി'))) {
        return c;
      }
    }

    return null;
  }

  Future<void> fetchLatestData() async {
    try {
      // 1. Cloud Firestore users collection as primary source
      final firestoreDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .get(const GetOptions(source: Source.serverAndCache));

      if (firestoreDoc.exists && firestoreDoc.data() != null && mounted) {
        final data = Map<String, dynamic>.from(firestoreDoc.data()!);
        data['id'] = widget.user.id;
        final profile = UserProfile.fromMap(data);
        populateControllers(profile, data);
      } else {
        // Fallback to Supabase if not yet present in Firestore
        final response = await Supabase.instance.client
            .from('kurichiyar_profiles')
            .select()
            .eq('id', widget.user.id)
            .maybeSingle();

        if (response != null && mounted) {
          final profile = UserProfile.fromMap(response);
          populateControllers(profile, response);
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile from Firestore: $e');
      try {
        final response = await Supabase.instance.client
            .from('kurichiyar_profiles')
            .select()
            .eq('id', widget.user.id)
            .maybeSingle();

        if (response != null && mounted) {
          final profile = UserProfile.fromMap(response);
          populateControllers(profile, response);
        }
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showPhotoValidationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPhotoValidationError(String message) => showPhotoValidationError(message);

  Future<void> pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (image == null) return;

    // Strict Quality & Safety Validation before upload:
    final file = File(image.path);
    final validation = await PhotoQualityValidatorService.instance
        .validateProfilePhoto(file, isFullLength: false);
    if (!validation.isValid) {
      _showPhotoValidationError(
        validation.errorMessageMl ??
            PhotoQualityValidatorService.kFaceNotClearMsg,
      );
      return;
    }

    setState(() => isUploadingPhoto = true);
    try {
      final fileName =
          'profile_photos/${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('profiles')
          .upload(fileName, file);
      final publicUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(fileName);

      // Bind photo directly to Firestore users/{uid} document
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.id)
            .set({
              'photo_url': publicUrl,
              'profile_photo': publicUrl,
              'avatar_url': publicUrl,
            }, SetOptions(merge: true));
      } catch (fErr) {
        debugPrint('Firestore photo sync note: $fErr');
      }

      setState(() {
        currentPhotoUrl = publicUrl;
        photoUrlController.text = publicUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isUploadingPhoto = false);
    }
  }

  Future<void> pickAndUploadFullLengthPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (image == null) return;

    final initialFile = File(image.path);

    // 1. Portrait Cropper restricted strictly to vertical portrait (3:4 or 9:16)
    if (!mounted) return;
    final croppedFile = await PortraitImageCropperDialog.show(
      context,
      imageFile: initialFile,
    );
    if (croppedFile == null) {
      // User cancelled cropper
      return;
    }

    // 2. Strict Quality & Safety Validation before upload:
    // Aspect Ratio check + Google ML Kit Pose Detection (shoulders, hips, lower body)
    // + Text/Contacts Blocker + Face Clarity
    final validation = await PhotoQualityValidatorService.instance
        .validateProfilePhoto(croppedFile, isFullLength: true);
    if (!validation.isValid) {
      _showPhotoValidationError(
        validation.errorMessageMl ??
            PhotoQualityValidatorService.kFullLengthPoseErrorMsg,
      );
      return;
    }

    setState(() => isUploadingFullLengthPhoto = true);
    try {
      final fileName =
          'profile_photos/full_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('profiles')
          .upload(fileName, croppedFile);
      final publicUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(fileName);

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.id)
            .set({
              'full_length_photo_url': publicUrl,
              'full_size_photo_url': publicUrl,
            }, SetOptions(merge: true));
      } catch (fErr) {
        debugPrint('Firestore full length photo sync note: $fErr');
      }

      setState(() {
        currentFullLengthPhotoUrl = publicUrl;
        fullLengthPhotoUrlController.text = publicUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('പൂർണ്ണകായ ചിത്രം വിജയകരമായി അപ്‌ലോഡ് ചെയ്തു!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading full-length photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload full-length photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isUploadingFullLengthPhoto = false);
    }
  }

  void deleteFullLengthPhoto() {
    setState(() {
      currentFullLengthPhotoUrl = '';
      fullLengthPhotoUrlController.clear();
    });

    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .set({
            'full_length_photo_url': '',
            'full_size_photo_url': '',
          }, SetOptions(merge: true));
    } catch (_) {}

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          PhotoQualityValidatorService.kFullLengthMissingMsg,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void deleteAdditionalPhoto() {
    setState(() {
      currentAdditionalPhotoUrl = '';
      additionalPhotoUrlController.clear();
    });
    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .set({
            'additional_photos': [],
          }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> pickAndUploadAdditionalPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (image == null) return;

    final file = File(image.path);
    final validation = await PhotoQualityValidatorService.instance
        .validateProfilePhoto(file, isFullLength: false);
    if (!validation.isValid) {
      _showPhotoValidationError(
        validation.errorMessageMl ??
            PhotoQualityValidatorService.kFaceNotClearMsg,
      );
      return;
    }

    setState(() => isUploadingAdditionalPhoto = true);
    try {
      final fileName =
          'profile_photos/extra_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('profiles')
          .upload(fileName, file);
      final publicUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(fileName);

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.id)
            .set({
              'additional_photos': [publicUrl],
            }, SetOptions(merge: true));
      } catch (fErr) {
        debugPrint('Firestore additional photo sync note: $fErr');
      }

      setState(() {
        currentAdditionalPhotoUrl = publicUrl;
        additionalPhotoUrlController.text = publicUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Additional photo uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading additional photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload additional photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isUploadingAdditionalPhoto = false);
    }
  }

  Future<void> saveChanges() async {
    if (!formKey.currentState!.validate()) return;

    // Strict Full-Length Photo Guard:
    final fullLengthToSave =
        fullLengthPhotoUrlController.text.trim().isNotEmpty
            ? fullLengthPhotoUrlController.text.trim()
            : currentFullLengthPhotoUrl.trim();

    if (fullLengthToSave.isEmpty) {
      _showPhotoValidationError(
        PhotoQualityValidatorService.kFullLengthMissingMsg,
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final fClan = selectedFatherClanId != null
          ? getClanById(selectedFatherClanId!)
          : null;
      final mClan = selectedMotherClanId != null
          ? getClanById(selectedMotherClanId!)
          : null;

      final photoUrlToSave = photoUrlController.text.trim().isNotEmpty
          ? photoUrlController.text.trim()
          : currentPhotoUrl.trim();

      String cleanClanName(String? raw) {
        if (raw == null || raw.trim().isEmpty) return '';
        String s = raw.trim();
        // Remove prefixes like "BANDHU (" or "PANTHI (" or "BANDHU - "
        s = s.replaceAll(
          RegExp(
            r'^(BANDHU|PANTHI|NATTOOR|OTHERS)\s*[\(\-\:]\s*',
            caseSensitive: false,
          ),
          '',
        );
        s = s.replaceAll(RegExp(r'[\)]\s*$'), '');
        return s.trim();
      }

      final fatherClanName = cleanClanName(
        fClan?.name ?? fClan?.displayLabel ?? widget.user.fatherTharavadu,
      );
      final motherClanName = cleanClanName(
        mClan?.name ?? mClan?.displayLabel ?? widget.user.motherTharavadu,
      );

      final updates = {
        'name': nameController.text.trim(),
        'full_name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'bio': bioController.text.trim(),
        'photo_url': photoUrlToSave,
        'full_length_photo_url': fullLengthToSave,
        'full_size_photo_url': fullLengthToSave,
        'additional_photos': currentAdditionalPhotoUrl.isNotEmpty
            ? [currentAdditionalPhotoUrl]
            : [],
        'father_clan_id': selectedFatherClanId,
        'father_tharavad': fatherClanName,
        'father_clan': fatherClanName,
        'mother_clan_id': selectedMotherClanId,
        'mother_tharavad': motherClanName,
        'mother_clan': motherClanName,
        'mothers_tarawad': mothersTarawadController.text.trim().isNotEmpty
            ? cleanClanName(mothersTarawadController.text.trim())
            : null,
        'bandhu_group': mClan?.type ?? 'BANDHU',
        'age': int.tryParse(ageController.text.trim()) ?? widget.user.age,
        'gender': selectedGender == Gender.male ? 'male' : 'female',
        'date_of_birth': selectedDob?.toIso8601String(),
        'location': locationController.text.trim(),
        'region': locationController.text.trim(),
        'education_level': educationController.text.trim(),
        'job': occupationController.text.trim(),
        'guardian_phone': phoneController.text.trim(),
        'public_display_number': publicDisplayNumberController.text.trim(),
        'father_name':
            isFatherDeceased &&
                !fatherNameController.text.trim().endsWith('(Late)')
            ? '${fatherNameController.text.trim()} (Late)'
            : fatherNameController.text.trim(),
        'mother_name':
            isMotherDeceased &&
                !motherNameController.text.trim().endsWith('(Late)')
            ? '${motherNameController.text.trim()} (Late)'
            : motherNameController.text.trim(),
        'house_name': houseNameController.text.trim(),
        'height': heightController.text.trim(),
        'weight': weightController.text.trim(),
        'blood_group': bloodGroupController.text.trim(),
        'physical_status': physicalStatusController.text.trim(),
        'pref_age_min': int.tryParse(prefAgeMinController.text.trim()),
        'pref_age_max': int.tryParse(prefAgeMaxController.text.trim()),
        'pref_education': prefEducationController.text.trim(),
        'pref_location': prefLocationController.text.trim(),
        'pref_occupation': prefOccupationController.text.trim(),
        'allow_photo_in_ads': allowPhotoInAds,
        'marital_status': isMarriedSelected
            ? 'married'
            : selectedMaritalStatus?.name,
        'has_family_restriction': hasFamilyRestriction,
        'restricted_families': selectedRestrictedFamilies
            .map((c) => c.name)
            .toList(),
        'restricted_tharavads': selectedRestrictedFamilies
            .map((c) => c.id)
            .toList(),
        if (isMarriedSelected) 'is_profile_hidden': true,
      };

      // Bind and write profile fields directly to Firestore document users/{uid}
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.id)
            .set(updates, SetOptions(merge: true));
      } catch (fErr) {
        debugPrint('Firestore profile save note: $fErr');
      }

      if (widget.user.isAgent || widget.user.role == 'agent') {
        final payload = {
          'agent_approval_status': 'PENDING',
          'pending_profile_edits': updates,
        };
        await Supabase.instance.client
            .from('kurichiyar_profiles')
            .update(payload)
            .eq('id', widget.user.id);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile update submitted for admin approval!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final updatedRow = await Supabase.instance.client
          .from('kurichiyar_profiles')
          .update(updates)
          .eq('id', widget.user.id)
          .select()
          .maybeSingle();

      if (emailController.text.trim().isNotEmpty &&
          Supabase.instance.client.auth.currentUser != null) {
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(email: emailController.text.trim()),
          );
        } catch (e) {
          debugPrint('Auth email sync note: $e');
        }
      }

      if (updatedRow != null) {
        MockData().updateCurrentUser(UserProfile.fromMap(updatedRow));
      }

      if (mounted) {
        if (isMarriedSelected) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WeddingSuccessPage()),
            (route) => false,
          );
        } else {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile updated successfully!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }
}
