import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../core/utils/mock_data.dart';
import '../../core/widgets/universal_tharavadu_dropdown.dart';
import 'family_tree_constants.dart';
import 'family_tree_home_screen.dart';

class FamilyRegistrationScreen extends StatefulWidget {
  final String? rejectionReason;
  final String? initialName;
  final String? initialEmail;
  final String? initialPhotoUrl;

  const FamilyRegistrationScreen({
    super.key,
    this.rejectionReason,
    this.initialName,
    this.initialEmail,
    this.initialPhotoUrl,
  });

  @override
  State<FamilyRegistrationScreen> createState() =>
      _FamilyRegistrationScreenState();
}

class _FamilyRegistrationScreenState extends State<FamilyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _houseController = TextEditingController();
  final _siblingPhoneController = TextEditingController();

  String? _networkPhotoUrl;

  String? _selectedPanthi;
  String? _selectedBandhu;
  DateTime? _dob;
  TimeOfDay? _birthTime;
  bool _isFirstTwin = false;
  bool _isSingleChild = false;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefillFromExistingProfile();
  }

  void _prefillFromExistingProfile() {
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
    if (widget.initialPhotoUrl != null && widget.initialPhotoUrl!.isNotEmpty) {
      _networkPhotoUrl = widget.initialPhotoUrl;
    }

    final me = MockData().currentUser;
    if (me != null) {
      if (_nameController.text.trim().isEmpty && me.name.isNotEmpty) {
        _nameController.text = me.name;
      }
      final phone = getEffectiveUserPhone();
      if (phone != null && phone.isNotEmpty) _phoneController.text = phone;
      if (me.familyDetails.houseName != null &&
          me.familyDetails.houseName!.isNotEmpty) {
        _houseController.text = me.familyDetails.houseName!;
      }
      if (me.dob != null) {
        _dob = me.dob;
      }
    }

    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      if (_nameController.text.trim().isEmpty &&
          fbUser.displayName != null &&
          fbUser.displayName!.trim().isNotEmpty) {
        _nameController.text = fbUser.displayName!.trim();
      }
      if (_emailController.text.trim().isEmpty &&
          fbUser.email != null &&
          fbUser.email!.trim().isNotEmpty) {
        _emailController.text = fbUser.email!.trim();
      }
      if (_phoneController.text.trim().isEmpty &&
          fbUser.phoneNumber != null &&
          fbUser.phoneNumber!.trim().isNotEmpty) {
        _phoneController.text = fbUser.phoneNumber!.trim();
      }
      if (_networkPhotoUrl == null &&
          fbUser.photoURL != null &&
          fbUser.photoURL!.isNotEmpty) {
        _networkPhotoUrl = fbUser.photoURL;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _siblingPhoneController.dispose();
    super.dispose();
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ക്യാമറ (Camera)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ഗ്യാലറി (Gallery)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage([ImageSource source = ImageSource.gallery]) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );

      if (picked != null) {
        final rawBytes = await picked.readAsBytes();

        // ഏത് ഫോർമാറ്റ് ആയാലും ഡീകോഡ് ചെയ്യുന്നു (PNG, WebP, etc.)
        final decodedImage = img.decodeImage(rawBytes);

        if (decodedImage != null) {
          // അതിനെ കൃത്യമായി JPG ഫോർമാറ്റിലേക്ക് കൺവേർട്ട് ചെയ്യുന്നു
          final jpgBytes = Uint8List.fromList(
            img.encodeJpg(decodedImage, quality: 85),
          );

          if (mounted) {
            setState(() {
              _imageBytes = jpgBytes; // എപ്പോഴും സ്ക്രീനിലും സ്റ്റോറേജിലും JPG മാത്രം
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _imageBytes = rawBytes;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ഫോട്ടോ തിരഞ്ഞെടുക്കുന്നതിൽ തടസ്സം: $e')),
        );
      }
    }
  }

  /// ഫ്രീ ക്വാട്ട പരിശോധിക്കുന്ന ഫയർബേസ് ലോജിക് (50 ഫ്രീ + മാസം 5 ഫ്രീ)
  /// Uses Firestore aggregation count() for high performance and low read cost
  Future<bool> _checkFreeTierEligible() async {
    try {
      final totalFreeQuery = await FirebaseFirestore.instance
          .collection('ft_members')
          .where('is_free_tier', isEqualTo: true)
          .count()
          .get();

      final totalCount = totalFreeQuery.count ?? 0;
      if (totalCount < 50) return true;

      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      try {
        final monthFreeQuery = await FirebaseFirestore.instance
            .collection('ft_members')
            .where('is_free_tier', isEqualTo: true)
            .where(
              'created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
            )
            .count()
            .get();

        final monthCount = monthFreeQuery.count ?? 0;
        return monthCount < 5;
      } catch (indexErr) {
        debugPrint('Composite query fallback on ft_members: $indexErr');
        final snap = await FirebaseFirestore.instance
            .collection('ft_members')
            .where('is_free_tier', isEqualTo: true)
            .limit(60)
            .get();

        final monthCount = snap.docs.where((d) {
          final ts = d.data()['created_at'];
          if (ts is Timestamp) {
            return ts.toDate().isAfter(firstDayOfMonth);
          }
          return false;
        }).length;
        return monthCount < 5;
      }
    } catch (e) {
      debugPrint('Free tier count check fallback: $e');
      return true;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ജനനത്തീയതി തിരഞ്ഞെടുക്കുക')),
      );
      return;
    }
    if (_selectedPanthi != null &&
        _selectedBandhu != null &&
        _selectedPanthi == _selectedBandhu &&
        !_selectedPanthi!.contains('മറ്റ്')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('പന്തിയും ബന്ധുവും ഒരേ തറവാടാവാൻ പാടില്ല'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isFree = await _checkFreeTierEligible();
      if (!mounted) return;

      if (!isFree) {
        final paid = await _showDummyPaymentDialog();
        if (!mounted) return;
        if (!paid) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final uid = FirebaseAuth.instance.currentUser?.uid ?? getEffectiveUserId();
      if (uid == null || uid.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ലോഗിൻ വിവരങ്ങൾ ലഭ്യമല്ല. വീണ്ടും ലോഗിൻ ചെയ്യുക.'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      String? photoUrl = _networkPhotoUrl;
      if (_imageBytes != null) {
        try {
          final ref =
              FirebaseStorage.instance.ref().child('ft_profiles/$uid.jpg');

          // എപ്പോഴും 'image/jpeg' ആയിത്തന്നെ അപ്ലോഡ് ചെയ്യും
          await ref.putData(
            _imageBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );

          photoUrl = await ref.getDownloadURL();
        } catch (e) {
          debugPrint('Profile photo upload notice: $e');
        }
      }

      final phoneRaw = _phoneController.text.trim();
      final phoneClean = cleanPhoneNumber(phoneRaw);
      final siblingPhoneRaw =
          _isSingleChild ? null : _siblingPhoneController.text.trim();
      final siblingPhoneClean =
          siblingPhoneRaw != null ? cleanPhoneNumber(siblingPhoneRaw) : null;

      final memberMap = <String, dynamic>{
        'uid': uid,
        'full_name': _nameController.text.trim(),
        'nickname': _nicknameController.text.trim(), // യൂസർ സ്വയം എഡിറ്റ് ചെയ്യുന്ന വിളിപ്പേര്
        'email': _emailController.text.trim(),
        'phone': phoneRaw,
        'phone_clean': phoneClean,
        'house_name': _houseController.text.trim(),
        'panthi_tharavadu': _selectedPanthi,
        'bandhu_tharavadu': _selectedBandhu,
        'dob': _dob!.toIso8601String(),
        'birth_time': _birthTime != null
            ? '${_birthTime!.hour.toString().padLeft(2, '0')}:${_birthTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'is_first_twin': _isFirstTwin,
        'is_single_child': _isSingleChild,
        'sibling_phone': siblingPhoneRaw,
        'sibling_phone_clean': siblingPhoneClean,
        'profile_photo': photoUrl,
        'is_free_tier': isFree,
        'approval_status': 'pending',
        'rejection_reason': null,
        'created_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('ft_members').doc(uid).set(
        memberMap,
        SetOptions(merge: true),
      );

      if (!_isSingleChild &&
          siblingPhoneRaw != null &&
          siblingPhoneRaw.isNotEmpty) {
        await FirebaseFirestore.instance.collection('ft_approvals').add({
          'applicant_uid': uid,
          'applicant_name': _nameController.text.trim(),
          'panthi': _selectedPanthi,
          'sibling_phone': siblingPhoneRaw,
          'sibling_phone_clean': siblingPhoneClean,
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFree
                ? 'സൗജന്യ രജിസ്ട്രേഷൻ പൂർത്തിയായി! പരിശോധനയിലാണ്.'
                : 'രജിസ്ട്രേഷൻ വിജയകരമായി സമർപ്പിച്ചു!',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      // On success, pushReplacement directly to FamilyTreeHomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FamilyTreeHomeScreen(memberData: memberMap),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showDummyPaymentDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('രജിസ്ട്രേഷൻ ഫീസ്'),
            content: const Text(
              'ഈ മാസത്തെ സൗജന്യ ക്വാട്ട പൂർത്തിയായി. കുടുംബമാല രജിസ്ട്രേഷൻ പൂർത്തിയാക്കാൻ ₹59 അടക്കേണ്ടതുണ്ട്.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('റദ്ദാക്കുക'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('₹59 അടയ്ക്കുക (UPI)'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'കുടുംബമാല രജിസ്ട്രേഷൻ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF000080)),
                  SizedBox(height: 16),
                  Text('രജിസ്ട്രേഷൻ സമർപ്പിക്കുന്നു...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.rejectionReason != null &&
                        widget.rejectionReason!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'തിരുത്തലുകൾ ആവശ്യമുണ്ട്: ${widget.rejectionReason}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Center(
                      child: GestureDetector(
                        onTap: _showImagePickerModal,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _imageBytes != null
                                  ? MemoryImage(_imageBytes!)
                                  : (_networkPhotoUrl != null &&
                                          _networkPhotoUrl!.isNotEmpty
                                      ? NetworkImage(_networkPhotoUrl!)
                                          as ImageProvider
                                      : null),
                              child: _imageBytes == null &&
                                      (_networkPhotoUrl == null ||
                                          _networkPhotoUrl!.isEmpty)
                                  ? const Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 32,
                                      color: Color(0xFF000080),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF000080),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'പ്രൊഫൈൽ ഫോട്ടോ ചേർക്കുക',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'പൂർണ്ണ നാമം',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'പേര് നൽകുക' : null,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'വിളിപ്പേര് (Nickname)',
                        hintText: 'കുടുംബത്തിൽ അറിയപ്പെടുന്ന വിളിപ്പേര് (ഐച്ഛികം)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'ഫോൺ നമ്പർ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'ഫോൺ നമ്പർ നൽകുക'
                          : null,
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'ഇമെയിൽ (Email)',
                        hintText: 'user@example.com (ഐച്ഛികം)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _houseController,
                      decoration: const InputDecoration(
                        labelText: 'വീട്ടുപേര്',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'വീട്ടുപേര് നൽകുക'
                          : null,
                    ),

                    const SizedBox(height: 12),

                    // അമ്മയുടെ തറവാട് (പന്തി)
                    UniversalTharavaduDropdown(
                      label: 'അമ്മയുടെ തറവാട് (പന്തി)',
                      hintText: 'അമ്മയുടെ തറവാട് (പന്തി) തിരഞ്ഞെടുക്കുക',
                      prefixIcon: const Icon(Icons.female_outlined),
                      selectedValue: _selectedPanthi,
                      onChanged: (v) => setState(() => _selectedPanthi = v),
                      validator: (v) =>
                          v == null ? 'പന്തി തറവാട് തിരഞ്ഞെടുക്കുക' : null,
                    ),

                    const SizedBox(height: 12),

                    // അച്ഛന്റെ തറവാട് (ബന്ധു)
                    UniversalTharavaduDropdown(
                      label: 'അച്ഛന്റെ തറവാട് (ബന്ധു)',
                      hintText: 'അച്ഛന്റെ തറവാട് (ബന്ധു) തിരഞ്ഞെടുക്കുക',
                      prefixIcon: const Icon(Icons.male_outlined),
                      selectedValue: _selectedBandhu,
                      onChanged: (v) => setState(() => _selectedBandhu = v),
                      validator: (v) =>
                          v == null ? 'ബന്ധു തറവാട് തിരഞ്ഞെടുക്കുക' : null,
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            icon: const Icon(Icons.calendar_month_outlined),
                            onPressed: () async {
                              final now = DateTime.now();
                              final firstDate = DateTime(1920);
                              DateTime initialDate = _dob ?? DateTime(2000, 1, 1);
                              if (initialDate.isAfter(now)) initialDate = now;
                              if (initialDate.isBefore(firstDate)) initialDate = firstDate;

                              final d = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: firstDate,
                                lastDate: now,
                              );
                              if (d != null && mounted) {
                                setState(() => _dob = d);
                              }
                            },
                            label: Text(
                              _dob == null
                                  ? 'ജനനത്തീയതി'
                                  : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            icon: const Icon(Icons.access_time_outlined),
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _birthTime ?? const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (t != null && mounted) {
                                setState(() => _birthTime = t);
                              }
                            },
                            label: Text(
                              _birthTime == null
                                  ? 'ജനന സമയം'
                                  : _birthTime!.format(context),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('ഇരട്ടക്കുട്ടി (ആദ്യം ജനിച്ചയാൾ)'),
                      value: _isFirstTwin,
                      onChanged: (v) =>
                          setState(() => _isFirstTwin = v ?? false),
                    ),

                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('കുടുംബത്തിൽ ഒറ്റ മകൻ / മകൾ ആണ്'),
                      value: _isSingleChild,
                      onChanged: (v) =>
                          setState(() => _isSingleChild = v ?? false),
                    ),

                    if (!_isSingleChild) ...[
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _siblingPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText:
                              'കൂടപ്പിറപ്പിന്റെ ഫോൺ നമ്പർ (അപ്രൂവലിനായി)',
                          hintText: '10 അക്ക മൊബൈൽ നമ്പർ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        validator: (v) => !_isSingleChild &&
                                (v == null || v.trim().isEmpty)
                            ? 'കൂടപ്പിറപ്പിന്റെ നമ്പർ നൽകുക'
                            : null,
                      ),
                    ],

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _submitForm,
                      child: const Text(
                        'വിവരങ്ങൾ സമർപ്പിക്കുക',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
