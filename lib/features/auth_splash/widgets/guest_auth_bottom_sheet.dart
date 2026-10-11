import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/utils/agent_qr_crypto.dart';
import '../../auth/login_page.dart';
import '../../../core/services/registration_route_helper.dart';

class GuestAuthBottomSheet extends StatefulWidget {
  final bool isSignUpMode;
  final bool isMalayalam;

  const GuestAuthBottomSheet({
    super.key,
    this.isSignUpMode = false,
    this.isMalayalam = false,
  });

  static void show(
    BuildContext context, {
    bool isSignUpMode = true,
    bool isMalayalam = true,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => GuestAuthBottomSheet(
        isSignUpMode: isSignUpMode,
        isMalayalam: isMalayalam,
      ),
    );
  }

  @override
  State<GuestAuthBottomSheet> createState() => _GuestAuthBottomSheetState();
}

class _GuestAuthBottomSheetState extends State<GuestAuthBottomSheet> {
  Future<void> _showQrGenerationDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPayload = prefs.getString('agent_qr_payload');
    final savedPin = prefs.getString('agent_qr_pin');

    if (!mounted) return;

    if (savedPayload != null &&
        savedPayload.isNotEmpty &&
        savedPin != null &&
        savedPin.isNotEmpty) {
      // Flow 2: PIN-Protected Viewing
      String enteredPin = '';
      String? errorMessage;

      final focusNode = FocusNode();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (focusNode.canRequestFocus) focusNode.requestFocus();
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Unlock Saved QR'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Enter your 4-digit PIN to view your secure Agent QR code.',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        focusNode: focusNode,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: '4-Digit PIN',
                          border: const OutlineInputBorder(),
                          errorText: errorMessage,
                        ),
                        onChanged: (v) {
                          enteredPin = v;
                          if (errorMessage != null)
  { setState(() => errorMessage = null); }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (resetCtx) => AlertDialog(
                          title: const Text('Reset QR Setup?'),
                          content: const Text(
                            'This will delete your currently saved Agent QR code from this device. You will need to re-enter your credentials to generate a new one.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(resetCtx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await prefs.remove('agent_qr_payload');
                                await prefs.remove('agent_qr_pin');
                                if (context.mounted) {
                                  Navigator.pop(resetCtx); // close confirmation
                                  Navigator.pop(
                                    dialogContext,
                                  ); // close unlock dialog
                                  _showQrGenerationDialog(); // restart setup
                                }
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot PIN?',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (enteredPin != savedPin) {
                        setState(() => errorMessage = 'Incorrect PIN.');
                        return;
                      }
                      Navigator.pop(dialogContext); // Close unlock dialog
                      _showSavedQrDialog(savedPayload); // Show QR
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade900,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Unlock'),
                  ),
                ],
              );
            },
          );
        },
      );
      return;
    }

    // Flow 1: Initial Setup
    String email = '';
    String password = '';
    String confirmPassword = '';
    String pin = '';
    bool isPasswordVisible = false;
    bool isConfirmPasswordVisible = false;
    bool isGenerated = false;
    String generatedPayload = '';
    final GlobalKey qrKey = GlobalKey();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!isGenerated) {
              final emailBorderColor = _getEmailBorderColor(email);
              final pwdBorderColor = _getPasswordBorderColor(password);
              final confirmBorderColor = confirmPassword.trim().isEmpty
                  ? Colors.red
                  : (confirmPassword.trim() == password.trim()
                        ? Colors.green
                        : Colors.red);
              final pinBorderColor = pin.trim().length == 4
                  ? Colors.green
                  : Colors.red;

              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                    SizedBox(width: 8),
                    Text('Generate Agent QR'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter your credentials and set a 4-digit PIN to securely protect your QR code.',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => setState(() => email = v),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: emailBorderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: emailBorderColor,
                              width: 2.0,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: emailBorderColor,
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: Icon(
                            _isValidEmailFormat(email)
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: emailBorderColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        obscureText: !isPasswordVisible,
                        onChanged: (v) => setState(() => password = v),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: pwdBorderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: pwdBorderColor,
                              width: 2.0,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: pwdBorderColor,
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () => setState(
                                  () => isPasswordVisible = !isPasswordVisible,
                                ),
                              ),
                              Icon(
                                _evaluatePasswordConditionsCount(password) == 4
                                    ? Icons.check_circle
                                    : (_evaluatePasswordConditionsCount(
                                                password,
                                              ) >=
                                              2
                                          ? Icons.warning_amber_rounded
                                          : Icons.error_outline),
                                color: pwdBorderColor,
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                      if (password.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getPasswordStrengthLabel(password),
                          style: TextStyle(
                            color: pwdBorderColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        obscureText: !isConfirmPasswordVisible,
                        onChanged: (v) => setState(() => confirmPassword = v),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: confirmBorderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: confirmBorderColor,
                              width: 2.0,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: confirmBorderColor,
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () => setState(
                                  () => isConfirmPasswordVisible =
                                      !isConfirmPasswordVisible,
                                ),
                              ),
                              Icon(
                                confirmPassword.trim().isNotEmpty &&
                                        confirmPassword.trim() ==
                                            password.trim()
                                    ? Icons.check_circle
                                    : Icons.error_outline,
                                color: confirmBorderColor,
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        onChanged: (v) => setState(() => pin = v),
                        decoration: InputDecoration(
                          labelText: '4-Digit Security PIN',
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: pinBorderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: pinBorderColor,
                              width: 2.0,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: pinBorderColor,
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: Icon(
                            pin.trim().length == 4
                                ? Icons.lock
                                : Icons.lock_open,
                            color: pinBorderColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!_isValidEmailFormat(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid email address.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (_evaluatePasswordConditionsCount(password) < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password is too weak. Please satisfy more security conditions.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (password.trim() != confirmPassword.trim()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match.'),
                          ),
                        );
                        return;
                      }
                      if (pin.trim().length != 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid 4-digit PIN.'),
                          ),
                        );
                        return;
                      }
                      try {
                        final finalPayload =
                            AgentQrCryptoHelper.encryptRegistrationPayload(
                              email: email,
                              password: password,
                              confirmPassword: confirmPassword,
                              pin: pin,
                            );

                        // Save permanently to local storage
                        prefs.setString('agent_qr_payload', finalPayload);
                        prefs.setString('agent_qr_pin', pin.trim());

                        setState(() {
                          generatedPayload = finalPayload;
                          isGenerated = true;
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Encryption error: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade900,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Generate Secure QR'),
                  ),
                ],
              );
            } else {
              return AlertDialog(
                title: const Text('Secure Agent QR Login'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Show this QR code to the Agent so they can log you in. They will need your 4-digit PIN to unlock it.',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: RepaintBoundary(
                            key: qrKey,
                            child: Container(
                              color: Colors
                                  .white, // Ensure white background when saving
                              child: QrImageView(
                                data: generatedPayload,
                                version: QrVersions.auto,
                                errorCorrectionLevel: QrErrorCorrectLevel.H,
                                embeddedImage: const AssetImage(
                                  'assets/images/logo_kym.png',
                                ),
                                embeddedImageStyle: const QrEmbeddedImageStyle(
                                  size: Size(48, 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            RenderRepaintBoundary boundary =
                                qrKey.currentContext!.findRenderObject()
                                    as RenderRepaintBoundary;
                            ui.Image image = await boundary.toImage(
                              pixelRatio: 3.0,
                            );
                            ByteData? byteData = await image.toByteData(
                              format: ui.ImageByteFormat.png,
                            );
                            if (byteData != null) {
                              final pngBytes = byteData.buffer.asUint8List();
                              final tmpDir = await getTemporaryDirectory();
                              final file = File('${tmpDir.path}/agent_qr.png');
                              await file.writeAsBytes(pngBytes);
                              await Gal.putImage(file.path);
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Success'),
                                      ],
                                    ),
                                    content: const Text(
                                      'QR Code saved successfully to gallery!',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Error'),
                                    ],
                                  ),
                                  content: Text('Failed to save QR: $e'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Save / Share QR'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  void _showSavedQrDialog(String payload) {
    final GlobalKey qrKey = GlobalKey();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Secure Agent QR Login'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Show this QR code to the Agent so they can log you in. They will need your 4-digit PIN to unlock it.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: RepaintBoundary(
                      key: qrKey,
                      child: Container(
                        color: Colors.white,
                        child: QrImageView(
                          data: payload,
                          version: QrVersions.auto,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          embeddedImage: const AssetImage(
                            'assets/images/logo_kym.png',
                          ),
                          embeddedImageStyle: const QrEmbeddedImageStyle(
                            size: Size(48, 48),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final localContext = context;
                    try {
                      RenderRepaintBoundary boundary =
                          qrKey.currentContext!.findRenderObject()
                              as RenderRepaintBoundary;
                      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                      ByteData? byteData = await image.toByteData(
                        format: ui.ImageByteFormat.png,
                      );
                      if (byteData != null) {
                        final pngBytes = byteData.buffer.asUint8List();
                        final tmpDir = await getTemporaryDirectory();
                        final file = File('${tmpDir.path}/agent_qr.png');
                        await file.writeAsBytes(pngBytes);
                        await Gal.putImage(file.path);
                        if (localContext.mounted) {
                          showDialog(
                            context: localContext,
                            builder: (c) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Success'),
                                ],
                              ),
                              content: const Text(
                                'QR Code saved successfully to gallery!',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (localContext.mounted) {
                        showDialog(
                          context: localContext,
                          builder: (c) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Error'),
                              ],
                            ),
                            content: Text('Failed to save QR: $e'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Save / Share QR'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isMalayalam
        ? 'അക്കൗണ്ടിലേക്ക് പ്രവേശിക്കുക'
        : 'Welcome to Kurichiyar Matrimony';
    final description = widget.isMalayalam
        ? 'സമ്പൂർണ്ണ വിവരങ്ങൾ കാണാനും ബന്ധപ്പെടാനും ദയവായി രജിസ്റ്റർ ചെയ്യുക അല്ലെങ്കിൽ ലോഗിൻ ചെയ്യുക.'
        : 'Register or sign in to view locked lineage data and connect with verified profiles.';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 52,
                  color: Color(0xFF000080),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.blueAccent,
                    ),
                    tooltip: 'Generate QR for Agent',
                    onPressed: _showQrGenerationDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C3E00),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await RegistrationRouteHelper.handleRegisterNavigation(context);
              },
              icon: const Icon(Icons.person_add),
              label: Text(
                widget.isMalayalam
                    ? 'രജിസ്റ്റർ ചെയ്യുക (REGISTER)'
                    : 'Register Now',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              icon: const Icon(Icons.login),
              label: Text(
                widget.isMalayalam ? 'ലോഗിൻ ചെയ്യുക (LOGIN)' : 'Login',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF000080),
                side: const BorderSide(color: Color(0xFF000080), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/agent_register');
              },
              icon: const Icon(Icons.assignment_ind),
              label: Text(
                widget.isMalayalam
                    ? 'ഏജന്റായി രജിസ്റ്റർ ചെയ്യുക (AGENT REGISTRATION)'
                    : 'Agent Registration',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF000080),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

bool _isValidEmailFormat(String email) {
  final clean = email.trim();
  if (clean.isEmpty) return false;
  return RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  ).hasMatch(clean);
}

Color _getEmailBorderColor(String email) {
  if (email.trim().isEmpty) return Colors.red;
  return _isValidEmailFormat(email) ? Colors.green : Colors.red;
}

int _evaluatePasswordConditionsCount(String pwd) {
  int metCount = 0;
  if (RegExp(r'[A-Z]').allMatches(pwd).length >= 2) metCount++;
  if (RegExp(r'[a-z]').allMatches(pwd).length > 2) metCount++;
  if (RegExp(r'[0-9]').allMatches(pwd).length >= 2) metCount++;
  if (RegExp(r'[@.,#\$%^&*!~?_+\-=\[\]{};:"\\|<>\/]').allMatches(pwd).length >=
      2)
  { metCount++; }
  return metCount;
}

Color _getPasswordBorderColor(String pwd) {
  if (pwd.isEmpty) return Colors.red;
  final score = _evaluatePasswordConditionsCount(pwd);
  if (score < 2) {
    return Colors.red;
  } else if (score < 4) {
    return Colors.amber.shade700;
  } else {
    return Colors.green;
  }
}

String _getPasswordStrengthLabel(String pwd) {
  if (pwd.isEmpty) return 'Required';
  final score = _evaluatePasswordConditionsCount(pwd);
  if (score < 2) {
    return 'Weak (Requires 2 upper, >2 lower, 2 numbers, 2 special)';
  } else if (score < 4) {
    return 'Medium (Add 2 upper, >2 lower, 2 numbers, 2 special)';
  } else {
    return 'Strong Password ✓';
  }
}
