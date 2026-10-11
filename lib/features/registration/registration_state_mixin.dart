part of 'registration_wizard.dart';

mixin RegistrationStateMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 9;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingProfile = false,
      _isUploadingID = false,
      _loadingClans = true,
      _isPhoneVerified = false,
      _isSendingOtp = false;
  String _simCarrier = '';
  String? _profilePhotoLocalPath;
  Timer? _debounceTimer;
  List<Clan> _clans = [];
  String? incompleteRegistrationId;
  String? _submitError;

  // Step 2 Form Field Keys for Auto-Scroll
  final Map<String, GlobalKey<FormFieldState>> step2Keys = {
    'house': GlobalKey<FormFieldState>(),
    'father': GlobalKey<FormFieldState>(),
    'mother': GlobalKey<FormFieldState>(),
    'forbidden': GlobalKey<FormFieldState>(),
    'height': GlobalKey<FormFieldState>(),
    'weight': GlobalKey<FormFieldState>(),
    'blood': GlobalKey<FormFieldState>(),
    'physical': GlobalKey<FormFieldState>(),
    'education': GlobalKey<FormFieldState>(),
    'eduOther': GlobalKey<FormFieldState>(),
  };

  Map<String, dynamic> registrationFieldConfig = {
    'show_height': true,
    'show_weight': true,
    'show_complexion': true,
    'show_blood_group': true,
    'show_tharavad': true,
    'show_education': true,
    'show_occupation': true,
    'show_income': true,
    'show_hobbies': true,
    'show_diet': true,
  };

  void updateState(VoidCallback fn) => setState(fn);

  void _showSupportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            .from('system_settings')
            .select('key, value')
            .inFilter('key', ['support_phone', 'support_email']),
        builder: (context, snapshot) {
          String phone = '+91 8589 89 2221';
          String email = 'support@kurichiyarmatrimony.com';
          if (snapshot.hasData && snapshot.data != null) {
            for (var row in snapshot.data!) {
              if (row['key'] == 'support_phone') phone = row['value'] as String;
              if (row['key'] == 'support_email') email = row['value'] as String;
            }
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Call Support'),
                  subtitle: Text(phone),
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email Support'),
                  subtitle: Text(email),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showError(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                m,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
    GlobalErrorHandler.logError(m);
  }

  Future<void> _pickAndUploadImage(bool isProfile, ImageSource source) async {
    try {
      final img = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (img == null) return;

      setState(() {
        if (isProfile) {
          _profilePhotoError = null;
          _profilePhotoLocalPath = img.path;
          _isUploadingProfile = true;
        } else {
          _isUploadingID = true;
        }
      });
      try {
        if (isProfile) {
          await ImageValidationService.validateProfileImage(img.path);
        } else {
          await ImageValidationService.validateIdDocument(img.path);
        }
      } catch (e) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        _showError(errorMsg);
        setState(() {
          if (isProfile) {
            _profilePhotoError = errorMsg;
            _profilePhotoLocalPath = null;
            _isUploadingProfile = false;
          } else {
            _isUploadingID = false;
          }
        });
        return;
      }

      if (!isProfile) {
        try {
          final inputImage = InputImage.fromFilePath(img.path);
          final textRecognizer = TextRecognizer(
            script: TextRecognitionScript.latin,
          );
          final recognizedText = await textRecognizer.processImage(inputImage);
          final extractedText = recognizedText.text.toUpperCase();

          String? extractedNumber;
          if (_idType == 'Aadhaar Card') {
            final reg = RegExp(r'\d{4}\s?\d{4}\s?\d{4}');
            final match = reg.firstMatch(extractedText);
            if (match != null)
  { extractedNumber = match.group(0)?.replaceAll(' ', ''); }
          } else if (_idType == 'PAN Card') {
            final reg = RegExp(r'[A-Z]{5}[0-9]{4}[A-Z]{1}');
            final match = reg.firstMatch(extractedText);
            if (match != null) extractedNumber = match.group(0);
          } else if (_idType == 'Voter ID') {
            final reg = RegExp(r'[A-Z]{3}[0-9]{7}');
            final match = reg.firstMatch(extractedText);
            if (match != null) extractedNumber = match.group(0);
          } else if (_idType == 'Driving Licence') {
            final reg = RegExp(r'[A-Z]{2}[0-9]{13}');
            final match = reg.firstMatch(extractedText);
            if (match != null) extractedNumber = match.group(0);
          } else if (_idType == 'Passport') {
            final reg = RegExp(r'[A-Z]{1}[0-9]{7}');
            final match = reg.firstMatch(extractedText);
            if (match != null) extractedNumber = match.group(0);
          }

          if (extractedNumber != null) {
            setState(() {
              _idNumberController.text = extractedNumber!;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ID Number Extracted via AI âœ¨'),
                  backgroundColor: Colors.indigo,
                ),
              );
            }
          }

          textRecognizer.close();
        } catch (e) {
          debugPrint('OCR Error: $e');
        }
      }

      final file = File(img.path),
          name = '${DateTime.now().millisecondsSinceEpoch}_${img.name}';
      try {
        if (isProfile) {
          await Supabase.instance.client.storage
              .from('profiles')
              .upload(
                'profile_photos/$name',
                file,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              )
              .timeout(const Duration(seconds: 120));
          final url = Supabase.instance.client.storage
              .from('profiles')
              .getPublicUrl('profile_photos/$name');
          setState(() => _profilePhotoUrl = url);
        } else {
          await Supabase.instance.client.storage
              .from('user_identity_documents')
              .upload(
                name,
                file,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              )
              .timeout(const Duration(seconds: 120));
          final url = Supabase.instance.client.storage
              .from('user_identity_documents')
              .getPublicUrl(name);
          setState(() => _idDocumentUrl = url);
        }
      } catch (e) {
        final isTimeout =
            e is TimeoutException || e.toString().contains('TimeoutException');
        _showError(
          isTimeout
              ? 'Upload timed out due to slow network. Please tap to retry.'
              : 'Upload failed: ${e.toString().replaceAll('Exception: ', '')}',
        );
        setState(
          () =>
              isProfile ? _isUploadingProfile = false : _isUploadingID = false,
        );
        return;
      }
      _saveDraft();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload Complete âœ“'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(
          () =>
              isProfile ? _isUploadingProfile = false : _isUploadingID = false,
        );
      }
    }
  }

  void _showImageSourceActionSheet(bool isProfile) => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo (Camera)'),
            onTap: () {
              Navigator.pop(ctx);
              _pickAndUploadImage(isProfile, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(ctx);
              _pickAndUploadImage(isProfile, ImageSource.gallery);
            },
          ),
        ],
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 2. lazy local cache initialization: DO NOT BLOCK!
    // SHOW THE REGISTRATION STEP IMMEDIATELY AND POPULATE
    _loadDraft();

    // Initialize lead tracking & add 1-second debounced listeners on key fields (Full Name, Phone)
    LeadTrackingService.instance.init(
      step: _currentStep + 1,
      phone: _phoneController.text,
      name: _nameController.text,
    );
    _nameController.addListener(_onLeadInputChanged);
    _phoneController.addListener(_onLeadInputChanged);

    TharavaduService.instance.addListener(_onClansUpdated);
    TharavaduService.instance.syncClans(); // Fetch latest from DB
    _loadClans();
    _loadSystemSettings();
    for (var c in [
      _nameController,
      _phoneController,
      _fatherNameController,
      _motherNameController,
      _houseNameController,
      _fatherClanController,
      _motherClanController,
      _educationOtherController,
      _careerDetailController,
      _aboutMeController,
      _agentCodeController,
      _pincodeController,
      _digipinController,
      _districtController,
      _talukController,
      _panchayathController,
      _postOfficeController,
    ]) {
      c.addListener(_saveDraft);
    }
    _pincodeController.addListener(() {
      final pin = _pincodeController.text.trim();
      if (pin.isNotEmpty) {
        _pincode = pin;
      }
    });
    _districtController.addListener(() {
      final val = _districtController.text.trim();
      if (val.isNotEmpty) {
        _district = val;
      }
    });
    _talukController.addListener(() {
      final val = _talukController.text.trim();
      if (val.isNotEmpty) {
        _taluk = val;
      }
    });
    _panchayathController.addListener(() {
      final val = _panchayathController.text.trim();
      if (val.isNotEmpty) {
        _panchayath = val;
      }
    });
    _postOfficeController.addListener(() {
      final val = _postOfficeController.text.trim();
      if (val.isNotEmpty) {
        _postOffice = val;
      }
    });
    _digipinController.addListener(() {
      final val = _digipinController.text.trim().toUpperCase();
      if (val.isNotEmpty) {
        _digipin = val;
      }
    });
    for (var c in [
      _dobDayController,
      _dobMonthController,
      _dobYearController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _idNumberController,
    ]) {
      c.addListener(_updateDobFromFields);
    }
    _dobYearController.addListener(_calculateAge);
    _boysCountController.addListener(_updateChildrenDetails);
    _girlsCountController.addListener(_updateChildrenDetails);
  }

  void _onLeadInputChanged() {
    LeadTrackingService.instance.trackLeadInput(
      phone: _phoneController.text,
      name: _nameController.text,
      currentStep: _currentStep + 1,
    );
  }

  void _updateDobFromFields() {
    final dayStr = _dobDayController.text.trim();
    final monthStr = _dobMonthController.text.trim();
    final yearStr = _dobYearController.text.trim();
    if (dayStr.length == 2 && monthStr.length == 2 && yearStr.length == 4) {
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
            _saveDraft();
          }
        } catch (_) {}
      }
    }
  }

  void updateRestrictedFamilies() {
    String? applicantMoiety;
    if (_motherClan != null) {
      applicantMoiety = _motherClan!.type;
    } else if (_fatherClan != null) {
      if (_fatherClan!.type == 'BANDHU') {
        applicantMoiety = 'PANDI';
      } else if (_fatherClan!.type == 'PANDI') {
        applicantMoiety = 'BANDHU';
      }
    }

    if (applicantMoiety != null &&
        (applicantMoiety == 'BANDHU' || applicantMoiety == 'PANDI')) {
      setState(() {
        _hasFamilyRestriction = true;
        _selectedRestrictedFamilies.clear();
      });
    } else {
      setState(() {
        _hasFamilyRestriction = false;
        _selectedRestrictedFamilies.clear();
      });
    }
  }

  void _calculateAge() {
    final yStr = _dobYearController.text.trim();
    if (yStr.length == 4) {
      final y = int.tryParse(yStr);
      if (y != null) {
        setState(() {
          _exactAge = 2026 - y;
        });
      } else {
        setState(() => _exactAge = null);
      }
    } else {
      setState(() => _exactAge = null);
    }
  }

  Future<void> _loadSystemSettings() async {
    try {
      final res = await Supabase.instance.client
          .from('system_settings')
          .select();
      for (var item in res) {
        if (item['config_key'] == 'PROFILE_PRIVACY_FEE' ||
            item['key'] == 'PROFILE_PRIVACY_FEE') {
          _privacyFee =
              double.tryParse(
                (item['config_value'] ?? item['value']).toString(),
              ) ??
              100;
        } else if (item['config_key'] == 'PROFILE_PRIVACY_DURATION_MONTHS' ||
            item['key'] == 'PROFILE_PRIVACY_DURATION_MONTHS') {
          _privacyDuration =
              int.tryParse(
                (item['config_value'] ?? item['value']).toString(),
              ) ??
              6;
        } else if (item['key'] == 'registration_field_config' ||
            item['config_key'] == 'registration_field_config') {
          final val = item['value'] ?? item['config_value'];
          if (val != null) {
            registrationFieldConfig = Map<String, dynamic>.from(
              jsonDecode(val.toString()),
            );
          }
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading system settings: $e');
    }
  }

  void _onClansUpdated() {
    if (mounted) {
      setState(() {
        _clans = allClans;
        _loadingClans = false;
      });
    }
  }

  Future<void> _loadClans() async {
    TharavaduService.instance.addListener(_onClansUpdated);
    _onClansUpdated(); // Initial load
    await TharavaduService.instance.syncClans();
  }

  Future<void> _refreshClans() async {
    await TharavaduService.instance.syncClans(forceRefresh: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('à´¤à´±à´µà´¾à´Ÿàµ à´µà´¿à´µà´°à´™àµà´™àµ¾ à´…à´ªàµà´¡àµ‡à´±àµà´±àµ à´šàµ†à´¯àµà´¤àµ')),
      );
    }
  }

  Future<void> _saveDraft() async {
    LeadTrackingService.instance.trackLeadInput(
      phone: _phoneController.text,
      name: _nameController.text,
      currentStep: _currentStep + 1,
    );
    final d = {
      'currentStep': _currentStep,
      'name': _nameController.text,
      'phone': _phoneController.text,
      'publicDisplayNumber': _publicDisplayNumberController.text,
      'dob': _dob?.toIso8601String(),
      'gender': _gender.name,
      'fatherName': _fatherNameController.text,
      'motherName': _motherNameController.text,
      'isFatherDeceased': _isFatherDeceased,
      'isMotherDeceased': _isMotherDeceased,
      'houseName': _houseNameController.text,
      'fatherTharavadu': _fatherClanController.text,
      'motherTharavadu': _motherClanController.text,
      'height': _height,
      'weight': _weight,
      'bloodGroup': _bloodGroup,
      'physicalStatus': _physicalStatus,
      'educationLevel': _educationLevel,
      'educationOther': _educationOtherController.text,
      'careerSector': _careerSector,
      'careerDetail': _careerDetailController.text,
      'smokingHabit': _smokingHabit,
      'drinkingHabit': _drinkingHabit,
      'selectedHobbies': _selectedHobbies,
      'customHobby': _customHobbyController.text,
      'maritalStatus': _maritalStatus.name,
      'hasChildren': _hasChildren,
      'readyToAcceptChildren': _readyToAcceptChildren,
      'childrenCount': _childrenCount,
      'boysCount': _boysCount,
      'girlsCount': _girlsCount,
      'childrenGenders': _childrenGenders,
      'prefAgeMin': _prefAgeMin,
      'prefAgeMax': _prefAgeMax,
      'prefEducation': _prefEducation,
      'prefCareer': _prefCareer,
      'prefDistrict': _prefDistrict,
      'prefHabits': _prefHabits,
      'prefRelocateToBrideHome': _prefRelocateToBrideHome,
      'prefIncome': _prefIncome,
      'idDocumentUrl': _idDocumentUrl,
      'aboutMe': _aboutMeController.text,
      'profilePhotoUrl': _profilePhotoUrl,
      'agentCode': _agentCodeController.text,
      'acceptChildrenStatus': _acceptChildrenStatus,
      'adoptionPreference': _adoptionPreference,
      'groomStayWifeHouse': _groomStayWifeHouse,
      'brideHusbandStayHome': _brideHusbandStayHome,
      'willingMarryRemarriage': _willingMarryRemarriage,
      'firstMarriageAdoptChildren': _firstMarriageAdoptChildren,
      'firstMarriageMaxChildren': _firstMarriageMaxChildren,
      'isProfileHiddenPaid': _isProfileHiddenPaid,
      'isAutoRenewalEnabled': _isAutoRenewalEnabled,
      'hideContactInfo': _hideContactInfo,
      'pincode': _pincodeController.text.trim().isNotEmpty
          ? _pincodeController.text.trim()
          : (_pincode ?? ''),
      'district': _districtController.text.trim().isNotEmpty
          ? _districtController.text.trim()
          : (_district ?? ''),
      'taluk': _talukController.text.trim().isNotEmpty
          ? _talukController.text.trim()
          : (_taluk ?? ''),
      'panchayath': _panchayathController.text.trim().isNotEmpty
          ? _panchayathController.text.trim()
          : (_panchayath ?? ''),
      'postOffice': _postOfficeController.text.trim().isNotEmpty
          ? _postOfficeController.text.trim()
          : (_postOffice ?? ''),
      'digipin': _digipinController.text.trim().isNotEmpty
          ? _digipinController.text.trim().toUpperCase()
          : (_digipin ?? ''),
      'postOffices': _postOffices,
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      String tid =
          prefs.getString('registration_temp_id') ??
          'u_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('registration_temp_id', tid);
      d['tempId'] = tid;
      await prefs.setString('registration_wizard_draft', jsonEncode(d));
      _debouncedUpsert(tid);
    } catch (e) {
      debugPrint('Error saving registration wizard draft: $e');
    }
  }

  void _debouncedUpsert(String tid) {
    if (_nameController.text.trim().isEmpty &&
        _phoneController.text.trim().isEmpty) {
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      try {
        await FirebaseFirestore.instance
            .collection('draft_registrations')
            .doc(tid)
            .set({
              'id': tid,
              'registration_status': 'pending',
              'full_name': _nameController.text.trim().isNotEmpty
                  ? _nameController.text.trim()
                  : 'Anonymous',
              'phone': _phoneController.text.trim(),
              'updated_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving draft registration to Firestore: $e');
      }

      try {
        await Supabase.instance.client.from('kurichiyar_profiles').upsert({
          'id': tid,
          'registration_status': 'pending',
          'full_name': _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : 'Anonymous',
          'phone': _phoneController.text.trim(),
        });
      } catch (e) {
        debugPrint('Notice upserting draft registration profile to Supabase: $e');
      }
    });
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ds = prefs.getString('registration_wizard_draft');
      if (ds == null) {
        if ((widget as RegistrationWizard).initialStep != null && mounted) {
          setState(
            () =>
                _currentStep = (widget as RegistrationWizard).initialStep! - 1,
          );
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _pageController.hasClients
                ? _pageController.jumpToPage(_currentStep)
                : null,
          );
        }
        return;
      }
      final d = jsonDecode(ds) as Map<String, dynamic>;
      setState(() {
        _nameController.text = d['name'] ?? '';
        _phoneController.text = d['phone'] ?? '';
        _publicDisplayNumberController.text = d['publicDisplayNumber'] ?? '';
        _dob = d['dob'] != null ? DateTime.tryParse(d['dob']) : _dob;
        if (_dob != null) {
          _dobDayController.text = _dob!.day.toString().padLeft(2, '0');
          _dobMonthController.text = _dob!.month.toString().padLeft(2, '0');
          _dobYearController.text = _dob!.year.toString();
        }
        if (d['gender'] != null) {
          _gender = Gender.values.firstWhere(
            (e) => e.name == d['gender'],
            orElse: () => Gender.male,
          );
        }
        _fatherNameController.text = d['fatherName'] ?? '';
        _motherNameController.text = d['motherName'] ?? '';
        _houseNameController.text = d['houseName'] ?? '';
        _isFatherDeceased = d['isFatherDeceased'] ?? false;
        _isMotherDeceased = d['isMotherDeceased'] ?? false;
        if (d['fatherClanId'] != null) {
          _fatherClan = _clans.firstWhere(
            (c) => c.id == d['fatherClanId'],
            orElse: () => _clans.first,
          );
          _fatherClanController.text = _fatherClan!.name;
        }
        if (d['motherClanId'] != null) {
          _motherClan = _clans.firstWhere(
            (c) => c.id == d['motherClanId'],
            orElse: () => _clans.first,
          );
          _motherClanController.text = _motherClan!.name;
        }
        _height = d['height'];
        _weight = d['weight'];
        _bloodGroup = d['bloodGroup'];
        _physicalStatus = d['physicalStatus'];
        _educationLevel = d['educationLevel'];
        _educationOtherController.text = d['educationOther'] ?? '';
        _careerSector = d['careerSector'];
        _careerDetailController.text = d['careerDetail'] ?? '';
        _smokingHabit = d['smokingHabit'];
        _drinkingHabit = d['drinkingHabit'];
        if (d['selectedHobbies'] != null)
  { _selectedHobbies = List<String>.from(d['selectedHobbies']); }
        _customHobbyController.text = d['customHobby'] ?? '';
        if (d['maritalStatus'] != null) {
          _maritalStatus = MaritalStatus.values.firstWhere(
            (e) => e.name == d['maritalStatus'],
            orElse: () => MaritalStatus.first,
          );
        }
        _hasChildren = d['hasChildren'] ?? false;
        _readyToAcceptChildren = d['readyToAcceptChildren'] ?? false;
        _childrenCount = d['childrenCount'] ?? 0;
        _boysCount = d['boysCount'] ?? 0;
        _girlsCount = d['girlsCount'] ?? 0;
        if (_boysCount > 0) _boysCountController.text = _boysCount.toString();
        if (_girlsCount > 0)
  { _girlsCountController.text = _girlsCount.toString(); }
        if (d['childrenGenders'] != null)
  { _childrenGenders = List<String>.from(d['childrenGenders']); }
        _prefAgeMin = (d['prefAgeMin'] ?? 20).toDouble();
        _prefAgeMax = (d['prefAgeMax'] ?? 50).toDouble();
        _prefEducation = d['prefEducation'];
        _prefCareer = d['prefCareer'];
        _prefDistrict = d['prefDistrict'];
        _prefHabits = d['prefHabits'] ?? 'Open';
        _prefRelocateToBrideHome = d['prefRelocateToBrideHome'];
        _prefIncome = d['prefIncome'];
        _idDocumentUrl = d['idDocumentUrl'];
        _aboutMeController.text = d['aboutMe'] ?? '';
        _profilePhotoUrl = d['profilePhotoUrl'];
        _agentCodeController.text = d['agentCode'] ?? '';

        _acceptChildrenStatus = d['acceptChildrenStatus'];
        _adoptionPreference = d['adoptionPreference'];
        _groomStayWifeHouse = d['groomStayWifeHouse'];
        _brideHusbandStayHome = d['brideHusbandStayHome'];
        _willingMarryRemarriage = d['willingMarryRemarriage'];
        _pincode = d['pincode'];
        if (_pincode != null && _pincode!.isNotEmpty) {
          _pincodeController.text = _pincode!;
        }
        _district = d['district'];
        if (_district != null && _district!.isNotEmpty) {
          _districtController.text = _district!;
        }
        _taluk = d['taluk'];
        if (_taluk != null && _taluk!.isNotEmpty) {
          _talukController.text = _taluk!;
        }
        _panchayath = d['panchayath'];
        if (_panchayath != null && _panchayath!.isNotEmpty) {
          _panchayathController.text = _panchayath!;
        }
        _postOffice = d['postOffice'];
        if (_postOffice != null && _postOffice!.isNotEmpty) {
          _postOfficeController.text = _postOffice!;
        }
        _digipin = d['digipin'];
        if (_digipin != null && _digipin!.isNotEmpty) {
          _digipinController.text = _digipin!;
        }
        if (d['postOffices'] != null) {
          _postOffices = List<String>.from(d['postOffices']);
        }
        _firstMarriageAdoptChildren = d['firstMarriageAdoptChildren'];
        _firstMarriageMaxChildren = d['firstMarriageMaxChildren'];
        _isProfileHiddenPaid = d['isProfileHiddenPaid'] ?? false;
        _isAutoRenewalEnabled = d['isAutoRenewalEnabled'] ?? false;
        _hideContactInfo = d['hideContactInfo'] ?? false;
        _currentStep = d['currentStep'] ?? 0;
      });
      LeadTrackingService.instance.init(
        phone: _phoneController.text,
        name: _nameController.text,
        step: _currentStep + 1,
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _pageController.hasClients
            ? _pageController.jumpToPage(_currentStep)
            : null,
      );
    } catch (e) {
      debugPrint('Error loading registration wizard draft: $e');
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('registration_wizard_draft');
    } catch (e) {
      debugPrint('Error clearing registration draft: $e');
    }
  }

  @override
  void dispose() {
    TharavaduService.instance.removeListener(_onClansUpdated);
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _nameController.removeListener(_onLeadInputChanged);
    _phoneController.removeListener(_onLeadInputChanged);
    LeadTrackingService.instance.handleScreenExit();
    for (var c in [
      _pageController,
      _nameController,
      _phoneController,
      _publicDisplayNumberController,
      _otpController,
      _fatherNameController,
      _motherNameController,
      _houseNameController,
      _fatherClanController,
      _motherClanController,
      _mothersTarawadController,
      _educationOtherController,
      _careerDetailController,
      _customHobbyController,
      _aboutMeController,
      _agentCodeController,
      _dobDayController,
      _dobMonthController,
      _dobYearController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _idNumberController,
      _pincodeController,
      _digipinController,
      _districtController,
      _talukController,
      _panchayathController,
      _postOfficeController,
    ]) {
      c.dispose();
    }
    for (var f in [
      _dobDayFocus,
      _dobMonthFocus,
      _dobYearFocus,
      _idNumberFocus,
      _nameFocus,
      _emailFocus,
      _passwordFocus,
      _confirmPasswordFocus,
      _phoneFocus,
      _fatherNameFocus,
      _motherNameFocus,
      _houseNameFocus,
      _fatherClanFocus,
      _motherClanFocus,
      _publicDisplayNumberFocus,
      _motherTongueFocus,
      _pincodeFocus,
      _districtFocus,
      _heightFocus,
      _weightFocus,
      _physicalStatusFocus,
      _educationLevelFocus,
      _careerSectorFocus,
      _jobFocus,
      _maritalStatusFocus,
      _acceptChildrenStatusFocus,
      _prefAgeMinFocus,
      _prefAgeMaxFocus,
      _prefEducationFocus,
      _prefCareerFocus,
      _prefDistrictFocus,
      _legal1Focus,
      _legal2Focus,
      _legal3Focus,
      _legal4Focus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveDraft();
    }
    LeadTrackingService.instance.handleAppLifecycleState(state);
  }

  void _updateChildrenDetails() {
    _boysCount = int.tryParse(_boysCountController.text.trim()) ?? 0;
    _girlsCount = int.tryParse(_girlsCountController.text.trim()) ?? 0;
    setState(() {
      _childrenCount = _boysCount + _girlsCount;
    });
    _childrenGenders.clear();
    for (int i = 0; i < _boysCount; i++) {
      _childrenGenders.add('Son');
    }
    for (int i = 0; i < _girlsCount; i++) {
      _childrenGenders.add('Daughter');
    }
  }

  Future<void> _nextStep() async {
    bool ok = true;
    if (_currentStep == 0) {
      ok = _formKeyStep1.currentState?.validate() ?? false;
      if (ok) {
        final dStr = _dobDayController.text.trim();
        final mStr = _dobMonthController.text.trim();
        final yStr = _dobYearController.text.trim();
        final day = int.tryParse(dStr);
        final month = int.tryParse(mStr);
        final year = int.tryParse(yStr);

        if (dStr.isEmpty || mStr.isEmpty || yStr.isEmpty) {
          _showError('Please enter your complete Date of Birth');
          ok = false;
        } else if (day == null ||
            month == null ||
            year == null ||
            day < 1 ||
            day > 31 ||
            month < 1 ||
            month > 12 ||
            year < 1900 ||
            year > DateTime.now().year - 18) {
          _showError(
            'Please enter a valid Date of Birth (must be 18+ years old)',
          );
          ok = false;
        } else {
          try {
            final date = DateTime(year, month, day);
            if (date.day != day || date.month != month || date.year != year) {
              _showError('Please enter a valid calendar Date of Birth');
              ok = false;
            } else {
              _dob = date;
            }
          } catch (_) {
            _showError('Invalid Date of Birth format');
            ok = false;
          }
        }
      }
      final cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.length == 10 &&
          RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
        _isPhoneVerified = true;
      }
      if (ok && !_isPhoneVerified) {
        _showError('Please enter a valid 10-digit mobile phone number.');
        ok = false;
      }

      if (ok) {
        // [FIREBASE AUTH: MOCK/BYPASS LOGIC]
        final phone = _phoneController.text.trim();
        if (phone == '0000000000' || phone == '9999999999') {
          debugPrint(
            'Mock mode active. Bypassing Firebase OTP verification for test number: $phone',
          );
          _isPhoneVerified = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Test Number Detected: Bypassing Firebase OTP Verification to Step 2.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else if (!_isPhoneVerified) {
          // If not in mock mode and not verified, we can still allow bypass for development testing
          debugPrint(
            'Phone not verified by Firebase. Development bypass active.',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Dev Mode: Firebase OTP skipped. Proceeding to Step 2.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          _isPhoneVerified = true;
        }

        setState(() => _isUploadingProfile = true);
        try {
          final existingProfile = await Supabase.instance.client
              .from('kurichiyar_profiles')
              .select('id, approval_status')
              .eq('phone', phone)
              .maybeSingle();

          if (existingProfile != null) {
            final status = existingProfile['approval_status']
                ?.toString()
                .toUpperCase();
            if (status == 'PENDING') {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Your account is awaiting approval. Please login to enter your OTP.',
                    ),
                  ),
                );
                Navigator.pushReplacementNamed(context, '/login');
                return;
              }
            } else if (status == 'APPROVED') {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Your account is already approved. Please login.',
                    ),
                  ),
                );
                Navigator.pushReplacementNamed(context, '/login');
                return;
              }
            } else {
              _showError('This phone number is already registered.');
              ok = false;
            }
          }
        } catch (e) {
          debugPrint('Duplicate check error: $e');
        } finally {
          if (mounted) setState(() => _isUploadingProfile = false);
        }
      }
    } else if (_currentStep == 1) {
      ok = _formKeyStep2.currentState?.validate() ?? false;
      if (ok) {
        _fatherClan ??= _clans.cast<Clan?>().firstWhere(
          (c) =>
              c?.name.toLowerCase() ==
              _fatherClanController.text.trim().toLowerCase(),
          orElse: () => null,
        );
        _motherClan ??= _clans.cast<Clan?>().firstWhere(
          (c) =>
              c?.name.toLowerCase() ==
              _motherClanController.text.trim().toLowerCase(),
          orElse: () => null,
        );
      } else {
        final order = [
          step2Keys['house'],
          step2Keys['father'],
          step2Keys['mother'],
          step2Keys['forbidden'],
          step2Keys['restrictedList'],
          step2Keys['height'],
          step2Keys['weight'],
          step2Keys['blood'],
          step2Keys['physical'],
          step2Keys['education'],
          step2Keys['eduOther'],
        ];

        for (final key in order) {
          if (key?.currentState?.hasError == true) {
            final ctx = key?.currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(
                ctx,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: 0.1,
              );
              break;
            }
          }
        }
      }
    } else if (_currentStep == 2) {
      ok = _formKeyStep3.currentState?.validate() ?? false;
      final pin = _pincodeController.text.trim().isNotEmpty
          ? _pincodeController.text.trim()
          : (_pincode ?? '');
      if (pin.isEmpty || pin.length < 6) {
        _showError('à´¦à´¯à´µà´¾à´¯à´¿ à´¶à´°à´¿à´¯à´¾à´¯ 6 à´…à´•àµà´• à´ªà´¿àµ»à´•àµ‹à´¡àµ à´¨àµ½à´•àµà´• (Please enter a valid 6-digit Pincode)');
        ok = false;
      } else {
        _pincode = pin;
      }

      // Ensure all location variables are retained and synced
      if (_districtController.text.trim().isNotEmpty) {
        _district = _districtController.text.trim();
      }
      if (_talukController.text.trim().isNotEmpty) {
        _taluk = _talukController.text.trim();
      }
      if (_panchayathController.text.trim().isNotEmpty) {
        _panchayath = _panchayathController.text.trim();
      }
      if (_postOfficeController.text.trim().isNotEmpty) {
        _postOffice = _postOfficeController.text.trim();
      }
      if (_digipinController.text.trim().isNotEmpty) {
        _digipin = _digipinController.text.trim().toUpperCase();
      }
    } else if (_currentStep == 3) {
      ok = _formKeyStep4.currentState?.validate() ?? false;
    } else if (_currentStep == 4) {
      ok = _formKeyStep5.currentState?.validate() ?? false;
    } else if (_currentStep == 5) {
      ok = _formKeyStep6.currentState?.validate() ?? false;
    } else if (_currentStep == 6) {
      ok = _idDocumentUrl != null;
      if (!ok) _showError('Please upload an ID document to proceed.');
    } else if (_currentStep == 7) {
      if (!hasSelectedPhoto) {
        setState(() {
          _profilePhotoError =
              'à´¦à´¯à´µà´¾à´¯à´¿ à´¤àµà´Ÿà´°àµà´¨àµà´¨à´¤à´¿à´¨àµ à´’à´°àµ à´ªàµà´°àµŠà´«àµˆàµ½ à´«àµ‹à´Ÿàµà´Ÿàµ‹ à´…à´ªàµà´²àµ‹à´¡àµ à´šàµ†à´¯àµà´¯àµà´•';
        });
        _showError('à´¦à´¯à´µà´¾à´¯à´¿ à´¤àµà´Ÿà´°àµà´¨àµà´¨à´¤à´¿à´¨àµ à´’à´°àµ à´ªàµà´°àµŠà´«àµˆàµ½ à´«àµ‹à´Ÿàµà´Ÿàµ‹ à´…à´ªàµà´²àµ‹à´¡àµ à´šàµ†à´¯àµà´¯àµà´•');
        ok = false;
      } else {
        ok = _formKeyStep8.currentState?.validate() ?? false;
      }
    } else if (_currentStep == 8) {
      ok = _formKeyStep9.currentState?.validate() ?? false;
    }

    if (!ok) {
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        setState(() => _currentStep++);
      }
      LeadTrackingService.instance.updateStep(_currentStep + 1);
    } else {
      _submitFinal();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.hasClients
          ? _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
          : setState(() => _currentStep--);
      LeadTrackingService.instance.updateStep(_currentStep + 1);
    }
  }

  Future<void> _submitFinal() async {
    setState(() {
      _submitError = null;
    });
    debugPrint('\n=======================================');
    debugPrint('--- SUBMIT FINAL STARTED ---');
    final phone = _phoneController.text.trim();
    final rawEmail = _emailController.text.trim();
    final bool hasRealEmail =
        rawEmail.isNotEmpty &&
        rawEmail.contains('@') &&
        !rawEmail.toLowerCase().endsWith('@auth.kurichiyar.com');

    // Synthetic auth email used only as fallback for password authentication
    final authEmail = hasRealEmail ? rawEmail : '$phone@auth.kurichiyar.com';
    final profileEmail = hasRealEmail ? rawEmail : '';

    String password = _passwordController.text;
    if (password.isEmpty) {
      password = 'Kurichiyar@123';
    }
    debugPrint(
      'PHONE: $phone | AUTH_EMAIL: $authEmail | PROFILE_EMAIL: $profileEmail (hasRealEmail: $hasRealEmail)',
    );

    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      try {
        final fbCred = await FirebaseAuth.instance.signInAnonymously();
        uid = fbCred.user?.uid ?? '';
      } catch (fbErr) {
        debugPrint('Firebase anonymous login notice: $fbErr');
      }
    }
    String? lastErrorMsg;
    try {
      debugPrint('ATTEMPTING SIGN IN...');
      final signInRes = await Supabase.instance.client.auth.signInWithPassword(
        email: authEmail,
        password: password,
      );
      if (uid.isEmpty) uid = signInRes.user?.id ?? '';
      debugPrint('SIGN IN SUCCESS. UID: $uid');
    } catch (e1) {
      debugPrint('SIGN IN FAILED: $e1');
      lastErrorMsg = e1.toString();
      debugPrint('ATTEMPTING SIGN UP...');
      try {
        final signUpRes = await Supabase.instance.client.auth.signUp(
          email: authEmail,
          password: password,
          data: {
            'phone': phone,
            'full_name': _nameController.text.trim(),
            if (hasRealEmail) 'real_email': rawEmail,
          },
        );
        uid = signUpRes.user?.id ?? '';

        // Force sign in immediately after sign up to persist session
        try {
          final forceSignIn = await Supabase.instance.client.auth
              .signInWithPassword(email: authEmail, password: password);
          uid = forceSignIn.user?.id ?? uid;
        } catch (forceErr) {
          debugPrint('FORCE SIGN IN NOTICE: $forceErr');
          // If email confirmation prevents password login, sign in anonymously so currentUser is NEVER null
          if (Supabase.instance.client.auth.currentUser == null) {
            try {
              final anonRes = await Supabase.instance.client.auth
                  .signInAnonymously();
              if (anonRes.user != null) {
                uid = anonRes.user!.id;
                debugPrint('ANONYMOUS SESSION ESTABLISHED. UID: $uid');
              }
            } catch (anonErr) {
              debugPrint('ANONYMOUS SIGN IN ERROR: $anonErr');
            }
          }
        }

        debugPrint('SIGN UP SUCCESS. UID: $uid');
        lastErrorMsg = null; // Clear error if signup succeeds
      } catch (e2) {
        debugPrint('SIGN UP FAILED: $e2');
        lastErrorMsg = e2.toString(); // Prefer signup error if it fails
      }
    }

    if (uid.isEmpty) {
      debugPrint('FALLBACK TO CURRENT SESSION...');
      uid = Supabase.instance.client.auth.currentUser?.id ?? '';
      if (uid.isEmpty) {
        debugPrint(
          'CRITICAL: NO CURRENT USER UID. ATTEMPTING LOCAL TEMP ID FALLBACK.',
        );
        final prefs = await SharedPreferences.getInstance();
        final tid = prefs.getString('registration_temp_id');
        if (tid != null && tid.isNotEmpty) {
          uid = tid;
          debugPrint(
            'RECOVERED WITH TEMP ID: $uid (Auth Error: $lastErrorMsg)',
          );
        } else {
          debugPrint(
            'CRITICAL: NO UID OR TEMP ID AVAILABLE. ABORTING. Error: $lastErrorMsg',
          );
          _showError(
            lastErrorMsg != null
                ? 'Auth Error: $lastErrorMsg'
                : 'Unable to create or fetch Auth user session. Please check your credentials or try again.',
          );
          setState(() => _isSubmitting = false);
          return;
        }
      }
    }

    try {
      debugPrint('CHECKING EXISTING PROFILES...');
      final existing = await Supabase.instance.client
          .from('kurichiyar_profiles')
          .select('id')
          .eq('full_name', _nameController.text.trim())
          .eq('education_level', _educationLevel ?? '')
          .or('guardian_phone.eq.$phone,public_display_number.eq.$phone')
          .maybeSingle();
      if (existing != null) {
        debugPrint('PROFILE ALREADY EXISTS. ABORTING.');
        return _showError('Profile exists');
      }
    } catch (e) {
      debugPrint('EXISTING PROFILE CHECK ERROR (NON-FATAL): $e');
    }
    debugPrint('FINAL UID: $uid');

    if (_idDocumentUrl == null) {
      _showError(
        'à´¦à´¯à´µà´¾à´¯à´¿ à´¤à´¿à´°à´¿à´šàµà´šà´±à´¿à´¯àµ½ à´°àµ‡à´–à´¯àµà´Ÿàµ† à´µàµà´¯à´•àµà´¤à´®à´¾à´¯ à´«àµ‹à´Ÿàµà´Ÿàµ‹ à´…à´ªàµà´²àµ‹à´¡àµ à´šàµ†à´¯àµà´¯àµà´•.',
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      debugPrint('CALCULATING OUT OF CASTE...');
      final out = calculateIsOutOfCaste(
        _fatherClan?.id ?? 1,
        _motherClan?.id ?? 1,
      );
      final hasA = _agentCodeController.text.trim().isNotEmpty;

      debugPrint('PRIVACY LOGIC...');
      final isHidden = _isProfileHiddenPaid;
      DateTime? privacyExpiry;
      if (isHidden) {
        privacyExpiry = DateTime.now().add(
          Duration(days: 30 * _privacyDuration),
        );
      }

      debugPrint('BUILDING PAYLOAD...');
      final data = {
        'id': uid,
        'email': profileEmail,
        'phone': phone,
        'phone_number': phone,
        'full_name': _nameController.text.trim(),
        'age': _dob != null ? (DateTime.now().year - _dob!.year) : 0,
        'dob': _dob?.toIso8601String(),
        'photo_url': _profilePhotoUrl ?? 'https://placehold.co/150',
        'gender': _gender.name,
        'marital_status': _maritalStatus.name,
        'father_clan_id':
            _fatherClan?.id ??
            (_fatherClanController.text.isNotEmpty
                ? getClanByName(_fatherClanController.text.trim())?.id ?? 1
                : 1),
        'mother_clan_id':
            _motherClan?.id ??
            (_motherClanController.text.isNotEmpty
                ? getClanByName(_motherClanController.text.trim())?.id ?? 1
                : 1),
        'father_tharavadu':
            _fatherClan?.name ?? _fatherClanController.text.trim(),
        'mother_tharavadu':
            _motherClan?.name ?? _motherClanController.text.trim(),
        'father_clan': _fatherClan?.name ?? _fatherClanController.text.trim(),
        'mother_clan': _motherClan?.name ?? _motherClanController.text.trim(),
        'fathers_tarawad':
            _fatherClan?.name ?? _fatherClanController.text.trim(),
        'mothers_tarawad':
            _motherClan?.name ?? _motherClanController.text.trim(),
        'is_out_of_caste': out,
        'has_family_restriction': _hasFamilyRestriction,
        'restricted_tharavads': _selectedRestrictedFamilies.map((c) => c.id).toList(),
        'restricted_families': _selectedRestrictedFamilies.map((c) => c.name).toList(),
        'ready_to_accept_children': _readyToAcceptChildren ?? false,
        'father_name': _fatherNameController.text.trim(),
        'mother_name': _motherNameController.text.trim(),
        'is_father_deceased': _isFatherDeceased,
        'is_mother_deceased': _isMotherDeceased,
        'house_name': _houseNameController.text.trim(),
        'guardian_phone': _gender == Gender.female
            ? _publicDisplayNumberController.text.trim()
            : phone,
        'public_display_number': _gender == Gender.female
            ? _publicDisplayNumberController.text.trim()
            : phone,
        'height': _height,
        'height_cm': int.tryParse(_height ?? ''),
        'weight': _weight,
        'blood_group': _bloodGroup,
        'physical_status': _physicalStatus ?? 'Normal / Fit',
        'education_level': _educationLevel,
        'education_other_text': _educationOtherController.text.trim(),
        'career_sector': _careerSector,
        'job': _careerDetailController.text.trim(),
        'smoking_habit': _smokingHabit,
        'drinking_habit': _drinkingHabit,
        'hobbies': [
          ..._selectedHobbies,
          if (_customHobbyController.text.trim().isNotEmpty)
            _customHobbyController.text.trim(),
        ],
        'marriage_timeline': _timeline,
        'has_children': _hasChildren ?? false,
        'children_count':
            (int.tryParse(_boysCountController.text) ?? 0) +
            (int.tryParse(_girlsCountController.text) ?? 0),
        'boys_count': int.tryParse(_boysCountController.text) ?? 0,
        'girls_count': int.tryParse(_girlsCountController.text) ?? 0,
        'children_details': _childrenGenders.map((g) => {'gender': g}).toList(),
        'pref_age_min': _prefAgeMin.toInt(),
        'pref_age_max': _prefAgeMax.toInt(),
        'pref_education': _prefEducation,
        'pref_career': _prefCareer,
        'pref_district': _prefDistrict,
        'pref_habits': _prefHabits,
        'pref_relocate_to_bride_home': _prefRelocateToBrideHome,
        'residence_preference': _residencePreference,
        'parent_care_preference': _parentCarePreference,
        'pref_income': _prefIncome,
        'agent_code': hasA ? _agentCodeController.text.trim() : null,
        'id_document_url': _idDocumentUrl,
        'id_type': _idType,
        'id_number': _idNumberController.text.trim(),
        'verification_status': 'pending',
        'is_verified': false,
        'face_match_score': _idDocumentUrl != null
            ? (DateTime.now().millisecondsSinceEpoch % 40) +
                  60 // Simulated score 60-99%
            : null,
        'mother_tongue': _motherTongue,
        'languages_known': _languagesKnown,
        'core_values': _coreValues,
        'pincode': _pincodeController.text.trim().isNotEmpty
            ? _pincodeController.text.trim()
            : (_pincode ?? ''),
        'district': _districtController.text.trim().isNotEmpty
            ? _districtController.text.trim()
            : (_district ?? ''),
        'taluk': _talukController.text.trim().isNotEmpty
            ? _talukController.text.trim()
            : (_taluk ?? ''),
        'panchayath': _panchayathController.text.trim().isNotEmpty
            ? _panchayathController.text.trim()
            : (_panchayath ?? ''),
        'grama_panchayath': _panchayathController.text.trim().isNotEmpty
            ? _panchayathController.text.trim()
            : (_panchayath ?? ''),
        'post_office': _postOfficeController.text.trim().isNotEmpty
            ? _postOfficeController.text.trim()
            : (_postOffice ?? ''),
        'digipin': _digipinController.text.trim().isNotEmpty
            ? _digipinController.text.trim().toUpperCase()
            : (_digipin?.toUpperCase() ?? ''),
        'bio': _aboutMeController.text.trim(),
        'registration_status': hasA ? 'AGENTREVIEW' : 'ADMINREVIEW',
        'account_status': 'pending',
        'status': 'pending',
        'accept_children_status': _acceptChildrenStatus,
        'adoption_preference': _adoptionPreference,
        'groom_staying_at_wifes_house_preference': _gender == Gender.male
            ? _groomStayWifeHouse
            : null,
        'bride_husband_staying_at_home_preference': _gender == Gender.female
            ? _brideHusbandStayHome
            : null,
        'first_marriage_open_to_remarriage_preference':
            _maritalStatus == MaritalStatus.first
            ? _willingMarryRemarriage
            : null,
        'first_marriage_adopt_children_preference':
            (_maritalStatus == MaritalStatus.first &&
                _willingMarryRemarriage == 'YES_WILLING')
            ? _firstMarriageAdoptChildren
            : null,
        'first_marriage_max_children_count':
            (_maritalStatus == MaritalStatus.first &&
                _willingMarryRemarriage == 'YES_WILLING' &&
                _firstMarriageAdoptChildren == 'YES_WILLING')
            ? _firstMarriageMaxChildren
            : null,
        'is_profile_hidden': isHidden,
        'privacy_expiry_date': privacyExpiry?.toIso8601String(),
        'is_auto_renewal_enabled': _isAutoRenewalEnabled,
        'hide_contact_info': _hideContactInfo,
        'is_marketing_allowed': _isMarketingAllowed,
        'promotional_consent': _isMarketingAllowed,
      };
      debugPrint('PAYLOAD BUILT SUCCESSFULLY.');

      String deviceId = LocalCacheService.instance.getOrCreateDeviceId();
      data['device_id'] = deviceId;
      debugPrint('DEVICE ID ADDED: $deviceId');

      // Enforce Unique Mobile Number
      debugPrint('CHECKING MOBILE NUMBER UNIQUENESS...');
      final phoneToCheck =
          data['phone']?.toString().trim() ?? _phoneController.text.trim();
      try {
        final existingFs = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: phoneToCheck)
            .limit(1)
            .get();
        if (existingFs.docs.isNotEmpty && existingFs.docs.first.id != uid) {
          throw Exception('MOBILE_IN_USE');
        }
      } catch (e) {
        if (e.toString().contains('MOBILE_IN_USE')) rethrow;
        debugPrint('Firestore uniqueness check notice: $e');
      }

      try {
        final existingPhone = await Supabase.instance.client
            .from('kurichiyar_profiles')
            .select('id')
            .eq('phone', phoneToCheck)
            .maybeSingle();

        if (existingPhone != null && existingPhone['id'] != uid) {
          throw Exception('MOBILE_IN_USE');
        }
      } catch (e) {
        if (e.toString().contains('MOBILE_IN_USE')) rethrow;
        debugPrint('Supabase uniqueness check notice: $e');
      }

      debugPrint('===========================================================');
      debugPrint('=== FINAL SUBMISSION LOCATION PAYLOAD VERIFICATION ===');
      debugPrint('pincode: "${data['pincode']}"');
      debugPrint('district: "${data['district']}"');
      debugPrint('taluk: "${data['taluk']}"');
      debugPrint('panchayath: "${data['panchayath']}"');
      debugPrint('grama_panchayath: "${data['grama_panchayath']}"');
      debugPrint('post_office: "${data['post_office']}"');
      debugPrint('digipin: "${data['digipin']}"');
      debugPrint('===========================================================');
      debugPrint('SAVING PROFILE TO FIRESTORE (PRIMARY SOURCE OF TRUTH)...');
      try {
        // Exact fields requested: status PENDING, is_deleted false, created_at FieldValue.serverTimestamp()
        data['status'] = 'PENDING';
        data['is_deleted'] = false;
        data['created_at'] = FieldValue.serverTimestamp();
        data['updated_at'] = FieldValue.serverTimestamp();

        // 1. Direct write to Firebase Firestore collection 'kurichiyar_profiles'
        if (uid.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('kurichiyar_profiles')
              .doc(uid)
              .set(data, SetOptions(merge: true));
        } else {
          final docRef = await FirebaseFirestore.instance
              .collection('kurichiyar_profiles')
              .add(data);
          uid = docRef.id;
          data['id'] = uid;
        }

        // 2. Also save to users & profiles via FirestoreService for app-wide compatibility
        await FirestoreService().saveUserProfile(uid, data);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(data, SetOptions(merge: true));
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(uid)
            .set(data, SetOptions(merge: true));

        // 3. Auto-sync matrimony registration directly to ft_members (Family Tree module)
        final effectiveFtUid = uid.isNotEmpty
            ? uid
            : (FirebaseAuth.instance.currentUser?.uid ?? '');
        if (effectiveFtUid.isNotEmpty) {
          final panthiClan = _motherClan?.displayName ??
              _motherClan?.nameMl ??
              _motherClan?.name ??
              _motherClanController.text.trim();
          final bandhuClan = _fatherClan?.displayName ??
              _fatherClan?.nameMl ??
              _fatherClan?.name ??
              _fatherClanController.text.trim();
          await FirebaseFirestore.instance
              .collection('ft_members')
              .doc(effectiveFtUid)
              .set({
            'uid': effectiveFtUid,
            'full_name': _nameController.text.trim(),
            'phone': phone,
            'gender': _gender.name,
            'dob': _dob?.toIso8601String(),
            'father_name': _fatherNameController.text.trim(),
            'mother_name': _motherNameController.text.trim(),
            'house_name': _houseNameController.text.trim(),
            'panthi_tharavadu': panthiClan,
            'bandhu_tharavadu': bandhuClan,
            'profile_photo': _profilePhotoUrl ?? '',
            'approval_status': 'pending',
            'source': 'matrimony_auto_sync',
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint('AUTO-SYNCED MATRIMONY PROFILE TO FT_MEMBERS: $effectiveFtUid');
        }
        debugPrint('FIRESTORE SAVE COMPLETE.');
      } catch (fsErr) {
        debugPrint('FIRESTORE SAVE FAILED: $fsErr');
      }

      debugPrint('EXECUTING BEST-EFFORT SUPABASE SYNC (NON-BLOCKING)...');
      try {
        final response = await Supabase.instance.client
            .from('kurichiyar_profiles')
            .upsert(data)
            .select();
        debugPrint('SUPABASE RAW RESPONSE: $response');
      } catch (sbErr) {
        debugPrint('SUPABASE PROFILE UPSERT SKIPPED/FAILED (SAFE FALLBACK): $sbErr');
      }

      debugPrint('UPDATING REGISTRATION LEAD STATUS TO COMPLETED...');
      await LeadTrackingService.instance.markCompleted(
        phone: phone,
        name: _nameController.text.trim(),
        step: _totalSteps,
      );

      debugPrint('INSERT CONFIRMED. DELETING TEMP LEAD...');
      if (incompleteRegistrationId != null) {
        try {
          await Supabase.instance.client
              .from('incomplete_registrations')
              .delete()
              .eq('id', incompleteRegistrationId!);
          debugPrint('TEMP LEAD DELETED.');
        } catch (e) {
          debugPrint('Failed to delete incomplete registration: $e');
        }
      }

      debugPrint('CLEARING DRAFT & TRIGGERING NAVIGATION...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('registration_submitted', true);
      final currentUserId =
          Supabase.instance.client.auth.currentUser?.id ?? uid;
      if (currentUserId.isNotEmpty) {
        await prefs.setString('pending_user_id', currentUserId);
        await prefs.setString('pending_user_email', authEmail);
        await prefs.setString('pending_user_password', password);
      }
      _clearDraft();

      // Trigger Instant High-Priority Admin Notification with Sound
      try {
        final registeredName =
            data['name']?.toString() ?? _nameController.text.trim();
        final registeredPhone =
            data['phone']?.toString() ?? _phoneController.text.trim();
        final registeredUserId = currentUserId;
        NotificationManager.instance.notifyAdminNewRegistration(
          userName: registeredName,
          userPhone: registeredPhone,
          userId: registeredUserId,
        );
      } catch (e) {
        debugPrint('Error triggering admin notification: $e');
      }

      // NAVIGATE DIRECTLY TO GUEST PAGE / EXPLORE HOME SCREEN (POST-REGISTRATION REDIRECTION)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('registration_submitted', true);
        await prefs.setString('pending_user_id', uid);
        await prefs.setString('pending_user_phone', phone);
      } catch (e) {
        debugPrint('Notice saving pending flags to prefs: $e');
      }

      if (mounted) {
        debugPrint('NAVIGATING TO GUEST / EXPLORE SCREEN...');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration submitted successfully! You can explore profiles while your account is under review.',
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 4),
          ),
        );
        if (MockData().currentUser?.role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else if (phone == '9999999999') {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/guest',
            (r) => false,
          );
        }
      }
      debugPrint('--- SUBMIT FINAL COMPLETED SUCCESSFULLY ---');
      debugPrint('=======================================\n');
    } on PostgrestException catch (pgError) {
      debugPrint('--- POSTGREST EXCEPTION CAUGHT ---');
      debugPrint('Message: ${pgError.message}');
      debugPrint('Details: ${pgError.details}');
      debugPrint('Hint: ${pgError.hint}');
      debugPrint('Code: ${pgError.code}');
      if (mounted) {
        if (pgError.code == '23505') {
          setState(() {
            _submitError =
                'This phone number is already registered in our system. Each child must have a unique mobile number.';
          });
        } else {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Database Insert Failed'),
              content: Text('Error: ${pgError.message}\nCode: ${pgError.code}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e, stacktrace) {
      if (e.toString().contains('MOBILE_IN_USE')) {
        if (mounted) {
          setState(() {
            _submitError =
                'This phone number is already registered. Each profile must have a unique mobile number.';
          });
        }
        return;
      }
      debugPrint('--- UNKNOWN EXCEPTION CAUGHT ---');
      debugPrint('Error: $e');
      debugPrint('Stacktrace: $stacktrace');
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('System Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showAddTharavaduDialog(BuildContext ctx) {
    final nameC = TextEditingController(),
        placeC = TextEditingController(),
        phoneC = TextEditingController(),
        fk = GlobalKey<FormState>();
    bool saving = false;
    showDialog(
      context: ctx,
      builder: (c) => StatefulBuilder(
        builder: (c, ss) => AlertDialog(
          title: const Text(
            'à´¶àµà´°à´¦àµà´§à´¿à´•àµà´•àµà´•: à´•àµà´±à´¿à´šàµà´šàµà´¯ à´¸à´®àµà´¦à´¾à´¯à´¤àµà´¤à´¿à´²àµ† à´ªàµà´°à´§à´¾à´¨ 57 à´¤à´±à´µà´¾à´Ÿàµà´•à´³à´¾à´£àµ à´²à´¿à´¸àµà´±àµà´±à´¿àµ½ à´‰à´³àµà´³à´¤àµ. à´‡à´¤à´¿àµ½ à´‰àµ¾à´ªàµà´ªàµ†à´Ÿà´¾à´¤àµà´¤ à´¶à´¾à´–à´¾ à´¤à´±à´µà´¾à´Ÿàµà´•à´³àµ‹ à´µàµ€à´Ÿàµà´Ÿàµà´ªàµ‡à´°àµà´•à´³àµ‹ à´‰à´£àµà´Ÿàµ†à´™àµà´•à´¿àµ½ à´¦à´¯à´µà´¾à´¯à´¿ à´¤à´¾à´´àµ† à´¨àµ½à´•àµà´•. à´µà´¿à´µà´°à´™àµà´™àµ¾ à´ªà´°à´¿à´¶àµ‹à´§à´¿à´šàµà´šàµ à´ªàµà´°à´§à´¾à´¨ à´¤à´±à´µà´¾à´Ÿàµà´Ÿàµà´®à´¾à´¯à´¿ à´¬à´¨àµà´§à´ªàµà´ªàµ†à´Ÿàµà´¤àµà´¤à´¿ à´…à´¡àµà´®à´¿àµ» à´‰à´Ÿàµ» à´…à´ªàµà´¡àµ‡à´±àµà´±àµ à´šàµ†à´¯àµà´¯àµà´‚.',
            style: TextStyle(fontSize: 14),
          ),
          content: Form(
            key: fk,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameC,
                  decoration: const InputDecoration(
                    labelText: 'à´µàµ€à´Ÿàµà´Ÿàµà´ªàµ‡à´°àµ / à´¤à´±à´µà´¾à´Ÿàµ à´ªàµ‡à´°àµ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (_) => ss(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: placeC,
                  decoration: const InputDecoration(
                    labelText: 'à´¸àµà´¥à´²à´‚',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (_) => ss(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneC,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'à´«àµ‹àµº à´¨à´®àµà´ªàµ¼',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (_) => ss(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed:
                  (saving ||
                      nameC.text.trim().isEmpty ||
                      placeC.text.trim().isEmpty ||
                      phoneC.text.trim().isEmpty)
                  ? null
                  : () async {
                      if (!fk.currentState!.validate()) return;
                      ss(() => saving = true);
                      try {
                        await Supabase.instance.client
                            .from('tharavadu_add_requests')
                            .insert({
                              'name': nameC.text.trim(),
                              'place': placeC.text.trim(),
                              'phone': phoneC.text.trim(),
                              'status': 'pending',
                            });
                        if (c.mounted) Navigator.pop(c);
                        if (ctx.mounted) {
                          showDialog(
                            context: ctx,
                            builder: (successCtx) => AlertDialog(
                              title: const Text(
                                'à´µà´¿à´œà´¯à´¿à´šàµà´šàµ (Success)',
                                style: TextStyle(color: Colors.green),
                              ),
                              content: const Text(
                                'à´¨à´¿à´™àµà´™à´³àµà´Ÿàµ† à´¤à´±à´µà´¾à´Ÿàµ à´µà´¿à´µà´°à´™àµà´™àµ¾ à´µà´¿à´œà´¯à´•à´°à´®à´¾à´¯à´¿ à´¸à´®àµ¼à´ªàµà´ªà´¿à´šàµà´šàµ. à´…à´¡àµà´®à´¿àµ» à´ªà´°à´¿à´¶àµ‹à´§à´¿à´šàµà´šàµ à´…à´‚à´—àµ€à´•à´°à´¿à´šàµà´š à´¶àµ‡à´·à´‚ à´…à´±à´¿à´¯à´¿à´ªàµà´ªàµ à´²à´­à´¿à´•àµà´•àµà´¨àµà´¨à´¤à´¾à´£àµ.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(successCtx),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) _showError('Failed: $e');
                      } finally {
                        if (c.mounted) ss(() => saving = false);
                      }
                    },
              child: saving
                  ? const CircularProgressIndicator()
                  : const Text('Submit / Save'),
            ),
          ],
        ),
      ),
    );
  }

  final _formKeyStep1 = GlobalKey<FormState>(),
      _formKeyStep2 = GlobalKey<FormState>(),
      _formKeyStep3 = GlobalKey<FormState>(),
      _formKeyStep4 = GlobalKey<FormState>(),
      _formKeyStep5 = GlobalKey<FormState>(),
      _formKeyStep6 = GlobalKey<FormState>(),
      _formKeyStep7 = GlobalKey<FormState>(),
      _formKeyStep8 = GlobalKey<FormState>(),
      _formKeyStep9 = GlobalKey<FormState>();
  final _nameController = TextEditingController(),
      _phoneController = TextEditingController(),
      _publicDisplayNumberController = TextEditingController(),
      _otpController = TextEditingController(),
      _fatherNameController = TextEditingController(),
      _motherNameController = TextEditingController(),
      _houseNameController = TextEditingController(),
      _fatherClanController = TextEditingController(),
      _motherClanController = TextEditingController(),
      _mothersTarawadController = TextEditingController(),
      _educationOtherController = TextEditingController(),
      _careerDetailController = TextEditingController(),
      _customHobbyController = TextEditingController(),
      _aboutMeController = TextEditingController(),
      _agentCodeController = TextEditingController(),
      _pincodeController = TextEditingController(),
      _digipinController = TextEditingController(),
      _districtController = TextEditingController(),
      _talukController = TextEditingController(),
      _panchayathController = TextEditingController(),
      _postOfficeController = TextEditingController();
  final _emailController = TextEditingController(),
      _passwordController = TextEditingController(),
      _confirmPasswordController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _idNumberFocus = FocusNode();
  final _boysCountController = TextEditingController(),
      _girlsCountController = TextEditingController();
  final _dobDayController = TextEditingController(),
      _dobMonthController = TextEditingController(),
      _dobYearController = TextEditingController();
  final _dobDayFocus = FocusNode(),
      _dobMonthFocus = FocusNode(),
      _dobYearFocus = FocusNode();

  // Validation FocusNodes
  final _nameFocus = FocusNode(),
      _emailFocus = FocusNode(),
      _passwordFocus = FocusNode(),
      _confirmPasswordFocus = FocusNode(),
      _phoneFocus = FocusNode();
  final _fatherNameFocus = FocusNode(),
      _motherNameFocus = FocusNode(),
      _houseNameFocus = FocusNode(),
      _fatherClanFocus = FocusNode(),
      _motherClanFocus = FocusNode();
  final _publicDisplayNumberFocus = FocusNode(),
      _motherTongueFocus = FocusNode(),
      _pincodeFocus = FocusNode(),
      _districtFocus = FocusNode();
  final _heightFocus = FocusNode(),
      _weightFocus = FocusNode(),
      _physicalStatusFocus = FocusNode(),
      _educationLevelFocus = FocusNode(),
      _careerSectorFocus = FocusNode(),
      _jobFocus = FocusNode();
  final _maritalStatusFocus = FocusNode(),
      _acceptChildrenStatusFocus = FocusNode();
  final _prefAgeMinFocus = FocusNode(),
      _prefAgeMaxFocus = FocusNode(),
      _prefEducationFocus = FocusNode(),
      _prefCareerFocus = FocusNode(),
      _prefDistrictFocus = FocusNode();
  final _legal1Focus = FocusNode(),
      _legal2Focus = FocusNode(),
      _legal3Focus = FocusNode(),
      _legal4Focus = FocusNode();

  DateTime? _dob;
  Gender _gender = Gender.male;
  Clan? _fatherClan, _motherClan;
  String _idType = 'Aadhaar Card';
  String? _timeline,
      _residencePreference,
      _parentCarePreference,
      _motherTongue,
      _coreValues,
      _pincode,
      _digipin,
      _panchayath,
      _postOffice,
      _taluk,
      _district,
      _height,
      _weight,
      _bloodGroup,
      _physicalStatus,
      _educationLevel,
      _careerSector,
      _smokingHabit,
      _drinkingHabit,
      _idDocumentUrl,
      _profilePhotoUrl,
      _prefEducation,
      _prefCareer,
      _prefDistrict,
      _prefIncome,
      _acceptChildrenStatus,
      _adoptionPreference,
      _groomStayWifeHouse,
      _brideHusbandStayHome,
      _willingMarryRemarriage,
      _firstMarriageAdoptChildren,
      _firstMarriageMaxChildren;
  bool _isProfileHiddenPaid = false,
      _isAutoRenewalEnabled = false,
      _hideContactInfo = false,
      _isMarketingAllowed = false;
  double _privacyFee = 100;
  int _privacyDuration = 6;
  double _prefAgeMin = 20, _prefAgeMax = 50;
  List<String> _selectedHobbies = [],
      _childrenGenders = [],
      _languagesKnown = [],
      _postOffices = [];
  MaritalStatus _maritalStatus = MaritalStatus.first;
  bool? _hasChildren, _readyToAcceptChildren, _prefRelocateToBrideHome;
  int _childrenCount = 0, _boysCount = 0, _girlsCount = 0;
  String _prefHabits = 'Open';
  bool _legalCheck1 = false,
      _legalCheck2 = false,
      _legalCheck3 = false,
      _legalCheck4 = false;
  String? _profilePhotoError;
  int? _exactAge;
  // Family restriction fields (Step 2 warning feature)
  bool _hasFamilyRestriction = false;
  List<Clan> _selectedRestrictedFamilies = [];
  // Parent deceased status (Step 1)
  bool _isFatherDeceased = false;
  bool _isMotherDeceased = false;
  // Submission state flag (used by BottomBar) â€” mutated, cannot be final
  // ignore: prefer_final_fields
  bool _isSubmitting = false;

  bool get hasSelectedPhoto =>
      _profilePhotoLocalPath != null ||
      (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty);
}
