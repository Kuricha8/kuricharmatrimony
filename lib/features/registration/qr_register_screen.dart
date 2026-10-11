import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QrRegisterScreen extends StatefulWidget {
  const QrRegisterScreen({super.key});

  @override
  State<QrRegisterScreen> createState() => _QrRegisterScreenState();
}

class _QrRegisterScreenState extends State<QrRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _agentIdController = TextEditingController(); // ഏജന്റ് കോഡ് (Optional)

  String? _qrPayload;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pincodeController.dispose();
    _agentIdController.dispose();
    super.dispose();
  }

  Future<void> _registerClient() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final pincode = _pincodeController.text.trim();
    final agentId = _agentIdController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('പേര്, ഇമെയിൽ, പാസ്വേഡ് എന്നിവ നിർബന്ധമാണ്.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. ഡാറ്റാബേസിൽ ക്ലയന്റ് പ്രൊഫൈൽ ഉണ്ടാക്കുന്നു (profiles & users collections)
      final profileData = {
        'name': name,
        'email': email,
        'pincode': pincode,
        'registered_under_agent': agentId,
        'is_agent': false,
        'is_deleted': false,
        'created_at': FieldValue.serverTimestamp(),
      };

      DocumentReference userRef = await FirebaseFirestore.instance.collection('profiles').add(profileData);

      // Also sync into users collection for app consistency
      await FirebaseFirestore.instance.collection('users').doc(userRef.id).set(profileData, SetOptions(merge: true));

      // 2. ഇമെയിലും പാസ്വേഡും അടങ്ങിയ സുരക്ഷിത QR ഡാറ്റ നിർമ്മിക്കുന്നു
      final credentials = jsonEncode({
        'uid': userRef.id,
        'email': email,
        'password': password,
      });

      if (mounted) {
        setState(() {
          _qrPayload = credentials;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('രജിസ്ട്രേഷൻ വിജയകരമായി പൂർത്തിയായി!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('രജിസ്ട്രേഷൻ പരാജയപ്പെട്ടു: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('രജിസ്ട്രേഷൻ & QR ലോഗിൻ'),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'പേര്',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'ഇമെയിൽ',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'പാസ്വേഡ്',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'പിൻകോഡ്',
                prefixIcon: Icon(Icons.pin_drop_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _agentIdController,
              decoration: const InputDecoration(
                labelText: 'ഏജന്റ് ഐഡി (ഉണ്ടെങ്കിൽ)',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerClient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'രജിസ്റ്റർ ചെയ്യുക',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 30),
            if (_qrPayload != null) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'നിങ്ങളുടെ ലോഗിൻ QR കോഡ് റെഡി:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF000080)),
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: _qrPayload!,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ഈ QR കോഡ് ഉപയോഗിച്ച് നിങ്ങൾക്ക് ഭാവിയിൽ നേരിട്ട് ലോഗിൻ ചെയ്യാം.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
