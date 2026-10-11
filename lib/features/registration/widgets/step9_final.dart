// ignore_for_file: library_private_types_in_public_api, deprecated_member_use
part of '../registration_wizard.dart';

class Step9Final extends StatelessWidget {
  final _RegistrationWizardState state;
  const Step9Final(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return state._buildCard(
      child: Form(
        key: state._formKeyStep9,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                AppLocalizations.of(context)!.step9Instruction,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const Icon(Icons.verified_user, size: 64, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.stepTitleFinal,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // --- BIO SECTION ---
            Text(
              OnboardingLocalizer.translate(context, 'About Me / Bio'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('ABOUT_ME_FIELD'),
              controller: state._aboutMeController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: OnboardingLocalizer.translate(context, 'About Me'),
                border: const OutlineInputBorder(),
                hintText:
                    '\u0D28\u0D3F\u0D19\u0D4D\u0D19\u0D3C\u0D46\u0D15\u0D4D\u0D15\u0D41\u0D31\u0D3F\u0D1A\u0D4D\u0D1A\u0D4D \u0D32\u0D3E\u0D33\u0D3F\u0D24\u0D2E\u0D3E\u0D2F\u0D3F \u0D35\u0D3F\u0D35\u0D30\u0D3F\u0D15\u0D4D\u0D15\u0D41\u0D15...',
              ),
            ),

            // --- PRIVACY SECTION ---
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.privacySettings,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        AppLocalizations.of(context)!.hideProfilePaid,
                      ),
                      subtitle: Text(
                        '${AppLocalizations.of(context)!.fee} \u20B9${state._privacyFee}',
                      ),
                      value: state._isProfileHiddenPaid,
                      onChanged: (val) {
                        if (val) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (ctx) => _SimulatedPaymentSheet(
                              amount: state._privacyFee,
                              onSuccess: () {
                                Navigator.pop(ctx);
                                state.updateState(() {
                                  state._isProfileHiddenPaid = true;
                                  state._hideContactInfo = true;
                                  state._saveDraft();
                                });
                              },
                              onFailure: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Payment Failed. Profile will remain visible.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                state.updateState(() {
                                  state._isProfileHiddenPaid = false;
                                  state._hideContactInfo = false;
                                  state._saveDraft();
                                });
                              },
                            ),
                          );
                        } else {
                          state.updateState(() {
                            state._isProfileHiddenPaid = false;
                            state._hideContactInfo = false;
                            state._saveDraft();
                          });
                        }
                      },
                      activeColor: const Color(0xFF000080),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(
                context,
              )!.ifYouAreGuidedByALocalAgentEnterTheirReferenceCodeBelowProfilesWithAnAgentCodeAreProcessedFasterThroughTheLocalAgentDashboard,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: state._agentCodeController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                )!.agentReferenceCodeOptional,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 32),

            // --- LEGAL DECLARATION CHECKLIST ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Legal Declaration Checklist / സത്യവാങ്മൂലം',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegalCheckbox(
              context,
              value: state._legalCheck1,
              onChanged: (val) => state.updateState(() {
                state._legalCheck1 = val ?? false;
              }),
              enText:
                  '1. I certify that all details provided (Age, Education, Occupation, Marital Status) are 100% accurate and true.',
              mlText:
                  '(ഈ പ്രൊഫൈലിൽ ഞാൻ നൽകിയിരിക്കുന്ന എല്ലാ വിവരങ്ങളും 100% സത്യസന്ധവും കൃത്യവുമാണെന്ന് ഞാൻ സാക്ഷ്യപ്പെടുത്തുന്നു.)',
            ),
            _buildLegalCheckbox(
              context,
              value: state._legalCheck2,
              onChanged: (val) => state.updateState(() {
                state._legalCheck2 = val ?? false;
              }),
              enText:
                  '2. I agree that verifying the background of profiles found through this app is my sole responsibility.',
              mlText:
                  '(ഈ ആപ്പ് വഴി കണ്ടെത്തുന്ന ആലോചനകളുടെ പശ്ചാത്തലം നേരിട്ട് അന്വേഷിച്ച് ബോധ്യപ്പെടേണ്ടത് എന്റെ മാത്രം ഉത്തരവാദിത്തമാണെന്ന് ഞാൻ സമ്മതിക്കുന്നു.)',
            ),
            _buildLegalCheckbox(
              context,
              value: state._legalCheck3,
              onChanged: (val) => state.updateState(() {
                state._legalCheck3 = val ?? false;
              }),
              enText:
                  '3. I promise not to misuse or misappropriate any data or phone numbers of other members.',
              mlText:
                  '(മറ്റ് അംഗങ്ങളുടെ വിവരങ്ങളോ ഫോൺ നമ്പറോ ഞാൻ ദുരുപയോഗം ചെയ്യുകയോ ദുരുദ്ദേശത്തോടെ ഉപയോഗിക്കുകയോ ഇല്ല എന്ന് ഉറപ്പുനൽകുന്നു.)',
            ),
            _buildLegalCheckbox(
              context,
              value: state._legalCheck4,
              onChanged: (val) => state.updateState(() {
                state._legalCheck4 = val ?? false;
              }),
              enText:
                  '4. I explicitly accept and bind myself to the full Terms & Conditions and Privacy Policy of Kurichiyar Matrimony.',
              mlText:
                  '(കുറിച്ചിയർ മാട്രിമോണിയുടെ ഔദ്യോഗിക നിയമ വ്യവസ്ഥകളും സ്വകാര്യതാ നയങ്ങളും ഞാൻ പൂർണ്ണമായി വായിച്ചു മനസ്സിലാക്കി അംഗീകരിക്കുന്നു.)',
            ),

            const SizedBox(height: 32),
            if (MockData().currentUser?.isAgent == true)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/agent_qr_scanner');
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(
                  AppLocalizations.of(context)!.scanUserQrCodeToFinalize,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade900,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SimulatedPaymentSheet extends StatelessWidget {
  final double amount;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;

  const _SimulatedPaymentSheet({
    required this.amount,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payment, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'Complete Payment of ₹${amount.toInt()}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This is a simulated payment gateway.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onSuccess,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'Simulate Success',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onFailure,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'Simulate Failure',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

Widget _buildLegalCheckbox(
  BuildContext context, {
  required bool value,
  required ValueChanged<bool?> onChanged,
  required String enText,
  required String mlText,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: value, onChanged: onChanged, activeColor: Colors.green),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mlText,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
