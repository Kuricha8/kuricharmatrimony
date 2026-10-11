import 'package:flutter/material.dart';

class ProfileVerificationGuard extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final Widget child;

  const ProfileVerificationGuard({
    super.key,
    required this.userProfile,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool isApproved = userProfile['verification_status'] == 'approved';
    final bool hasFatherClan =
        (userProfile['father_clan'] != null &&
        userProfile['father_clan'].toString().trim().isNotEmpty);
    final bool hasMotherClan =
        (userProfile['mother_clan'] != null &&
        userProfile['mother_clan'].toString().trim().isNotEmpty);

    // അപ്രൂവൽ ഇല്ലെങ്കിലോ തറവാട് വിവരങ്ങൾ ഇല്ലെങ്കിലോ ലോക്ക് ഓവർലേ കാണിക്കുന്നു
    final bool isLocked = !isApproved || !hasFatherClan || !hasMotherClan;

    return Stack(
      children: [
        child,
        if (isLocked)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(
                alpha: 0.65,
              ), // ബാക്ക്ഗ്രൗണ്ട് ഡിം ചെയ്യുന്നു
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A1212), // മെറൂൺ / ഡാർക്ക് തീം
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // വൃക്ഷ ചിഹ്നം / ഐക്കൺ
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2E0A0A),
                      ),
                      child: const Icon(
                        Icons.account_tree_rounded,
                        size: 48,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // തലക്കെട്ട്
                    const Text(
                      "മാച്ചുകൾ ലോക്ക് ചെയ്തിരിക്കുന്നു",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // വിവരണം
                    const Text(
                      "താങ്കളുടെ കുടുംബവിവരങ്ങൾ നൽകിയിട്ടില്ല / അഡ്മിൻ പരിശോധനയിലാണ്. കുടുംബം (തറവാട്) സ്ഥിരീകരിച്ചാൽ മാത്രമേ മാച്ചുകൾ കാണാൻ സാധിക്കൂ.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // ലോക്ക്ഡ് ബാഡ്ജുകൾ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLockBadge(Icons.people_outline, "Matches Desk"),
                        _buildLockBadge(
                          Icons.favorite_outline,
                          "Moiety Checker",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLockBadge(IconData icon, String label) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white38, size: 30),
            ),
            const Icon(Icons.lock, color: Colors.redAccent, size: 22),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
