import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class AgentQrCryptoResult {
  final String email;
  final String password;
  final String confirmPassword;
  final String sessionId;

  AgentQrCryptoResult({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.sessionId,
  });
}

class AgentQrCryptoHelper {
  AgentQrCryptoHelper._();

  /// Derives a 256-bit AES Key from a 4-digit PIN using SHA-256 hashing.
  static enc.Key deriveKeyFromPin(String pin) {
    final cleanPin = pin.trim().replaceAll(RegExp(r'\s+'), '');
    final bytes = utf8.encode(cleanPin);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypts registration credentials into a secure KM_ENC QR payload string.
  static String encryptRegistrationPayload({
    required String email,
    required String password,
    required String confirmPassword,
    required String pin,
    String? sessionId,
  }) {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    final cleanConfirmPassword = confirmPassword.trim();
    final cleanPin = pin.trim().replaceAll(RegExp(r'\s+'), '');
    final activeSessionId =
        sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

    debugPrint('=== [QR_ENCRYPT] Encrypting Registration Payload ===');
    debugPrint(
      'Email: "$cleanEmail" | PIN Length: ${cleanPin.length} | Session: $activeSessionId',
    );

    final jsonPayload = jsonEncode({
      'e': cleanEmail,
      'p': cleanPassword,
      'cp': cleanConfirmPassword,
      'sessionId': activeSessionId,
    });

    final key = deriveKeyFromPin(cleanPin);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(jsonPayload, iv: iv);

    final finalPayload = 'KM_ENC:${iv.base64}:${encrypted.base64}';
    debugPrint(
      '=== [QR_ENCRYPT] Generated Encrypted QR Payload: $finalPayload ===',
    );
    return finalPayload;
  }

  /// Decrypts a scanned KM_ENC QR payload string given a 4-digit PIN.
  static AgentQrCryptoResult decryptRegistrationPayload({
    required String qrData,
    required String pin,
  }) {
    final cleanData = qrData.trim();
    final cleanPin = pin.trim().replaceAll(RegExp(r'\s+'), '');

    debugPrint('=== [QR_DECRYPT] Attempting Decryption ===');
    debugPrint('Scanned Raw QR: "$cleanData"');
    debugPrint('Entered PIN: "$cleanPin" (Length: ${cleanPin.length})');

    if (!cleanData.startsWith('KM_ENC:')) {
      throw FormatException('Invalid QR code prefix. Expected "KM_ENC:".');
    }

    final cipherContent = cleanData.substring(7).trim();
    final key = deriveKeyFromPin(cleanPin);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    String decryptedJson;

    try {
      if (cipherContent.contains(':')) {
        final parts = cipherContent.split(':');
        final iv = enc.IV.fromBase64(parts[0]);
        decryptedJson = encrypter.decrypt64(parts[1], iv: iv);
      } else {
        // Fallback for older single-token payloads
        final fallbackIv = enc.IV.fromUtf8(cleanPin.padRight(16, '0'));
        decryptedJson = encrypter.decrypt64(cipherContent, iv: fallbackIv);
      }
      debugPrint(
        '=== [QR_DECRYPT] Decrypted JSON Raw String: $decryptedJson ===',
      );
    } catch (e, st) {
      debugPrint('=== [QR_DECRYPT] AES Decryption Failed: $e\n$st ===');
      throw FormatException(
        'Incorrect 4-digit PIN or corrupted encryption data.',
      );
    }

    try {
      final Map<String, dynamic> map = jsonDecode(decryptedJson);
      final email = (map['e'] ?? map['email'] ?? '').toString().trim();
      final password = (map['p'] ?? map['password'] ?? '').toString().trim();
      final confirmPassword =
          (map['cp'] ??
                  map['confirm_password'] ??
                  map['confirmPassword'] ??
                  password)
              .toString()
              .trim();
      final sessionId = (map['sessionId'] ?? map['session_id'] ?? '')
          .toString()
          .trim();

      debugPrint('=== [QR_DECRYPT] Parsing Success! ===');
      debugPrint(
        'Extracted Email: "$email" | Password Length: ${password.length} | Session: $sessionId',
      );

      return AgentQrCryptoResult(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        sessionId: sessionId,
      );
    } catch (e, st) {
      debugPrint('=== [QR_DECRYPT] JSON Parsing Failed: $e\n$st ===');
      throw FormatException('Failed to parse decrypted QR payload format.');
    }
  }
}
