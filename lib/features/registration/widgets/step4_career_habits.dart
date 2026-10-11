import 'package:flutter/material.dart';
import 'package:kurichiyar_matrimony/features/registration/widgets/safe_dropdown.dart';
import 'package:kurichiyar_matrimony/core/models/models.dart';

class Step4CareerHabits extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Gender gender;
  final String? careerSector;
  final TextEditingController careerDetailController;
  final String? smokingHabit;
  final String? drinkingHabit;
  final List<String> selectedHobbies;
  final TextEditingController customHobbyController;
  final ValueChanged<String?> onCareerSectorChanged;
  final ValueChanged<String?> onSmokingHabitChanged;
  final ValueChanged<String?> onDrinkingHabitChanged;
  final ValueChanged<String> onHobbyToggled;
  final VoidCallback onCustomHobbyChanged;
  final Map<String, dynamic> config;
  final Widget Function({required Widget child}) buildCard;

  const Step4CareerHabits({
    super.key,
    required this.formKey,
    required this.gender,
    required this.careerSector,
    required this.careerDetailController,
    required this.smokingHabit,
    required this.drinkingHabit,
    required this.selectedHobbies,
    required this.customHobbyController,
    required this.onCareerSectorChanged,
    required this.onSmokingHabitChanged,
    required this.onDrinkingHabitChanged,
    required this.onHobbyToggled,
    required this.onCustomHobbyChanged,
    this.config = const {},
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    List<String> careers = [
      'Government Job',
      'Private Job',
      'Business',
      'Agriculture / Farming',
      'Unemployed',
      'Others',
    ];
    if (gender == Gender.female) {
      careers.addAll(['Home Maker', 'Preparing for PSC / Competitive Exams']);
    }

    // Mapping to Malayalam
    final careerLabels = {
      'Government Job': 'സർക്കാർ ജോലി',
      'Private Job': 'സ്വകാര്യ മേഖല',
      'Business': 'സ്വയം തൊഴിൽ / ബിസിനസ്സ്',
      'Agriculture / Farming': 'കൃഷി',
      'Unemployed': 'തൊഴിൽ ഇല്ല',
      'Others': 'മറ്റുള്ളവ',
      'Home Maker': 'വീട്ടമ്മ',
      'Preparing for PSC / Competitive Exams':
          'പി.എസ്.സി / പരീക്ഷകൾക്ക് തയ്യാറെടുക്കുന്നു',
    };

    final habitLabels = {
      'Never': 'ഇല്ല',
      'Occasionally': 'വല്ലപ്പോഴും',
      'Regularly': 'സ്ഥിരമായി',
    };

    final hobbyLabels = {
      'Travelling': 'യാത്രകൾ',
      'Reading': 'വായന',
      'Farming': 'കൃഷി',
      'Sports': 'കായികം',
      'Cooking': 'പാചകം',
      'Music': 'സംഗീതം',
    };

    return buildCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ജോലി & ശീലങ്ങൾ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
              child: Text(
                'നിങ്ങൾക്ക് ഏറ്റവും അനുയോജ്യമായ ജീവിതപങ്കാളിയെ കണ്ടെത്താൻ നിങ്ങളുടെ തൊഴിൽ വിവരങ്ങളും ജീവിതശൈലിയും കൃത്യമായി രേഖപ്പെടുത്തേണ്ടത് നിർബന്ധമാണ്.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (config['show_occupation'] != false) ...[
              SafeDropdown<String>(
                decoration: InputDecoration(
                  labelText: 'ജോലി മേഖല',
                  border: const OutlineInputBorder(),
                  helperText:
                      'നിങ്ങളുടെ നിലവിലെ തൊഴിലോ വരുമാനമാർഗ്ഗമോ വ്യക്തമാക്കുക.',
                  helperMaxLines: 2,
                ),
                initialValue: careerSector,
                items: careers
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(careerLabels[c] ?? c),
                      ),
                    )
                    .toList(),
                onChanged: onCareerSectorChanged,
                validator: (v) => v == null ? 'Required' : null,
              ),
              if (careerSector == 'Business') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: careerDetailController,
                  decoration: InputDecoration(
                    labelText: 'ഏത് തരം ബിസിനസ്സ്?',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ] else if (careerSector == 'Others') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: careerDetailController,
                  decoration: InputDecoration(
                    labelText: 'ഏത് തരം ജോലി?',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 32),
            ],
            const Text(
              'ശീലങ്ങൾ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'പരസ്പര വിശ്വാസത്തിനും സുതാര്യതയ്ക്കുമായി നിങ്ങളുടെ ശീലങ്ങൾ സത്യസന്ധമായി രേഖപ്പെടുത്തുക.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SafeDropdown<String>(
              decoration: InputDecoration(
                labelText: 'പുകവലി',
                border: OutlineInputBorder(),
              ),
              initialValue: smokingHabit,
              items: ['Never', 'Occasionally', 'Regularly']
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(habitLabels[c] ?? c),
                    ),
                  )
                  .toList(),
              onChanged: onSmokingHabitChanged,
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            SafeDropdown<String>(
              decoration: InputDecoration(
                labelText: 'മദ്യപാനം',
                border: OutlineInputBorder(),
              ),
              initialValue: drinkingHabit,
              items: ['Never', 'Occasionally', 'Regularly']
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(habitLabels[c] ?? c),
                    ),
                  )
                  .toList(),
              onChanged: onDrinkingHabitChanged,
              validator: (v) => v == null ? 'Required' : null,
            ),

            if (config['show_hobbies'] != false) ...[
              const SizedBox(height: 32),
              const Text(
                'ഹോബികൾ (ഓപ്ഷണൽ)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'നിങ്ങളുടെ ഇഷ്ടങ്ങളും താല്പര്യങ്ങളും പങ്കുവെക്കുന്നത് സമാന ചിന്താഗതിയുള്ളവരെ കണ്ടെത്താൻ സഹായിക്കും.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children:
                    [
                      'Travelling',
                      'Reading',
                      'Farming',
                      'Sports',
                      'Cooking',
                      'Music',
                    ].map((hobby) {
                      final isSelected = selectedHobbies.contains(hobby);
                      return FilterChip(
                        label: Text(hobbyLabels[hobby] ?? hobby),
                        selected: isSelected,
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.2),
                        checkmarkColor: Theme.of(context).colorScheme.secondary,
                        onSelected: (bool selected) {
                          onHobbyToggled(hobby);
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: customHobbyController,
                decoration: InputDecoration(
                  labelText: 'മറ്റു ഹോബികൾ',
                  hintText: 'e.g. Photography, Gardening',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  onCustomHobbyChanged();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
