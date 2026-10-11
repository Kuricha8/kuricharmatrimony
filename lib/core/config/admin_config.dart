import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Configuration for Admin Details & Contact Info
class AdminConfig {
  static const String superAdminPhone = '8606415174';
  static const String superAdminPhoneWithCode = '+918606415174';
  static const String adminPhoneNumber = '+918606415174';
  static const String formattedAdminPhone = '+91 8606415174';
  static const String adminEmail = 'support@kurichiyar.com';

  static const List<String> superAdminPhones = [
    '8606415174',
    '+918606415174',
    '8129057934',
    '+918129057934',
  ];

  /// Checks if given phone number or email belongs to the Super Admin.
  static bool isSuperAdmin({String? phone, String? email}) {
    if (phone != null && phone.trim().isNotEmpty) {
      final clean = phone.replaceAll(RegExp(r'\D'), '');
      if (clean.endsWith('8606415174') || clean.endsWith('8129057934')) {
        return true;
      }
    }
    if (email != null && email.trim().isNotEmpty) {
      final cleanEmail = email.toLowerCase().trim();
      if (cleanEmail == 'kuricha8@gmail.com') return true;
      if (cleanEmail.contains('8606415174') || cleanEmail.contains('8129057934')) {
        return true;
      }
    }
    return false;
  }

  /// Automatically ensures isAdmin: true and role: 'admin' in Firestore and Supabase.
  static Future<void> ensureAdminRecord(String uid, {String? phone, String? email}) async {
    if (uid.isEmpty) return;
    try {
      final Map<String, dynamic> firestoreUpdate = {
        'isAdmin': true,
        'role': 'admin',
        'is_approved': true,
        'approval_status': 'APPROVED',
        'registration_status': 'APPROVED',
        'account_status': 'APPROVED',
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (phone != null && phone.isNotEmpty) {
        firestoreUpdate['phone'] = phone;
        firestoreUpdate['guardian_phone'] = phone;
      }
      if (email != null && email.isNotEmpty) {
        firestoreUpdate['email'] = email;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(firestoreUpdate, SetOptions(merge: true));

      debugPrint('[AdminConfig] Successfully set isAdmin: true and role: admin in Firestore for $uid');
    } catch (e) {
      debugPrint('[AdminConfig] Error setting admin in Firestore: $e');
    }

    try {
      await Supabase.instance.client
          .from('kurichiyar_profiles')
          .update({
            'role': 'admin',
            'is_approved': true,
            'approval_status': 'APPROVED',
            'registration_status': 'APPROVED',
            'account_status': 'APPROVED',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', uid);
      debugPrint('[AdminConfig] Successfully set role: admin in Supabase for $uid');
    } catch (e) {
      debugPrint('[AdminConfig] Error updating Supabase profile role: $e');
    }

    try {
      await Supabase.instance.client
          .from('agents')
          .update({
            'approval_status': 'APPROVED',
            'status': 'ACTIVE',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', uid);
    } catch (_) {}
  }
}
