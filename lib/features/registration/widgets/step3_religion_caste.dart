import 'package:flutter/material.dart';
import 'package:kurichiyar_matrimony/core/services/digipin_service.dart';
import 'package:kurichiyar_matrimony/features/registration/widgets/safe_dropdown.dart';
import '../../../core/models/models.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';

class Step3ReligionCaste extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Widget Function({required Widget child}) buildCard;
  final Gender gender;
  final String? motherTongue;
  final List<String> languagesKnown;
  final String? coreValues;
  final TextEditingController? digipinController;
  final TextEditingController pincodeController;
  final TextEditingController? districtController;
  final TextEditingController? talukController;
  final TextEditingController? panchayathController;
  final TextEditingController? postOfficeController;
  final TextEditingController aboutMeController;
  final List<String> postOffices;
  final String? postOffice;
  final String? taluk;
  final String? district;
  final String? panchayath;
  final String? groomStayWifeHouse;
  final String? brideHusbandStayHome;

  final ValueChanged<String?> onMotherTongueChanged;
  final ValueChanged<List<String>> onLanguagesKnownChanged;
  final ValueChanged<String?> onCoreValuesChanged;
  final ValueChanged<String>? onDigipinChanged;
  final ValueChanged<String> onPincodeChanged;
  final ValueChanged<String?> onPostOfficeChanged;
  final ValueChanged<String>? onDistrictChanged;
  final ValueChanged<String>? onTalukChanged;
  final ValueChanged<String>? onPanchayathChanged;
  final ValueChanged<String?> onGroomStayChanged;
  final ValueChanged<String?> onBrideStayChanged;

  const Step3ReligionCaste({
    super.key,
    required this.formKey,
    required this.buildCard,
    required this.gender,
    required this.motherTongue,
    required this.languagesKnown,
    required this.coreValues,
    this.digipinController,
    required this.pincodeController,
    this.districtController,
    this.talukController,
    this.panchayathController,
    this.postOfficeController,
    required this.aboutMeController,
    required this.postOffices,
    required this.postOffice,
    required this.taluk,
    required this.district,
    this.panchayath,
    required this.groomStayWifeHouse,
    required this.brideHusbandStayHome,
    required this.onMotherTongueChanged,
    required this.onLanguagesKnownChanged,
    required this.onCoreValuesChanged,
    this.onDigipinChanged,
    required this.onPincodeChanged,
    required this.onPostOfficeChanged,
    this.onDistrictChanged,
    this.onTalukChanged,
    this.onPanchayathChanged,
    required this.onGroomStayChanged,
    required this.onBrideStayChanged,
  });

  @override
  State<Step3ReligionCaste> createState() => _Step3ReligionCasteState();
}

class _Step3ReligionCasteState extends State<Step3ReligionCaste> {
  late final TextEditingController _digipinController;
  late final TextEditingController _districtController;
  late final TextEditingController _talukController;
  late final TextEditingController _panchayathController;
  late final TextEditingController _postOfficeController;
  bool _isLocatingDigipin = false;

