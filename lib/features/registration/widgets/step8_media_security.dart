// ignore_for_file: library_private_types_in_public_api, deprecated_member_use
part of '../registration_wizard.dart';

class Step8MediaSecurity extends StatelessWidget {
  final _RegistrationWizardState state;
  const Step8MediaSecurity(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return state._buildCard(
      child: Form(
        key: state._formKeyStep8,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: const Text(
                  'നിങ്ങളുടെ വ്യക്തമായ ഫോട്ടോയും സുരക്ഷാ വിവരങ്ങളും നൽകുക.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.stepTitleMedia,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (state._profilePhotoError != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state._profilePhotoError!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Center(
                child: GestureDetector(
                  onTap: state._isUploadingProfile
                      ? null
                      : () => state._showImageSourceActionSheet(true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            (state._profilePhotoError != null &&
                                !state.hasSelectedPhoto)
                            ? Colors.red.shade400
                            : (state.hasSelectedPhoto
                                  ? const Color(0xFF000080)
                                  : Colors.grey.shade300),
                        width:
                            (state._profilePhotoError != null &&
                                !state.hasSelectedPhoto)
                            ? 2.5
                            : (state.hasSelectedPhoto ? 2.5 : 1.5),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: state._profilePhotoLocalPath != null
                          ? FileImage(File(state._profilePhotoLocalPath!))
                                as ImageProvider
                          : (state._profilePhotoUrl != null
                                ? (state._profilePhotoUrl!.startsWith('http')
                                          ? NetworkImage(
                                              state._profilePhotoUrl!,
                                            )
                                          : FileImage(
                                              File(state._profilePhotoUrl!),
                                            ))
                                      as ImageProvider
                                : null),
                      child: state._isUploadingProfile
                          ? const CircularProgressIndicator()
                          : (!state.hasSelectedPhoto)
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppLocalizations.of(context)!.tapToUploadPrimaryPhoto,
                ),
              ),

              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Can we use your photo for social media advertisements?\n(നിങ്ങളുടെ ഫോട്ടോ സോഷ്യൽ മീഡിയ പരസ്യങ്ങൾക്കായി ഉപയോഗിക്കാൻ അനുവദിക്കാമോ?)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            value: true,
                            groupValue: state._isMarketingAllowed,
                            title: const Text(
                              "Yes (അതെ)",
                              style: TextStyle(fontSize: 13),
                            ),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) =>
                                _handleConsentChange(context, val),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            value: false,
                            groupValue: state._isMarketingAllowed,
                            title: const Text(
                              "No (ഇല്ല)",
                              style: TextStyle(fontSize: 13),
                            ),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) =>
                                _handleConsentChange(context, val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleConsentChange(BuildContext context, bool? value) {
    if (value == true) {
      if (!state.hasSelectedPhoto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please upload a profile photo first! (ആദ്യം ഒരു പ്രൊഫൈൽ ഫോട്ടോ അപ്‌ലോഡ് ചെയ്യുക!)',
            ),
          ),
        );
        return;
      }
      state.updateState(() {
        state._isMarketingAllowed = true;
      });
      _showAdPreviewDialog(context);
    } else {
      state.updateState(() {
        state._isMarketingAllowed = false;
      });
    }
  }

  void _showAdPreviewDialog(BuildContext context) {
    final fullName = state._nameController.text.trim();
    final age = state._dob != null
        ? (DateTime.now().year - state._dob!.year).toString()
        : '25';
    final careerSector = state._careerSector ?? '';
    final careerDetail = state._careerDetailController.text.trim();

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

    final localizedSector = careerLabels[careerSector] ?? careerSector;

    String occupation = '';
    if (careerSector == 'Business' || careerSector == 'Others') {
      occupation = careerDetail.isNotEmpty ? careerDetail : localizedSector;
    } else {
      occupation = [
        localizedSector,
        careerDetail,
      ].where((s) => s.trim().isNotEmpty).join(' - ');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              color: const Color(
                0xFFF9F4EB,
              ), // ട്രഡീഷണൽ വുഡൻ/ക്രീം ബാക്ക്ഗ്രൗണ്ട്
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. ഏറ്റവും മുകളിലെ ലോഗോയും ആപ്പ് പേരും
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Color(0xFFC0392B),
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Kurichar Matrimony",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B2500),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 2. മലയാളം ഹെഡ്ലൈൻ
                      const Text(
                        "നിങ്ങളുടെ അനുയോജ്യമായ\nജീവിതപങ്കാളിയെ കണ്ടെത്തൂ",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB71C1C),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. ഫ്രെയിമിലുള്ള പ്രൊഫൈൽ ഫോട്ടോ
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFB8860B), // ഗോൾഡൻ ബോർഡർ
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: state._profilePhotoLocalPath != null
                              ? FileImage(File(state._profilePhotoLocalPath!))
                                    as ImageProvider
                              : (state._profilePhotoUrl != null
                                    ? (state._profilePhotoUrl!.startsWith(
                                                'http',
                                              )
                                              ? NetworkImage(
                                                  state._profilePhotoUrl!,
                                                )
                                              : FileImage(
                                                  File(state._profilePhotoUrl!),
                                                ))
                                          as ImageProvider
                                    : null),
                          child:
                              (state._profilePhotoLocalPath == null &&
                                  state._profilePhotoUrl == null)
                              ? const Icon(
                                  Icons.person,
                                  size: 65,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. പേര്, വയസ്സ്, ജോലി
                      Text(
                        fullName.isNotEmpty ? fullName : "User Name",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "വയസ്സ്: $age  |  ജോലി: ${occupation.trim().isNotEmpty ? occupation.trim() : "വിവരങ്ങൾ ലഭ്യമല്ല"}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 5. ആപ്പ് ഇൻസ്റ്റാൾ ചെയ്യാനുള്ള മെസ്സേജ് ബോക്സ്
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: const Text(
                          "കൂടുതൽ വിവരങ്ങൾ അറിയാൻ ഇപ്പോൾ\nതന്നെ ഞങ്ങളുടെ ആപ്പ് ഇൻസ്റ്റാൾ ചെയ്യൂ!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B5E20),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 6. QR Code & Website Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: QrImageView(
                              data: "https://kuricharmatrimony.vercel.app",
                              version: QrVersions.auto,
                              size: 64,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "സ്കാൻ ചെയ്ത്\nഡൗൺലോഡ് ചെയ്യുക",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF37474F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "സന്ദർശിക്കുക: kuricharmatrimony.vercel.app",
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF616161),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // 7. ആക്ഷൻ ബട്ടണുകൾ (റദ്ദാക്കുക & സ്ഥിരീകരിക്കുക)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF0D1B2A),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                state.updateState(() {
                                  state._isMarketingAllowed = false;
                                });
                              },
                              child: const Text(
                                "റദ്ദാക്കുക\n(Cancel)",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF0D1B2A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC0392B),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                // already set to true in _handleConsentChange
                              },
                              child: const Text(
                                "സ്ഥിരീകരിക്കുക\n(Confirm)",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
