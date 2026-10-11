import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/mock_data.dart';

/// 27 Authentic Panthi (പന്തി) Clans from Kurichiyar tradition
const List<String> panthiClans = [
  'ചെന്നകണ്ടൻ വാളാടൻ (ഒറ്റമലച്ചി)',
  'കുണ്ടറ (കുണ്ടറ മൂല)',
  'പലോടൻ (പാലോട്ട്)',
  'കാവ് പലോടൻ (കാവിൽ)',
  'ചെറും പാലൻ (കാക്കൻ ചിറ)',
  'മൂത്തേടൻ (മൂത്തേടത്ത്)',
  'മറാടി (പുതുറുത്തോമ്പിൽ)',
  'എടത്തന (എടത്തന)',
  'കൂടൻ (വാളമടക്കിൽ)',
  'ചെന്നലാറ കുറ്റിയോടൻ (ചെന്ന ലാറ)',
  'കോലിയേൻ (നിട്ടറ)',
  'പുത്തൂറ് (കൊമ്മയാട്)',
  'നെല്ലേരി മറാടി (മറാടി നെല്ലേരി)',
  'ചെറക്കര (കോളിമൂല)',
  'കുന്നംകോലൻ (ചേരിമ്മൽ)',
  'കുറ്റിയോട്ട് കുറ്റിയോടൻ (കുറ്റിയോട്ട്)',
  'കരിമ്പിലിച്ചി (നെടുമ്പിലാശ്ശേരി)',
  'നെല്ല് കുടിയൻ (കക്കോട്ടറ)',
  'കല്ലിയോടൻ (കല്ലിയോട്ട്)',
  'ഒതയം കോലൻ (ഒതയോത്ത്)',
  'മാങ്ങണി പുത്തുറ് (മാങ്ങണി)',
  'വാളാടൻ (ഇല്ലത്തുംമൂല)',
  'പുച്ചിയേരി (ചായമൽ)',
  'എടപ്പിടി (എടപ്പിടി)',
  'വെണ്ണിയോറ (വെണ്ണിയോറ)',
  'വേമാത്ത് പുച്ചേരി (വേമോത്ത്)',
  'കൊടിയേരി (പൂളയ്ക്കൽ)',
  'മറ്റ് വയനാടൻ തറവാടുകൾ',
];

/// 30 Authentic Bandhu (ബന്ധു) Clans from Kurichiyar tradition
const List<String> bandhuClans = [
  'കാർക്കോടൻ തലക്കറ (കാർക്കേട്ടിൽ)',
  'അതിരും കോലൻ (പാഞ്ചേരി)',
  'പെറളഞ്ഞി (മുതുവാട്ടിൽ)',
  'കാക്കിലി (ഓടുടുoബിൽ)',
  'ചല്പ (പിൽപ്പിടി - പള്ളിയറ)',
  'ചെലപെറോൻ (എരണകൊല്ലി)',
  'കരിമ്പിച്ചി (കൊടങ്ങേല)',
  'കൊടുമതലക്കറ (കെടുമയിൽ)',
  'തോട്ടായി (എടലകുനി)',
  'എടമന (എടമന)',
  'പറക്കാടൻ (വെള്ളോട്ടിൽ)',
  'പാടണി (കുഴിക്കണ്ടം)',
  'മട്ടലം കരിമ്പിച്ചി (മട്ടിലിയം)',
  'പൂരിഞ്ഞി മിലിയാടി (പുരിഞ്ഞിൽ)',
  'കൊന്നിയോടൻ (കൊന്നിയോട്ട്)',
  'ഇടുനി (കിഴക്കുംപാട്ട് - ഇടുനി)',
  'ചെറൂല് (മെനരത്ത്)',
  'പാലിയേരി (പാലേരി)',
  'കല്ലറ കരിമ്പിച്ചി (പാറമൂല)',
  'കുനിമൽ മിലിയാടി (കുനിയമ്മൽ)',
  'തേറ്റ (വെങ്ങലേട്ട്)',
  'ചമ്മിയേരി (താഴെ തലപ്പുഴ)',
  'എരിചേരി (ചേറാല)',
  'കുക്കോടൻ (കൂക്കോട്ടിൽ)',
  'ആനി തലക്കറ (ആന്നി)',
  'വെള്ളരി മിലിയാടി (വെള്ളരി)',
  'പടിയേരി (ഞാറലോട്ട്)',
  'പുതിയിടം ചമ്മിയേരി (പുതിയിടം)',
  'അയിനിയാടൻ (ചെന്നoമ്പാടി)',
  'പെരിഞ്ചോല പെരിഞ്ചോല',
  'മറ്റ് വയനാടൻ തറവാടുകൾ',
];

/// Normalize phone numbers by extracting clean digits and stripping national prefix
String cleanPhoneNumber(String? phone) {
  if (phone == null || phone.isEmpty) return '';
  String digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length > 10 && digits.startsWith('91')) {
    digits = digits.substring(2);
  } else if (digits.length > 10 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return digits;
}

/// Helper to get the effective active user ID across Firebase, Supabase, or MockData
String? getEffectiveUserId() {
  return FirebaseAuth.instance.currentUser?.uid ??
      Supabase.instance.client.auth.currentUser?.id ??
      MockData().currentUser?.id;
}

/// Helper to get the effective user phone across auth systems
String? getEffectiveUserPhone() {
  final firebasePhone = FirebaseAuth.instance.currentUser?.phoneNumber;
  if (firebasePhone != null && firebasePhone.isNotEmpty) return firebasePhone;

  final me = MockData().currentUser;
  if (me != null) {
    if (me.guardianPhone != null && me.guardianPhone!.trim().isNotEmpty) {
      return me.guardianPhone!.trim();
    }
    if (me.publicDisplayNumber != null && me.publicDisplayNumber!.trim().isNotEmpty) {
      return me.publicDisplayNumber!.trim();
    }
  }
  return null;
}
