// ignore_for_file: library_private_types_in_public_api, deprecated_member_use
import 'dart:convert';
import 'dart:io';
import '../../core/services/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../clan_feed/tharavadu_list.dart';
import '../../core/utils/mock_data.dart';
import '../../core/services/image_validation_service.dart';
import '../../core/services/pincode_service.dart';
import '../../core/services/notification_manager.dart';
import '../../core/services/lead_tracking_service.dart';

import '../../core/utils/global_error_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firebase_firestore_service.dart';

import 'widgets/step1_basic_info.dart';
import 'widgets/step2_personal_details.dart';
import 'widgets/step3_religion_caste.dart';
import 'widgets/step4_career_habits.dart';
import 'widgets/step5_marital_history.dart';
import 'widgets/step6_partner_preferences.dart';

import '../../core/services/registration_route_helper.dart';

part 'registration_state_mixin.dart';
part 'widgets/step7_document_verification.dart';
part 'widgets/step8_media_security.dart';
part 'widgets/step9_final.dart';
part 'widgets/bottom_bar.dart';

class RegistrationWizard extends StatefulWidget {
  final int? initialStep;
  final bool isPreviewMode;
  const RegistrationWizard({
    super.key,
    this.initialStep,
    this.isPreviewMode = false,
  });

  @override
  State<RegistrationWizard> createState() => _RegistrationWizardState();
}

