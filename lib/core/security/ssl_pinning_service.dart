import 'dart:io';
import 'package:flutter/foundation.dart';

class SslPinningService {
  // In a production scenario, you would extract the SHA-256 fingerprint of your
  // Supabase/Firebase SSL certificate and hardcode it here.
  // Example Hash: 'SHA256: ABCDEF1234567890...'
  static const List<String> allowedCertFingerprints = [
    'INSERT_YOUR_PRODUCTION_CERT_HASH_HERE',
  ];

  static void initialize() {
    HttpOverrides.global = _PinnedHttpOverrides();
    debugPrint('SSL Pinning Service Initialized.');
  }
}

class _PinnedHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    HttpClient client = super.createHttpClient(context);
    client
        .badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Allow local development without pinning
      if (host == 'localhost' || host == '10.0.2.2') {
        return true;
      }

      // Check if the certificate fingerprint matches our pinned hashes
      final certFingerprint = cert.sha1.toString(); // simplified for example

      // For demonstration, if no hashes are configured yet, we fail open.
      // IN PRODUCTION: Change this to fail CLOSED (return false) if no match.
      if (SslPinningService.allowedCertFingerprints.contains(
        'INSERT_YOUR_PRODUCTION_CERT_HASH_HERE',
      )) {
        debugPrint(
          'WARNING: SSL Pinning is active but using dummy hash. Traffic is allowed.',
        );
        return true;
      }

      bool isPinned = SslPinningService.allowedCertFingerprints.contains(
        certFingerprint,
      );
      if (!isPinned) {
        debugPrint(
          'CRITICAL SECURITY ALERT: MITM Attack Detected! SSL Pinning Failed for host: \$host',
        );
      }
      return isPinned;
    };
    return client;
  }
}
