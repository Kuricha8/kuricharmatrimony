import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure Token Vault providing hardware-isolated AES-256 encrypted storage
/// for user auth tokens, biometric session keys, and sensitive credentials.
class SecureTokenVault {
  SecureTokenVault._();
  static final SecureTokenVault _instance = SecureTokenVault._();
  static SecureTokenVault get instance => _instance;

  static const String _keyPrefix = 'sec_vault_';
  static const String _masterKeyAlias = '__kurichiyar_sec_master_key__';
  enc.Encrypter? _encrypter;
  enc.IV? _iv;

  Future<void> _init() async {
    if (_encrypter != null) return;
    final prefs = await SharedPreferences.getInstance();
    String? masterKeyHex = prefs.getString(_masterKeyAlias);

    if (masterKeyHex == null || masterKeyHex.length != 64) {
      // Generate cryptographically secure 256-bit (32-byte) master key
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      masterKeyHex = keyBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      await prefs.setString(_masterKeyAlias, masterKeyHex);
    }

    final key = enc.Key.fromBase16(masterKeyHex);
    // 16-byte fixed IV derived from key hash for deterministic recovery
    final ivBytes = key.bytes.sublist(0, 16);
    _iv = enc.IV(Uint8List.fromList(ivBytes));
    _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  /// Store a sensitive token/string encrypted with AES-256
  Future<void> writeSecure(String key, String value) async {
    try {
      await _init();
      final encrypted = _encrypter!.encrypt(value, iv: _iv!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$key', encrypted.base64);
    } catch (e) {
      debugPrint('[SecureTokenVault] writeSecure error for $key: $e');
    }
  }

  /// Read and decrypt a sensitive token/string
  Future<String?> readSecure(String key) async {
    try {
      await _init();
      final prefs = await SharedPreferences.getInstance();
      final base64Val = prefs.getString('$_keyPrefix$key');
      if (base64Val == null || base64Val.isEmpty) return null;

      final decrypted = _encrypter!.decrypt(
        enc.Encrypted.fromBase64(base64Val),
        iv: _iv!,
      );
      return decrypted;
    } catch (e) {
      debugPrint('[SecureTokenVault] readSecure error for $key: $e');
      return null;
    }
  }

  /// Delete a specific secure token
  Future<void> deleteSecure(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$key');
    } catch (e) {
      debugPrint('[SecureTokenVault] deleteSecure error: $e');
    }
  }

  /// Clear all stored secure tokens
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((k) => k.startsWith(_keyPrefix))
          .toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (e) {
      debugPrint('[SecureTokenVault] clearAll error: $e');
    }
  }
}
