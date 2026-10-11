import 'package:flutter/material.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mobile_number/mobile_number.dart';
import '../../core/models/models.dart';
import '../../core/widgets/universal_tharavadu_dropdown.dart';

class AgentRegistrationScreen extends StatefulWidget {
  const AgentRegistrationScreen({super.key});

  @override
  State<AgentRegistrationScreen> createState() =>
      _AgentRegistrationScreenState();
}

class _AgentRegistrationScreenState extends State<AgentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _dobDayController = TextEditingController();
  final _dobMonthController = TextEditingController();
  final _dobYearController = TextEditingController();
  final _dobDayFocus = FocusNode();
  final _dobMonthFocus = FocusNode();
  final _dobYearFocus = FocusNode();

  final _locationController = TextEditingController();

  String? _selectedTharavadu;
  Gender _gender = Gender.male;
  DateTime? _dob;
  bool _isPhoneVerified = false;
  String _simCarrier = '';
  bool _isSendingOtp = false;

  bool _isLoading = false;
  bool _obscurePassword = true;

  File? _profileImageFile;
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      enableTracking: false,
    ),
  );

  @override
  void initState() {
    super.initState();
    _dobDayController.addListener(_updateDobFromFields);
    _dobMonthController.addListener(_updateDobFromFields);
    _dobYearController.addListener(_updateDobFromFields);
  }

  void _updateDobFromFields() {
    final dayStr = _dobDayController.text.trim();
    final monthStr = _dobMonthController.text.trim();
    final yearStr = _dobYearController.text.trim();
    if (dayStr.isNotEmpty && monthStr.isNotEmpty && yearStr.length == 4) {
      final day = int.tryParse(dayStr);
      final month = int.tryParse(monthStr);
      final year = int.tryParse(yearStr);
      if (day != null && month != null && year != null) {
        try {
          final parsedDate = DateTime(year, month, day);
          if (parsedDate.day == day &&
              parsedDate.month == month &&
              parsedDate.year == year) {
            setState(() {
              _dob = parsedDate;
            });
            return;
          }
        } catch (_) {}
      }
    }

    if (_dob != null) {
      setState(() {
        _dob = null;
      });
    }
  }

  int? get _exactAge {
    if (_dob == null) return null;
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - _dob!.year;
    if (currentDate.month < _dob!.month ||
        (currentDate.month == _dob!.month && currentDate.day < _dob!.day)) {
      age--;
    }
    return age;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    _dobDayController.dispose();
    _dobMonthController.dispose();
    _dobYearController.dispose();
    _dobDayFocus.dispose();
    _dobMonthFocus.dispose();
    _dobYearFocus.dispose();

    _locationController.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _pickAndVerifyImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final file = File(pickedFile.path);
      final inputImage = InputImage.fromFile(file);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'മുഖം വ്യക്തമല്ല! ദയവായി വ്യക്തമായ ഒരു ഫോട്ടോ അപ്‌ലോഡ് ചെയ്യുക.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _profileImageFile = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _profileImageFile = file;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTharavadu == null || _selectedTharavadu!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Tharavadu.')),
      );
      return;
    }
    if (_profileImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a verified profile photo.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please verify your phone number using the SIM selector.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final finalAge = _exactAge;
    if (finalAge == null || finalAge < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be at least 18 years old.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      // Create user in Supabase Auth
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user ?? response.session?.user;
      if (user != null) {
        String profileImageUrl = 'https://placehold.co/150';
        try {
          // Upload photo to Supabase storage
          final imageExtension = _profileImageFile!.path.split('.').last;
          final storagePath = '${user.id}/profile.$imageExtension';

          await Supabase.instance.client.storage
              .from('agent-profiles')
              .upload(storagePath, _profileImageFile!);

          profileImageUrl = Supabase.instance.client.storage
              .from('agent-profiles')
              .getPublicUrl(storagePath);
        } catch (storageErr) {
          debugPrint('Agent profile photo upload failed: $storageErr');
        }

        // Insert into public.agents table
        await Supabase.instance.client.from('agents').insert({
          'id': user.id,
          'name': name,
          'phone': phone,
          'email': email,
          'age': finalAge,
          'tharavadu': _selectedTharavadu ?? '',
          'status': 'PENDING',
          'profile_image': profileImageUrl,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Agent Registration successful! Pending Admin Approval.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Route back to login or waiting screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/agent_waiting',
            (route) => false,
          );
        }
      } else {
        throw Exception('Failed to create user.');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agent Registration',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Branding Banner
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Center(
                child: Text(
                  'Kurichiyar Matrimony Agent Portal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickAndVerifyImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _profileImageFile != null
                                    ? FileImage(_profileImageFile!)
                                    : null,
                                child: _profileImageFile == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF000080),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Upload Verified Profile Photo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 1. Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.fullName,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // 2. Phone Number
                      if (!_isPhoneVerified) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isSendingOtp
                                  ? null
                                  : () async {
                                      bool hasPermission =
                                          await MobileNumber.hasPhonePermission;
                                      if (!hasPermission) {
                                        await MobileNumber
                                            .requestPhonePermission;
                                        hasPermission = await MobileNumber
                                            .hasPhonePermission;
                                      }

                                      List<SimCard> simCards = [];
                                      if (hasPermission) {
                                        try {
                                          simCards =
                                              (await MobileNumber
                                                  .getSimCards) ??
                                              [];
                                        } catch (e) {
                                          debugPrint(
                                            'Mobile number fetch error: $e',
                                          );
                                        }
                                      }

                                      if (!context.mounted) return;

                                      final selectedSim =
                                          await showModalBottomSheet<
                                            Map<String, String>
                                          >(
                                            context: context,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                            ),
                                            builder: (ctx) => SafeArea(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Padding(
                                                    padding: EdgeInsets.all(
                                                      16.0,
                                                    ),
                                                    child: Text(
                                                      'Select SIM for Agent Registration',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  if (simCards.isEmpty)
                                                    const Padding(
                                                      padding: EdgeInsets.all(
                                                        16.0,
                                                      ),
                                                      child: Text(
                                                        'No SIM cards detected or permission denied.',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    ...simCards.map(
                                                      (sim) => ListTile(
                                                        leading: const Icon(
                                                          Icons.sim_card,
                                                          color: Colors.blue,
                                                        ),
                                                        title: Text(
                                                          sim.carrierName ??
                                                              'Unknown Carrier',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        subtitle: Text(
                                                          sim.number ??
                                                              'Unknown Number',
                                                        ),
                                                        onTap: () {
                                                          if (sim.number !=
                                                                  null &&
                                                              sim
                                                                  .number!
                                                                  .isNotEmpty) {
                                                            Navigator.pop(ctx, {
                                                              'carrier':
                                                                  sim.carrierName ??
                                                                  'SIM',
                                                              'phone':
                                                                  sim.number!,
                                                            });
                                                          } else {
                                                            ScaffoldMessenger.of(
                                                              ctx,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Phone number not stored on this SIM. Please enter manually.',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  const Divider(height: 1),
                                                  ListTile(
                                                    leading: const Icon(
                                                      Icons.edit,
                                                      color: Colors.grey,
                                                    ),
                                                    title: const Text(
                                                      'Enter Mobile Number Manually',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    onTap: () =>
                                                        Navigator.pop(ctx, {
                                                          'carrier': 'Manual',
                                                          'phone': '',
                                                        }),
                                                  ),
                                                  const SizedBox(height: 16),
                                                ],
                                              ),
                                            ),
                                          );

                                      if (selectedSim == null) return;

                                      final carrier = selectedSim['carrier']!;

                                      if (carrier == 'Manual') {
                                        setState(() {
                                          _simCarrier = 'Manual';
                                          _isPhoneVerified = true;
                                        });
                                        return;
                                      }

                                      setState(() => _isSendingOtp = true);
                                      await Future.delayed(
                                        const Duration(milliseconds: 1000),
                                      );

                                      final displayPhone =
                                          selectedSim['phone']!;

                                      setState(() {
                                        _phoneController.text = displayPhone;
                                        _simCarrier = carrier;
                                        _isPhoneVerified = true;
                                        _isSendingOtp = false;
                                      });
                                    },
                              icon: _isSendingOtp
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.sim_card,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isSendingOtp
                                    ? 'Binding SIM Card...'
                                    : 'Auto-fetch Verified SIM Number',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF000080),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                'If auto-fetch fails or is denied, you may enter manually.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (_simCarrier == 'Manual') ...[
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Enter Verified Phone Number manually',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          validator: (v) => v!.isEmpty
                              ? 'Please enter your phone number'
                              : null,
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.05),
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Verified Phone Number (SIM Bound)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Verified: $_simCarrier (${_phoneController.text})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
                      const SizedBox(height: 16),

                      // 3. Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.emailAddress,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!value.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 4. Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.setPassword,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // 5. Date of Birth
                      Text(
                        AppLocalizations.of(context)!.selectDob,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dobDayController,
                              focusNode: _dobDayFocus,
                              keyboardType: TextInputType.number,
                              maxLength: 2,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: 'DD',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                counterText: '',
                              ),
                              onChanged: (val) {
                                if (val.length == 2) {
                                  _dobMonthFocus.requestFocus();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _dobMonthController,
                              focusNode: _dobMonthFocus,
                              keyboardType: TextInputType.number,
                              maxLength: 2,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: 'MM',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                counterText: '',
                              ),
                              onChanged: (val) {
                                if (val.length == 2) {
                                  _dobYearFocus.requestFocus();
                                } else if (val.isEmpty) {
                                  _dobDayFocus.requestFocus();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _dobYearController,
                              focusNode: _dobYearFocus,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: 'YYYY',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                counterText: '',
                              ),
                              onChanged: (val) {
                                if (val.isEmpty) {
                                  _dobMonthFocus.requestFocus();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Gender and Age Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Gender Section (Left Side)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.genderMaleFemale,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RadioGroup<Gender>(
                                groupValue: _gender,
                                onChanged: (v) => setState(() => _gender = v!),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Radio<Gender>(value: Gender.male),
                                    Text(
                                      AppLocalizations.of(context)!.genderMale,
                                    ),
                                    const SizedBox(width: 16),
                                    Radio<Gender>(value: Gender.female),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.genderFemale,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Age Display (Right Side, below Year box)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _exactAge != null ? 'Age: $_exactAge' : 'Age: --',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          )!.houseNameCurrentResidence,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // 6. Tharavadu
                      UniversalTharavaduDropdown(
                        label: AppLocalizations.of(
                          context,
                        )!.yourTharavadu,
                        selectedValue: _selectedTharavadu,
                        onChanged: (value) {
                          setState(() {
                            _selectedTharavadu = value;
                          });
                        },
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000080),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Application',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Banner/Footer
            Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Center(
                child: Text(
                  'Kurichiyar Matrimony © 2026 - Advertisements',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
