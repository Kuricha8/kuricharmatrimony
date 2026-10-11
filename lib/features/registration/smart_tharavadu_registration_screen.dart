import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/haptic_helper.dart';
import '../clan_feed/tharavadu_list.dart';
import '../../core/services/lead_tracking_service.dart';
import '../../core/services/image_compression_service.dart';
import '../family_tree/family_tree_home_screen.dart';

/// Dedicated Smart Tharavadu / Family Tree Member Registration Screen.
/// Strictly uses Firebase (Firestore & Firebase Storage) with mandatory profile photo,
/// parents' names, and date of birth.
class SmartTharavaduRegistrationScreen extends StatefulWidget {
  const SmartTharavaduRegistrationScreen({super.key});

  @override
  State<SmartTharavaduRegistrationScreen> createState() =>
      _SmartTharavaduRegistrationScreenState();
}

class _SmartTharavaduRegistrationScreenState
    extends State<SmartTharavaduRegistrationScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _houseNameController = TextEditingController();
  final TextEditingController _townController = TextEditingController();

  File? _imageFile;
  Uint8List? _imageBytes;
  XFile? _pickedXFile;
  DateTime? _selectedDob;
  String _gender = 'male';
  int? _selectedMaternalClanId;
  int? _selectedPaternalClanId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TharavaduService.instance.loadCachedClans();
    TharavaduService.instance.subscribeToUpdates();
    LeadTrackingService.instance.init(
      step: 1,
      phone: _phoneController.text,
      name: _fullNameController.text,
    );
    _fullNameController.addListener(_onLeadChanged);
    _phoneController.addListener(_onLeadChanged);
  }

  void _onLeadChanged() {
    LeadTrackingService.instance.trackLeadInput(
      phone: _phoneController.text,
      name: _fullNameController.text,
      currentStep: 1,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    LeadTrackingService.instance.handleAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fullNameController.removeListener(_onLeadChanged);
    _phoneController.removeListener(_onLeadChanged);
    LeadTrackingService.instance.handleScreenExit();
    _fullNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _houseNameController.dispose();
    _townController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedXFile = picked;
          _imageBytes = bytes;
          try {
            _imageFile = File(picked.path);
          } catch (_) {
            _imageFile = null;
          }
        });
        HapticHelper.lightImpact();
      }
    } catch (e) {
      debugPrint('[SmartTharavaduRegistration] Photo pick error: $e');
      if (mounted) {
        AppToast.showError(
          context,
          'ഫോട്ടോ തിരഞ്ഞെടുക്കുന്നതിൽ തടസ്സം നേരിട്ടു: $e',
        );
      }
    }
  }

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'പ്രൊഫൈൽ ഫോട്ടോ തിരഞ്ഞെടുക്കുക',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ക്യാമറയോ ഗാലറിയോ ഉപയോഗിച്ച് പുതിയ ഫോട്ടോ നൽകുക *',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPhotoSourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'ക്യാമറ (Camera)',
                    color: const Color(0xFF15803D),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildPhotoSourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'ഗ്യാലറി (Gallery)',
                    color: const Color(0xFF1E3A8A),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSourceTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDob() async {
    final now = DateTime.now();
    final initialDate =
        _selectedDob ?? DateTime(now.year - 22, now.month, now.day);
    final firstDate = DateTime(1910);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'ജനന തീയതി തിരഞ്ഞെടുക്കുക',
      cancelText: 'റദ്ദാക്കുക',
      confirmText: 'ശരി',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      HapticHelper.selectionClick();
    }
  }

  Future<void> _submitLineageRecord() async {
    // 1. Mandatory Profile Photo validation
    if (_imageBytes == null && _imageFile == null) {
      HapticHelper.error();
      AppToast.showError(
        context,
        'ദയവായി പ്രൊഫൈൽ ഫോട്ടോ തിരഞ്ഞെടുക്കുക (Profile Photo is required) *',
      );
      return;
    }

    // 2. Form validation
    if (!_formKey.currentState!.validate()) {
      HapticHelper.error();
      return;
    }

    // 3. Mandatory Date of Birth validation
    if (_selectedDob == null) {
      HapticHelper.error();
      AppToast.showError(
        context,
        'ദയവായി ജനന തീയതി തിരഞ്ഞെടുക്കുക (Date of Birth is required) *',
      );
      return;
    }

    // 4. Clan validation
    if (_selectedMaternalClanId == null || _selectedPaternalClanId == null) {
      HapticHelper.error();
      AppToast.showError(
        context,
        'ദയവായി മാതൃ തറവാടും പിതൃ തറവാടും തിരഞ്ഞെടുക്കുക.',
      );
      return;
    }
    if (_selectedMaternalClanId == _selectedPaternalClanId) {
      HapticHelper.error();
      AppToast.showWarning(
        context,
        'മാതൃ തറവാടും പിതൃ തറവാടും ഒരേപോലെയാകാൻ പാടില്ല.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticHelper.mediumImpact();

    final maternalClan = getClanById(_selectedMaternalClanId!);
    final paternalClan = getClanById(_selectedPaternalClanId!);

    try {
      // 5. Upload profile photo to Firebase Storage under member_photos/
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = _pickedXFile != null
          ? '${timestamp}_${_pickedXFile!.name}'
          : '${timestamp}_photo.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('member_photos/$fileName');

      final uploadBytes = _imageBytes ?? await _imageFile!.readAsBytes();
      final compressedBytes =
          await ImageCompressionService.compressImageBytes(uploadBytes);
      final uploadTask = await storageRef.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final photoUrl = await uploadTask.ref.getDownloadURL();

      // 6. Direct submission to Firestore collection family_tree_members
      final currentUser = FirebaseAuth.instance.currentUser;
      final memberData = {
        'user_id': currentUser?.uid,
        'full_name': _fullNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'gender': _gender,
        'dob': Timestamp.fromDate(_selectedDob!),
        'dob_iso': _selectedDob!.toIso8601String(),
        'dob_formatted': DateFormat('dd/MM/yyyy').format(_selectedDob!),
        'photo_url': photoUrl,
        'father_name': _fatherNameController.text.trim(),
        'mother_name': _motherNameController.text.trim(),
        'house_name': _houseNameController.text.trim(),
        'town': _townController.text.trim(),
        'maternal_clan_id': _selectedMaternalClanId,
        'maternal_clan_name': maternalClan?.displayName ??
            maternalClan?.nameMl ??
            maternalClan?.name,
        'paternal_clan_id': _selectedPaternalClanId,
        'paternal_clan_name': paternalClan?.displayName ??
            paternalClan?.nameMl ??
            paternalClan?.name,
        'status': 'pending',
        'is_verified': false,
        'is_approved': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('family_tree_members')
          .add(memberData);

      // 6b. Single Source of Truth: Write directly to ft_members collection using currentUser.uid
      final ftMemberPayload = {
        'uid': currentUser?.uid,
        'user_id': currentUser?.uid,
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'gender': _gender,
        'dob': _selectedDob?.toIso8601String(),
        'dob_timestamp': Timestamp.fromDate(_selectedDob!),
        'dob_formatted': DateFormat('dd/MM/yyyy').format(_selectedDob!),
        'profile_photo': photoUrl,
        'photo_url': photoUrl,
        'father_name': _fatherNameController.text.trim(),
        'mother_name': _motherNameController.text.trim(),
        'house_name': _houseNameController.text.trim(),
        'town': _townController.text.trim(),
        'panthi_tharavadu': maternalClan?.displayName ??
            maternalClan?.nameMl ??
            maternalClan?.name ??
            '',
        'bandhu_tharavadu': paternalClan?.displayName ??
            paternalClan?.nameMl ??
            paternalClan?.name ??
            '',
        'maternal_clan_id': _selectedMaternalClanId,
        'paternal_clan_id': _selectedPaternalClanId,
        'approval_status': 'pending',
        'status': 'pending',
        'is_verified': false,
        'is_approved': false,
        'source': 'smart_tharavadu_registration',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (currentUser?.uid != null && currentUser!.uid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('ft_members')
            .doc(currentUser.uid)
            .set(ftMemberPayload, SetOptions(merge: true));
      }

      // Secondary sync to lineage_records for lineage queries
      try {
        await FirebaseFirestore.instance
            .collection('lineage_records')
            .doc(docRef.id)
            .set({
          'member_id': docRef.id,
          'user_id': currentUser?.uid,
          'full_name': _fullNameController.text.trim(),
          'father_name': _fatherNameController.text.trim(),
          'mother_name': _motherNameController.text.trim(),
          'maternal_clan_name': maternalClan?.displayName ?? maternalClan?.nameMl,
          'paternal_clan_name': paternalClan?.displayName ?? paternalClan?.nameMl,
          'photo_url': photoUrl,
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[SmartTharavaduRegistration] Secondary lineage record write note: $e');
      }

      // Mark lead completed in registration_leads
      await LeadTrackingService.instance.markCompleted(
        phone: _phoneController.text.trim(),
        name: _fullNameController.text.trim(),
        step: 1,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      HapticHelper.success();

      // 7. Show success dialog and navigate back
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'വിജയിച്ചു!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'കുടുംബ വൃക്ഷ വംശാവലി അംഗത്വ വിവരങ്ങളും ഫോട്ടോയും വിജയകരമായി സമർപ്പിച്ചു. അഡ്മിൻ പരിശോധനയ്ക്ക് ശേഷം നെറ്റ്‌വർക്കിൽ ചേർക്കുന്നതാണ്.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FamilyTreeHomeScreen(
                        memberData: ftMemberPayload,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('ശരി (Done)'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      HapticHelper.error();
      AppToast.showError(context, 'സമർപ്പിക്കൽ പരാജയപ്പെട്ടു: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TharavaduService.instance,
      builder: (context, _) {
        final clans = TharavaduService.allClans;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'സ്മാർട്ട് തറവാട് വംശാവലി രജിസ്ട്രേഷൻ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(18.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF15803D), Color(0xFF22C55E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.park_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'കുടുംബ വൃക്ഷ വംശാവലി ഫോം',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'കുറിച്ച്യ സമുദായ കുടുംബാംഗങ്ങളുടെയും ലിനേജ് വിവരങ്ങളുടെയും രജിസ്ട്രേഷൻ.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Card Container for Member Details
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'അംഗത്തിന്റെ വിവരങ്ങൾ (Member Details)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // ── Mandatory Profile Photo Picker Widget ────────────────
                            Center(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: _showPhotoPickerSheet,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 110,
                                          height: 110,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _imageFile != null
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFF1E3A8A),
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: _imageBytes != null
                                                ? Image.memory(
                                                    _imageBytes!,
                                                    width: 110,
                                                    height: 110,
                                                    fit: BoxFit.cover,
                                                  )
                                                : (_imageFile != null
                                                    ? Image.file(
                                                        _imageFile!,
                                                        width: 110,
                                                        height: 110,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Container(
                                                        color: const Color(0xFFF1F5F9),
                                                        child: const Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons.person_rounded,
                                                              size: 52,
                                                              color:
                                                                  Color(0xFF94A3B8),
                                                            ),
                                                          ],
                                                        ),
                                                      )),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 2,
                                          right: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: (_imageBytes != null || _imageFile != null)
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFF1E3A8A),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              (_imageBytes != null || _imageFile != null)
                                                  ? Icons.check
                                                  : Icons.camera_alt_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: _showPhotoPickerSheet,
                                    icon: const Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _imageFile != null
                                          ? 'ഫോട്ടോ മാറ്റുക (Change Photo)'
                                          : 'പ്രൊഫൈൽ ഫോട്ടോ ചേർക്കുക (Add Photo) *',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _imageFile != null
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Full Name
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                labelText: 'പൂർണ്ണ നാമം (Full Name) *',
                                hintText: 'ഉദാ: വിപിൻ ചന്ദ്രൻ',
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF1E3A8A),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'ദയവായി പേര് നൽകുക'
                                      : null,
                            ),
                            const SizedBox(height: 14),

                            // Phone Number
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'ഫോൺ നമ്പർ (Phone Number) *',
                                hintText: 'ഉദാ: 9876543210',
                                prefixIcon: const Icon(
                                  Icons.phone_outlined,
                                  color: Color(0xFF1E3A8A),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'ദയവായി ഫോൺ നമ്പർ നൽകുക'
                                      : null,
                            ),
                            const SizedBox(height: 14),

                            // ── Date of Birth with DatePicker ────────────────────────
                            TextFormField(
                              controller: _dobController,
                              readOnly: true,
                              onTap: _selectDob,
                              decoration: InputDecoration(
                                labelText: 'ജനന തീയതി (Date of Birth) *',
                                hintText: 'DD/MM/YYYY (ഉദാ: 15/05/1998)',
                                prefixIcon: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Color(0xFF1E3A8A),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.event_rounded,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                  onPressed: _selectDob,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'ദയവായി ജനന തീയതി തിരഞ്ഞെടുക്കുക'
                                      : null,
                            ),
                            const SizedBox(height: 14),

                            // Gender Selection
                            const Text(
                              'ലിംഗഭേദം (Gender)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(
                                      child: Text('ആൺ (Male)'),
                                    ),
                                    selected: _gender == 'male',
                                    selectedColor: const Color(0xFF1E3A8A),
                                    labelStyle: TextStyle(
                                      color: _gender == 'male'
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected: (val) {
                                      if (val) setState(() => _gender = 'male');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(
                                      child: Text('പെൺ (Female)'),
                                    ),
                                    selected: _gender == 'female',
                                    selectedColor: Colors.pink.shade700,
                                    labelStyle: TextStyle(
                                      color: _gender == 'female'
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() => _gender = 'female');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Clan & Lineage Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'തറവാട് & കുല വിവരങ്ങൾ (Clan Details)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── Father's Name ──────────────────────────────────────
                            TextFormField(
                              controller: _fatherNameController,
                              decoration: InputDecoration(
                                labelText: 'അച്ഛന്റെ പേര് (Father\'s Name) *',
                                hintText: 'ഉദാ: ചന്ദ്രൻ',
                                prefixIcon: const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF15803D),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'ദയവായി അച്ഛന്റെ പേര് നൽകുക'
                                      : null,
                            ),
                            const SizedBox(height: 14),

                            // ── Mother's Name ──────────────────────────────────────
                            TextFormField(
                              controller: _motherNameController,
                              decoration: InputDecoration(
                                labelText: 'അമ്മയുടെ പേര് (Mother\'s Name) *',
                                hintText: 'ഉദാ: കല്യാണി',
                                prefixIcon: const Icon(
                                  Icons.person_2_rounded,
                                  color: Color(0xFF15803D),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'ദയവായി അമ്മയുടെ പേര് നൽകുക'
                                      : null,
                            ),
                            const SizedBox(height: 14),

                            // House Name
                            TextFormField(
                              controller: _houseNameController,
                              decoration: InputDecoration(
                                labelText: 'വീട്ടുപേര് (House Name) *',
                                hintText: 'ഉദാ: കരിപ്പാലി വീട്',
                                prefixIcon: const Icon(
                                  Icons.home_outlined,
                                  color: Color(0xFF15803D),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'ദയവായി വീട്ടുപേര് നൽകുക'
                                      : null,
                            ),
                            const SizedBox(height: 14),

                            // Town / Village
                            TextFormField(
                              controller: _townController,
                              decoration: InputDecoration(
                                labelText: 'സ്ഥലം / ഗ്രാമം (Town / Village)',
                                hintText: 'ഉദാ: മാനന്തവാടി',
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF15803D),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Maternal Clan Dropdown
                            DropdownButtonFormField<int>(
                              initialValue: _selectedMaternalClanId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText:
                                    'മാതൃ തറവാട് / സ്വന്തം കുലം (Maternal Clan) *',
                                prefixIcon: const Icon(
                                  Icons.family_restroom,
                                  color: Color(0xFF15803D),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: clans.map((c) {
                                return DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text(
                                    '${c.displayName} (${c.groupName})',
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              validator: (v) => v == null
                                  ? 'മാതൃ തറവാട് തിരഞ്ഞെടുക്കുക'
                                  : null,
                              onChanged: (val) =>
                                  setState(() => _selectedMaternalClanId = val),
                            ),
                            const SizedBox(height: 16),

                            // Paternal Clan Dropdown
                            DropdownButtonFormField<int>(
                              initialValue: _selectedPaternalClanId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'പിതൃ തറവാട് (Paternal Clan) *',
                                prefixIcon: const Icon(
                                  Icons.elderly,
                                  color: Color(0xFF15803D),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: clans.map((c) {
                                return DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text(
                                    '${c.displayName} (${c.groupName})',
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              validator: (v) => v == null
                                  ? 'പിതൃ തറവാട് തിരഞ്ഞെടുക്കുക'
                                  : null,
                              onChanged: (val) =>
                                  setState(() => _selectedPaternalClanId = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitLineageRecord,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 22,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'സമർപ്പിക്കുന്നു...'
                            : 'കുടുംബ വൃക്ഷത്തിലേക്ക് സമർപ്പിക്കുക (Submit Record)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