class _RegistrationWizardState extends State<RegistrationWizard>
    with WidgetsBindingObserver, RegistrationStateMixin<RegistrationWizard> {
  @override
  void initState() {
    super.initState();
    if (!widget.isPreviewMode) {
      RegistrationRouteHelper.isUserRegisteredOrPending().then((isRegistered) {
        if (isRegistered && mounted) {
          Navigator.pushReplacementNamed(context, '/verification_pending');
        }
      });
    }
  }

  Widget _buildStepWidget(int index) {
    switch (index) {
      case 0:
        return Step1BasicInfo(
          formKey: _formKeyStep1,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          nameController: _nameController,
          phoneController: _phoneController,
          publicDisplayNumberController: _publicDisplayNumberController,
          otpController: _otpController,
          fatherNameController: _fatherNameController,
          motherNameController: _motherNameController,
          dobDayController: _dobDayController,
          dobMonthController: _dobMonthController,
          dobYearController: _dobYearController,
          dobDayFocus: _dobDayFocus,
          dobMonthFocus: _dobMonthFocus,
          dobYearFocus: _dobYearFocus,
          gender: _gender,
          exactAge: _exactAge,
          isPhoneVerified: _isPhoneVerified,
          isSendingOtp: _isSendingOtp,
          simCarrier: _simCarrier,
          isFatherDeceased: _isFatherDeceased,
          isMotherDeceased: _isMotherDeceased,
          onFatherDeceasedChanged: (v) =>
              updateState(() => _isFatherDeceased = v),
          onMotherDeceasedChanged: (v) =>
              updateState(() => _isMotherDeceased = v),
          onGenderChanged: (v) => updateState(() => _gender = v),
          onLeadCapture: (id) => incompleteRegistrationId = id,
          onSimCarrierChanged: (c) => updateState(() => _simCarrier = c),
          onPhoneVerifiedChanged: (v) =>
              updateState(() => _isPhoneVerified = v),
          onSendingOtpChanged: (v) => updateState(() => _isSendingOtp = v),

          onEnterManualPhone: () => updateState(() => _simCarrier = 'Manual'),
          onCalculateAge: _calculateAge,
          buildCard: _buildCard,
        );
      case 1:
        return Step2PersonalDetails(
          formKey: _formKeyStep2,
          houseNameController: _houseNameController,
          fatherClanController: _fatherClanController,
          motherClanController: _motherClanController,
          fatherClan: _fatherClan,
          motherClan: _motherClan,
          loadingClans: _loadingClans,
          clans: _clans,
          onRefreshClans: _refreshClans,
          onAddTharavadu: () => _showAddTharavaduDialog(context),
          onFatherClanChanged: (v) => updateState(() {
            _fatherClan = v;
            updateRestrictedFamilies();
          }),
          onMotherClanChanged: (v) => updateState(() {
            _motherClan = v;
            if (v != null) {
              _mothersTarawadController.text = v.name;
            } else {
              _mothersTarawadController.text = '';
            }
            updateRestrictedFamilies();
          }),
          height: _height,
          weight: _weight,
          bloodGroup: _bloodGroup,
          physicalStatus: _physicalStatus,
          educationLevel: _educationLevel,
          educationOtherController: _educationOtherController,
          onHeightChanged: (v) => updateState(() => _height = v),
          onWeightChanged: (v) => updateState(() => _weight = v),
          onBloodGroupChanged: (v) => updateState(() => _bloodGroup = v),
          onPhysicalStatusChanged: (v) =>
              updateState(() => _physicalStatus = v),
          onEducationLevelChanged: (v) =>
              updateState(() => _educationLevel = v),
          hasFamilyRestriction: _hasFamilyRestriction,
          mothersTarawadController: _mothersTarawadController,
          selectedRestrictedFamilies: _selectedRestrictedFamilies,
          onFamilyRestrictionChanged: (v) => updateState(() {
            _hasFamilyRestriction = v ?? false;
            if (!_hasFamilyRestriction) {
              _selectedRestrictedFamilies.clear();
            }
          }),
          onRestrictedFamiliesChanged: (v) =>
              updateState(() => _selectedRestrictedFamilies = v),
          config: registrationFieldConfig,
          buildCard: _buildCard,
          step2Keys: step2Keys,
        );
      case 2:
        return Step3ReligionCaste(
          formKey: _formKeyStep3,
          buildCard: _buildCard,
          gender: _gender,
          motherTongue: _motherTongue,
          languagesKnown: _languagesKnown,
          coreValues: _coreValues,
          digipinController: _digipinController,
          pincodeController: _pincodeController,
          districtController: _districtController,
          talukController: _talukController,
          panchayathController: _panchayathController,
          postOfficeController: _postOfficeController,
          aboutMeController: _aboutMeController,
          postOffices: _postOffices,
          postOffice: _postOffice,
          taluk: _taluk,
          district: _district,
          panchayath: _panchayath,
          groomStayWifeHouse: _groomStayWifeHouse,
          brideHusbandStayHome: _brideHusbandStayHome,
          onMotherTongueChanged: (v) => updateState(() => _motherTongue = v),
          onLanguagesKnownChanged: (v) =>
              updateState(() => _languagesKnown = v),
          onCoreValuesChanged: (v) => updateState(() => _coreValues = v),
          onDigipinChanged: (v) => updateState(() {
            _digipin = v.trim().toUpperCase();
            _digipinController.text = _digipin!;
          }),
          onPincodeChanged: (v) async {
            final pin = v.trim();
            // Sync on every keystroke
            updateState(() {
              _pincode = pin;
            });
            if (pin.length == 6) {
              final locs = await PincodeService.fetchLocation(pin);
              if (locs.isNotEmpty) {
                final firstLoc = locs.first;
                final dist = firstLoc.district;
                final tlk = firstLoc.taluk;
                final panch = firstLoc.panchayath.isNotEmpty ? firstLoc.panchayath : tlk;
                final poList = locs
                    .map((l) => l.postOffice)
                    .where((p) => p.isNotEmpty)
                    .toList();
                final po = poList.isNotEmpty ? poList.first : firstLoc.postOffice;
                updateState(() {
                  _district = dist;
                  _taluk = tlk;
                  _panchayath = panch;
                  _postOffices = poList;
                  _postOffice = po;

                  _districtController.text = dist;
                  _talukController.text = tlk;
                  _panchayathController.text = panch;
                  _postOfficeController.text = po;
                });
              }
            }
          },
          onPostOfficeChanged: (v) => updateState(() {
            _postOffice = v;
            if (v != null) _postOfficeController.text = v;
          }),
          onDistrictChanged: (v) => updateState(() {
            _district = v;
            _districtController.text = v;
          }),
          onTalukChanged: (v) => updateState(() {
            _taluk = v;
            _talukController.text = v;
          }),
          onPanchayathChanged: (v) => updateState(() {
            _panchayath = v;
            _panchayathController.text = v;
          }),
          onGroomStayChanged: (v) => updateState(() => _groomStayWifeHouse = v),
          onBrideStayChanged: (v) =>
              updateState(() => _brideHusbandStayHome = v),
        );
      case 3:
        return Step4CareerHabits(
          formKey: _formKeyStep4,
          gender: _gender,
          careerSector: _careerSector,
          careerDetailController: _careerDetailController,
          smokingHabit: _smokingHabit,
          drinkingHabit: _drinkingHabit,
          selectedHobbies: _selectedHobbies,
          customHobbyController: _customHobbyController,
          onCareerSectorChanged: (v) => updateState(() {
            _careerSector = v;
            if (v != 'Business' && v != 'Others') {
              _careerDetailController.clear();
            }
          }),
          onSmokingHabitChanged: (v) => updateState(() => _smokingHabit = v),
          onDrinkingHabitChanged: (v) => updateState(() => _drinkingHabit = v),
          onHobbyToggled: (hobby) => updateState(() {
            if (_selectedHobbies.contains(hobby)) {
              _selectedHobbies.remove(hobby);
            } else {
              _selectedHobbies.add(hobby);
            }
          }),
          onCustomHobbyChanged: () =>
              updateState(() {}), // just to trigger UI if needed
          config: registrationFieldConfig,
          buildCard: _buildCard,
        );
      case 4:
        return Step5MaritalHistory(
          formKey: _formKeyStep5,
          maritalStatus: _maritalStatus,
          hasChildren: _hasChildren,
          childrenCount: _childrenCount,
          boysCountController: _boysCountController,
          isMarketingAllowed: _isMarketingAllowed,
          onMarketingAllowedChanged: (v) => updateState(() {
            _isMarketingAllowed = v;
          }),
          onMaritalStatusChanged: (v) => updateState(() {
            _maritalStatus = v;
            if (v == MaritalStatus.first) _hasChildren = null;
          }),
          onChildrenCountUpdated: () => updateState(_updateChildrenDetails),
          girlsCountController: _girlsCountController,
          onHasChildrenChanged: (v) => updateState(() {
            _hasChildren = v;
            if (v == false) {
              _boysCountController.clear();
              _girlsCountController.clear();
            }
          }),
          timeline: _timeline,
          readyToAcceptChildren: _readyToAcceptChildren,
          acceptChildrenStatus: _acceptChildrenStatus,
          adoptionPreference: _adoptionPreference,
          willingMarryRemarriage: _willingMarryRemarriage,
          firstMarriageAdoptChildren: _firstMarriageAdoptChildren,
          firstMarriageMaxChildren: _firstMarriageMaxChildren,
          onTimelineChanged: (v) => updateState(() => _timeline = v),
          onReadyToAcceptChildrenChanged: (v) =>
              updateState(() => _readyToAcceptChildren = v),
          onAcceptChildrenStatusChanged: (v) =>
              updateState(() => _acceptChildrenStatus = v),
          onAdoptionPreferenceChanged: (v) =>
              updateState(() => _adoptionPreference = v),
          onWillingMarryRemarriageChanged: (v) =>
              updateState(() => _willingMarryRemarriage = v),
          onFirstMarriageAdoptChildrenChanged: (v) =>
              updateState(() => _firstMarriageAdoptChildren = v),
          onFirstMarriageMaxChildrenChanged: (v) =>
              updateState(() => _firstMarriageMaxChildren = v),
          buildCard: _buildCard,
        );
      case 5:
        return Step6PartnerPreferences(
          formKey: _formKeyStep6,
          prefAgeMin: _prefAgeMin,
          prefAgeMax: _prefAgeMax,
          prefEducation: _prefEducation,
          prefCareer: _prefCareer,
          prefDistrict: _prefDistrict,
          prefIncome: _prefIncome,
          prefHabits: _prefHabits,
          prefRelocateToBrideHome: _prefRelocateToBrideHome,
          residencePreference: _residencePreference,
          parentCarePreference: _parentCarePreference,
          onAgeRangeChanged: (r) => updateState(() {
            _prefAgeMin = r.start;
            _prefAgeMax = r.end;
          }),
          onPrefEducationChanged: (v) => updateState(() => _prefEducation = v),
          onPrefCareerChanged: (v) => updateState(() => _prefCareer = v),
          onPrefDistrictChanged: (v) => updateState(() => _prefDistrict = v),
          onPrefIncomeChanged: (v) => updateState(() => _prefIncome = v),
          onPrefHabitsChanged: (v) =>
              updateState(() => _prefHabits = v ?? 'Doesn\'t Matter'),
          onPrefRelocateToBrideHomeChanged: (v) =>
              updateState(() => _prefRelocateToBrideHome = v),
          onResidencePreferenceChanged: (v) =>
              updateState(() => _residencePreference = v),
          onParentCarePreferenceChanged: (v) =>
              updateState(() => _parentCarePreference = v),
          config: registrationFieldConfig,
          buildCard: _buildCard,
        );
      case 6:
        return Step7DocumentVerification(this);
      case 7:
        return Step8MediaSecurity(this);
      case 8:
        return Step9Final(this);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: widget.isPreviewMode
          ? null
          : AppBar(
              title: Text(AppLocalizations.of(context)!.createProfile),
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: _showSupportMenu,
                  tooltip: 'Help / Support',
                ),
              ],
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_buildStepWidget(_currentStep)],
          ),
        ),
      ),
      bottomNavigationBar: !widget.isPreviewMode ? BottomBar(this) : null,
    );
  }

  // Minimal card wrapper used by steps
  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Padding(padding: const EdgeInsets.all(24.0), child: child),
          Positioned(
            bottom: 8,
            right: 8,
            child: Text(
              'Page Code: P-10${_currentStep + 1}',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingLocalizer {
  static String translate(BuildContext context, String value) {
    final locale = Localizations.localeOf(context).languageCode;

    // Normal / Fit
    if (value == 'Normal / Fit') {
      if (locale == 'ml') return 'സാധാരണ നിലയിൽ';
      if (locale == 'hi') return 'सामान्य / फिट';
      return 'Normal / Fit';
    }
    if (value == 'Differently Abled') {
      if (locale == 'ml') return 'ശാരീരിക വെല്ലുവിളികൾ നേരിടുന്നവർ';
      if (locale == 'hi') return 'दिव्यांग';
      return 'Differently Abled';
    }

    // Education levels
    if (value == 'High School') {
      if (locale == 'ml') return 'ഹൈസ്കൂൾ';
      if (locale == 'hi') return 'हाई स्कूल';
      return 'High School';
    }
    if (value == 'Diploma') {
      if (locale == 'ml') return 'ഡിപ്ലോമ';
      if (locale == 'hi') return 'डिप्लोमा';
      return 'Diploma';
    }
    if (value == 'Bachelors') {
      if (locale == 'ml') return 'ബിരുദം (Bachelors)';
      if (locale == 'hi') return 'स्नातक';
      return 'Bachelors';
    }
    if (value == 'Masters') {
      if (locale == 'ml') return 'ബിരുദാനന്തര ബിരുദം (Masters)';
      if (locale == 'hi') return 'स्नातकोत्तर';
      return 'Masters';
    }
    if (value == 'Doctorate') {
      if (locale == 'ml') return 'പിഎച്ച്ഡി/ഡാക്ടറേറ്റ്';
      if (locale == 'hi') return 'डॉक्टरेट';
      return 'Doctorate';
    }
    if (value == 'Others') {
      if (locale == 'ml') return 'മറ്റുള്ളവ';
      if (locale == 'hi') return 'अन्य';
      return 'Others';
    }

    // Career sectors
    if (value == 'Government') {
      if (locale == 'ml') return 'സർക്കാർ ജോലി';
      if (locale == 'hi') return 'सरकारी नौकरी';
      return 'Government';
    }
    if (value == 'Private') {
      if (locale == 'ml') return 'സ്വകാര്യ മേഖല';
      if (locale == 'hi') return 'निजी क्षेत्र';
      return 'Private';
    }
    if (value == 'Self-Employed / Business') {
      if (locale == 'ml') return 'സ്വയം തൊഴിൽ / ബിസിനസ്സ്';
      if (locale == 'hi') return 'स्व-रोजगार / व्यवसाय';
      return 'Self-Employed / Business';
    }
    if (value == 'Professional (Doctor/Engineer/etc.)') {
      if (locale == 'ml') return 'പ്രൊഫഷണൽ (ഡോക്ടർ/എഞ്ചിനീയർ)';
      if (locale == 'hi') return 'पेशेवर (डॉक्टर/इंजीनियर)';
      return 'Professional (Doctor/Engineer/etc.)';
    }
    if (value == 'Agriculture') {
      if (locale == 'ml') return 'കൃഷി';
      if (locale == 'hi') return 'कृषि';
      return 'Agriculture';
    }
    if (value == 'Home Maker') {
      if (locale == 'ml') return 'ഗൃഹനാഥ/ഗൃഹനാഥൻ';
      if (locale == 'hi') return 'गृहणी / गृहस्थ';
      return 'Home Maker';
    }
    if (value == 'Unemployed') {
      if (locale == 'ml') return 'തൊഴിൽരഹിതൻ/തൊഴിൽരഹിത';
      if (locale == 'hi') return 'बेरोजगार';
      return 'Unemployed';
    }

    // Income
    if (value == 'Under 1 Lakh') {
      if (locale == 'ml') return '1 ലക്ഷത്തിന് താഴെ';
      if (locale == 'hi') return '1 लाख से कम';
      return 'Under 1 Lakh';
    }
    if (value == '1 - 3 Lakhs') {
      if (locale == 'ml') return '1 - 3 ലക്ഷം';
      if (locale == 'hi') return '1 - 3 लाख';
      return '1 - 3 Lakhs';
    }
    if (value == '3 - 5 Lakhs') {
      if (locale == 'ml') return '3 - 5 ലക്ഷം';
      if (locale == 'hi') return '3 - 5 लाख';
      return '3 - 5 Lakhs';
    }
    if (value == '5 - 10 Lakhs') {
      if (locale == 'ml') return '5 - 10 ലക്ഷം';
      if (locale == 'hi') return '5 - 10 लाख';
      return '5 - 10 Lakhs';
    }
    if (value == '10 Lakhs+') {
      if (locale == 'ml') return '10 ലക്ഷത്തിന് മുകളിൽ';
      if (locale == 'hi') return '10 लाख+';
      return '10 Lakhs+';
    }

    // Habits
    if (value == 'None') {
      if (locale == 'ml') return 'ഒന്നുമില്ല';
      if (locale == 'hi') return 'कोई नहीं';
      return 'None';
    }
    if (value == 'Smoking') {
      if (locale == 'ml') return 'പുകവലി';
      if (locale == 'hi') return 'धूम्रपान';
      return 'Smoking';
    }
    if (value == 'Drinking') {
      if (locale == 'ml') return 'മദ്യപാനം';
      if (locale == 'hi') return 'शराब पीना';
      return 'Drinking';
    }
    if (value == 'Both') {
      if (locale == 'ml') return 'രണ്ടും';
      if (locale == 'hi') return 'दोनों';
      return 'Both';
    }

    // General Preferences / Options
    if (value == 'YES_WILLING') {
      if (locale == 'ml') return 'അതെ, സമ്മതമാണ്';
      if (locale == 'hi') return 'हाँ, तैयार हूँ';
      return 'Yes, Willing';
    }
    if (value == 'NO_UNWILLING') {
      if (locale == 'ml') return 'അല്ല, സമ്മതമല്ല';
      if (locale == 'hi') return 'नहीं, तैयार नहीं हूँ';
      return 'No, Unwilling';
    }
    if (value == 'OPEN_TO_DISCUSS') {
      if (locale == 'ml') return 'ചർച്ച ചെയ്യാൻ തയ്യാറാണ്';
      if (locale == 'hi') return 'चर्चा के लिए तैयार';
      return 'Open to discuss';
    }

    return value;
  }
}
