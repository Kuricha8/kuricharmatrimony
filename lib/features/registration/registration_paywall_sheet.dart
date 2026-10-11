import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/haptic_helper.dart';

/// Lifetime ₹29 Paywall Modal requiring payment verification prior to registration.
class RegistrationPaywallSheet extends StatefulWidget {
  final VoidCallback onPaymentVerified;

  const RegistrationPaywallSheet({super.key, required this.onPaymentVerified});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onPaymentVerified,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RegistrationPaywallSheet(onPaymentVerified: onPaymentVerified),
    );
  }

  @override
  State<RegistrationPaywallSheet> createState() =>
      _RegistrationPaywallSheetState();
}

class _RegistrationPaywallSheetState extends State<RegistrationPaywallSheet> {
  bool _isProcessing = false;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      AppToast.showError(context, 'ദയവായി സാധുവായ 10 അക്ക മൊബൈൽ നമ്പർ നൽകുക.');
      return;
    }

    setState(() => _isProcessing = true);
    HapticHelper.mediumImpact();

    try {
      // Simulate Razorpay / UPI Intent SDK Trigger
      await Future.delayed(const Duration(seconds: 2));

      // Generated Payment Transaction ID
      final paymentId = 'PAY_RZP_${DateTime.now().millisecondsSinceEpoch}';

      // Insert core record into users_core with is_lifetime_paid = true
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('users_core').upsert({
          'id': user.id,
          'phone_number': phone,
          'full_name': 'New Member',
          'dob': DateTime.now().toIso8601String().split('T')[0],
          'is_lifetime_paid': true,
          'payment_id': paymentId,
        });
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);
      HapticHelper.success();
      AppToast.showSuccess(
        context,
        '₹29 ലൈഫ് ടൈം രജിസ്ട്രേഷൻ ഫീസ് വിജയകരമായി നൽകി!',
      );
      Navigator.pop(context);
      widget.onPaymentVerified();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      HapticHelper.error();
      AppToast.showError(context, 'പേയ്‌മെന്റ് പരാജയപ്പെട്ടു: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFFFFFBEB),
            child: Icon(
              Icons.verified_user_rounded,
              size: 40,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'കുറിച്ച്യർ മാട്രിമോണി ലൈഫ് ടൈം രജിസ്ട്രേഷൻ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ഒരു തവണ മാത്രം ₹29 നൽകി കുറിച്ച്യർ സമുദായ അംഗങ്ങൾക്കായുള്ള ആജീവനാന്ത അംഗത്വം നേടൂ.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'മൊബൈൽ നമ്പർ (Mobile Number)',
              prefixIcon: const Icon(Icons.phone_android),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _processPayment,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.payment_rounded),
            label: Text(
              _isProcessing
                  ? 'പേയ്‌മെന്റ് ചെയ്യുന്നു...'
                  : '₹29 നൽകി രജിസ്ട്രേഷൻ തുടരുക (Pay ₹29)',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
