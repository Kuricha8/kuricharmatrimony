import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/utils/mock_data.dart';

class AgentQrScannerScreen extends StatefulWidget {
  final String? name;
  final String? email;
  final String? phone;
  final String? password;
  final File? photoFile;

  const AgentQrScannerScreen({
    super.key,
    this.name,
    this.email,
    this.phone,
    this.password,
    this.photoFile,
  });

  @override
  State<AgentQrScannerScreen> createState() => _AgentQrScannerScreenState();
}

class _AgentQrScannerScreenState extends State<AgentQrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processScannedData(String data) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (data.contains('/profile/')) {
        final uri = Uri.tryParse(data);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          final userId = uri.pathSegments.last;

          final userRecord = await Supabase.instance.client
              .from('kurichiyar_profiles')
              .select('*')
              .eq('id', userId)
              .maybeSingle();
          if (userRecord == null) throw Exception('User not found in database');

          final email = userRecord['email'];

          // Show Password Prompt Dialog to Unlock
          String? enteredPassword;
          if (mounted) {
            enteredPassword = await showDialog<String>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                final pwdController = TextEditingController();
                final focusNode = FocusNode();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (focusNode.canRequestFocus) focusNode.requestFocus();
                });
                return AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Security Lock'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Please enter the user-defined password to unlock and view these secured details.',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: pwdController,
                        focusNode: focusNode,
                        autofocus: true,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, pwdController.text),
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
          }

          if (enteredPassword == null || enteredPassword.isEmpty) {
            setState(() {
              _isProcessing = false;
            });
            return;
          }

          // Verify password using a temporary client to avoid logging the current agent out
          final verifyUrl =
              dotenv.env['SUPABASE_URL'] ??
              'https://noidreeslytswkmsnmcn.supabase.co';
          final verifyKey =
              dotenv.env['SUPABASE_ANON_KEY'] ??
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vaWRyZWVzbHl0c3drbXNubWNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5NTA2ODksImV4cCI6MjA5OTUyNjY4OX0.VnpX0xjRNi89efECRAzMiu79trSQlblpRjfWZLkjMo4';
          final verifyClient = SupabaseClient(verifyUrl, verifyKey);

          try {
            await verifyClient.auth.signInWithPassword(
              email: email,
              password: enteredPassword,
            );
          } catch (e) {
            verifyClient.dispose();
            throw Exception('Incorrect password. Access denied.');
          }
          verifyClient.dispose();

          // Show Unlocked Details
          if (mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_open, color: Colors.green, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Secured Details Unlocked',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      Icons.person,
                      'Name',
                      userRecord['name'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.email,
                      'Email',
                      userRecord['email'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.phone,
                      'Phone',
                      userRecord['phone_number'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.badge,
                      'Agent Code',
                      userRecord['agent_code'] ?? 'None',
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      }

      // Decrypt if it's the new PIN-protected format
      String decryptedData = data;
      debugPrint('=== [AGENT_QR_SCANNER] Scanned Raw Data: $data ===');

      if (data.startsWith('KM_ENC:')) {
        final encryptedBase64 = data.substring(7).trim();
        debugPrint(
          '=== [AGENT_QR_SCANNER] Encrypted Base64 Payload Length: ${encryptedBase64.length} ===',
        );
        String? pin;
        if (mounted) {
          pin = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              final pinController = TextEditingController();
              final focusNode = FocusNode();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (focusNode.canRequestFocus) focusNode.requestFocus();
              });
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Unlock QR Code'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This user QR code is secured. Please enter the user\'s 4-digit PIN to unlock it.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pinController,
                      focusNode: focusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '4-Digit PIN',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (ctx.mounted && Navigator.canPop(ctx)) {
                        Navigator.pop(ctx, null);
                      }
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final input = pinController.text.trim().replaceAll(
                        RegExp(r'\s+'),
                        '',
                      );
                      if (ctx.mounted && Navigator.canPop(ctx)) {
                        Navigator.pop(ctx, input);
                      }
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
        }

        final cleanPin = pin?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
        debugPrint(
          '=== [AGENT_QR_SCANNER] User Entered PIN: "$cleanPin" (Length: ${cleanPin.length}) ===',
        );

        if (cleanPin.length != 4) {
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        try {
          final key = enc.Key.fromUtf8(cleanPin.padRight(32, '0'));
          final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

          if (encryptedBase64.contains(':')) {
            final parts = encryptedBase64.split(':');
            final iv = enc.IV.fromBase64(parts[0]);
            decryptedData = encrypter.decrypt64(parts[1], iv: iv);
          } else {
            final iv = enc.IV.fromUtf8(cleanPin.padRight(16, '0'));
            decryptedData = encrypter.decrypt64(encryptedBase64, iv: iv);
          }
          debugPrint(
            '=== [AGENT_QR_SCANNER] Decryption SUCCESS: $decryptedData ===',
          );
        } catch (e, stack) {
          debugPrint(
            '=== [AGENT_QR_SCANNER] Decryption FAILED: $e\n$stack ===',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incorrect PIN. Decryption failed.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      }

      final payload = jsonDecode(decryptedData);
      if (payload is Map<String, dynamic> && payload.containsKey('sessionId')) {
        final sessionId = payload['sessionId'] as String;

        // Use form fields or fallback to payload or dummy
        final email = widget.email?.isNotEmpty == true
            ? widget.email!
            : (payload['e'] as String? ??
                  'temp_${DateTime.now().millisecondsSinceEpoch}@example.com');
        final password = widget.password?.isNotEmpty == true
            ? widget.password!
            : (payload['p'] as String? ?? 'temp_pass_123');
        final name = widget.name?.isNotEmpty == true
            ? widget.name!
            : 'Guest User';
        final phone = widget.phone?.isNotEmpty == true ? widget.phone! : '';

        // Create the user account
        try {
          final res = await Supabase.instance.client.auth.signUp(
            email: email,
            password: password,
          );
          final uid = res.user?.id;
          if (uid != null) {
            String? photoUrl;
            if (widget.photoFile != null) {
              final path =
                  'profiles/${DateTime.now().millisecondsSinceEpoch}.jpg';
              await Supabase.instance.client.storage
                  .from('profiles')
                  .upload(path, widget.photoFile!);
              photoUrl = Supabase.instance.client.storage
                  .from('profiles')
                  .getPublicUrl(path);
            }

            final agentCode = MockData().currentUser?.agentCode;
            if (agentCode != null) {
              await Supabase.instance.client
                  .from('kurichiyar_profiles')
                  .upsert({
                    'id': uid,
                    'name': name,
                    'email': email,
                    'phone_number': phone,
                    'photo_url': photoUrl,
                    'agent_code': agentCode,
                    'account_status': 'PENDING_ADMIN_APPROVAL',
                    'registration_status': 'pending',
                    'role': 'member',
                  });
            }
          }
        } catch (e) {
          debugPrint('Auth/DB Error: \$e');
          // If already registered, ignore and proceed
        }

        // Broadcast success with credentials to the user's phone via Realtime
        await Supabase.instance.client
            .channel('qr_scan_session:$sessionId')
            .sendBroadcastMessage(
              event: 'success',
              payload: {'status': 'ok', 'e': email, 'p': password},
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User paired and registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Pop twice to return to Dashboard (closes scanner and fast registration form)
          Navigator.pop(context);
          Navigator.pop(context);
        }
      } else {
        throw const FormatException('Invalid QR Payload');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning QR: \$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Delay before allowing another scan
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan User QR Code'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processScannedData(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Point camera at User's QR Code",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}
