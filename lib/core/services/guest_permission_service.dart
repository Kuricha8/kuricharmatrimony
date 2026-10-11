import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/mock_data.dart';
import '../../features/auth_splash/widgets/guest_auth_bottom_sheet.dart';

/// Central permission controller enforcing strict guest mode access restrictions.
///
/// Rules:
/// 1. Allowed for Guest: View Public Hub Feed, View Stories, Like/Favorite Profiles.
/// 2. Restricted for Guest: Photo uploads, status creation, image pickers.
/// 3. If restricted action triggered: Shows standard Malayalam modal prompting login/registration.
class GuestPermissionService {
  /// Strictly checks if current session is Guest.
  /// True if FirebaseAuth user is null, or Supabase user is null and MockData user is guest.
  static bool get isGuest {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return true;

    final supaUser = Supabase.instance.client.auth.currentUser;
    final currentUser = MockData().currentUser;

    if (supaUser == null &&
        (currentUser == null || currentUser.id == 'guest' || currentUser.id.isEmpty)) {
      return true;
    }

    return false;
  }

  /// Verifies if user is an approved member with Tharavadu rights to post status updates.
  static bool get canUploadStatus {
    if (isGuest) return false;
    final currentUser = MockData().currentUser;
    if (currentUser == null) return false;
    return (currentUser.motherClanId > 0 ||
            currentUser.fatherClanId > 0 ||
            currentUser.hasValidTharavadu) &&
        currentUser.isApproved;
  }

  /// Shows the standard restriction modal:
  /// "ഫോട്ടോകളും സ്റ്റാറ്റസുകളും പങ്കിടാൻ ദയവായി രജിസ്റ്റർ ചെയ്യുക (Please register or login to upload photos/status)"
  static void showUploadRestrictedDialog(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onLoginSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Warm amber tint
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFB45309),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'അംഗങ്ങൾക്ക് മാത്രം (Members Only)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customMessage ??
                    'ഫോട്ടോകളും സ്റ്റാറ്റസുകളും പങ്കിടാൻ ദയവായി രജിസ്റ്റർ ചെയ്യുക (Please register or login to upload photos/status)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    GuestAuthBottomSheet.show(context);
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text(
                    'രജിസ്റ്റർ ചെയ്യുക / Login',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'പിന്നീടാവാം (Later)',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
