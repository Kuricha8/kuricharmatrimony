import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Helper to handle smart routing for "Register / Create Profile" actions
class RegistrationRouteHelper {
  /// Checks if the current user has already registered or has a pending/submitted application in Firestore / Supabase
  static Future<bool> isUserRegisteredOrPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Check local submission flags
      if (prefs.getBool('registration_submitted') == true) return true;
      final pendingUserId = prefs.getString('pending_user_id');
      if (pendingUserId != null && pendingUserId.isNotEmpty) return true;

      // 2. Resolve logged in user ID
      final fbUid = FirebaseAuth.instance.currentUser?.uid;
      final sbUid = Supabase.instance.client.auth.currentUser?.id;
      final uid = fbUid ?? sbUid;

      if (uid != null && uid.isNotEmpty) {
        // 3. Check Firestore 'users' collection
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get(const GetOptions(source: Source.serverAndCache));
          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data()!;
            final fullName = (data['full_name'] ?? data['name'] ?? '').toString().trim();
            final phone = (data['phone'] ?? data['phone_number'] ?? '').toString().trim();
            final status = (data['status'] ?? data['approvalStatus'] ?? data['registration_status'] ?? '').toString().trim();

            if ((fullName.isNotEmpty && fullName != 'Anonymous') || phone.isNotEmpty || status.isNotEmpty) {
              return true;
            }
          }
        } catch (fsErr) {
          debugPrint('Registration check Firestore users notice: $fsErr');
        }

        // 4. Check Firestore 'kurichiyar_profiles' collection
        try {
          final profDoc = await FirebaseFirestore.instance
              .collection('kurichiyar_profiles')
              .doc(uid)
              .get(const GetOptions(source: Source.serverAndCache));
          if (profDoc.exists && profDoc.data() != null) {
            return true;
          }
        } catch (fsErr) {
          debugPrint('Registration check Firestore kurichiyar_profiles notice: $fsErr');
        }

        // 5. Check Supabase 'kurichiyar_profiles'
        try {
          final sbData = await Supabase.instance.client
              .from('kurichiyar_profiles')
              .select('id, full_name, status')
              .eq('id', uid)
              .maybeSingle();
          if (sbData != null) return true;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Registration check error: $e');
    }
    return false;
  }

  /// Smart navigation when clicking any "Register / Create Profile" button
  /// -> If already registered: opens the "Application Pending / Under Review" screen
  /// -> If not registered (new guest): opens the normal Registration Wizard
  static Future<void> handleRegisterNavigation(BuildContext context) async {
    final isRegistered = await isUserRegisteredOrPending();
    if (!context.mounted) return;

    if (isRegistered) {
      Navigator.pushNamed(context, '/verification_pending');
    } else {
      Navigator.pushNamed(context, '/register');
    }
  }
}
