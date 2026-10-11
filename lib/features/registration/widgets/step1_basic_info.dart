// ignore_for_file: library_private_types_in_public_api, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';
import 'package:kurichiyar_matrimony/core/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_number/mobile_number.dart';
import 'dart:convert';
import 'package:kurichiyar_matrimony/core/services/lead_tracking_service.dart';
import 'registration_qr_scanner_screen.dart';

class Step1BasicInfo extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController nameController;
  final TextEditingController fatherNameController;
  final TextEditingController motherNameController;
  final TextEditingController phoneController;
  final TextEditingController publicDisplayNumberController;
  final TextEditingController otpController;
  final TextEditingController dobDayController;
  final TextEditingController dobMonthController;
  final TextEditingController dobYearController;
  final FocusNode dobDayFocus;
  final FocusNode dobMonthFocus;
  final FocusNode dobYearFocus;
  final Gender gender;
  final int? exactAge;
  final bool isPhoneVerified;
  final bool isSendingOtp;
  final bool isNameLocked;
  final bool isFatherDeceased;
  final bool isMotherDeceased;
  final String simCarrier;
  final VoidCallback onEnterManualPhone;
  final VoidCallback onCalculateAge;
  final ValueChanged<Gender> onGenderChanged;
  final ValueChanged<String> onLeadCapture;
  final ValueChanged<String> onSimCarrierChanged;
  final ValueChanged<bool> onPhoneVerifiedChanged;
  final ValueChanged<bool> onSendingOtpChanged;
  final ValueChanged<bool> onFatherDeceasedChanged;
  final ValueChanged<bool> onMotherDeceasedChanged;
  final Widget Function({required Widget child}) buildCard;

  const Step1BasicInfo({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.nameController,
    required this.fatherNameController,
    required this.motherNameController,
    required this.phoneController,
    required this.publicDisplayNumberController,
    required this.otpController,
    required this.dobDayController,
    required this.dobMonthController,
    required this.dobYearController,
    required this.dobDayFocus,
    required this.dobMonthFocus,
    required this.dobYearFocus,
    required this.gender,
    this.exactAge,
    required this.isPhoneVerified,
    required this.isSendingOtp,
    this.isNameLocked = false,
    required this.simCarrier,
    this.isFatherDeceased = false,
    this.isMotherDeceased = false,
    required this.onGenderChanged,
    required this.onLeadCapture,
    required this.onSimCarrierChanged,
    required this.onPhoneVerifiedChanged,
    required this.onSendingOtpChanged,
    required this.onFatherDeceasedChanged,
    required this.onMotherDeceasedChanged,
    required this.onEnterManualPhone,
    required this.onCalculateAge,
    required this.buildCard,
  });

  @override
  State<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends State<Step1BasicInfo> {
  bool _isQrScanPopulated = false;

  @override
  Widget build(BuildContext context) {
    return widget.buildCard(
      child: Form(
        key: widget.formKey,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                AppLocalizations.of(context)!.step1Instruction,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.stepTitleBasicInfo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: widget.nameController,
              readOnly: widget.isNameLocked,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.fullName,
                border: const OutlineInputBorder(),
                filled: widget.isNameLocked,
                fillColor: widget.isNameLocked ? Colors.grey.shade200 : null,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
  { return AppLocalizations.of(context)!.requiredField; }
                if (v.trim().length < 3)
  { return 'Full name must be at least 3 characters'; }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.fatherNameController,
              decoration: const InputDecoration(
                labelText: "Father's Name",
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (widget.isFatherDeceased) return null;
                if (v == null || v.trim().isEmpty)
  { return AppLocalizations.of(context)!.requiredField; }
                return null;
              },
            ),
            Row(
              children: [
                Checkbox(
                  value: widget.isFatherDeceased,
                  onChanged: (val) {
                    if (val != null) widget.onFatherDeceasedChanged(val);
                  },
                ),
                const Text('Late (Deceased)'),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.motherNameController,
              decoration: const InputDecoration(
                labelText: "Mother's Name",
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (widget.isMotherDeceased) return null;
                if (v == null || v.trim().isEmpty)
  { return AppLocalizations.of(context)!.requiredField; }
                return null;
              },
            ),
            Row(
              children: [
                Checkbox(
                  value: widget.isMotherDeceased,
                  onChanged: (val) {
                    if (val != null) widget.onMotherDeceasedChanged(val);
                  },
                ),
                const Text('Late (Deceased)'),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              readOnly: _isQrScanPopulated,
              enableInteractiveSelection: !_isQrScanPopulated,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.emailAddress,
                border: const OutlineInputBorder(),
                filled: _isQrScanPopulated,
                fillColor: _isQrScanPopulated ? Colors.green.shade50 : null,
                suffixIcon: _isQrScanPopulated
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(Icons.lock, color: Colors.green),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.indigo,
                        ),
                        tooltip: 'Scan QR Code for Email & Password',
                        onPressed: () async {
                          final result = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const RegistrationQrScannerScreen(),
                            ),
                          );
                          if (result != null && result.isNotEmpty) {
                            try {
                              final data = jsonDecode(result);
                              if (data is Map) {
                                final emailVal =
                                    (data['e'] ?? data['email'] ?? '')
                                        .toString()
                                        .trim();
                                final passVal =
                                    (data['p'] ?? data['password'] ?? '')
                                        .toString()
                                        .trim();
                                final confirmPassVal =
                                    (data['cp'] ??
                                            data['confirm_password'] ??
                                            data['confirmPassword'] ??
                                            passVal)
                                        .toString()
                                        .trim();

                                if (emailVal.isNotEmpty)
  { widget.emailController.text = emailVal; }
                                if (passVal.isNotEmpty)
  { widget.passwordController.text = passVal; }
                                if (confirmPassVal.isNotEmpty) {
                                  widget.confirmPasswordController.text =
                                      confirmPassVal;
                                }
                              }
                            } catch (e) {
                              if (result.contains(',')) {
                                final parts = result.split(',');
                                if (parts.isNotEmpty)
  { widget.emailController.text = parts[0].trim(); }
                                if (parts.length > 1) {
                                  widget.passwordController.text = parts[1]
                                      .trim();
                                }
                                if (parts.length > 2) {
                                  widget.confirmPasswordController.text =
                                      parts[2].trim();
                                } else if (parts.length > 1) {
                                  widget.confirmPasswordController.text =
                                      parts[1].trim();
                                }
                              } else if (result.contains(':')) {
                                final parts = result.split(':');
                                if (parts.isNotEmpty)
  { widget.emailController.text = parts[0].trim(); }
                                if (parts.length > 1) {
                                  widget.passwordController.text = parts[1]
                                      .trim();
                                }
                                if (parts.length > 2) {
                                  widget.confirmPasswordController.text =
                                      parts[2].trim();
                                } else if (parts.length > 1) {
                                  widget.confirmPasswordController.text =
                                      parts[1].trim();
                                }
                              } else {
                                widget.emailController.text = result.trim();
                              }
                            }

                            setState(() {
                              _isQrScanPopulated = true;
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Agent QR scanned successfully! Credentials locked & protected.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                      ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
  { return AppLocalizations.of(context)!.emailIsRequired; }
                if (!RegExp(
                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                ).hasMatch(v.trim()))
  { return AppLocalizations.of(context)!.enterAValidEmailAddress; }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _PasswordInputField(
              controller: widget.passwordController,
              labelText: AppLocalizations.of(context)!.password,
              readOnly: _isQrScanPopulated,
              hideVisibilityToggle: _isQrScanPopulated,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  v == null || v.trim().isEmpty || v.trim().length < 6
                  ? AppLocalizations.of(
                      context,
                    )!.passwordMustBeAtLeast6Characters
                  : null,
            ),
            const SizedBox(height: 16),
            _PasswordInputField(
              controller: widget.confirmPasswordController,
              labelText: AppLocalizations.of(context)!.confirmPassword,
              readOnly: _isQrScanPopulated,
              hideVisibilityToggle: _isQrScanPopulated,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return AppLocalizations.of(
                    context,
                  )!.confirmPasswordIsRequired;
                }
                if (v.trim() != widget.passwordController.text.trim())
  { return AppLocalizations.of(context)!.passwordsDoNotMatch; }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dual-Mode Phone Number Field (Direct Typing + SIM Auto-Fetch)
            TextFormField(
              controller: widget.phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (v) {
                final clean = v.replaceAll(RegExp(r'\D'), '');
                if (clean.length == 10 &&
                    RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
                  widget.onPhoneVerifiedChanged(true);
                } else {
                  widget.onPhoneVerifiedChanged(false);
                }
              },
              decoration: InputDecoration(
                labelText: 'Mobile / Phone Number / ഫോൺ നമ്പർ',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                prefixText: '+91 ',
                prefixStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                counterText: '',
                helperText:
                    'Type 10-digit mobile number or tap SIM icon to select',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (RegExp(r'^[6-9]\d{9}$').hasMatch(
                      widget.phoneController.text.replaceAll(RegExp(r'\D'), ''),
                    ))
                      const Padding(
                        padding: EdgeInsets.only(right: 4.0),
                        child: Icon(Icons.check_circle, color: Colors.green),
                      ),
                    IconButton(
                      icon: const Icon(Icons.sim_card, color: Colors.indigo),
                      tooltip: 'Auto-fill from SIM / Phone Hint',
                      onPressed: () async {
                        bool hasPermission =
                            await MobileNumber.hasPhonePermission;
                        if (!hasPermission) {
                          await MobileNumber.requestPhonePermission;
                          hasPermission = await MobileNumber.hasPhonePermission;
                        }

                        List<SimCard> simCards = [];
                        if (hasPermission) {
                          try {
                            simCards = (await MobileNumber.getSimCards) ?? [];
                          } catch (e) {
                            debugPrint('Mobile number fetch error: $e');
                          }
                        }

                        if (!context.mounted) return;

                        final selectedSim =
                            await showModalBottomSheet<Map<String, String>>(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              builder: (ctx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.selectSimForRegistration,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (simCards.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.noSimCardsDetected,
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      )
                                    else
                                      ...simCards.map(
                                        (sim) => ListTile(
                                          leading: const Icon(
                                            Icons.sim_card,
                                            color: Colors.blue,
                                          ),
                                          title: Text(
                                            sim.carrierName ??
                                                AppLocalizations.of(
                                                  context,
                                                )!.unknownCarrier,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            sim.number ??
                                                AppLocalizations.of(
                                                  context,
                                                )!.unknownNumber,
                                          ),
                                          onTap: () {
                                            if (sim.number != null &&
                                                sim.number!.isNotEmpty) {
                                              Navigator.pop(ctx, {
                                                'carrier':
                                                    sim.carrierName ?? 'SIM',
                                                'phone': sim.number!,
                                              });
                                            } else {
                                              ScaffoldMessenger.of(
                                                ctx,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.phoneNumberNotStored,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.edit,
                                        color: Colors.grey,
                                      ),
                                      title: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.enterMobileNumberManually,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onTap: () => Navigator.pop(ctx, {
                                        'carrier': 'Manual',
                                        'phone': '',
                                      }),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            );

                        if (selectedSim == null) return;
                        final displayPhone = selectedSim['phone']!.replaceAll(
                          RegExp(r'\D'),
                          '',
                        );
                        final clean10 = displayPhone.length > 10
                            ? displayPhone.substring(displayPhone.length - 10)
                            : displayPhone;

                        if (clean10.isNotEmpty) {
                          widget.phoneController.text = clean10;
                          widget.onSimCarrierChanged(selectedSim['carrier']!);
                          widget.onPhoneVerifiedChanged(true);
                          LeadTrackingService.instance.trackLeadInput(
                            phone: clean10,
                            name: widget.nameController.text,
                            currentStep: 1,
                          );

                          try {
                            final name = widget.nameController.text.trim();
                            final res = await Supabase.instance.client
                                .from('incomplete_registrations')
                                .insert({
                                  'full_name': name.isNotEmpty
                                      ? name
                                      : 'Anonymous',
                                  'phone_number': clean10,
                                  'verification_status': 'Pending',
                                })
                                .select('id')
                                .maybeSingle();
                            if (res != null) {
                              widget.onLeadCapture(res['id'] as String);
                            }
                          } catch (e) {
                            debugPrint('Lead capture error: $e');
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Phone number populated from SIM selection!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
  { return 'Mobile phone number is required'; }
                final clean = v.replaceAll(RegExp(r'\D'), '');
                if (clean.length != 10)
  { return 'Enter a valid 10-digit mobile number'; }
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean))
  { return 'Must be a valid Indian mobile number starting with 6-9'; }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 3-Block Manual DOB input fields
            Text(
              AppLocalizations.of(context)!.selectDob,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Day block
                Expanded(
                  child: TextFormField(
                    controller: widget.dobDayController,
                    focusNode: widget.dobDayFocus,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Day (DD)',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (val) {
                      if (val.length == 2) {
                        widget.dobMonthFocus.requestFocus();
                      }
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final day = int.tryParse(v.trim());
                      if (day == null || day < 1 || day > 31)
  { return 'Invalid (1-31)'; }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Month block
                Expanded(
                  child: TextFormField(
                    controller: widget.dobMonthController,
                    focusNode: widget.dobMonthFocus,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Month (MM)',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (val) {
                      if (val.length == 2) {
                        widget.dobYearFocus.requestFocus();
                      } else if (val.isEmpty) {
                        widget.dobDayFocus.requestFocus();
                      }
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final month = int.tryParse(v.trim());
                      if (month == null || month < 1 || month > 12)
  { return 'Invalid (1-12)'; }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Year block
                Expanded(
                  child: TextFormField(
                    controller: widget.dobYearController,
                    focusNode: widget.dobYearFocus,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Year (YYYY)',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (val) {
                      if (val.isEmpty) {
                        widget.dobMonthFocus.requestFocus();
                      }
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final year = int.tryParse(v.trim());
                      final currentYear = DateTime.now().year;
                      if (year == null ||
                          year < 1940 ||
                          year > currentYear - 20) {
                        return 'Must be at least 20 years old';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 16,
              children: [
                // Gender Section (Left Side)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.genderMaleFemale,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Radio<Gender>(
                          value: Gender.male,
                          groupValue: widget.gender,
                          onChanged: (v) => widget.onGenderChanged(v!),
                        ),
                        Text(AppLocalizations.of(context)!.genderMale),
                        const SizedBox(width: 8),
                        Radio<Gender>(
                          value: Gender.female,
                          groupValue: widget.gender,
                          onChanged: (v) => widget.onGenderChanged(v!),
                        ),
                        Text(AppLocalizations.of(context)!.genderFemale),
                      ],
                    ),
                  ],
                ),
                // Age Display (Right Side, below Year box)
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
                  child: Text(
                    widget.exactAge != null
                        ? 'Age: ${widget.exactAge}'
                        : 'Age: --',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.gender == Gender.female) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.publicDisplayNumberController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText:
                      'Public Display Number (WhatsApp / Guardian) / പബ്ലിക് ഡിസ്പ്ലേ നമ്പർ',
                  prefixIcon: Icon(Icons.contact_phone),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  if (widget.gender != Gender.female) return null;
                  if (v == null || v.trim().isEmpty)
  { return 'Public display number is required'; }
                  final clean = v.replaceAll(RegExp(r'\D'), '');
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean))
  { return 'Enter valid 10-digit Indian mobile number'; }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool hideVisibilityToggle;

  const _PasswordInputField({
    required this.controller,
    required this.labelText,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.hideVisibilityToggle = false,
  });

  @override
  State<_PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<_PasswordInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final bool isLocked = widget.readOnly || widget.hideVisibilityToggle;
    final bool effectiveObscure = isLocked ? true : _obscureText;

    return TextFormField(
      controller: widget.controller,
      obscureText: effectiveObscure,
      readOnly: isLocked,
      enableInteractiveSelection: !isLocked,
      onChanged: widget.onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        suffixIcon: isLocked
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(Icons.lock, color: Colors.green),
              )
            : IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
      ),
      validator: widget.validator,
    );
  }
}
