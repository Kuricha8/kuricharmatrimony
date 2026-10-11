import 'package:flutter/material.dart';

/// A stylish Paywall & Privacy Lock Card displayed over locked contact and location sections
/// for Free / Unpaid registered users.
///
/// Requirement:
/// "Display a stylish "Locked" card over these sections:
///  "ഫോൺ നമ്പറും ലൊക്കേഷൻ വിവരങ്ങളും കാണാൻ പ്രീമിയം അംഗത്വം നേടുക" with an "Upgrade / Pay Now" button."
class PaywallPrivacyLockCard extends StatelessWidget {
  final VoidCallback onUpgrade;
  final EdgeInsetsGeometry? margin;

  const PaywallPrivacyLockCard({
    super.key,
    required this.onUpgrade,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E1B4B), // Indigo 950
            Color(0xFF172554), // Blue 950
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient decoration circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Icon Badge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Premium Privacy Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFFCD34D),
                        size: 13,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'PREMIUM PRIVACY LOCK',
                        style: TextStyle(
                          color: Color(0xFFFCD34D),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Malayalam Headline
                const Text(
                  'ഫോൺ നമ്പറും ലൊക്കേഷൻ വിവരങ്ങളും കാണാൻ പ്രീമിയം അംഗത്വം നേടുക',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),

                // Explanatory Subtitle
                const Text(
                  'രജിസ്റ്റർ ചെയ്ത അംഗങ്ങളുടെ ഫോൺ നമ്പർ, വാട്ട്‌സ്ആപ്പ്, വീട്ടുപേര്, വിലാസം, മാപ്പ് നാവിഗേഷൻ എന്നിവ കാണുന്നതിന് പ്ലാൻ അപ്‌ഗ്രേഡ് ചെയ്യുക.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8), // Slate 400
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                // Locked Item Previews
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildLockedFeatureRow(
                        Icons.phone_locked_rounded,
                        'ഫോൺ നമ്പറും രക്ഷാധികാരിയുടെ ഫോണും',
                        '+91 ••••• •••••',
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      _buildLockedFeatureRow(
                        Icons.home_work_rounded,
                        'വീട്ടുപേരും പൂർണ്ണ വിലാസവും',
                        '•••••••••••••••••',
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      _buildLockedFeatureRow(
                        Icons.location_on_rounded,
                        'നേറ്റീവ് ലൊക്കേഷനും GPS മാപ്പും',
                        'Strictly Protected GPS',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Call to action button: "Upgrade / Pay Now"
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onUpgrade,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF59E0B),
                            Color(0xFFD97706),
                            Color(0xFFB45309),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Upgrade / Pay Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedFeatureRow(IconData icon, String title, String maskedPreview) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFCD34D)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 10, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text(
                maskedPreview,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
