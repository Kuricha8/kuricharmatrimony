import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/unlocked_contacts_provider.dart';
import '../../core/services/payment_service.dart';
import '../../core/utils/mock_data.dart';
import '../../features/subscriptions/subscription_page.dart';

/// Reusable Widget for displaying phone numbers locked behind a Cashfree paywall.
///
/// Features:
/// - Masked format by default (`+91 86*****5174`).
/// - Reactive state sync across all screens via [UnlockedContactsProvider].
/// - If unlocked: displays complete unmasked phone number with direct Call, Copy & WhatsApp buttons.
/// - If locked: displays "Unlock Contact ₹49" button triggering [PaymentService].
class LockedPhoneNumberWidget extends StatelessWidget {
  final String targetUserId;
  final String? phoneNumber;
  final bool? isAlreadyUnlocked;
  final String? label;
  final bool compact;
  final TextStyle? textStyle;
  final Color? buttonColor;

  const LockedPhoneNumberWidget({
    super.key,
    required this.targetUserId,
    required this.phoneNumber,
    this.isAlreadyUnlocked,
    this.label,
    this.compact = false,
    this.textStyle,
    this.buttonColor,
  });

  /// Formats raw phone number into masked string: `+91 86*****5174`
  String _maskPhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return "നമ്പർ ലഭ്യമല്ല";
    }
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length >= 10) {
      final firstTwo = clean.substring(clean.length - 10, clean.length - 8);
      final lastFour = clean.substring(clean.length - 4);
      return "+91 $firstTwo*****$lastFour";
    } else if (clean.length >= 4) {
      final lastFour = clean.substring(clean.length - 4);
      return "+91 ******$lastFour";
    }
    return "+91 **********";
  }

  /// Format phone to standard display string
  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return "Not Available";
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return "+91 ${clean.substring(0, 5)} ${clean.substring(5)}";
    }
    return phone;
  }

  /// Launch phone call using url_launcher
  Future<void> _makeCall(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse('tel:+$cleanPhone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Fallback: direct launch
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone dialer: $e')),
        );
      }
    }
  }

  /// Copy phone number to Clipboard
  void _copyToClipboard(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Phone number copied ($phone)'),
          ],
        ),
        backgroundColor: const Color(0xFF000080),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Open WhatsApp chat
  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse('https://wa.me/91$cleanPhone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Watch global unlocked state provider so all widgets update reactively across screens
    final unlockedProvider = context.watch<UnlockedContactsProvider>();
    final bool isUnlockedGlobally = unlockedProvider.isUnlocked(targetUserId);
    final bool unlocked = (isAlreadyUnlocked == true) || isUnlockedGlobally;

    final String displayPhone = phoneNumber?.trim() ?? '';
    final String maskedText = _maskPhoneNumber(displayPhone);
    final String fullText = _formatPhoneNumber(displayPhone);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: unlocked ? Colors.green.shade50 : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: unlocked ? Colors.green.shade300 : Colors.amber.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unlocked ? Icons.phone : Icons.phone_locked,
              size: 14,
              color: unlocked ? Colors.green.shade800 : Colors.amber.shade900,
            ),
            const SizedBox(width: 6),
            Text(
              unlocked ? fullText : maskedText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: unlocked ? Colors.green.shade900 : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            if (unlocked) ...[
              InkWell(
                onTap: () => _makeCall(context, displayPhone),
                child: const Icon(Icons.call, size: 14, color: Colors.green),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _copyToClipboard(context, displayPhone),
                child: const Icon(Icons.copy, size: 14, color: Colors.blue),
              ),
            ] else ...[
              InkWell(
                onTap: () => _handleUnlockTap(context, displayPhone),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: buttonColor ?? const Color(0xFF000080),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Unlock ₹49',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: unlocked ? Colors.green.shade200 : Colors.amber.shade300,
        ),
      ),
      color: unlocked ? const Color(0xFFF4FBF7) : const Color(0xFFFFFBF0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      unlocked ? Icons.phone : Icons.phone_locked,
                      size: 18,
                      color: unlocked
                          ? Colors.green.shade700
                          : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label ??
                          (unlocked
                              ? 'Unlocked Contact Number'
                              : 'Locked Contact Number'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: unlocked
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
                if (unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 12,
                          color: Colors.green.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'UNLOCKED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 12,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LOCKED (₹49)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    unlocked ? fullText : maskedText,
                    style:
                        textStyle ??
                        TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: unlocked ? 0.5 : 1.2,
                          color: Colors.black87,
                        ),
                  ),
                ),
                if (unlocked) ...[
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _makeCall(context, displayPhone),
                        icon: const Icon(Icons.call, size: 14),
                        label: const Text(
                          'Call',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Copy Number',
                        icon: const Icon(
                          Icons.copy,
                          size: 18,
                          color: Colors.blue,
                        ),
                        onPressed: () =>
                            _copyToClipboard(context, displayPhone),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                      IconButton(
                        tooltip: 'WhatsApp',
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: Colors.green,
                        ),
                        onPressed: () => _openWhatsApp(context, displayPhone),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                    ],
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor ?? const Color(0xFF000080),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _handleUnlockTap(context, displayPhone),
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: const Text(
                      'Unlock (₹49)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleUnlockTap(BuildContext context, String displayPhone) {
    final me = MockData().currentUser;
    if (me == null || !me.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contact details are available for PREMIUM users only. Please upgrade your subscription first!',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SubscriptionPage(currentUser: me ?? MockData().currentUser!),
        ),
      );
    } else {
      PaymentService().unlockContact(
        context: context,
        targetUserId: targetUserId,
        targetPhoneNumber: displayPhone,
        amount: 49.0,
      );
    }
  }
}
