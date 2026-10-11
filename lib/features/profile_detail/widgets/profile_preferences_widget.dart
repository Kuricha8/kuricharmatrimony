import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/localization/localization_service.dart';

class ProfilePreferencesWidget extends StatelessWidget {
  final UserProfile profile;
  const ProfilePreferencesWidget({super.key, required this.profile});

  final List<String> explicitQuestions = const [
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

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final answers = [
      profile.prefJointFamily,
      profile.prefRelocate,
      profile.prefManageJobFamily,
      profile.prefDirectTalk,
      profile.prefNuclearFamily,
      profile.prefShareFinances,
      profile.prefNightShift,
      profile.prefConsultDecisions,
      profile.prefDiscloseDebts,
      profile.prefTravelSocialize,
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite, color: Colors.indigo),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'പ്രതീക്ഷകളും താല്പര്യങ്ങളും',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ...List.generate(explicitQuestions.length, (index) {
              return _buildPrefRow(
                context,
                explicitQuestions[index],
                answers[index],
              );
            }),
            const Divider(height: 24),
            Text(
              loc.translate('other_preferences'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            if (profile.prefAgeMin > 0 || profile.prefAgeMax > 0)
              _buildDetailRow(
                loc.translate('preferred_age'),
                '${profile.prefAgeMin} ${loc.translate('to')} ${profile.prefAgeMax}',
              ),
            if (profile.prefEducation?.isNotEmpty ?? false)
              _buildDetailRow(
                loc.translate('preferred_education'),
                profile.prefEducation!,
              ),
            if (profile.prefLocation?.isNotEmpty ?? false)
              _buildDetailRow(
                loc.translate('preferred_location'),
                profile.prefLocation!,
              ),
            if (profile.prefOccupation?.isNotEmpty ?? false)
              _buildDetailRow(
                loc.translate('preferred_occupation'),
                profile.prefOccupation!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrefRow(BuildContext context, String question, bool? answer) {
    final String ansText = answer == null
        ? 'വ്യക്തമാക്കിയിട്ടില്ല'
        : (answer ? 'അതെ' : 'അല്ല');

    final icon = answer == null
        ? Icons.help_outline
        : (answer ? Icons.check_circle : Icons.cancel);
    final color = answer == null
        ? Colors.grey
        : (answer ? Colors.green : Colors.red);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ansText,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
