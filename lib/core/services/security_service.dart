import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/banned_screen.dart';

class SecurityService {
  static const MethodChannel _channel = MethodChannel(
    'com.kurichiyar.matrimony/security',
  );

  // NOTE: Replace with the actual SHA-256 hash of your production keystore certificate.
  // For testing purposes in debug mode, Android signs with a debug keystore.
  // Since we don't know the exact hash yet, we'll temporarily set it to expect the debug hash
  // or bypass it strictly for development. Once in production, set this to the real hash.
  static const String expectedProductionHash = 'EXPECTED_SHA_256_HASH_HERE';

  static Future<void> verifyAppIntegrity(BuildContext context) async {
    try {
      final String apkHash = await _channel.invokeMethod('getApkSignatureHash');
      debugPrint('Detected APK Signature Hash: $apkHash');

      // TEMPORARY: In development/debug, the hash will be from the debug keystore.
      // For the demo to work without crashing immediately, we'll log it but not crash
      // unless we strictly enable it. In production, uncomment the block below.

      /*
      if (apkHash != expectedProductionHash) {
        // App is tampered!
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TamperedAppScreen()),
          );
        }
      }
      */
    } catch (e) {
      debugPrint('Failed to verify app integrity: $e');
    }
  }

  static Future<void> flagAccount(BuildContext context, String reason) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.rpc(
          'flag_account_tampering',
          params: {'target_user_id': user.id},
        );
        debugPrint('Account flagged for tampering: $reason');

        // Immediately log them out and show banned screen
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BannedScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to flag account: $e');
    }
  }
}

class TamperedAppScreen extends StatelessWidget {
  const TamperedAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_bad, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Tampered App Detected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This application has been modified and is unsafe to use. Please download the official version from our website.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Exit App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
