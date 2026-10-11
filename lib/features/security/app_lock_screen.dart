import 'package:flutter/material.dart';
import '../../core/services/biometric_auth_service.dart';

class AppLockScreen extends StatefulWidget {
  final bool isSetupMode;
  final VoidCallback onSuccess;

  const AppLockScreen({
    super.key,
    required this.isSetupMode,
    required this.onSuccess,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Prompt native device lock (Fingerprint / PIN / Pattern) on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final success = await BiometricAuthService.instance.authenticate(
        localizedReason: widget.isSetupMode
            ? 'ആപ്പ് ലോക്ക് ക്രമീകരിക്കാൻ ദയവായി സ്ഥിരീകരിക്കുക'
            : 'തുടരാൻ ഫോൺ ലോക്ക് അല്ലെങ്കിൽ വിരലടയാളം ഉപയോഗിക്കുക',
      );
      if (success) {
        if (widget.isSetupMode) {
          await BiometricAuthService.instance.setAppLockEnabled(true);
        }
        widget.onSuccess();
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium dark navy
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // App Emblem
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFAA7C11)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Kurichiyar Matrimony',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'കുറിച്ച്യർ സമുദായ മാട്രിമോണി',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),

              const Spacer(flex: 3),

              // Lock Icon Showcase
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  size: 72,
                  color: Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                widget.isSetupMode
                    ? 'ആപ്പ് ലോക്ക് ക്രമീകരിക്കുക'
                    : 'ആപ്പ് ലോക്ക് ചെയ്തിരിക്കുന്നു',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isSetupMode
                    ? 'തുടരാൻ ഫിംഗർപ്രിന്റ് അല്ലെങ്കിൽ സ്ക്രീൻ ലോക്ക് ഉപയോഗിക്കുക.'
                    : 'തുടരാൻ ഫോൺ ഫിംഗർപ്രിന്റ് അല്ലെങ്കിൽ സ്ക്രീൻ ലോക്ക് ഉപയോഗിക്കുക.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 36),

              // Unlock Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _authenticate,
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.lock_open_rounded, size: 20),
                  label: Text(
                    _isAuthenticating
                        ? 'സ്ഥിരീകരിക്കുന്നു...'
                        : 'അൺലോക്ക് ചെയ്യുക (Unlock)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              if (widget.isSetupMode) ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'റദ്ദാക്കുക (Cancel)',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
