import 'package:flutter/material.dart';
import 'package:kurichiyar_matrimony/features/registration/widgets/safe_dropdown.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';

class Step6PartnerPreferences extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final double prefAgeMin;
  final double prefAgeMax;
  final String? prefEducation;
  final String? prefCareer;
  final String? prefDistrict;
  final String? prefIncome;
  final String? prefHabits;
  final bool? prefRelocateToBrideHome;
  final String? residencePreference;
  final String? parentCarePreference;

  final ValueChanged<RangeValues> onAgeRangeChanged;
  final ValueChanged<String?> onPrefEducationChanged;
  final ValueChanged<String?> onPrefCareerChanged;
  final ValueChanged<String?> onPrefDistrictChanged;
  final ValueChanged<String?> onPrefIncomeChanged;
  final ValueChanged<String?> onPrefHabitsChanged;
  final ValueChanged<bool?> onPrefRelocateToBrideHomeChanged;
  final ValueChanged<String?> onResidencePreferenceChanged;
  final ValueChanged<String?> onParentCarePreferenceChanged;
  final Map<String, dynamic> config;
  final Widget Function({required Widget child}) buildCard;

  const Step6PartnerPreferences({
    super.key,
    required this.formKey,
    required this.prefAgeMin,
    required this.prefAgeMax,
    required this.prefEducation,
    required this.prefCareer,
    required this.prefDistrict,
    required this.prefIncome,
    required this.prefHabits,
    required this.prefRelocateToBrideHome,
    required this.residencePreference,
    required this.parentCarePreference,
    required this.onAgeRangeChanged,
    required this.onPrefEducationChanged,
    required this.onPrefCareerChanged,
    required this.onPrefDistrictChanged,
    required this.onPrefIncomeChanged,
    required this.onPrefHabitsChanged,
    required this.onPrefRelocateToBrideHomeChanged,
    required this.onResidencePreferenceChanged,
    required this.onParentCarePreferenceChanged,
    this.config = const {},
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    return buildCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                AppLocalizations.of(context)!.step6Instruction,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.partnerPreferences,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            Text(
              '${AppLocalizations.of(context)!.preferredAgeRange}: ${prefAgeMin.toInt()} - ${prefAgeMax.toInt()}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            RangeSlider(
              values: RangeValues(prefAgeMin, prefAgeMax),
              min: 18,
              max: 60,
              divisions: 42,
              labels: RangeLabels(
                '${prefAgeMin.toInt()}',
                '${prefAgeMax.toInt()}',
              ),
              onChanged: onAgeRangeChanged,
            ),
            const SizedBox(height: 16),

            SafeDropdown<String>(
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context)!.preferredEducation} *',
                border: const OutlineInputBorder(),
              ),
              initialValue: prefEducation,
              items: [
                'Any',
                'High School',
                'Diploma',
                'Bachelor\'s Degree',
                'Master\'s Degree',
                'Doctorate',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onPrefEducationChanged,
              validator: (v) => v == null
                  ? 'ദയവായി താല്പര്യപ്പെടുന്ന വിദ്യാഭ്യാസം തിരഞ്ഞെടുക്കുക.'
                  : null,
            ),
            const SizedBox(height: 16),

            SafeDropdown<String>(
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context)!.preferredCareerSector} *',
                border: const OutlineInputBorder(),
              ),
              initialValue: prefCareer,
              items: [
                'Any',
                'Private Sector',
                'Government/Public Sector',
                'Business/Self Employed',
                'Not Working',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onPrefCareerChanged,
              validator: (v) => v == null
                  ? 'ദയവായി താല്പര്യപ്പെടുന്ന തൊഴിൽ മേഖല തിരഞ്ഞെടുക്കുക.'
                  : null,
            ),
            const SizedBox(height: 16),

            SafeDropdown<String>(
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context)!.preferredDistrict} *',
                border: const OutlineInputBorder(),
              ),
              initialValue: prefDistrict,
              items: [
                'Any',
                'Wayanad',
                'Kannur',
                'Kozhikode',
                'Malappuram',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onPrefDistrictChanged,
              validator: (v) => v == null
                  ? 'ദയവായി താല്പര്യപ്പെടുന്ന ജില്ല തിരഞ്ഞെടുക്കുക.'
                  : null,
            ),
            const SizedBox(height: 16),
            if (config['show_income'] != false) ...[
              SafeDropdown<String>(
                decoration: InputDecoration(
                  labelText:
                      '${AppLocalizations.of(context)!.preferredIncome} *',
                  border: const OutlineInputBorder(),
                ),
                initialValue: prefIncome,
                items:
                    [
                          'Any',
                          'Below 2 Lakhs',
                          '2 - 5 Lakhs',
                          '5 - 10 Lakhs',
                          'Above 10 Lakhs',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: onPrefIncomeChanged,
                validator: (v) => v == null
                    ? 'ദയവായി താല്പര്യപ്പെടുന്ന വരുമാന പരിധി തിരഞ്ഞെടുക്കുക.'
                    : null,
              ),
              const SizedBox(height: 16),
            ],

            SafeDropdown<String>(
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context)!.preferredHabitsSmokingDrinking} *',
                border: const OutlineInputBorder(),
              ),
              initialValue: prefHabits,
              items: [
                const DropdownMenuItem(
                  value: 'Open',
                  child: Text('ഏതും ഓക്കെ / Any'),
                ),
                const DropdownMenuItem(
                  value: 'Doesn\'t Matter',
                  child: Text('ഏതും സാരമില്ല / Doesn\'t Matter'),
                ),
                const DropdownMenuItem(
                  value: 'Strictly No',
                  child: Text('പാടില്ല / Strictly No'),
                ),
                const DropdownMenuItem(
                  value: 'Occasionally Acceptable',
                  child: Text('വല്ലപ്പോഴും ആകാം / Occasionally Acceptable'),
                ),
              ],
              onChanged: onPrefHabitsChanged,
              validator: (v) => v == null
                  ? 'ശീലങ്ങളുമായി ബന്ധപ്പെട്ട താല്പര്യം തിരഞ്ഞെടുക്കുക.'
                  : null,
            ),

            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.postMarriagePreferences,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            SafeDropdown<bool>(
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context)!.willingToRelocateToBridesHome} *',
                border: const OutlineInputBorder(),
              ),
              initialValue: prefRelocateToBrideHome,
              items: [
                DropdownMenuItem(
                  value: true,
                  child: Text(AppLocalizations.of(context)!.thalperyamundu),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text(AppLocalizations.of(context)!.thalperyamilla),
                ),
              ],
              onChanged: onPrefRelocateToBrideHomeChanged,
              validator: (v) => v == null
                  ? 'താമസ സൗകര്യവുമായി ബന്ധപ്പെട്ട താല്പര്യം വ്യക്തമാക്കുക.'
                  : null,
            ),
            const SizedBox(height: 16),

            SafeDropdown<String>(
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context)!.residencePreference} *',
                border: const OutlineInputBorder(),
              ),
              initialValue: residencePreference,
              items: [
                'Living with parents',
                'Independent House/Nuclear family',
                'Not Decided',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onResidencePreferenceChanged,
              validator: (v) => v == null
                  ? 'വിവാഹശേഷം താമസിക്കാൻ ആഗ്രഹിക്കുന്ന സ്ഥലം തിരഞ്ഞെടുക്കുക.'
                  : null,
            ),
            const SizedBox(height: 16),

            SafeDropdown<String>(
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context)!.parentCarePreference} *',
                border: const OutlineInputBorder(),
              ),
              initialValue: parentCarePreference,
              items: [
                'Will live with my parents',
                'Will support them financially',
                'Will take care of both sides',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onParentCarePreferenceChanged,
              validator: (v) => v == null
                  ? 'മാതാപിതാക്കളെ നോക്കുന്നതുമായി ബന്ധപ്പെട്ട താല്പര്യം തിരഞ്ഞെടുക്കുക.'
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
