import 'package:flutter/material.dart';
import 'package:kurichiyar_matrimony/features/registration/widgets/safe_dropdown.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';
import 'package:kurichiyar_matrimony/core/models/models.dart';

class Step5MaritalHistory extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final MaritalStatus maritalStatus;
  final bool? hasChildren;
  final int childrenCount;
  final TextEditingController boysCountController;
  final TextEditingController girlsCountController;
  final ValueChanged<MaritalStatus> onMaritalStatusChanged;
  final ValueChanged<bool?> onHasChildrenChanged;

  final String? timeline;
  final bool? readyToAcceptChildren;
  final String? acceptChildrenStatus;
  final String? adoptionPreference;
  final String? willingMarryRemarriage;
  final String? firstMarriageAdoptChildren;
  final String? firstMarriageMaxChildren;

  final ValueChanged<String?> onTimelineChanged;
  final ValueChanged<bool?> onReadyToAcceptChildrenChanged;
  final ValueChanged<String?> onAcceptChildrenStatusChanged;
  final ValueChanged<String?> onAdoptionPreferenceChanged;
  final ValueChanged<String?> onWillingMarryRemarriageChanged;
  final ValueChanged<String?> onFirstMarriageAdoptChildrenChanged;
  final ValueChanged<String?> onFirstMarriageMaxChildrenChanged;

  final bool isMarketingAllowed;
  final ValueChanged<bool> onMarketingAllowedChanged;
  final VoidCallback onChildrenCountUpdated;
  final Widget Function({required Widget child}) buildCard;

  const Step5MaritalHistory({
    super.key,
    required this.formKey,
    required this.maritalStatus,
    required this.hasChildren,
    required this.childrenCount,
    required this.boysCountController,
    required this.girlsCountController,
    required this.onMaritalStatusChanged,
    required this.onHasChildrenChanged,
    required this.timeline,
    required this.readyToAcceptChildren,
    required this.acceptChildrenStatus,
    required this.adoptionPreference,
    required this.willingMarryRemarriage,
    required this.firstMarriageAdoptChildren,
    required this.firstMarriageMaxChildren,
    required this.onTimelineChanged,
    required this.onReadyToAcceptChildrenChanged,
    required this.onAcceptChildrenStatusChanged,
    required this.onAdoptionPreferenceChanged,
    required this.onWillingMarryRemarriageChanged,
    required this.onFirstMarriageAdoptChildrenChanged,
    required this.onFirstMarriageMaxChildrenChanged,
    required this.isMarketingAllowed,
    required this.onMarketingAllowedChanged,
    required this.onChildrenCountUpdated,
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
                AppLocalizations.of(context)!.step5Instruction,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.stepTitleMarital,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            SafeDropdown<MaritalStatus>(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.maritalStatus,
                border: const OutlineInputBorder(),
              ),
              initialValue: maritalStatus,
              items: [
                DropdownMenuItem(
                  value: MaritalStatus.first,
                  child: Text(AppLocalizations.of(context)!.firstMarriage),
                ),
                DropdownMenuItem(
                  value: MaritalStatus.remarriage2nd,
                  child: Text(AppLocalizations.of(context)!.remarriage2nd),
                ),
                DropdownMenuItem(
                  value: MaritalStatus.remarriage3rdPlus,
                  child: Text(AppLocalizations.of(context)!.remarriage3rd),
                ),
              ],
              onChanged: (v) {
                if (v != null) onMaritalStatusChanged(v);
              },
            ),

            if (maritalStatus != MaritalStatus.first) ...[
              const SizedBox(height: 24),
              SafeDropdown<bool>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.doYouHaveChildrenMandatory,
                  border: const OutlineInputBorder(),
                ),
                initialValue: hasChildren,
                items: [
                  DropdownMenuItem(
                    value: true,
                    child: Text(AppLocalizations.of(context)!.yesHave),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text(AppLocalizations.of(context)!.noHave),
                  ),
                ],
                validator: (v) => v == null
                    ? AppLocalizations.of(
                        context,
                      )!.pleaseSelectWhetherYouHaveChildren
                    : null,
                onChanged: onHasChildrenChanged,
              ),

              if (hasChildren == true) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: boysCountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.boysCount,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => onChildrenCountUpdated(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: girlsCountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.girlsCount,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => onChildrenCountUpdated(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.totalChildren,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '$childrenCount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SafeDropdown<bool>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.readyToAcceptChildren,
                  border: OutlineInputBorder(),
                ),
                initialValue: readyToAcceptChildren,
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
                onChanged: onReadyToAcceptChildrenChanged,
              ),
              const SizedBox(height: 16),
              SafeDropdown<String>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.acceptChildrenStatus,
                  border: OutlineInputBorder(),
                ),
                initialValue: acceptChildrenStatus,
                items:
                    ['Living with me', 'Living with partner', 'Not applicable']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: onAcceptChildrenStatusChanged,
              ),
              const SizedBox(height: 16),
              SafeDropdown<String>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.adoptionPreference,
                  border: OutlineInputBorder(),
                ),
                initialValue: adoptionPreference,
                items: ['Open to adopt', 'Not open to adopt', 'Maybe']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: onAdoptionPreferenceChanged,
              ),
            ] else ...[
              const SizedBox(height: 32),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.noChildrenHistoryRequiredForFirstMarriage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SafeDropdown<String>(
                decoration: const InputDecoration(
                  labelText:
                      'പുനർവിവാഹം ആലോചിക്കുന്നുണ്ടോ? (Open to Remarriage?)',
                  border: OutlineInputBorder(),
                  helperText:
                      'വിവാഹമോചിതരോ പങ്കാളി മരിച്ചവരോ ആയ ആലോചനകൾ സ്വീകരിക്കാൻ താല്പര്യമുണ്ടോ എന്ന് വ്യക്തമാക്കുക.',
                  helperMaxLines: 3,
                ),
                initialValue: willingMarryRemarriage,
                items: ['YES_WILLING', 'NO']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: onWillingMarryRemarriageChanged,
              ),
              if (willingMarryRemarriage == 'YES_WILLING') ...[
                const SizedBox(height: 16),
                SafeDropdown<String>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.openToAdoptingChildren,
                    border: OutlineInputBorder(),
                  ),
                  initialValue: firstMarriageAdoptChildren,
                  items: ['YES_WILLING', 'NO']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: onFirstMarriageAdoptChildrenChanged,
                ),
                if (firstMarriageAdoptChildren == 'YES_WILLING') ...[
                  const SizedBox(height: 16),
                  SafeDropdown<String>(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.maxChildrenToAdopt,
                      border: OutlineInputBorder(),
                    ),
                    initialValue: firstMarriageMaxChildren,
                    items: ['1', '2', '3+']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: onFirstMarriageMaxChildrenChanged,
                  ),
                ],
              ],
            ],

            const SizedBox(height: 32),
            SafeDropdown<String>(
              decoration: const InputDecoration(
                labelText: 'വിവാഹം നടത്താൻ ഉദ്ദേശിക്കുന്ന സമയം',
                border: OutlineInputBorder(),
                helperText:
                    'വിവാഹം എത്ര സമയത്തിനുള്ളിൽ നടത്താൻ ആഗ്രഹിക്കുന്നു എന്ന് തിരഞ്ഞെടുക്കുക.',
                helperMaxLines: 2,
              ),
              initialValue: timeline,
              items: [
                'Immediately',
                'Within 6 months',
                'Within 1 year',
                'Not decided',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: onTimelineChanged,
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.promotionalConsent,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  'പ്രൊമോഷണൽ മാർക്കറ്റിംഗ് സന്ദേശങ്ങൾ ലഭിക്കാൻ താല്പര്യമുണ്ടോ?',
                ),
                value: isMarketingAllowed,
                onChanged: onMarketingAllowedChanged,
                activeTrackColor: Colors.blue.shade200,
                activeThumbColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
