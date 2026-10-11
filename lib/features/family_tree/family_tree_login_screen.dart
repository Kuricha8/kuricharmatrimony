import 'package:flutter/material.dart';
import '../auth/login_page.dart';
import 'family_tree_auth_service.dart';

/// Dedicated Login & Entry Screen for the Kurichiyar Family Tree (കുടുംബമാല)
class FamilyTreeLoginScreen extends StatelessWidget {
  const FamilyTreeLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'കുടുംബമാല എൻട്രി (Family Tree)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Heritage Icon Badge
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF000080).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF000080).withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    size: 48,
                    color: Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 24),

                // Title & Subtitle
                const Text(
                  'കുറിച്ച്യർ കുടുംബമാല',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '57 പാരമ്പര്യ തറവാടുകളിലെയും പന്തി/ബന്ധു ബന്ധങ്ങൾ ഒരു കുടക്കീഴിൽ കാണാനും രേഖപ്പെടുത്താനും പ്രവേശിക്കുക.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // ─── 1. CONTINUE WITH GOOGLE BUTTON (PRIMARY) ───
                GoogleSignInButton(
                  label: 'Google വഴി തുടരുക (Continue with Google)',
                  onPressed: () =>
                      FamilyTreeAuthService.handleContinueWithGoogle(context),
                ),

                const SizedBox(height: 20),

                // Divider (OR)
                const SizedBox(
                  width: 320,
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'അല്ലെങ്കിൽ (OR)',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── 2. ALTERNATIVE EMAIL / PASSWORD LOGIN ───
                SizedBox(
                  width: 320,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                      side: const BorderSide(
                        color: Color(0xFF000080),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.mail_outline, size: 20),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    label: const Text(
                      'ഇമെയിൽ / ഫോൺ വഴി ലോഗിൻ',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Info Card
                Container(
                  width: 340,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Colors.teal,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'സുരക്ഷിതവും വിശ്വസനീയവുമായ കമ്മ്യൂണിറ്റി പരിശോധന ഉറപ്പാക്കുന്നു.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade800,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
