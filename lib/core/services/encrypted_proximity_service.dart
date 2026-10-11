import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ProximityPayload {
  final String userId;
  final String maternalClan;
  final String paternalClan;
  final String houseName;
  final String timestamp;
  final bool isCommunityVerified;

  ProximityPayload({
    required this.userId,
    required this.maternalClan,
    required this.paternalClan,
    required this.houseName,
    required this.timestamp,
    required this.isCommunityVerified,
  });

  Map<String, dynamic> toJson() => {
    'uid': userId,
    'mc': maternalClan,
    'pc': paternalClan,
    'hn': houseName,
    'ts': timestamp,
    'cv': isCommunityVerified,
  };

  factory ProximityPayload.fromJson(Map<String, dynamic> json) {
    return ProximityPayload(
      userId: json['uid'] ?? '',
      maternalClan: json['mc'] ?? '',
      paternalClan: json['pc'] ?? '',
      houseName: json['hn'] ?? '',
      timestamp: json['ts'] ?? '',
      isCommunityVerified: json['cv'] ?? false,
    );
  }
}

/// Offline Encrypted Proximity Identification Service for QR, NFC, and BLE Beacons
class EncryptedProximityService {
  static final _key = encrypt.Key.fromUtf8(
    'KurichiyarMatrimonyProximity2026',
  ); // 32-char key
  static final _iv = encrypt.IV.fromUtf8('KMProximityIV2026'); // 16-char IV

  /// Encrypt payload string for QR Code, NFC Tag, or BLE Advertisement
  static String encryptPayload(ProximityPayload payload) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.cbc),
    );
    final jsonStr = jsonEncode(payload.toJson());
    final encrypted = encrypter.encrypt(jsonStr, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypt incoming payload from scanned QR Code, NFC Tag, or BLE signal
  static ProximityPayload? decryptPayload(String base64EncryptedData) {
    try {
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key, mode: encrypt.AESMode.cbc),
      );
      final decryptedStr = encrypter.decrypt64(base64EncryptedData, iv: _iv);
      final Map<String, dynamic> jsonMap = jsonDecode(decryptedStr);
      return ProximityPayload.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Hashes phone number to produce an anonymous proximity token
  static String generateAnonymousToken(String phoneNumber) {
    final bytes = utf8.encode('$phoneNumber:KM_SALT_2026');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
}
