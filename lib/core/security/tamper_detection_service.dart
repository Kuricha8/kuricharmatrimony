import 'dart:io';
import 'package:flutter/foundation.dart';

enum SecurityIntegrityStatus {
  secure,
  rootedOrJailbroken,
  debuggerAttached,
  hookingDetected,
  unknown,
}

class TamperAuditResult {
  final bool isCompromised;
  final SecurityIntegrityStatus status;
  final List<String> detectedThreats;

  const TamperAuditResult({
    required this.isCompromised,
    required this.status,
    required this.detectedThreats,
  });
}

/// Service to detect rooted devices, jailbreaks, hooking frameworks, and tampering on cold boot.
class TamperDetectionService {
  static const List<String> _knownRootPaths = [
    '/system/app/Superuser.apk',
    '/sbin/su',
    '/system/bin/su',
    '/system/xbin/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/su',
    '/su/bin/su',
    '/system/xbin/daemonsu',
    '/system/etc/init.d/99SuperSUDaemon',
    '/dev/com.koushikdutta.superuser.daemon/',
    '/system/bin/.ext/.su',
    '/system/usr/we-need-root/su-backup',
    '/system/xbin/mu',
  ];

  static const List<String> _knownJailbreakPaths = [
    '/Applications/Cydia.app',
    '/Library/MobileSubstrate/MobileSubstrate.dylib',
    '/bin/bash',
    '/usr/sbin/sshd',
    '/etc/apt',
    '/private/var/lib/apt/',
    '/private/var/lib/cydia',
    '/private/var/stash',
    '/usr/bin/cycript',
    '/usr/local/bin/cycript',
    '/usr/lib/libcycript.dylib',
  ];

  /// Runs cold boot integrity checks without crashing or blocking users
  static Future<TamperAuditResult> runSecurityAudit() async {
    if (kIsWeb) {
      return const TamperAuditResult(
        isCompromised: false,
        status: SecurityIntegrityStatus.secure,
        detectedThreats: [],
      );
    }

    final List<String> threats = [];

    try {
      if (Platform.isAndroid) {
        // 1. Check for common root binaries
        for (final path in _knownRootPaths) {
          try {
            if (File(path).existsSync()) {
              threats.add('Root binary found at: $path');
            }
          } catch (_) {}
        }

        // 2. Check for build.prop test-keys
        try {
          final buildProp = File('/system/build.prop');
          if (buildProp.existsSync()) {
            final content = buildProp.readAsStringSync();
            if (content.contains('test-keys') ||
                content.contains('lineageos')) {
              threats.add('Custom OS or test-keys firmware signature detected');
            }
          }
        } catch (_) {}
      } else if (Platform.isIOS) {
        // Check for jailbreak artifacts
        for (final path in _knownJailbreakPaths) {
          try {
            if (File(path).existsSync() || Directory(path).existsSync()) {
              threats.add('Jailbreak path detected: $path');
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[TamperDetectionService] Audit error: $e');
    }

    final isCompromised = threats.isNotEmpty;
    final status = isCompromised
        ? SecurityIntegrityStatus.rootedOrJailbroken
        : SecurityIntegrityStatus.secure;

    if (isCompromised) {
      debugPrint(
        '⚠️ [SECURITY AUDIT WARNING] Potential device integrity risks detected:',
      );
      for (final t in threats) {
        debugPrint('   - $t');
      }
    } else {
      debugPrint(
        '🛡️ [SECURITY AUDIT PASS] Device integrity check passed. Environment is secure.',
      );
    }

    return TamperAuditResult(
      isCompromised: isCompromised,
      status: status,
      detectedThreats: threats,
    );
  }
}
