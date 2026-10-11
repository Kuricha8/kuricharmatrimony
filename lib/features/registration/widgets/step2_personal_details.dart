// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:kurichiyar_matrimony/features/registration/widgets/safe_dropdown.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';
import 'package:kurichiyar_matrimony/core/models/models.dart';

class Step2PersonalDetails extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController houseNameController;
  final TextEditingController fatherClanController;
  final TextEditingController motherClanController;
  final Clan? fatherClan;
  final Clan? motherClan;
  final bool loadingClans;
  final List<Clan> clans;
  final VoidCallback onRefreshClans;
  final VoidCallback onAddTharavadu;
  final ValueChanged<Clan?> onFatherClanChanged;
  final ValueChanged<Clan?> onMotherClanChanged;
  final String? height;
  final String? weight;
  final String? bloodGroup;
  final String? physicalStatus;
  final String? educationLevel;
  final TextEditingController educationOtherController;
  final ValueChanged<String?> onHeightChanged;
  final ValueChanged<String?> onWeightChanged;
  final ValueChanged<String?> onBloodGroupChanged;
  final ValueChanged<String?> onPhysicalStatusChanged;
  final ValueChanged<String?> onEducationLevelChanged;
  final bool hasFamilyRestriction;
  final TextEditingController mothersTarawadController;
  final List<Clan> selectedRestrictedFamilies;
  final ValueChanged<bool?> onFamilyRestrictionChanged;
  final ValueChanged<List<Clan>> onRestrictedFamiliesChanged;
  final Map<String, dynamic> config;
  final Widget Function({required Widget child}) buildCard;
  final Map<String, GlobalKey<FormFieldState>> step2Keys;

  const Step2PersonalDetails({
    super.key,
    required this.formKey,
    required this.houseNameController,
    required this.fatherClanController,
    required this.motherClanController,
    required this.fatherClan,
    required this.motherClan,
    required this.loadingClans,
    required this.clans,
    required this.onRefreshClans,
    required this.onAddTharavadu,
    required this.onFatherClanChanged,
    required this.onMotherClanChanged,
    required this.height,
    required this.weight,
    required this.bloodGroup,
    required this.physicalStatus,
    required this.educationLevel,
    required this.educationOtherController,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onBloodGroupChanged,
    required this.onPhysicalStatusChanged,
    required this.onEducationLevelChanged,
    required this.hasFamilyRestriction,
    required this.mothersTarawadController,
    required this.selectedRestrictedFamilies,
    required this.onFamilyRestrictionChanged,
    required this.onRestrictedFamiliesChanged,
    this.config = const {},
    required this.buildCard,
    required this.step2Keys,
  });

  @override
  Widget build(BuildContext context) {
    return buildCard(
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  AppLocalizations.of(context)!.step2Instruction,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.step2LineageHousehold,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              TextFormField(
                key: step2Keys['house'],
                controller: houseNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.houseNameCurrentResidence,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'വീട്ടുപേര് / തറവാട് പേര് നിർബന്ധമാണ്'
                    : null,
              ),
              const SizedBox(height: 24),

              if (config['show_tharavad'] != false) ...[
                if (loadingClans) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.loadingTharavaduList,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FormField<String>(
                          key: step2Keys['father'],
                          validator: (value) =>
                              fatherClanController.text.trim().isEmpty
                              ? 'അച്ഛന്റെ ഗോത്രം / തറവാട് നിർബന്ധമാണ്'
                              : null,
                          builder: (state) {
                            return DropdownMenu<Clan>(
                              controller: fatherClanController,
                              errorText: state.errorText,
                              requestFocusOnTap: true,
                              enableFilter: true,
                              enableSearch: true,
                              expandedInsets: EdgeInsets.zero,
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                )!.fathersClanTharavadu,
                              ),
                              dropdownMenuEntries: clans
                                  .map(
                                    (c) => DropdownMenuEntry(
                                      value: c,
                                      label: c.displayName.isNotEmpty
                                          ? c.displayName
                                          : c.name,
                                    ),
                                  )
                                  .toList(),
                              onSelected: (v) {
                                state.didChange(v?.name);
                                onFatherClanChanged(v);
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.indigo,
                          ),
                          onPressed: onAddTharavadu,
                          tooltip: 'Suggest New Tharavadu',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: onRefreshClans,
                          tooltip: 'Refresh',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FormField<String>(
                          key: step2Keys['mother'],
                          validator: (value) =>
                              motherClanController.text.trim().isEmpty
                              ? 'അമ്മയുടെ ഗോത്രം / തറവാട് നിർബന്ധമാണ്'
                              : null,
                          builder: (state) {
                            return DropdownMenu<Clan>(
                              controller: motherClanController,
                              errorText: state.errorText,
                              requestFocusOnTap: true,
                              enableFilter: true,
                              enableSearch: true,
                              expandedInsets: EdgeInsets.zero,
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                )!.mothersClanTharavadu,
                              ),
                              dropdownMenuEntries: clans
                                  .map(
                                    (c) => DropdownMenuEntry(
                                      value: c,
                                      label: c.displayName.isNotEmpty
                                          ? c.displayName
                                          : c.name,
                                    ),
                                  )
                                  .toList(),
                              onSelected: (v) {
                                state.didChange(v?.name);
                                onMotherClanChanged(v);
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.indigo,
                          ),
                          onPressed: onAddTharavadu,
                          tooltip: 'Suggest New Tharavadu',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: onRefreshClans,
                          tooltip: 'Refresh',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      'നിങ്ങളുടെ തറവാട് ലിസ്റ്റിൽ കാണുന്നില്ലെങ്കിൽ, അടുത്തുള്ള + ഐക്കൺ അമർത്തി തറവാടിന്റെ പേരും സ്ഥലവും രേഖപ്പെടുത്തുക. അഡ്മിൻ പരിശോധനയ്ക്ക് ശേഷം ഇത് ലിസ്റ്റിൽ ഉൾപ്പെടുത്തുന്നതാണ്.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      String moietyStr = "";
                      if (motherClan != null) {
                        moietyStr = motherClan!.type == 'PANDI'
                            ? 'PANTHI'
                            : (motherClan!.type == 'BANDHU' ? 'BANDHU' : '');
                      } else if (fatherClan != null) {
                        moietyStr = fatherClan!.type == 'BANDHU'
                            ? 'PANTHI'
                            : (fatherClan!.type == 'PANDI' ? 'BANDHU' : '');
                      }

                      final isRestricted = moietyStr.isNotEmpty;
                      if (!isRestricted) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'ശ്രദ്ധ: ഈ തറവാട് $moietyStr ഗ്രൂപ്പിൽ ഉൾപ്പെടുന്നു. ഇതേ ഗ്രൂപ്പിലെ മറ്റ് തറവാടുകൾ (സഹോദര തറവാടുകൾ) ആയ ആളുകളെ വിവാഹം ചെയ്യാൻ പാടുള്ളതല്ല.',
                                style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontSize: 13,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],

              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FormField<bool>(
                        key: step2Keys['forbidden'],
                        initialValue: hasFamilyRestriction,
                        validator: (v) =>
                            null, // defaults to false, so always valid
                        builder: (state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'വിവാഹം കഴിക്കാൻ പാടില്ലാത്ത തറവാടുകൾ ഏതൊക്കെയെന്ന് നിങ്ങൾക്ക് അറിയാമോ?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<bool>(
                                      title: const Text('Yes'),
                                      value: true,
                                      groupValue: hasFamilyRestriction,
                                      onChanged: (v) {
                                        state.didChange(v);
                                        onFamilyRestrictionChanged(v);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<bool>(
                                      title: const Text('No'),
                                      value: false,
                                      groupValue: hasFamilyRestriction,
                                      onChanged: (v) {
                                        state.didChange(v);
                                        onFamilyRestrictionChanged(v);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (state.hasError)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Text(
                                    state.errorText!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      if (hasFamilyRestriction) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: mothersTarawadController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Mother's Tarawad",
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors
                                .grey
                                .shade200, // indicate it's locked visually
                            hintText: "Select Mother's Clan above",
                          ),
                        ),
                        const SizedBox(height: 16),
                        FormField<List<Clan>>(
                          key: step2Keys['restrictedList'],
                          initialValue: selectedRestrictedFamilies,
                          validator: (v) => (selectedRestrictedFamilies.isEmpty)
                              ? 'കുറഞ്ഞത് ഒരു തറവാടെങ്കിലും തിരഞ്ഞെടുക്കുക'
                              : null,
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Select Restricted Families',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: state.hasError
                                        ? Colors.red.shade700
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: state.hasError
                                      ? const EdgeInsets.all(8)
                                      : EdgeInsets.zero,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: state.hasError
                                          ? Colors.red.shade700
                                          : Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Wrap(
                                        spacing: 8.0,
                                        runSpacing: 4.0,
                                        children: selectedRestrictedFamilies.map(
                                          (clan) {
                                            return Chip(
                                              label: Text(clan.name),
                                              deleteIcon: const Icon(
                                                Icons.close,
                                                size: 18,
                                              ),
                                              onDeleted: () {
                                                final newList = List<Clan>.from(
                                                  selectedRestrictedFamilies,
                                                );
                                                newList.removeWhere(
                                                  (c) => c.id == clan.id,
                                                );
                                                state.didChange(newList);
                                                onRestrictedFamiliesChanged(
                                                  newList,
                                                );
                                              },
                                            );
                                          },
                                        ).toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<int?>(
                                              key: ValueKey(
                                                selectedRestrictedFamilies
                                                    .length,
                                              ),
                                              isExpanded: true,
                                              value: null,
                                              hint: const Text(
                                                'Add a family...',
                                              ),
                                              items: clans
                                                  .where(
                                                    (c) =>
                                                        !selectedRestrictedFamilies
                                                            .any(
                                                              (selected) =>
                                                                  selected.id ==
                                                                  c.id,
                                                            ),
                                                  )
                                                  .map((clan) {
                                                    return DropdownMenuItem<
                                                      int?
                                                    >(
                                                      value: clan.id,
                                                      child: Text(
                                                        clan.name,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    );
                                                  })
                                                  .toList(),
                                              onChanged: (selectedId) {
                                                if (selectedId != null) {
                                                  final match = clans
                                                      .firstWhere(
                                                        (c) =>
                                                            c.id == selectedId,
                                                      );
                                                  final newList = List<Clan>.from(
                                                    selectedRestrictedFamilies,
                                                  );
                                                  newList.add(match);
                                                  state.didChange(newList);
                                                  onRestrictedFamiliesChanged(
                                                    newList,
                                                  );
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                filled: true,
                                                fillColor: Colors.white,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {},
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12.0,
                                      top: 4.0,
                                    ),
                                    child: Text(
                                      state.errorText!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const SizedBox(height: 32),
              if (config['show_height'] != false ||
                  config['show_weight'] != false ||
                  config['show_blood_group'] != false ||
                  config['show_complexion'] != false ||
                  config['show_education'] != false) ...[
                Text(
                  AppLocalizations.of(context)!.physicalEducationAttributes,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              ],
              if (config['show_height'] != false ||
                  config['show_weight'] != false)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (config['show_height'] != false)
                      Expanded(
                        child: SafeDropdown<String>(
                          key: step2Keys['height'],
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.heightCm,
                            border: OutlineInputBorder(),
                          ),
                          initialValue: height,
                          items:
                              List.generate(
                                    81,
                                    (index) => (130 + index).toString(),
                                  ) // 130cm to 210cm
                                  .map(
                                    (h) => DropdownMenuItem(
                                      value: h,
                                      child: Text(h),
                                    ),
                                  )
                                  .toList(),
                          onChanged: onHeightChanged,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'ഉയരം നിർബന്ധമാണ്'
                              : null,
                        ),
                      ),
                    if (config['show_height'] != false &&
                        config['show_weight'] != false)
                      const SizedBox(width: 16),
                    if (config['show_weight'] != false)
                      Expanded(
                        child: TextFormField(
                          key: step2Keys['weight'],
                          initialValue: weight,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.weightKg,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: onWeightChanged,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'ഭാരം നിർബന്ധമാണ്'
                              : null,
                        ),
                      ),
                  ],
                ),
              if (config['show_height'] != false &&
                  config['show_weight'] != false)
                _buildBMICard(context),
              if (config['show_height'] != false ||
                  config['show_weight'] != false)
                const SizedBox(height: 16),
              if (config['show_blood_group'] != false ||
                  config['show_complexion'] != false)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (config['show_blood_group'] != false)
                      Expanded(
                        child: SafeDropdown<String>(
                          key: step2Keys['blood'],
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.bloodGroup,
                            border: OutlineInputBorder(),
                          ),
                          initialValue: bloodGroup,
                          items:
                              ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(b),
                                    ),
                                  )
                                  .toList(),
                          onChanged: onBloodGroupChanged,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'രക്ത ഗ്രൂപ്പ് നിർബന്ധമാണ്'
                              : null,
                        ),
                      ),
                    if (config['show_blood_group'] != false &&
                        config['show_complexion'] != false)
                      const SizedBox(width: 16),
                    if (config['show_complexion'] != false)
                      Expanded(
                        child: SafeDropdown<String>(
                          key: step2Keys['physical'],
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.physicalStatus,
                            border: OutlineInputBorder(),
                          ),
                          initialValue: physicalStatus,
                          items: [
                            DropdownMenuItem(
                              value: 'Normal / Fit',
                              child: Text(
                                AppLocalizations.of(context)!.normalFit,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Differently Abled',
                              child: Text(
                                AppLocalizations.of(context)!.differentlyAbled,
                              ),
                            ),
                          ],
                          onChanged: onPhysicalStatusChanged,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'ശാരീരിക അവസ്ഥ നിർബന്ധമാണ്'
                              : null,
                        ),
                      ),
                  ],
                ),
              if (config['show_blood_group'] != false ||
                  config['show_complexion'] != false)
                const SizedBox(height: 16),
              if (config['show_education'] != false) ...[
                SafeDropdown<String>(
                  key: step2Keys['education'],
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.educationLevel,
                    border: OutlineInputBorder(),
                  ),
                  initialValue: educationLevel,
                  items: [
                    DropdownMenuItem(
                      value: 'High School',
                      child: Text(AppLocalizations.of(context)!.highSchool),
                    ),
                    DropdownMenuItem(
                      value: 'Diploma',
                      child: Text(AppLocalizations.of(context)!.diploma),
                    ),
                    DropdownMenuItem(
                      value: 'Bachelor\'s Degree',
                      child: Text(
                        AppLocalizations.of(context)!.bachelorSDegree,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Master\'s Degree',
                      child: Text(AppLocalizations.of(context)!.masterSDegree),
                    ),
                    DropdownMenuItem(
                      value: 'Doctorate',
                      child: Text(AppLocalizations.of(context)!.doctorate),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text(AppLocalizations.of(context)!.other),
                    ),
                  ],
                  onChanged: onEducationLevelChanged,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'വിദ്യാഭ്യാസ യോഗ്യത നിർബന്ധമാണ്'
                      : null,
                ),
                if (educationLevel == 'Other') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    key: step2Keys['eduOther'],
                    controller: educationOtherController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.specifyEducation,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'വിദ്യാഭ്യാസ വിവരങ്ങൾ നൽകുക'
                        : null,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBMICard(BuildContext context) {
    if (height == null || weight == null || height!.isEmpty || weight!.isEmpty)
  { return const SizedBox.shrink(); }
    final h = double.tryParse(height!);
    final w = double.tryParse(weight!);
    if (h == null || w == null || h <= 0) return const SizedBox.shrink();

    final bmi = w / ((h / 100) * (h / 100));
    final bmiFormatted = bmi.toStringAsFixed(1);

    String status = '';
    Color color = Colors.grey;
    if (bmi < 18.5) {
      status = AppLocalizations.of(context)!.bmiUnderweight;
      color = Colors.orange;
    } else if (bmi < 25) {
      status = AppLocalizations.of(context)!.bmiNormal;
      color = Colors.green;
    } else if (bmi < 30) {
      status = AppLocalizations.of(context)!.bmiOverweight;
      color = Colors.orange;
    } else {
      status = AppLocalizations.of(context)!.bmiObese;
      color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.monitor_weight_outlined, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '${AppLocalizations.of(context)!.bmiLabel}: $bmiFormatted ($status)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
