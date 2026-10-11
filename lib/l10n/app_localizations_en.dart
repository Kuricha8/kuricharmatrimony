// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get step1BasicInfo => 'Step 1: Basic Info';

  @override
  String get fullName => 'Full Name';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get guardianRelativePhone => 'Guardian/Relative Phone Number';

  @override
  String get requiredField => 'Required';

  @override
  String get verifyViaWhatsapp => 'Verify via WhatsApp';

  @override
  String get personalPhoneNumber => 'Personal Phone Number';

  @override
  String get dob => 'DOB';

  @override
  String get genderMaleFemale => 'Gender (Male / Female)';

  @override
  String get step2LineageHousehold => 'Step 2: Lineage & Household';

  @override
  String get fathersName => 'Father\'s Name';

  @override
  String get mothersName => 'Mother\'s Name';

  @override
  String get houseNameCurrentResidence => 'House Name (Current Residence)';

  @override
  String get fathersClanTharavadu => 'Father\'s Clan / Tharavadu';

  @override
  String get mothersClanTharavadu => 'Mother\'s Clan / Tharavadu';

  @override
  String get step3PhysicalEducation => 'Step 3: Physical & Education';

  @override
  String get heightInCm => 'Height (in cm)';

  @override
  String get weightInKg => 'Weight (in kg)';

  @override
  String get physicalCondition => 'Physical Condition';

  @override
  String get highestEducation => 'Highest Education';

  @override
  String get step4CareerHabits => 'Step 4: Career & Habits';

  @override
  String get careerSector => 'Career Sector';

  @override
  String get specifyJobDetails => 'Specify Job Details';

  @override
  String get annualIncome => 'Annual Income';

  @override
  String get habitsSmokingDrinking => 'Habits (Smoking / Drinking)';

  @override
  String get step5MaritalHistory => 'Step 5: Marital History';

  @override
  String get maritalStatus => 'Marital Status';

  @override
  String get step6PartnerPreferences => 'Step 6: Partner Preferences';

  @override
  String get preferredAgeRange => 'Preferred Age Range';

  @override
  String get expectedEducation => 'Expected Education';

  @override
  String get preferredJobCareerSector => 'Preferred Job / Career Sector';

  @override
  String get minimumExpectedAnnualIncome => 'Minimum Expected Annual Income';

  @override
  String get habitsCompliance => 'Habits Compliance';

  @override
  String get residentialPlacementAgreement => 'Residential Placement Agreement';

  @override
  String get step7IdentityVerification => 'Step 7: Identity Verification';

  @override
  String get step8MediaSecurityAboutMe => 'Step 8: Media, Security & About Me';

  @override
  String get tapToUploadPrimaryPhoto => 'Tap to upload primary photo';

  @override
  String get aboutMe => 'About Me';

  @override
  String get setPassword => 'Set Password';

  @override
  String get step9FinalAgentVerification => 'Step 9: Final Agent Verification';

  @override
  String get agentReferenceCodeOptional => 'Agent Reference Code (Optional)';

  @override
  String get nextContinue => 'Next / Continue';

  @override
  String stepXOf9(int step) {
    return 'Step $step of 9';
  }

  @override
  String get pincodeLabel => 'PIN Code';

  @override
  String get postOfficeLabel => 'Post Office / Area';

  @override
  String get talukLabel => 'Taluk / Sub-District';

  @override
  String get districtLabel => 'District';

  @override
  String get stateLabel => 'State';

  @override
  String get termsAndConditionsMl =>
      'ഈ ആപ്ലിക്കേഷന്റെ നിബന്ധനകളും വ്യവസ്ഥകളും ഞാൻ അംഗീകരിക്കുന്നു';

  @override
  String get termsAndConditionsEn =>
      'I agree to the Terms & Conditions of this application.';

  @override
  String get termsAndConditions =>
      'I agree to the Terms & Conditions of this application.';

  @override
  String get bloodGroup => 'Blood Group';

  @override
  String get smoking => 'Smoking';

  @override
  String get drinking => 'Drinking';

  @override
  String get marriageTimeline => 'Marriage Timeline';

  @override
  String get any => 'Any';

  @override
  String get allTharavadus => 'All Tharavadus';

  @override
  String get yourTharavadu => 'Your Tharavadu';

  @override
  String get partnerTharavadu => 'Partner\'s Tharavadu';

  @override
  String get publicPhoneNumber => 'Public Phone Number (Optional)';

  @override
  String get illamNikkalQuestion =>
      'After marriage, do you have any objection if the husband comes and stays at your house?';

  @override
  String get groomStayWifeHouseQuestion =>
      'After marriage, are you willing to stay at the wife\'s house and take care of her parents?';

  @override
  String get yesWilling => 'Yes';

  @override
  String get notWilling => 'No';

  @override
  String get depends => 'Depends';

  @override
  String get noObjection => 'No Objection';

  @override
  String get hasObjection => 'Has Objection';

  @override
  String get willingMarryRemarriageQuestion =>
      'Are you willing to consider marriage proposals from individuals seeking a second marriage?';

  @override
  String get acceptChildrenQuestion =>
      'Are you willing to accept and take responsibility for their children from the previous marriage?';

  @override
  String get maxChildrenAcceptQuestion =>
      'If yes, how many children are you willing to accept?';

  @override
  String get child1 => '1 Child';

  @override
  String get children2 => '2 Children';

  @override
  String get moreThan2 => 'More than 2';

  @override
  String get noLimit => 'No Limit';

  @override
  String paidPrivacyPrompt(String amount, int months) {
    return 'Pay $amount INR to hide profile for $months months?';
  }

  @override
  String get privacySubtext =>
      'Only people you send a request to can view your profile.';

  @override
  String autoRenewalPrompt(int months) {
    return 'Do you want to enable auto-renewal after $months months?';
  }

  @override
  String get confirmLikeTitle => 'Are you sure?';

  @override
  String get confirmLikeMessage => 'Do you want to send a request?';

  @override
  String get habitOpenAny => 'Open / Any';

  @override
  String get noHabitsOnly => 'No Habits Only';

  @override
  String get thalperyamundu => 'Yes';

  @override
  String get thalperyamilla => 'No';

  @override
  String get adoptionInterestQuestion =>
      'Are you interested in child adoption?';

  @override
  String get upTo1Child => 'Up to 1 Child';

  @override
  String get upTo2Children => 'Up to 2 Children';

  @override
  String get anyNumber => 'Any Number';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get verify => 'Verify';

  @override
  String get phoneVerified => 'Phone Verified';

  @override
  String get otpHint => 'Enter 6-Digit OTP';

  @override
  String get selectDob => 'Select Date of Birth (20+ Only)';

  @override
  String get stepTitleBasicInfo => 'Step 1: Basic Info';

  @override
  String get stepTitleLineage => 'Step 2: Lineage & Household';

  @override
  String get stepTitlePhysical => 'Step 3: Physical & Education';

  @override
  String get stepTitleCareer => 'Step 4: Career & Habits';

  @override
  String get stepTitleMarital => 'Step 5: Marital History';

  @override
  String get stepTitlePreferences => 'Step 6: Partner Preferences';

  @override
  String get stepTitleIdentity => 'Step 7: Identity Verification';

  @override
  String get stepTitleMedia => 'Step 8: Media, Security & About Me';

  @override
  String get stepTitleFinal => 'Step 9: Final Agent Verification';

  @override
  String get kudumbaVriksham => 'Kudumba Vriksham';

  @override
  String get vamshavali => 'Vamshavali';

  @override
  String get eventsTitle => 'Events';

  @override
  String get upcomingEvents => 'Upcoming';

  @override
  String
  get uploadAValidGovernmentIdAadhaarVoterIdToVerifyYourIdentityThisIsStrictlyKeptSecureAndOnlyVisibleToAuthorizedAgents =>
      'Upload a valid Government ID (Aadhaar/Voter ID) to verify your identity. This is strictly kept secure and only visible to authorized Agents.';

  @override
  String get openToAdopt => 'Open to adopt';

  @override
  String get preferredCareerSector => 'Preferred Career Sector';

  @override
  String get accountRejected => 'ACCOUNT REJECTED';

  @override
  String get parentCarePreference => 'Parent Care Preference';

  @override
  String get b => 'B-';

  @override
  String get submitVerification => 'Submit Verification';

  @override
  String get occasionally => 'Occasionally';

  @override
  String
  get weAreSorryButYourProfileHasBeenRejectedByTheAdministratorPleaseContactSupportIfYouBelieveThisIsAMistake =>
      'We are sorry, but your profile has been rejected by the administrator. Please contact support if you believe this is a mistake.';

  @override
  String get independentHouseNuclearFamily =>
      'Independent House/Nuclear family';

  @override
  String get aboutMeBio => 'About Me / Bio';

  @override
  String get privateJob => 'Private Job';

  @override
  String get preferredDistrict => 'Preferred District';

  @override
  String get preparingForPscCompetitiveExams =>
      'Preparing for PSC / Competitive Exams';

  @override
  String get preferredHabitsSmokingDrinking =>
      'Preferred Habits (Smoking/Drinking)';

  @override
  String get onlyShowYourContactDetailsToProfilesYouHaveMutuallyMatchedWith =>
      'Only show your contact details to profiles you have mutually matched with.';

  @override
  String get diploma => 'Diploma';

  @override
  String get open => 'Open';

  @override
  String get farming => 'Farming';

  @override
  String get regularly => 'Regularly';

  @override
  String get enterAValid6DigitPinToLoadAreaPostOffice =>
      'Enter a valid 6-digit PIN to load Area/Post Office';

  @override
  String get others => 'Others';

  @override
  String get b2 => 'B+';

  @override
  String get heightCm => 'Height (cm)';

  @override
  String get openToAdoptingChildren => 'Open to Adopting Children?';

  @override
  String get normalFit => 'Normal / Fit';

  @override
  String get firstMarriage => 'First Marriage';

  @override
  String get areaPostOffice => 'Area / Post Office';

  @override
  String get emailIsRequired => 'Email is required';

  @override
  String get below2Lakhs => 'Below 2 Lakhs';

  @override
  String get never => 'Never';

  @override
  String get notWorking => 'Not Working';

  @override
  String get maybe => 'Maybe';

  @override
  String get businessSelfEmployed => 'Business/Self Employed';

  @override
  String get bachelorSDegree => 'Bachelor\'s Degree';

  @override
  String get livingWithParents => 'Living with parents';

  @override
  String get differentlyAbled => 'Differently Abled';

  @override
  String get sports => 'Sports';

  @override
  String get accountStatus => 'Account Status';

  @override
  String get kozhikode => 'Kozhikode';

  @override
  String get homeMaker => 'Home Maker';

  @override
  String get o => 'O+';

  @override
  String get uploadIdDocument => 'Upload ID Document';

  @override
  String get highSchool => 'High School';

  @override
  String get physicalEducationAttributes => 'Physical & Education Attributes';

  @override
  String get partnerPreferences => 'Partner Preferences';

  @override
  String get ab => 'AB+';

  @override
  String get hideContactInformation => 'Hide Contact Information';

  @override
  String get remarriage2nd => 'Remarriage (2nd)';

  @override
  String get totalChildren => 'Total Children';

  @override
  String get maxChildrenToAdopt => 'Max Children to Adopt';

  @override
  String get boysCount => 'Boys Count';

  @override
  String get o2 => 'O-';

  @override
  String get notOpenToAdopt => 'Not open to adopt';

  @override
  String get pleaseSelectWhetherYouHaveChildren =>
      'Please select whether you have children';

  @override
  String get notDecided => 'Not decided';

  @override
  String get within6Months => 'Within 6 months';

  @override
  String get kannur => 'Kannur';

  @override
  String get specifyEducation => 'Specify Education';

  @override
  String get willSupportThemFinancially => 'Will support them financially';

  @override
  String get areYouInterestedInReceivingPromotionalMarketingMessages =>
      'Are you interested in receiving promotional marketing messages?';

  @override
  String get loadingTharavaduList => 'Loading Tharavadu list...';

  @override
  String get agricultureFarming => 'Agriculture / Farming';

  @override
  String get enter12DigitIdentityNumber => 'Enter 12-Digit Identity Number';

  @override
  String get doctorate => 'Doctorate';

  @override
  String get willLiveWithMyParents => 'Will live with my parents';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get educationLevel => 'Education Level';

  @override
  String get malappuram => 'Malappuram';

  @override
  String get addMissingTharavadu => 'Add Missing Tharavadu';

  @override
  String get within1Year => 'Within 1 year';

  @override
  String get preferIndependentLiving => 'PREFER INDEPENDENT LIVING';

  @override
  String get back => 'Back';

  @override
  String get noChildrenHistoryRequiredForFirstMarriage =>
      'No children history required for First Marriage.';

  @override
  String get travelling => 'Travelling';

  @override
  String get notApplicable => 'Not applicable';

  @override
  String get preferredEducation => 'Preferred Education';

  @override
  String
  get ifYouAreGuidedByALocalAgentEnterTheirReferenceCodeBelowProfilesWithAnAgentCodeAreProcessedFasterThroughTheLocalAgentDashboard =>
      'If you are guided by a local Agent, enter their Reference Code below. Profiles with an Agent Code are processed faster through the local Agent Dashboard.';

  @override
  String get physicalStatus => 'Physical Status';

  @override
  String get girlsCount => 'Girls Count';

  @override
  String get reading => 'Reading';

  @override
  String get openToRemarriage => 'Open to Remarriage?';

  @override
  String get acceptChildrenStatus => 'Accept Children Status';

  @override
  String get livingPreferences => 'Living Preferences';

  @override
  String get unemployed => 'Unemployed';

  @override
  String get governmentJob => 'Government Job';

  @override
  String get business => 'Business';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get above10Lakhs => 'Above 10 Lakhs';

  @override
  String get privateSector => 'Private Sector';

  @override
  String get a => 'A+';

  @override
  String get uploading => 'Uploading...';

  @override
  String get preferredIncome => 'Preferred Income';

  @override
  String get notDecided2 => 'Not Decided';

  @override
  String get goBack => 'Go Back';

  @override
  String get governmentPublicSector => 'Government/Public Sector';

  @override
  String get willTakeCareOfBothSides => 'Will take care of both sides';

  @override
  String get adoptionPreference => 'Adoption Preference';

  @override
  String get a2 => 'A-';

  @override
  String get other => 'Other';

  @override
  String get smartLocation => 'Smart Location';

  @override
  String get livingWithMe => 'Living with me';

  @override
  String get enterValid6DigitPin => 'Enter valid 6-digit PIN';

  @override
  String get remarriage3rd => 'Remarriage (3rd+)';

  @override
  String get scanUserQrCodeToFinalize => 'Scan User QR Code to Finalize';

  @override
  String get hideProfilePaid => 'Hide Profile (Paid)';

  @override
  String get music => 'Music';

  @override
  String get livingWithPartner => 'Living with partner';

  @override
  String get doesnTMatter => 'Doesn\'t Matter';

  @override
  String get strictlyNo => 'Strictly No';

  @override
  String get occasionallyAcceptable => 'Occasionally Acceptable';

  @override
  String get promotionalConsent => 'Promotional Consent';

  @override
  String get documentUploaded => 'Document Uploaded';

  @override
  String get wayanad => 'Wayanad';

  @override
  String get doYouHaveChildrenMandatory => 'Do you have children? (Mandatory)';

  @override
  String get nextStep => 'Next Step';

  @override
  String get readyToAcceptChildren => 'Ready to Accept Children?';

  @override
  String get cooking => 'Cooking';

  @override
  String get residencePreference => 'Residence Preference';

  @override
  String get immediately => 'Immediately';

  @override
  String get ab2 => 'AB-';

  @override
  String get enterAValidEmailAddress => 'Enter a valid email address';

  @override
  String get password => 'Password';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'Password must be at least 6 characters';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordIsRequired => 'Confirm Password is required';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get step1Instruction =>
      'Create your account by entering your email and password.';

  @override
  String get step2Instruction =>
      'Please provide your personal and physical details.';

  @override
  String get step3Instruction =>
      'Please provide your current location details and living preferences below.';

  @override
  String get step4Instruction =>
      'Please verify your government ID for security.';

  @override
  String get step5Instruction => 'Please enter your marital history.';

  @override
  String get step6Instruction => 'Enter your preferences for your partner.';

  @override
  String get step7Instruction =>
      'Upload your main photo. Face detection is active.';

  @override
  String get step8Instruction => 'Provide your family background details.';

  @override
  String get step9Instruction => 'Add a short bio and select privacy settings.';

  @override
  String get fee => 'Fee';

  @override
  String get postMarriagePreferences => 'Post-Marriage Preferences';

  @override
  String get willingToRelocateToBridesHome =>
      'Willing to Relocate to Bride\'s Home?';

  @override
  String get yesHave => 'Yes';

  @override
  String get noHave => 'No';

  @override
  String get willingToStayAtWifesHouse => 'Residence Preference';

  @override
  String get residencePreferenceHelperText =>
      'Considering families with only daughters, choose this if you are willing to permanently stay at and support the bride\'s house after marriage.';

  @override
  String get residencePrefWifeHouse => 'Interested (Stay at Bride\'s House)';

  @override
  String get residencePrefOwnHouse => 'Stay at Own House';

  @override
  String get residencePrefFlexible => 'Flexible (Decide Based on Situation)';

  @override
  String get yesOption => 'YES';

  @override
  String get noOption => 'NO';

  @override
  String get dependsOption => 'DEPENDS';

  @override
  String get backBtn => 'Back';

  @override
  String get nextStepBtn => 'Next Step';

  @override
  String get masterSDegree => 'Master\'s Degree';

  @override
  String get autoFetchSim => 'Auto-fetch Verified SIM Number';

  @override
  String get autoFetchFailsManual =>
      'If auto-fetch fails or is denied, you may enter manually.';

  @override
  String get selectSimForRegistration => 'Select SIM for Registration';

  @override
  String get noSimCardsDetected =>
      'No SIM cards detected or permission denied.';

  @override
  String get unknownCarrier => 'Unknown Carrier';

  @override
  String get unknownNumber => 'Unknown Number';

  @override
  String get phoneNumberNotStored =>
      'Phone number not stored on this SIM. Please enter manually.';

  @override
  String get enterMobileNumberManually => 'Enter Mobile Number Manually';

  @override
  String get simBindingSuccessful =>
      'SIM Binding Successful! Phone number verified via system.';

  @override
  String get bindingSimCard => 'Binding SIM Card...';

  @override
  String get incomingCall => 'Incoming Call...';

  @override
  String get calling => 'Calling...';

  @override
  String get activeCall => 'Active Call';

  @override
  String get callEnded => 'Call Ended';

  @override
  String get callRejected => 'Call Rejected';

  @override
  String get unknownCaller => 'Unknown Caller';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get muteAudio => 'Mute';

  @override
  String get unmuteAudio => 'Unmute';

  @override
  String get speakerphone => 'Speaker';

  @override
  String get endCall => 'End Call';

  @override
  String get close => 'Close';

  @override
  String get bmiLabel => 'BMI';

  @override
  String get bmiUnderweight => 'Underweight';

  @override
  String get bmiNormal => 'Normal Weight';

  @override
  String get bmiOverweight => 'Overweight';

  @override
  String get bmiObese => 'Obese';

  @override
  String get home => 'Home';

  @override
  String get matches => 'Matches';

  @override
  String get chat => 'Chat';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get familyTree => 'Family Tree';

  @override
  String get moietyChecker => 'Moiety Checker';

  @override
  String get clanFeed => 'Clan Feed';

  @override
  String get tharavadu => 'Tharavadu';

  @override
  String get matchDesk => 'Match Desk';

  @override
  String get myStatus => 'My Status';

  @override
  String get statuses => 'Statuses';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get apply => 'Apply';

  @override
  String get uploadPhoto => 'Upload Photo';

  @override
  String get viewStatus => 'View Status';

  @override
  String get replyPrivately => 'Reply Privately';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search by name or tharavadu...';

  @override
  String get filter => 'Filter';

  @override
  String get send => 'Send';

  @override
  String get share => 'Share';

  @override
  String get submit => 'Submit';

  @override
  String get logout => 'Logout';

  @override
  String get confirm => 'Confirm';

  @override
  String get add => 'Add';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get viewMore => 'View More';

  @override
  String get viewDetails => 'View Details';

  @override
  String get noActiveStatuses => 'No Active Statuses';

  @override
  String get loading => 'Loading...';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get verificationPending => 'Verification Pending';

  @override
  String get noMatchesFound => 'No matches found';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get emptyList => 'List is empty';

  @override
  String get statusListEmpty => 'No active statuses found';

  @override
  String get noUpdates => 'No updates';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get gender => 'Gender';

  @override
  String get age => 'Age';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get tharavaduName => 'Tharavadu Name';

  @override
  String get selectLanguage => 'App Language';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get accountPrivacy => 'Account Privacy';

  @override
  String get security => 'Security';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get version => 'Version';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get viewFullProfile => 'View Full Profile';

  @override
  String get memberCount => 'Member Count';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noInternetConnection => 'No Internet Connection';
}
