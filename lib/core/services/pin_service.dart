import 'biometric_auth_service.dart';

/// Legacy PinService adapter delegating to BiometricAuthService
class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  /// Check if App Lock is currently enabled
  Future<bool> isAppLockEnabled() =>
      BiometricAuthService.instance.isAppLockEnabled();

  /// Backward-compatible alias for isAppLockEnabled
  Future<bool> hasPin() => isAppLockEnabled();

  /// Set App Lock enabled or disabled
  Future<void> setAppLockEnabled(bool enabled) async {
    await BiometricAuthService.instance.setAppLockEnabled(enabled);
  }

  /// Enable biometric lock
  Future<void> enableBiometricLock() => setAppLockEnabled(true);

  /// Disable biometric lock
  Future<void> removePin() => setAppLockEnabled(false);

  /// Check if device supports biometrics or device PIN/Pattern
  Future<bool> canAuthenticate() =>
      BiometricAuthService.instance.canCheckBiometrics();

  /// Authenticate using native device lock (Biometric / PIN / Pattern)
  Future<bool> authenticate({
    String localizedReason =
        'തുടരാൻ ഫോൺ ലോക്ക് അല്ലെങ്കിൽ വിരലടയാളം ഉപയോഗിക്കുക',
  }) =>
      BiometricAuthService.instance.authenticate(
        localizedReason: localizedReason,
      );
}
