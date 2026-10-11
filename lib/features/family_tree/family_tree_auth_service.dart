import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'family_tree_home_screen.dart';
import 'family_registration_screen.dart';

/// Service responsible for Google Authentication and routing for the Family Tree module.
class FamilyTreeAuthService {
  static const String _webClientId =
      '224732363568-2esu3ndodmul0j33u4fub8cpfsj263k6.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    scopes: ['email', 'profile'],
  );

  /// Trigger Google Sign-In and authenticate with Firebase using GoogleAuthProvider.credential
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the Google sign-in dialog
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Family Tree Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Full Family Tree flow on tapping "Continue with Google":
  /// 1. Authenticate with Google & Firebase
  /// 2. Check Firestore collection `ft_members` for the user's UID
  /// 3. If document exists: pushReplacement to FamilyTreeHomeScreen(memberData: doc.data())
  /// 4. If document does NOT exist: pushReplacement to FamilyRegistrationScreen pre-filling name, email, photo URL
  static Future<void> handleContinueWithGoogle(BuildContext context) async {
    bool isDialogShowing = false;

    void showLoading(String message) {
      isDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF000080),
                    strokeWidth: 3,
                  ),
                  const SizedBox(width: 18),
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    void dismissLoading() {
      if (isDialogShowing && context.mounted) {
        isDialogShowing = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    try {
      showLoading('Google വഴി ലോഗിൻ ചെയ്യുന്നു...');
      final userCredential = await signInWithGoogle();
      dismissLoading();

      if (userCredential == null || userCredential.user == null) {
        // User dismissed the Google sign-in dialog
        return;
      }

      final user = userCredential.user!;
      final uid = user.uid;

      showLoading('കുടുംബാംഗത്വം പരിശോധിക്കുന്നു...');
      final doc = await FirebaseFirestore.instance
          .collection('ft_members')
          .doc(uid)
          .get();
      dismissLoading();

      if (!context.mounted) return;

      if (doc.exists && doc.data() != null) {
        // Registered member: Navigate straight to FamilyTreeHomeScreen
        final memberData = doc.data() as Map<String, dynamic>;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FamilyTreeHomeScreen(memberData: memberData),
          ),
        );
      } else {
        // First-time member: Navigate to FamilyRegistrationScreen pre-filled
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FamilyRegistrationScreen(
              initialName: user.displayName ?? '',
              initialEmail: user.email ?? '',
              initialPhotoUrl: user.photoURL,
            ),
          ),
        );
      }
    } catch (e) {
      dismissLoading();
      debugPrint('Google Sign-In entry exception: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In പരാജയപ്പെട്ടു: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

/// Official Styled "Continue with Google" Button
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.label = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300, width: 1.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google 'G' stylized badge
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'G',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3C4043),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
