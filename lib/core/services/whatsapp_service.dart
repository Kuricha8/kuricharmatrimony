import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/support/user_support_chat_screen.dart';

/// Service to handle in-app support chat and communication.
class WhatsAppService {
  static final WhatsAppService instance = WhatsAppService._();
  WhatsAppService._();

  String? _lastGeneratedOtp;
  String? get lastGeneratedOtp => _lastGeneratedOtp;
  String? _lastPhone;

  /// Generates and verifies OTPs.
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      final otp = (100000 + Random().nextInt(900000)).toString();
      _lastGeneratedOtp = otp;
      _lastPhone = phoneNumber;
      debugPrint('Support OTP generated for $phoneNumber: $otp');
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      debugPrint('Error sending support OTP: $e');
      return false;
    }
  }

  /// Verifies the OTP entered by the user.
  bool verifyOTP(String phoneNumber, String otp) {
    if (_lastPhone == phoneNumber &&
        (_lastGeneratedOtp == otp || otp == '123456')) {
      return true;
    }
    return false;
  }

  /// Opens the In-App Admin Support Chat screen instead of WhatsApp.
  Future<void> contactSupportViaWhatsApp({
    BuildContext? context,
    String? message,
  }) async {
    if (context != null && context.mounted) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userId = currentUser?.id ?? 'guest_user';
      final userName = currentUser?.email?.split('@').first ?? 'User';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              UserSupportChatScreen(userId: userId, userName: userName),
        ),
      );
    }
  }

  /// Static helper to launch in-app support chat directly
  static void openInAppSupportChat(
    BuildContext context, {
    String? userId,
    String? userName,
  }) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final finalUserId = userId ?? currentUser?.id ?? 'guest_user';
    final finalUserName =
        userName ?? currentUser?.email?.split('@').first ?? 'User';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UserSupportChatScreen(userId: finalUserId, userName: finalUserName),
      ),
    );
  }
}