  @override
  void initState() {
    super.initState();
    _digipinController = widget.digipinController ?? TextEditingController();
    _districtController = widget.districtController ?? TextEditingController(text: widget.district ?? '');
    _talukController = widget.talukController ?? TextEditingController(text: widget.taluk ?? '');
    _panchayathController = widget.panchayathController ?? TextEditingController(text: widget.panchayath ?? '');
    _postOfficeController = widget.postOfficeController ?? TextEditingController(text: widget.postOffice ?? '');

    if (_districtController.text.isEmpty && widget.district != null) {
      _districtController.text = widget.district!;
    }
    if (_talukController.text.isEmpty && widget.taluk != null) {
      _talukController.text = widget.taluk!;
    }
    if (_panchayathController.text.isEmpty && widget.panchayath != null) {
      _panchayathController.text = widget.panchayath!;
    }
    if (_postOfficeController.text.isEmpty && widget.postOffice != null) {
      _postOfficeController.text = widget.postOffice!;
    }

    // Auto-fetch high accuracy GPS DIGIPIN on screen load if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_digipinController.text.trim().isEmpty) {
        _autoFetchDigipin(showSnackBar: false);
      }
    });
  }

  @override
  void didUpdateWidget(Step3ReligionCaste oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.district != null && widget.district!.isNotEmpty && _districtController.text != widget.district) {
      _districtController.text = widget.district!;
    }
    if (widget.taluk != null && widget.taluk!.isNotEmpty && _talukController.text != widget.taluk) {
      _talukController.text = widget.taluk!;
    }
    if (widget.panchayath != null && widget.panchayath!.isNotEmpty && _panchayathController.text != widget.panchayath) {
      _panchayathController.text = widget.panchayath!;
    }
    if (widget.postOffice != null && widget.postOffice!.isNotEmpty && _postOfficeController.text != widget.postOffice) {
      _postOfficeController.text = widget.postOffice!;
    }
  }

  Future<void> _autoFetchDigipin({bool showSnackBar = true}) async {
    if (_isLocatingDigipin) return;
    setState(() => _isLocatingDigipin = true);

    try {
      final pin = await DigiPinService.fetchCurrentDigiPin(context: context);
      if (pin != null && pin.isNotEmpty && mounted) {
        setState(() {
          _digipinController.text = pin;
        });
        widget.onDigipinChanged?.call(pin);
      }
    } catch (e) {
      debugPrint('Auto DIGIPIN error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLocatingDigipin = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.buildCard(
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction Subtitle
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text(
                "നിങ്ങളുടെ നിലവിലെ സ്ഥലവിവരങ്ങളും താമസ സൗകര്യത്തെക്കുറിച്ചുള്ള താല്പര്യങ്ങളും താഴെ നൽകുക.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            // Fixed Step 3 Heading
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF1E3A8A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "ഘട്ടം 3: ലൊക്കേഷൻ & താമസ സൗകര്യങ്ങൾ",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              "സ്മാർട്ട് ലൊക്കേഷൻ (Smart Location)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),

            // 1. DIGIPIN Field (Editable + GPS Auto-fill)
            TextFormField(
              key: const ValueKey('DIGIPIN_FIELD'),
              controller: _digipinController,
              readOnly: false,
              textCapitalization: TextCapitalization.characters,
              maxLength: 12,
              decoration: InputDecoration(
                labelText: 'ഡിജിപിൻ (DIGIPIN - ഓപ്ഷണൽ)',
                hintText: 'ഉദാ: 4MP-K6P-J5L3',
                helperText:
                    'വീട്ടിലിരുന്നാണ് രജിസ്റ്റർ ചെയ്യുന്നതെങ്കിൽ GPS ബട്ടൺ അമർത്തുക, അല്ലെങ്കിൽ വീടിന്റെ DIGIPIN നൽകുക',
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                prefixIcon: const Icon(
                  Icons.qr_code_2,
                  color: Color(0xFF1E3A8A),
                ),
                suffixIcon: _isLocatingDigipin
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.my_location,
                          color: Color(0xFF1E3A8A),
                        ),
                        tooltip: 'നിലവിലെ GPS ലൊക്കേഷൻ എടുക്കുക',
                        onPressed: () => _autoFetchDigipin(showSnackBar: true),
                      ),
              ),
              onChanged: (val) {
                widget.onDigipinChanged?.call(val.trim().toUpperCase());
              },
            ),
            const SizedBox(height: 16),

            // 2. Postal Pincode Field (6-digit auto-fetch)
            TextFormField(
              key: const ValueKey('PINCODE_FIELD'),
              controller: widget.pincodeController,
              decoration: const InputDecoration(
                labelText: 'പിൻകോഡ് (Pincode) *',
                hintText: '6 അക്ക പിൻകോഡ് നൽകുക',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin_drop_outlined),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: widget.onPincodeChanged,
              validator: (v) {
                final trimmed = v?.trim() ?? '';
                if (trimmed.isEmpty || trimmed.length != 6) {
                  return 'ശരിയായ 6 അക്ക പിൻകോഡ് നൽകുക';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // 3. Area / Post Office Dropdown
            if (widget.postOffices.isNotEmpty)
              SafeDropdown<String>(
                key: const ValueKey('POST_OFFICE'),
                decoration: const InputDecoration(
                  labelText: 'പോസ്റ്റ് ഓഫീസ് / പ്രദേശം *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                initialValue: widget.postOffice,
                items: widget.postOffices
                    .map(
                      (po) => DropdownMenuItem(
                        value: po,
                        child: Text(po, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  _postOfficeController.text = val ?? '';
                  widget.onPostOfficeChanged(val);
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'പോസ്റ്റ് ഓഫീസ് തിരഞ്ഞെടുക്കുക' : null,
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "പോസ്റ്റ് ഓഫീസ് വിവരങ്ങൾ വരാൻ 6 അക്ക പിൻകോഡ് നൽകുക",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // 4. Panchayath Field (Auto-filled / Editable)
            TextFormField(
              key: const ValueKey('PANCHAYATH_FIELD'),
              controller: _panchayathController,
              decoration: const InputDecoration(
                labelText: 'പഞ്ചായത്ത് (Grama Panchayath)',
                hintText: 'പഞ്ചായത്ത് നൽകുക',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onChanged: (val) {
                widget.onPanchayathChanged?.call(val.trim());
              },
            ),
            const SizedBox(height: 14),

            // 5. Taluk Field (Auto-filled / Editable)
            TextFormField(
              key: const ValueKey('TALUK_FIELD'),
              controller: _talukController,
              decoration: const InputDecoration(
                labelText: 'താലൂക്ക് / സബ് ഡിസ്ട്രിക്റ്റ് (Taluk)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map_outlined),
              ),
              onChanged: (val) {
                widget.onTalukChanged?.call(val.trim());
              },
            ),
            const SizedBox(height: 14),

            // 6. District Field (Auto-filled / Editable)
            TextFormField(
              key: const ValueKey('DISTRICT_FIELD'),
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: 'ജില്ല (District)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.holiday_village_outlined),
              ),
              onChanged: (val) {
                widget.onDistrictChanged?.call(val.trim());
              },
            ),

            const SizedBox(height: 24),
            const Text(
              "താമസ സൗകര്യ മുൻഗണനകൾ (Living Preferences)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 7. Living Preferences for Groom / Bride
            if (widget.gender == Gender.male) ...[
              SafeDropdown<String>(
                key: const ValueKey('MALE_LIVING_PREFERENCE'),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.willingToStayAtWifesHouse,
                  border: const OutlineInputBorder(),
                  helperText: AppLocalizations.of(
                    context,
                  )!.residencePreferenceHelperText,
                  helperMaxLines: 4,
                ),
                initialValue: widget.groomStayWifeHouse,
                items: [
                  DropdownMenuItem(
                    value: 'YES',
                    child: Text(
                      AppLocalizations.of(context)!.residencePrefWifeHouse,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'NO',
                    child: Text(
                      AppLocalizations.of(context)!.residencePrefOwnHouse,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'DEPENDS',
                    child: Text(
                      AppLocalizations.of(context)!.residencePrefFlexible,
                    ),
                  ),
                ],
                onChanged: widget.onGroomStayChanged,
                validator: (v) => v == null ? 'Required' : null,
              ),
            ],

            if (widget.gender == Gender.female)
              SafeDropdown<String>(
                key: const ValueKey('FEMALE_LIVING_PREFERENCE'),
                decoration: const InputDecoration(
                  labelText: "ഭർത്താവിന്റെ വീട്ടിൽ താമസിക്കാൻ താല്പര്യമുണ്ടോ?",
                  border: OutlineInputBorder(),
                ),
                initialValue: widget.brideHusbandStayHome,
                items: ['YES', 'NO', 'PREFER INDEPENDENT LIVING']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: widget.onBrideStayChanged,
                validator: (v) => v == null ? 'Required' : null,
              ),
          ],
        ),
      ),
    );
  }
}
