import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Biometric / Screen Lock Authentication Service
///
/// Handles native Fingerprint, Face, PIN, and Pattern authentication via `local_auth`.
class BiometricAuthService {
  BiometricAuthService._internal();
  static final BiometricAuthService instance = BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String appLockKey = 'is_app_lock_enabled';

  /// Check if the device hardware and OS supports biometrics or device credentials.
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('BiometricAuthService: isDeviceSupported error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check whether biometric sensors or screen locks are available on the device.
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('BiometricAuthService: canCheckBiometrics error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Get list of enrolled biometric types (fingerprint, face, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('BiometricAuthService: getAvailableBiometrics error: $e');
      return <BiometricType>[];
    }
  }

  /// Check if app lock is enabled in SharedPreferences
  Future<bool> isAppLockEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(appLockKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Enable or disable app lock in SharedPreferences
  Future<bool> setAppLockEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(appLockKey, enabled);
    } catch (_) {
      return false;
    }
  }

  /// Authenticate the user with Fingerprint, Face, PIN, or Pattern.
  ///
  /// Uses `stickyAuth: true` and `biometricOnly: false` so device lock (PIN/Pattern)
  /// is also accepted if biometric sensors are unavailable or fails.
  Future<bool> authenticate({
    String localizedReason = 'തുടരാൻ ഫോൺ ലോക്ക് അല്ലെങ്കിൽ വിരലടയാളം ഉപയോഗിക്കുക (Use screen lock or fingerprint to continue)',
  }) async {
    try {
      if (kIsWeb) return true; // Web does not have native device screen lock

      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        debugPrint('BiometricAuthService: Device does not support local authentication.');
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true, // stickyAuth
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricAuthService: authenticate PlatformException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('BiometricAuthService: authenticate error: $e');
      return false;
    }
  }

  /// Cancels any ongoing authentication session
  Future<bool> stopAuthentication() async {
    try {
      return await _localAuth.stopAuthentication();
    } catch (_) {
      return false;
    }
  }
}
