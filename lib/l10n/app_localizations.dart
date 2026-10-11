import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ml.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ml'),
  ];

  /// No description provided for @step1BasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Basic Info'**
  String get step1BasicInfo;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfile;

  /// No description provided for @guardianRelativePhone.
  ///
  /// In en, this message translates to:
  /// **'Guardian/Relative Phone Number'**
  String get guardianRelativePhone;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @verifyViaWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Verify via WhatsApp'**
  String get verifyViaWhatsapp;

  /// No description provided for @personalPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Personal Phone Number'**
  String get personalPhoneNumber;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'DOB'**
  String get dob;

  /// No description provided for @genderMaleFemale.
  ///
  /// In en, this message translates to:
  /// **'Gender (Male / Female)'**
  String get genderMaleFemale;

  /// No description provided for @step2LineageHousehold.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Lineage & Household'**
  String get step2LineageHousehold;

  /// No description provided for @fathersName.
  ///
  /// In en, this message translates to:
  /// **'Father\'s Name'**
  String get fathersName;

  /// No description provided for @mothersName.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s Name'**
  String get mothersName;

  /// No description provided for @houseNameCurrentResidence.
  ///
  /// In en, this message translates to:
  /// **'House Name (Current Residence)'**
  String get houseNameCurrentResidence;

  /// No description provided for @fathersClanTharavadu.
  ///
  /// In en, this message translates to:
  /// **'Father\'s Clan / Tharavadu'**
  String get fathersClanTharavadu;

  /// No description provided for @mothersClanTharavadu.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s Clan / Tharavadu'**
  String get mothersClanTharavadu;

  /// No description provided for @step3PhysicalEducation.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Physical & Education'**
  String get step3PhysicalEducation;

  /// No description provided for @heightInCm.
  ///
  /// In en, this message translates to:
  /// **'Height (in cm)'**
  String get heightInCm;

  /// No description provided for @weightInKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (in kg)'**
  String get weightInKg;

  /// No description provided for @physicalCondition.
  ///
  /// In en, this message translates to:
  /// **'Physical Condition'**
  String get physicalCondition;

  /// No description provided for @highestEducation.
  ///
  /// In en, this message translates to:
  /// **'Highest Education'**
  String get highestEducation;

  /// No description provided for @step4CareerHabits.
  ///
  /// In en, this message translates to:
  /// **'Step 4: Career & Habits'**
  String get step4CareerHabits;

  /// No description provided for @careerSector.
  ///
  /// In en, this message translates to:
  /// **'Career Sector'**
  String get careerSector;

  /// No description provided for @specifyJobDetails.
  ///
  /// In en, this message translates to:
  /// **'Specify Job Details'**
  String get specifyJobDetails;

  /// No description provided for @annualIncome.
  ///
  /// In en, this message translates to:
  /// **'Annual Income'**
  String get annualIncome;

  /// No description provided for @habitsSmokingDrinking.
  ///
  /// In en, this message translates to:
  /// **'Habits (Smoking / Drinking)'**
  String get habitsSmokingDrinking;

  /// No description provided for @step5MaritalHistory.
  ///
  /// In en, this message translates to:
  /// **'Step 5: Marital History'**
  String get step5MaritalHistory;

  /// No description provided for @maritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital Status'**
  String get maritalStatus;

  /// No description provided for @step6PartnerPreferences.
  ///
  /// In en, this message translates to:
  /// **'Step 6: Partner Preferences'**
  String get step6PartnerPreferences;

  /// No description provided for @preferredAgeRange.
  ///
  /// In en, this message translates to:
  /// **'Preferred Age Range'**
  String get preferredAgeRange;

  /// No description provided for @expectedEducation.
  ///
  /// In en, this message translates to:
  /// **'Expected Education'**
  String get expectedEducation;

  /// No description provided for @preferredJobCareerSector.
  ///
  /// In en, this message translates to:
  /// **'Preferred Job / Career Sector'**
  String get preferredJobCareerSector;

  /// No description provided for @minimumExpectedAnnualIncome.
  ///
  /// In en, this message translates to:
  /// **'Minimum Expected Annual Income'**
  String get minimumExpectedAnnualIncome;

  /// No description provided for @habitsCompliance.
  ///
  /// In en, this message translates to:
  /// **'Habits Compliance'**
  String get habitsCompliance;

  /// No description provided for @residentialPlacementAgreement.
  ///
  /// In en, this message translates to:
  /// **'Residential Placement Agreement'**
  String get residentialPlacementAgreement;

  /// No description provided for @step7IdentityVerification.
  ///
  /// In en, this message translates to:
  /// **'Step 7: Identity Verification'**
  String get step7IdentityVerification;

  /// No description provided for @step8MediaSecurityAboutMe.
  ///
  /// In en, this message translates to:
  /// **'Step 8: Media, Security & About Me'**
  String get step8MediaSecurityAboutMe;

  /// No description provided for @tapToUploadPrimaryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload primary photo'**
  String get tapToUploadPrimaryPhoto;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMe;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get setPassword;

  /// No description provided for @step9FinalAgentVerification.
  ///
  /// In en, this message translates to:
  /// **'Step 9: Final Agent Verification'**
  String get step9FinalAgentVerification;

  /// No description provided for @agentReferenceCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Agent Reference Code (Optional)'**
  String get agentReferenceCodeOptional;

  /// No description provided for @nextContinue.
  ///
  /// In en, this message translates to:
  /// **'Next / Continue'**
  String get nextContinue;

  /// No description provided for @stepXOf9.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 9'**
  String stepXOf9(int step);

  /// No description provided for @pincodeLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get pincodeLabel;

  /// No description provided for @postOfficeLabel.
  ///
  /// In en, this message translates to:
  /// **'Post Office / Area'**
  String get postOfficeLabel;

  /// No description provided for @talukLabel.
  ///
  /// In en, this message translates to:
  /// **'Taluk / Sub-District'**
  String get talukLabel;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateLabel;

  /// No description provided for @termsAndConditionsMl.
  ///
  /// In en, this message translates to:
  /// **'ഈ ആപ്ലിക്കേഷന്റെ നിബന്ധനകളും വ്യവസ്ഥകളും ഞാൻ അംഗീകരിക്കുന്നു'**
  String get termsAndConditionsMl;

  /// No description provided for @termsAndConditionsEn.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions of this application.'**
  String get termsAndConditionsEn;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions of this application.'**
  String get termsAndConditions;

  /// No description provided for @bloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get bloodGroup;

  /// No description provided for @smoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get smoking;

  /// No description provided for @drinking.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get drinking;

  /// No description provided for @marriageTimeline.
  ///
  /// In en, this message translates to:
  /// **'Marriage Timeline'**
  String get marriageTimeline;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @allTharavadus.
  ///
  /// In en, this message translates to:
  /// **'All Tharavadus'**
  String get allTharavadus;

  /// No description provided for @yourTharavadu.
  ///
  /// In en, this message translates to:
  /// **'Your Tharavadu'**
  String get yourTharavadu;

  /// No description provided for @partnerTharavadu.
  ///
  /// In en, this message translates to:
  /// **'Partner\'s Tharavadu'**
  String get partnerTharavadu;

  /// No description provided for @publicPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Public Phone Number (Optional)'**
  String get publicPhoneNumber;

  /// No description provided for @illamNikkalQuestion.
  ///
  /// In en, this message translates to:
  /// **'After marriage, do you have any objection if the husband comes and stays at your house?'**
  String get illamNikkalQuestion;

  /// No description provided for @groomStayWifeHouseQuestion.
  ///
  /// In en, this message translates to:
  /// **'After marriage, are you willing to stay at the wife\'s house and take care of her parents?'**
  String get groomStayWifeHouseQuestion;

  /// No description provided for @yesWilling.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesWilling;

  /// No description provided for @notWilling.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get notWilling;

  /// No description provided for @depends.
  ///
  /// In en, this message translates to:
  /// **'Depends'**
  String get depends;

  /// No description provided for @noObjection.
  ///
  /// In en, this message translates to:
  /// **'No Objection'**
  String get noObjection;

  /// No description provided for @hasObjection.
  ///
  /// In en, this message translates to:
  /// **'Has Objection'**
  String get hasObjection;

  /// No description provided for @willingMarryRemarriageQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you willing to consider marriage proposals from individuals seeking a second marriage?'**
  String get willingMarryRemarriageQuestion;

  /// No description provided for @acceptChildrenQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you willing to accept and take responsibility for their children from the previous marriage?'**
  String get acceptChildrenQuestion;

  /// No description provided for @maxChildrenAcceptQuestion.
  ///
  /// In en, this message translates to:
  /// **'If yes, how many children are you willing to accept?'**
  String get maxChildrenAcceptQuestion;

  /// No description provided for @child1.
  ///
  /// In en, this message translates to:
  /// **'1 Child'**
  String get child1;

  /// No description provided for @children2.
  ///
  /// In en, this message translates to:
  /// **'2 Children'**
  String get children2;

  /// No description provided for @moreThan2.
  ///
  /// In en, this message translates to:
  /// **'More than 2'**
  String get moreThan2;

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No Limit'**
  String get noLimit;

  /// No description provided for @paidPrivacyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} INR to hide profile for {months} months?'**
  String paidPrivacyPrompt(String amount, int months);

  /// No description provided for @privacySubtext.
  ///
  /// In en, this message translates to:
  /// **'Only people you send a request to can view your profile.'**
  String get privacySubtext;

  /// No description provided for @autoRenewalPrompt.
  ///
  /// In en, this message translates to:
  /// **'Do you want to enable auto-renewal after {months} months?'**
  String autoRenewalPrompt(int months);

  /// No description provided for @confirmLikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get confirmLikeTitle;

  /// No description provided for @confirmLikeMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to send a request?'**
  String get confirmLikeMessage;

  /// No description provided for @habitOpenAny.
  ///
  /// In en, this message translates to:
  /// **'Open / Any'**
  String get habitOpenAny;

  /// No description provided for @noHabitsOnly.
  ///
  /// In en, this message translates to:
  /// **'No Habits Only'**
  String get noHabitsOnly;

  /// No description provided for @thalperyamundu.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get thalperyamundu;

  /// No description provided for @thalperyamilla.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get thalperyamilla;

  /// No description provided for @adoptionInterestQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you interested in child adoption?'**
  String get adoptionInterestQuestion;

  /// No description provided for @upTo1Child.
  ///
  /// In en, this message translates to:
  /// **'Up to 1 Child'**
  String get upTo1Child;

  /// No description provided for @upTo2Children.
  ///
  /// In en, this message translates to:
  /// **'Up to 2 Children'**
  String get upTo2Children;

  /// No description provided for @anyNumber.
  ///
  /// In en, this message translates to:
  /// **'Any Number'**
  String get anyNumber;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone Verified'**
  String get phoneVerified;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-Digit OTP'**
  String get otpHint;

  /// No description provided for @selectDob.
  ///
  /// In en, this message translates to:
  /// **'Select Date of Birth (20+ Only)'**
  String get selectDob;

  /// No description provided for @stepTitleBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Basic Info'**
  String get stepTitleBasicInfo;

  /// No description provided for @stepTitleLineage.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Lineage & Household'**
  String get stepTitleLineage;

  /// No description provided for @stepTitlePhysical.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Physical & Education'**
  String get stepTitlePhysical;

  /// No description provided for @stepTitleCareer.
  ///
  /// In en, this message translates to:
  /// **'Step 4: Career & Habits'**
  String get stepTitleCareer;

  /// No description provided for @stepTitleMarital.
  ///
  /// In en, this message translates to:
  /// **'Step 5: Marital History'**
  String get stepTitleMarital;

  /// No description provided for @stepTitlePreferences.
  ///
  /// In en, this message translates to:
  /// **'Step 6: Partner Preferences'**
  String get stepTitlePreferences;

  /// No description provided for @stepTitleIdentity.
  ///
  /// In en, this message translates to:
  /// **'Step 7: Identity Verification'**
  String get stepTitleIdentity;

  /// No description provided for @stepTitleMedia.
  ///
  /// In en, this message translates to:
  /// **'Step 8: Media, Security & About Me'**
  String get stepTitleMedia;

  /// No description provided for @stepTitleFinal.
  ///
  /// In en, this message translates to:
  /// **'Step 9: Final Agent Verification'**
  String get stepTitleFinal;

  /// No description provided for @kudumbaVriksham.
  ///
  /// In en, this message translates to:
  /// **'Kudumba Vriksham'**
  String get kudumbaVriksham;

  /// No description provided for @vamshavali.
  ///
  /// In en, this message translates to:
  /// **'Vamshavali'**
  String get vamshavali;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingEvents;

  /// No description provided for @uploadAValidGovernmentIdAadhaarVoterIdToVerifyYourIdentityThisIsStrictlyKeptSecureAndOnlyVisibleToAuthorizedAgents.
  ///
  /// In en, this message translates to:
  /// **'Upload a valid Government ID (Aadhaar/Voter ID) to verify your identity. This is strictly kept secure and only visible to authorized Agents.'**
  String
  get uploadAValidGovernmentIdAadhaarVoterIdToVerifyYourIdentityThisIsStrictlyKeptSecureAndOnlyVisibleToAuthorizedAgents;

  /// No description provided for @openToAdopt.
  ///
  /// In en, this message translates to:
  /// **'Open to adopt'**
  String get openToAdopt;

  /// No description provided for @preferredCareerSector.
  ///
  /// In en, this message translates to:
  /// **'Preferred Career Sector'**
  String get preferredCareerSector;

  /// No description provided for @accountRejected.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT REJECTED'**
  String get accountRejected;

  /// No description provided for @parentCarePreference.
  ///
  /// In en, this message translates to:
  /// **'Parent Care Preference'**
  String get parentCarePreference;

  /// No description provided for @b.
  ///
  /// In en, this message translates to:
  /// **'B-'**
  String get b;

  /// No description provided for @submitVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit Verification'**
  String get submitVerification;

  /// No description provided for @occasionally.
  ///
  /// In en, this message translates to:
  /// **'Occasionally'**
  String get occasionally;

  /// No description provided for @weAreSorryButYourProfileHasBeenRejectedByTheAdministratorPleaseContactSupportIfYouBelieveThisIsAMistake.
  ///
  /// In en, this message translates to:
  /// **'We are sorry, but your profile has been rejected by the administrator. Please contact support if you believe this is a mistake.'**
  String
  get weAreSorryButYourProfileHasBeenRejectedByTheAdministratorPleaseContactSupportIfYouBelieveThisIsAMistake;

  /// No description provided for @independentHouseNuclearFamily.
  ///
  /// In en, this message translates to:
  /// **'Independent House/Nuclear family'**
  String get independentHouseNuclearFamily;

  /// No description provided for @aboutMeBio.
  ///
  /// In en, this message translates to:
  /// **'About Me / Bio'**
  String get aboutMeBio;

  /// No description provided for @privateJob.
  ///
  /// In en, this message translates to:
  /// **'Private Job'**
  String get privateJob;

  /// No description provided for @preferredDistrict.
  ///
  /// In en, this message translates to:
  /// **'Preferred District'**
  String get preferredDistrict;

  /// No description provided for @preparingForPscCompetitiveExams.
  ///
  /// In en, this message translates to:
  /// **'Preparing for PSC / Competitive Exams'**
  String get preparingForPscCompetitiveExams;

  /// No description provided for @preferredHabitsSmokingDrinking.
  ///
  /// In en, this message translates to:
  /// **'Preferred Habits (Smoking/Drinking)'**
  String get preferredHabitsSmokingDrinking;

  /// No description provided for @onlyShowYourContactDetailsToProfilesYouHaveMutuallyMatchedWith.
  ///
  /// In en, this message translates to:
  /// **'Only show your contact details to profiles you have mutually matched with.'**
  String get onlyShowYourContactDetailsToProfilesYouHaveMutuallyMatchedWith;

  /// No description provided for @diploma.
  ///
  /// In en, this message translates to:
  /// **'Diploma'**
  String get diploma;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @farming.
  ///
  /// In en, this message translates to:
  /// **'Farming'**
  String get farming;

  /// No description provided for @regularly.
  ///
  /// In en, this message translates to:
  /// **'Regularly'**
  String get regularly;

  /// No description provided for @enterAValid6DigitPinToLoadAreaPostOffice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit PIN to load Area/Post Office'**
  String get enterAValid6DigitPinToLoadAreaPostOffice;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @b2.
  ///
  /// In en, this message translates to:
  /// **'B+'**
  String get b2;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// No description provided for @openToAdoptingChildren.
  ///
  /// In en, this message translates to:
  /// **'Open to Adopting Children?'**
  String get openToAdoptingChildren;

  /// No description provided for @normalFit.
  ///
  /// In en, this message translates to:
  /// **'Normal / Fit'**
  String get normalFit;

  /// No description provided for @firstMarriage.
  ///
  /// In en, this message translates to:
  /// **'First Marriage'**
  String get firstMarriage;

  /// No description provided for @areaPostOffice.
  ///
  /// In en, this message translates to:
  /// **'Area / Post Office'**
  String get areaPostOffice;

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailIsRequired;

  /// No description provided for @below2Lakhs.
  ///
  /// In en, this message translates to:
  /// **'Below 2 Lakhs'**
  String get below2Lakhs;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @notWorking.
  ///
  /// In en, this message translates to:
  /// **'Not Working'**
  String get notWorking;

  /// No description provided for @maybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get maybe;

  /// No description provided for @businessSelfEmployed.
  ///
  /// In en, this message translates to:
  /// **'Business/Self Employed'**
  String get businessSelfEmployed;

  /// No description provided for @bachelorSDegree.
  ///
  /// In en, this message translates to:
  /// **'Bachelor\'s Degree'**
  String get bachelorSDegree;

  /// No description provided for @livingWithParents.
  ///
  /// In en, this message translates to:
  /// **'Living with parents'**
  String get livingWithParents;

  /// No description provided for @differentlyAbled.
  ///
  /// In en, this message translates to:
  /// **'Differently Abled'**
  String get differentlyAbled;

  /// No description provided for @sports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sports;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @kozhikode.
  ///
  /// In en, this message translates to:
  /// **'Kozhikode'**
  String get kozhikode;

  /// No description provided for @homeMaker.
  ///
  /// In en, this message translates to:
  /// **'Home Maker'**
  String get homeMaker;

  /// No description provided for @o.
  ///
  /// In en, this message translates to:
  /// **'O+'**
  String get o;

  /// No description provided for @uploadIdDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload ID Document'**
  String get uploadIdDocument;

  /// No description provided for @highSchool.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get highSchool;

  /// No description provided for @physicalEducationAttributes.
  ///
  /// In en, this message translates to:
  /// **'Physical & Education Attributes'**
  String get physicalEducationAttributes;

  /// No description provided for @partnerPreferences.
  ///
  /// In en, this message translates to:
  /// **'Partner Preferences'**
  String get partnerPreferences;

  /// No description provided for @ab.
  ///
  /// In en, this message translates to:
  /// **'AB+'**
  String get ab;

  /// No description provided for @hideContactInformation.
  ///
  /// In en, this message translates to:
  /// **'Hide Contact Information'**
  String get hideContactInformation;

  /// No description provided for @remarriage2nd.
  ///
  /// In en, this message translates to:
  /// **'Remarriage (2nd)'**
  String get remarriage2nd;

  /// No description provided for @totalChildren.
  ///
  /// In en, this message translates to:
  /// **'Total Children'**
  String get totalChildren;

  /// No description provided for @maxChildrenToAdopt.
  ///
  /// In en, this message translates to:
  /// **'Max Children to Adopt'**
  String get maxChildrenToAdopt;

  /// No description provided for @boysCount.
  ///
  /// In en, this message translates to:
  /// **'Boys Count'**
  String get boysCount;

  /// No description provided for @o2.
  ///
  /// In en, this message translates to:
  /// **'O-'**
  String get o2;

  /// No description provided for @notOpenToAdopt.
  ///
  /// In en, this message translates to:
  /// **'Not open to adopt'**
  String get notOpenToAdopt;

  /// No description provided for @pleaseSelectWhetherYouHaveChildren.
  ///
  /// In en, this message translates to:
  /// **'Please select whether you have children'**
  String get pleaseSelectWhetherYouHaveChildren;

  /// No description provided for @notDecided.
  ///
  /// In en, this message translates to:
  /// **'Not decided'**
  String get notDecided;

  /// No description provided for @within6Months.
  ///
  /// In en, this message translates to:
  /// **'Within 6 months'**
  String get within6Months;

  /// No description provided for @kannur.
  ///
  /// In en, this message translates to:
  /// **'Kannur'**
  String get kannur;

  /// No description provided for @specifyEducation.
  ///
  /// In en, this message translates to:
  /// **'Specify Education'**
  String get specifyEducation;

  /// No description provided for @willSupportThemFinancially.
  ///
  /// In en, this message translates to:
  /// **'Will support them financially'**
  String get willSupportThemFinancially;

  /// No description provided for @areYouInterestedInReceivingPromotionalMarketingMessages.
  ///
  /// In en, this message translates to:
  /// **'Are you interested in receiving promotional marketing messages?'**
  String get areYouInterestedInReceivingPromotionalMarketingMessages;

  /// No description provided for @loadingTharavaduList.
  ///
  /// In en, this message translates to:
  /// **'Loading Tharavadu list...'**
  String get loadingTharavaduList;

  /// No description provided for @agricultureFarming.
  ///
  /// In en, this message translates to:
  /// **'Agriculture / Farming'**
  String get agricultureFarming;

  /// No description provided for @enter12DigitIdentityNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter 12-Digit Identity Number'**
  String get enter12DigitIdentityNumber;

  /// No description provided for @doctorate.
  ///
  /// In en, this message translates to:
  /// **'Doctorate'**
  String get doctorate;

  /// No description provided for @willLiveWithMyParents.
  ///
  /// In en, this message translates to:
  /// **'Will live with my parents'**
  String get willLiveWithMyParents;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @educationLevel.
  ///
  /// In en, this message translates to:
  /// **'Education Level'**
  String get educationLevel;

  /// No description provided for @malappuram.
  ///
  /// In en, this message translates to:
  /// **'Malappuram'**
  String get malappuram;

  /// No description provided for @addMissingTharavadu.
  ///
  /// In en, this message translates to:
  /// **'Add Missing Tharavadu'**
  String get addMissingTharavadu;

  /// No description provided for @within1Year.
  ///
  /// In en, this message translates to:
  /// **'Within 1 year'**
  String get within1Year;

  /// No description provided for @preferIndependentLiving.
  ///
  /// In en, this message translates to:
  /// **'PREFER INDEPENDENT LIVING'**
  String get preferIndependentLiving;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @noChildrenHistoryRequiredForFirstMarriage.
  ///
  /// In en, this message translates to:
  /// **'No children history required for First Marriage.'**
  String get noChildrenHistoryRequiredForFirstMarriage;

  /// No description provided for @travelling.
  ///
  /// In en, this message translates to:
  /// **'Travelling'**
  String get travelling;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get notApplicable;

  /// No description provided for @preferredEducation.
  ///
  /// In en, this message translates to:
  /// **'Preferred Education'**
  String get preferredEducation;

  /// No description provided for @ifYouAreGuidedByALocalAgentEnterTheirReferenceCodeBelowProfilesWithAnAgentCodeAreProcessedFasterThroughTheLocalAgentDashboard.
  ///
  /// In en, this message translates to:
  /// **'If you are guided by a local Agent, enter their Reference Code below. Profiles with an Agent Code are processed faster through the local Agent Dashboard.'**
  String
  get ifYouAreGuidedByALocalAgentEnterTheirReferenceCodeBelowProfilesWithAnAgentCodeAreProcessedFasterThroughTheLocalAgentDashboard;

  /// No description provided for @physicalStatus.
  ///
  /// In en, this message translates to:
  /// **'Physical Status'**
  String get physicalStatus;

  /// No description provided for @girlsCount.
  ///
  /// In en, this message translates to:
  /// **'Girls Count'**
  String get girlsCount;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @openToRemarriage.
  ///
  /// In en, this message translates to:
  /// **'Open to Remarriage?'**
  String get openToRemarriage;

  /// No description provided for @acceptChildrenStatus.
  ///
  /// In en, this message translates to:
  /// **'Accept Children Status'**
  String get acceptChildrenStatus;

  /// No description provided for @livingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Living Preferences'**
  String get livingPreferences;

  /// No description provided for @unemployed.
  ///
  /// In en, this message translates to:
  /// **'Unemployed'**
  String get unemployed;

  /// No description provided for @governmentJob.
  ///
  /// In en, this message translates to:
  /// **'Government Job'**
  String get governmentJob;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @above10Lakhs.
  ///
  /// In en, this message translates to:
  /// **'Above 10 Lakhs'**
  String get above10Lakhs;

  /// No description provided for @privateSector.
  ///
  /// In en, this message translates to:
  /// **'Private Sector'**
  String get privateSector;

  /// No description provided for @a.
  ///
  /// In en, this message translates to:
  /// **'A+'**
  String get a;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @preferredIncome.
  ///
  /// In en, this message translates to:
  /// **'Preferred Income'**
  String get preferredIncome;

  /// No description provided for @notDecided2.
  ///
  /// In en, this message translates to:
  /// **'Not Decided'**
  String get notDecided2;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @governmentPublicSector.
  ///
  /// In en, this message translates to:
  /// **'Government/Public Sector'**
  String get governmentPublicSector;

  /// No description provided for @willTakeCareOfBothSides.
  ///
  /// In en, this message translates to:
  /// **'Will take care of both sides'**
  String get willTakeCareOfBothSides;

  /// No description provided for @adoptionPreference.
  ///
  /// In en, this message translates to:
  /// **'Adoption Preference'**
  String get adoptionPreference;

  /// No description provided for @a2.
  ///
  /// In en, this message translates to:
  /// **'A-'**
  String get a2;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @smartLocation.
  ///
  /// In en, this message translates to:
  /// **'Smart Location'**
  String get smartLocation;

  /// No description provided for @livingWithMe.
  ///
  /// In en, this message translates to:
  /// **'Living with me'**
  String get livingWithMe;

  /// No description provided for @enterValid6DigitPin.
  ///
  /// In en, this message translates to:
  /// **'Enter valid 6-digit PIN'**
  String get enterValid6DigitPin;

  /// No description provided for @remarriage3rd.
  ///
  /// In en, this message translates to:
  /// **'Remarriage (3rd+)'**
  String get remarriage3rd;

  /// No description provided for @scanUserQrCodeToFinalize.
  ///
  /// In en, this message translates to:
  /// **'Scan User QR Code to Finalize'**
  String get scanUserQrCodeToFinalize;

  /// No description provided for @hideProfilePaid.
  ///
  /// In en, this message translates to:
  /// **'Hide Profile (Paid)'**
  String get hideProfilePaid;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @livingWithPartner.
  ///
  /// In en, this message translates to:
  /// **'Living with partner'**
  String get livingWithPartner;

  /// No description provided for @doesnTMatter.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t Matter'**
  String get doesnTMatter;

  /// No description provided for @strictlyNo.
  ///
  /// In en, this message translates to:
  /// **'Strictly No'**
  String get strictlyNo;

  /// No description provided for @occasionallyAcceptable.
  ///
  /// In en, this message translates to:
  /// **'Occasionally Acceptable'**
  String get occasionallyAcceptable;

  /// No description provided for @promotionalConsent.
  ///
  /// In en, this message translates to:
  /// **'Promotional Consent'**
  String get promotionalConsent;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document Uploaded'**
  String get documentUploaded;

  /// No description provided for @wayanad.
  ///
  /// In en, this message translates to:
  /// **'Wayanad'**
  String get wayanad;

  /// No description provided for @doYouHaveChildrenMandatory.
  ///
  /// In en, this message translates to:
  /// **'Do you have children? (Mandatory)'**
  String get doYouHaveChildrenMandatory;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStep;

  /// No description provided for @readyToAcceptChildren.
  ///
  /// In en, this message translates to:
  /// **'Ready to Accept Children?'**
  String get readyToAcceptChildren;

  /// No description provided for @cooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get cooking;

  /// No description provided for @residencePreference.
  ///
  /// In en, this message translates to:
  /// **'Residence Preference'**
  String get residencePreference;

  /// No description provided for @immediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get immediately;

  /// No description provided for @ab2.
  ///
  /// In en, this message translates to:
  /// **'AB-'**
  String get ab2;

  /// No description provided for @enterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterAValidEmailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordMustBeAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6Characters;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password is required'**
  String get confirmPasswordIsRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @step1Instruction.
  ///
  /// In en, this message translates to:
  /// **'Create your account by entering your email and password.'**
  String get step1Instruction;

  /// No description provided for @step2Instruction.
  ///
  /// In en, this message translates to:
  /// **'Please provide your personal and physical details.'**
  String get step2Instruction;

  /// No description provided for @step3Instruction.
  ///
  /// In en, this message translates to:
  /// **'Please provide your current location details and living preferences below.'**
  String get step3Instruction;

  /// No description provided for @step4Instruction.
  ///
  /// In en, this message translates to:
  /// **'Please verify your government ID for security.'**
  String get step4Instruction;

  /// No description provided for @step5Instruction.
  ///
  /// In en, this message translates to:
  /// **'Please enter your marital history.'**
  String get step5Instruction;

  /// No description provided for @step6Instruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your preferences for your partner.'**
  String get step6Instruction;

  /// No description provided for @step7Instruction.
  ///
  /// In en, this message translates to:
  /// **'Upload your main photo. Face detection is active.'**
  String get step7Instruction;

  /// No description provided for @step8Instruction.
  ///
  /// In en, this message translates to:
  /// **'Provide your family background details.'**
  String get step8Instruction;

  /// No description provided for @step9Instruction.
  ///
  /// In en, this message translates to:
  /// **'Add a short bio and select privacy settings.'**
  String get step9Instruction;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @postMarriagePreferences.
  ///
  /// In en, this message translates to:
  /// **'Post-Marriage Preferences'**
  String get postMarriagePreferences;

  /// No description provided for @willingToRelocateToBridesHome.
  ///
  /// In en, this message translates to:
  /// **'Willing to Relocate to Bride\'s Home?'**
  String get willingToRelocateToBridesHome;

  /// No description provided for @yesHave.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesHave;

  /// No description provided for @noHave.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noHave;

  /// No description provided for @willingToStayAtWifesHouse.
  ///
  /// In en, this message translates to:
  /// **'Residence Preference'**
  String get willingToStayAtWifesHouse;

  /// No description provided for @residencePreferenceHelperText.
  ///
  /// In en, this message translates to:
  /// **'Considering families with only daughters, choose this if you are willing to permanently stay at and support the bride\'s house after marriage.'**
  String get residencePreferenceHelperText;

  /// No description provided for @residencePrefWifeHouse.
  ///
  /// In en, this message translates to:
  /// **'Interested (Stay at Bride\'s House)'**
  String get residencePrefWifeHouse;

  /// No description provided for @residencePrefOwnHouse.
  ///
  /// In en, this message translates to:
  /// **'Stay at Own House'**
  String get residencePrefOwnHouse;

  /// No description provided for @residencePrefFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible (Decide Based on Situation)'**
  String get residencePrefFlexible;

  /// No description provided for @yesOption.
  ///
  /// In en, this message translates to:
  /// **'YES'**
  String get yesOption;

  /// No description provided for @noOption.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get noOption;

  /// No description provided for @dependsOption.
  ///
  /// In en, this message translates to:
  /// **'DEPENDS'**
  String get dependsOption;

  /// No description provided for @backBtn.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backBtn;

  /// No description provided for @nextStepBtn.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStepBtn;

  /// No description provided for @masterSDegree.
  ///
  /// In en, this message translates to:
  /// **'Master\'s Degree'**
  String get masterSDegree;

  /// No description provided for @autoFetchSim.
  ///
  /// In en, this message translates to:
  /// **'Auto-fetch Verified SIM Number'**
  String get autoFetchSim;

  /// No description provided for @autoFetchFailsManual.
  ///
  /// In en, this message translates to:
  /// **'If auto-fetch fails or is denied, you may enter manually.'**
  String get autoFetchFailsManual;

  /// No description provided for @selectSimForRegistration.
  ///
  /// In en, this message translates to:
  /// **'Select SIM for Registration'**
  String get selectSimForRegistration;

  /// No description provided for @noSimCardsDetected.
  ///
  /// In en, this message translates to:
  /// **'No SIM cards detected or permission denied.'**
  String get noSimCardsDetected;

  /// No description provided for @unknownCarrier.
  ///
  /// In en, this message translates to:
  /// **'Unknown Carrier'**
  String get unknownCarrier;

  /// No description provided for @unknownNumber.
  ///
  /// In en, this message translates to:
  /// **'Unknown Number'**
  String get unknownNumber;

  /// No description provided for @phoneNumberNotStored.
  ///
  /// In en, this message translates to:
  /// **'Phone number not stored on this SIM. Please enter manually.'**
  String get phoneNumberNotStored;

  /// No description provided for @enterMobileNumberManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Mobile Number Manually'**
  String get enterMobileNumberManually;

  /// No description provided for @simBindingSuccessful.
  ///
  /// In en, this message translates to:
  /// **'SIM Binding Successful! Phone number verified via system.'**
  String get simBindingSuccessful;

  /// No description provided for @bindingSimCard.
  ///
  /// In en, this message translates to:
  /// **'Binding SIM Card...'**
  String get bindingSimCard;

  /// No description provided for @incomingCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming Call...'**
  String get incomingCall;

  /// No description provided for @calling.
  ///
  /// In en, this message translates to:
  /// **'Calling...'**
  String get calling;

  /// No description provided for @activeCall.
  ///
  /// In en, this message translates to:
  /// **'Active Call'**
  String get activeCall;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call Ended'**
  String get callEnded;

  /// No description provided for @callRejected.
  ///
  /// In en, this message translates to:
  /// **'Call Rejected'**
  String get callRejected;

  /// No description provided for @unknownCaller.
  ///
  /// In en, this message translates to:
  /// **'Unknown Caller'**
  String get unknownCaller;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @muteAudio.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get muteAudio;

  /// No description provided for @unmuteAudio.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmuteAudio;

  /// No description provided for @speakerphone.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speakerphone;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End Call'**
  String get endCall;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @bmiLabel.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get bmiLabel;

  /// No description provided for @bmiUnderweight.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get bmiUnderweight;

  /// No description provided for @bmiNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal Weight'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get bmiOverweight;

  /// No description provided for @bmiObese.
  ///
  /// In en, this message translates to:
  /// **'Obese'**
  String get bmiObese;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matches;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @familyTree.
  ///
  /// In en, this message translates to:
  /// **'Family Tree'**
  String get familyTree;

  /// No description provided for @moietyChecker.
  ///
  /// In en, this message translates to:
  /// **'Moiety Checker'**
  String get moietyChecker;

  /// No description provided for @clanFeed.
  ///
  /// In en, this message translates to:
  /// **'Clan Feed'**
  String get clanFeed;

  /// No description provided for @tharavadu.
  ///
  /// In en, this message translates to:
  /// **'Tharavadu'**
  String get tharavadu;

  /// No description provided for @matchDesk.
  ///
  /// In en, this message translates to:
  /// **'Match Desk'**
  String get matchDesk;

  /// No description provided for @myStatus.
  ///
  /// In en, this message translates to:
  /// **'My Status'**
  String get myStatus;

  /// No description provided for @statuses.
  ///
  /// In en, this message translates to:
  /// **'Statuses'**
  String get statuses;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @viewStatus.
  ///
  /// In en, this message translates to:
  /// **'View Status'**
  String get viewStatus;

  /// No description provided for @replyPrivately.
  ///
  /// In en, this message translates to:
  /// **'Reply Privately'**
  String get replyPrivately;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or tharavadu...'**
  String get searchHint;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @noActiveStatuses.
  ///
  /// In en, this message translates to:
  /// **'No Active Statuses'**
  String get noActiveStatuses;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get verificationPending;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @emptyList.
  ///
  /// In en, this message translates to:
  /// **'List is empty'**
  String get emptyList;

  /// No description provided for @statusListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active statuses found'**
  String get statusListEmpty;

  /// No description provided for @noUpdates.
  ///
  /// In en, this message translates to:
  /// **'No updates'**
  String get noUpdates;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @tharavaduName.
  ///
  /// In en, this message translates to:
  /// **'Tharavadu Name'**
  String get tharavaduName;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get selectLanguage;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @accountPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Account Privacy'**
  String get accountPrivacy;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @viewFullProfile.
  ///
  /// In en, this message translates to:
  /// **'View Full Profile'**
  String get viewFullProfile;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'Member Count'**
  String get memberCount;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ml'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ml':
      return AppLocalizationsMl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
