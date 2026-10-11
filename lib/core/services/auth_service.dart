import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'consent_service.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '224732363568-2esu3ndodmul0j33u4fub8cpfsj263k6.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );

  /// Email and Password based sign up
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    debugPrint('Signing up using email: $email');
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user != null) {
      await _injectConsentMetadata(response.user!.id);
    }
    return response;
  }

  /// Email and Password based sign in
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    debugPrint('Signing in using email: $email');
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user != null) {
      await _injectConsentMetadata(response.user!.id);
    }
    return response;
  }

  /// 100% Free Authentication: Phone + Password mapped to a synthetic email.
  /// Bypasses SMS OTP gateways entirely.
  Future<AuthResponse> signUpWithPhonePassword(
    String countryCode,
    String phone,
    String password,
  ) async {
    // e.g. +971501234567 -> +971501234567@auth.kurichiyar.com
    final syntheticEmail = '$countryCode$phone@auth.kurichiyar.com';

    debugPrint('Signing up using synthetic email: $syntheticEmail');

    final response = await Supabase.instance.client.auth.signUp(
      email: syntheticEmail,
      password: password,
      data: {'phone_number': '$countryCode$phone'},
    );
    if (response.user != null) {
      await _injectConsentMetadata(response.user!.id);
    }
    return response;
  }

  Future<AuthResponse> signInWithPhonePassword(
    String countryCode,
    String phone,
    String password,
  ) async {
    final syntheticEmail = '$countryCode$phone@auth.kurichiyar.com';

    debugPrint('Signing in using synthetic email: $syntheticEmail');

    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: syntheticEmail,
      password: password,
    );
    if (response.user != null) {
      await _injectConsentMetadata(response.user!.id);
    }
    return response;
  }

  /// Google Sign-In (Free Email Authentication)
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In canceled by user.');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Google Auth tokens are null.');
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      if (response.user != null) {
        await _injectConsentMetadata(response.user!.id);
      }

      debugPrint('Successfully signed in with Google: \${googleUser.email}');
    } catch (e) {
      debugPrint('Google Sign-In Error: \$e');
      rethrow;
    }
  }

  /// Securely updates admin credentials in Supabase Auth and the corresponding profile row.
  Future<void> updateAdminCredentials(
    String newEmail,
    String newPassword,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('No active admin session found.');
    }

    final Map<String, dynamic> updates = {};
    if (newEmail.isNotEmpty) {
      updates['email'] = newEmail;
    }
    if (newPassword.isNotEmpty) {
      updates['password'] = newPassword;
    }

    if (updates.isEmpty) return;

    // Update in Supabase Auth
    final userAttributes = UserAttributes(
      email: newEmail.isNotEmpty ? newEmail : null,
      password: newPassword.isNotEmpty ? newPassword : null,
    );
    await Supabase.instance.client.auth.updateUser(userAttributes);

    // Update the email in public.profiles table if it was updated
    if (newEmail.isNotEmpty) {
      await Supabase.instance.client
          .from('kurichiyar_profiles')
          .update({'email': newEmail})
          .eq('id', user.id);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _injectConsentMetadata(String uid) async {
    final consentData = await ConsentService.getConsentMetadata();
    if (consentData != null) {
      try {
        await ConsentService.uploadConsent(uid, consentData);
        debugPrint('Injected consent metadata for user $uid');
      } catch (e) {
        debugPrint('Failed to inject consent metadata: $e');
      }
    }
  }
}
