import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/user_profile.dart';
import '../../core/utils/mock_data.dart';

class PartnerPreferencesEditSheet extends StatefulWidget {
  final UserProfile profile;

  const PartnerPreferencesEditSheet({super.key, required this.profile});

  @override
  State<PartnerPreferencesEditSheet> createState() =>
      _PartnerPreferencesEditSheetState();
}

class _PartnerPreferencesEditSheetState
    extends State<PartnerPreferencesEditSheet> {
  late List<bool?> answers;
  bool isLoading = false;

  List<String> _getQuestions(String languageCode) {
    if (languageCode == 'en') {
      return const [
        "1. Are you interested in living together in a joint family with your husband's parents after marriage?",
        "2. Are you ready to relocate abroad or to another place if required by your husband's job?",
        "3. Do you intend to manage both your job and family responsibilities together after marriage?",
        "4. Do you want to speak directly with your partner to understand each other before marriage?",
        "5. Do you prefer to move out and live in a nuclear family after marriage?",
        "6. Do you prefer sharing the financial matters of the family together?",
        "7. Will you have any difficulty accepting a partner with night shift jobs or jobs requiring frequent travel?",
        "8. Do you prefer taking major family decisions only after consulting your partner?",
        "9. Are you ready to openly disclose any financial liabilities or debts to your partner before marriage?",
        "10. Are you a person who likes to travel and socialize with your partner during holidays?",
      ];
    } else if (languageCode == 'hi') {
      return const [
        "1. क्या आप शादी के बाद पति के माता-पिता के साथ संयुक्त परिवार में रहने में रुचि रखते हैं?",
        "2. क्या आप पति की नौकरी के लिए विदेश या किसी अन्य स्थान पर जाने के लिए तैयार हैं?",
        "3. क्या आप शादी के बाद नौकरी और पारिवारिक जिम्मेदारियों दोनों को एक साथ संभालने का इरादा रखते हैं?",
        "4. क्या आप शादी से पहले एक-दूसरे को समझने के लिए सीधे बात करना चाहते हैं?",
        "5. क्या आप शादी के बाद एकल परिवार में रहना पसंद करते हैं?",
        "6. क्या आप परिवार के वित्तीय मामलों को मिलकर संभालना पसंद करते हैं?",
        "7. क्या आपको नाइट शिफ्ट या लगातार यात्रा वाली नौकरी करने वाले साथी को स्वीकार करने में कठिनाई होगी?",
        "8. क्या आप अपने साथी से परामर्श करने के बाद ही बड़े पारिवारिक निर्णय लेना पसंद करते हैं?",
        "9. क्या आप शादी से पहले किसी भी वित्तीय देनदारियों या ऋण का खुलकर खुलासा करने के लिए तैयार हैं?",
        "10. क्या आप ऐसे व्यक्ति हैं जो छुट्टियों के दौरान अपने साथी के साथ यात्रा करना और घुलना-मिलना पसंद करते हैं?",
      ];
    } else {
      return const [
        "1. വിവാഹശേഷം ഭർത്താവിന്റെ മാതാപിതാക്കൾക്കൊപ്പം കൂട്ടുകുടുംബമായി താമസിക്കാൻ താല്പര്യമുണ്ടോ?",
        "2. ഭർത്താവിന്റെ ജോലിയുടെ ഭാഗമായി വിദേശത്തേക്കോ മറ്റൊരു സ്ഥലത്തേക്കോ താമസം മാറാൻ തയ്യാറാണോ?",
        "3. വിവാഹശേഷം ജോലിയും കുടുംബ ഉത്തരവാദിത്തങ്ങളും ഒരുമിച്ച് കൊണ്ടുപോകാൻ ഉദ്ദേശിക്കുന്നുണ്ടോ?",
        "4. വിവാഹത്തിന് മുമ്പ് പരസ്പരം മനസ്സിലാക്കാൻ നേരിട്ട് സംസാരിക്കാൻ ആഗ്രഹിക്കുന്നുണ്ടോ?",
        "5. വിവാഹശേഷം അണുകുടുംബമായി മാറി താമസിക്കാനാണോ താല്പര്യം?",
        "6. കുടുംബത്തിലെ സാമ്പത്തിക കാര്യങ്ങൾ പരസ്പരം ഒരുമിച്ച് കൈകാര്യം ചെയ്യാൻ താല്പര്യപ്പെടുന്നുണ്ടോ?",
        "7. നൈറ്റ് ഷിഫ്റ്റോ അടിക്കടി യാത്രയോ ഉള്ള പങ്കാളിയെ സ്വീകരിക്കുന്നതിൽ ബുദ്ധിമുട്ടുണ്ടോ?",
        "8. കുടുംബത്തിലെ പ്രധാന തീരുമാനങ്ങൾ പങ്കാളിയോട് ആലോചിച്ച ശേഷം എടുക്കാൻ താല്പര്യപ്പെടുന്നുണ്ടോ?",
        "9. വിവാഹത്തിന് മുമ്പ് നിലവിലുള്ള സാമ്പത്തിക ബാധ്യതകൾ പങ്കാളിയോട് തുറന്നു പറയാൻ തയ്യാറാണോ?",
        "10. അവധി ദിവസങ്ങളിൽ പങ്കാളിയോടൊപ്പം യാത്രകൾ ചെയ്യാനും ഇടപഴകാനും ഇഷ്ടപ്പെടുന്ന ആളാണോ?",
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    answers = [
      widget.profile.prefJointFamily,
      widget.profile.prefRelocate,
      widget.profile.prefManageJobFamily,
      widget.profile.prefDirectTalk,
      widget.profile.prefNuclearFamily,
      widget.profile.prefShareFinances,
      widget.profile.prefNightShift,
      widget.profile.prefConsultDecisions,
      widget.profile.prefDiscloseDebts,
      widget.profile.prefTravelSocialize,
    ];
  }

  Future<void> _savePreferences() async {
    setState(() => isLoading = true);
    try {
      final updateData = {
        'pref_joint_family': answers[0],
        'pref_relocate': answers[1],
        'pref_manage_job_family': answers[2],
        'pref_direct_talk': answers[3],
        'pref_nuclear_family': answers[4],
        'pref_share_finances': answers[5],
        'pref_night_shift': answers[6],
        'pref_consult_decisions': answers[7],
        'pref_disclose_debts': answers[8],
        'pref_travel_socialize': answers[9],
      };

      await Supabase.instance.client
          .from('kurichiyar_profiles')
          .update(updateData)
          .eq('id', widget.profile.id);

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.profile.id)
            .set(updateData, SetOptions(merge: true));
      } catch (fErr) {
        debugPrint('Firestore preferences sync note: $fErr');
      }

      final me = MockData().currentUser;
      if (me != null && me.id == widget.profile.id) {
        MockData().updateCurrentUser(
          me.copyWith(
            prefJointFamily: answers[0],
            prefRelocate: answers[1],
            prefManageJobFamily: answers[2],
            prefDirectTalk: answers[3],
            prefNuclearFamily: answers[4],
            prefShareFinances: answers[5],
            prefNightShift: answers[6],
            prefConsultDecisions: answers[7],
            prefDiscloseDebts: answers[8],
            prefTravelSocialize: answers[9],
          ),
        );
      }

      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        final successMsg = locale == 'en'
            ? 'Preferences saved successfully!'
            : locale == 'hi'
            ? 'प्राथमिकताएं सफलतापूर्वक सहेजी गईं!'
            : 'വിവരങ്ങൾ സേവ് ചെയ്തു';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final questions = _getQuestions(locale);

    final title = locale == 'en'
        ? 'Expectations & Partner Preferences'
        : locale == 'hi'
        ? 'अपेक्षाएं और साथी प्राथमिकताएं'
        : 'പ്രതീക്ഷകളും താല്പര്യങ്ങളും';

    final yesLabel = locale == 'en'
        ? 'Yes'
        : locale == 'hi'
        ? 'हां'
        : 'അതെ';

    final noLabel = locale == 'en'
        ? 'No'
        : locale == 'hi'
        ? 'नहीं'
        : 'അല്ല';

    final unsetLabel = locale == 'en'
        ? 'Unset'
        : locale == 'hi'
        ? 'तय नहीं'
        : 'തീരുമാനിച്ചിട്ടില്ല';

    final saveLabel = locale == 'en'
        ? 'Save Preferences'
        : locale == 'hi'
        ? 'प्राथमिकताएं सहेजें'
        : 'വിവരങ്ങൾ സേവ് ചെയ്യുക';

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questions[index],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildOptionButton(
                                title: yesLabel,
                                isSelected: answers[index] == true,
                                color: Colors.green,
                                onTap: () =>
                                    setState(() => answers[index] = true),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildOptionButton(
                                title: noLabel,
                                isSelected: answers[index] == false,
                                color: Colors.red,
                                onTap: () =>
                                    setState(() => answers[index] = false),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildOptionButton(
                                title: unsetLabel,
                                isSelected: answers[index] == null,
                                color: Colors.grey,
                                onTap: () =>
                                    setState(() => answers[index] = null),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : _savePreferences,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    saveLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String title,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? color : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
