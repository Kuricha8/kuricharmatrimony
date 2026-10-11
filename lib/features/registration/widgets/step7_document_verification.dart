// ignore_for_file: library_private_types_in_public_api, deprecated_member_use
part of '../registration_wizard.dart';

class Step7DocumentVerification extends StatelessWidget {
  final _RegistrationWizardState state;
  const Step7DocumentVerification(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ഈ പ്രക്രിയ പൂർത്തിയാക്കാതെ ബാക്കിലോട്ട് പോകാൻ കഴിയില്ല',
            ),
          ),
        );
      },
      child: state._buildCard(
        child: Form(
          key: state._formKeyStep7,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    AppLocalizations.of(context)!.step7Instruction,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const Icon(Icons.security, size: 64, color: Colors.indigo),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.stepTitleIdentity,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'യൂസർമാരുടെ സുരക്ഷ ഉറപ്പാക്കുന്നതിനായി സർക്കാർ അംഗീകൃത തിരിച്ചറിയൽ രേഖ അപ്ലോഡ് ചെയ്യേണ്ടത് നിർബന്ധമാണ്.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'തിരിച്ചറിയൽ രേഖയുടെ തരം തിരഞ്ഞെടുക്കുക',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: state._idType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items:
                      [
                            'Aadhaar Card',
                            'PAN Card',
                            'Driving Licence',
                            'Voter ID',
                            'Passport',
                          ]
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      state.updateState(() => state._idType = v);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'തിരിച്ചറിയൽ നമ്പർ നൽകുക',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: state._idNumberController,
                  focusNode: state._idNumberFocus,
                  keyboardType: state._idType == 'Aadhaar Card'
                      ? TextInputType.number
                      : TextInputType.text,
                  inputFormatters: state._idType == 'Aadhaar Card'
                      ? [FilteringTextInputFormatter.digitsOnly]
                      : null,
                  maxLength: state._idType == 'Aadhaar Card' ? 12 : null,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText:
                        'Enter exact ID number or use upload to auto-scan',
                    counterText: "",
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'നമ്പറുകൾ മാത്രം നൽകുക. ശരിയായ തിരിച്ചറിയൽ നമ്പർ രേഖപ്പെടുത്തുക.';
                    }
                    if (state._idType == 'Aadhaar Card' &&
                        v.trim().length != 12) {
                      return 'നമ്പറുകൾ മാത്രം നൽകുക. ശരിയായ തിരിച്ചറിയൽ നമ്പർ രേഖപ്പെടുത്തുക.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (state._idDocumentUrl != null) ...[
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                      image: DecorationImage(
                        image: NetworkImage(state._idDocumentUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Document Uploaded ✓',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ElevatedButton.icon(
                  onPressed: state._isUploadingID
                      ? null
                      : () => state._showImageSourceActionSheet(false),
                  icon: state._isUploadingID
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    state._isUploadingID
                        ? 'Uploading...'
                        : state._idDocumentUrl == null
                        ? '📄 തിരിച്ചറിയൽ രേഖ അപ്ലോഡ് ചെയ്യുക'
                        : 'Change / Re-upload',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state._idDocumentUrl == null
                        ? Colors.indigo
                        : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                if (state._isUploadingID) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.indigo,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Compressing & Uploading ID... Please wait',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.indigo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
