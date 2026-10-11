import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'family_tree_home_screen.dart';
import 'family_tree_login_screen.dart';
import 'family_registration_screen.dart';

/// Alias for FamilyTreeLoginScreen to support universal naming
typedef LoginScreen = FamilyTreeLoginScreen;

/// Universal Family Tree Navigation Handler
/// 1. If user is a Guest (not logged in) -> prompts/navigates to FamilyTreeLoginScreen
/// 2. If user is logged in:
///    - Checks Firestore collection `ft_members` for `currentUser.uid`.
///    - If document exists -> navigates directly into `FamilyTreeHomeScreen(memberData)`.
///    - If document does not exist -> navigates to `FamilyRegistrationScreen(pre-filled)`.
Future<void> handleFamilyTreeNavigation(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  // 1. ഗസ്റ്റ് യൂസർ ആണെങ്കിൽ -> ഫാമിലി ട്രീ ലോഗിൻ പേജിലേക്ക് വിടുക
  if (user == null) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FamilyTreeLoginScreen()),
    );
    return;
  }

  // ലോഡിംഗ് കാണിക്കുന്നു
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: Color(0xFF000080)),
    ),
  );

  try {
    // ft_members കളക്ഷനിൽ യൂസറുടെ രേഖയുണ്ടോ എന്ന് നോക്കുന്നു
    final doc = await FirebaseFirestore.instance
        .collection('ft_members')
        .doc(user.uid)
        .get();

    if (!context.mounted) return;
    Navigator.pop(context); // ലോഡിംഗ് മാറ്റുന്നു

    if (doc.exists && doc.data() != null) {
      // 2. രജിസ്റ്റർ ചെയ്ത ആളാണെങ്കിൽ -> നേരെ ഫാമിലി ട്രീ ഉള്ളിലേക്ക്
      final data = doc.data() as Map<String, dynamic>;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FamilyTreeHomeScreen(
            memberData: data,
          ),
        ),
      );
    } else {
      // 3. രജിസ്റ്റർ ചെയ്യാത്ത ആളാണെങ്കിൽ -> പ്രീ-ഫിൽ ചെയ്ത രജിസ്ട്രേഷൻ ഫോമിലേക്ക്
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FamilyRegistrationScreen(
            initialName: user.displayName,
            initialEmail: user.email,
            initialPhotoUrl: user.photoURL,
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('Family tree navigation error: $e');
    if (context.mounted) {
      Navigator.pop(context); // ലോഡിംഗ് മാറ്റുന്നു
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FamilyRegistrationScreen(
            initialName: user.displayName,
            initialEmail: user.email,
            initialPhotoUrl: user.photoURL,
          ),
        ),
      );
    }
  }
}

/// Universal Family Tree Guide Card Widget
/// Reusable card component for Guest Screen, Main Screen, and Dashboard
class FamilyTreeGuideCardWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const FamilyTreeGuideCardWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFFE8F5E9),
      child: InkWell(
        onTap: onTap ?? () => handleFamilyTreeNavigation(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(
                  Icons.account_tree_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'കുടുംബ വൃക്ഷം / പാരമ്പര്യം (Family Tree Guide)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.teal,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '57 തറവാടുകളുടെയും പന്തി/ബന്ധു പാരമ്പര്യത്തിന്റെയും വിവരങ്ങൾ കാണുക',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
