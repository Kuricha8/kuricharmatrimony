import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/haptic_helper.dart';
import '../premium_packages/cashfree_service.dart';
import 'smart_kinship_registration_wizard.dart';

/// Public Hub Custom BottomSheet Modal triggering Cashfree PG SDK for ₹29 Lifetime Membership.
class PublicHubCashfreePaywallSheet extends StatefulWidget {
  final VoidCallback? onPaymentSuccess;

  const PublicHubCashfreePaywallSheet({super.key, this.onPaymentSuccess});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onPaymentSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          PublicHubCashfreePaywallSheet(onPaymentSuccess: onPaymentSuccess),
    );
  }

  @override
  State<PublicHubCashfreePaywallSheet> createState() =>
      _PublicHubCashfreePaywallSheetState();
}

class _PublicHubCashfreePaywallSheetState
    extends State<PublicHubCashfreePaywallSheet> {
  bool _isProcessing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _startCashfreePayment() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      AppToast.showError(context, 'ദയവായി നിങ്ങളുടെ പേര് നൽകുക.');
      return;
    }

    if (phone.length < 10) {
      AppToast.showError(context, 'ദയവായി സാധുവായ 10 അക്ക മൊബൈൽ നമ്പർ നൽകുക.');
      return;
    }

    setState(() => _isProcessing = true);
    HapticHelper.mediumImpact();

    final orderId = 'KM_LIFETIME_${DateTime.now().millisecondsSinceEpoch}';
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    await CashfreeService().startPayment(
      orderId: orderId,
      orderAmount: 29.0,
      customerId: userId,
      customerPhone: phone,
      customerName: name,
      customerEmail: user?.email ?? '$phone@kurichiyarmatrimony.in',
      planName: 'Lifetime Membership Fee',
      tierName: 'Lifetime',
      durationMonths: 999,
      onSuccess: () async {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        HapticHelper.success();
        AppToast.showSuccess(
          context,
          '₹29 ക്യാഷ്ഫ്രീ പേയ്‌മെന്റ് വിജയിച്ചു! രജിസ്ട്രേഷൻ ഫോം തുറക്കുന്നു...',
        );

        // Upsert user_core record and insert payment record
        try {
          await Supabase.instance.client.from('users_core').upsert({
            'id': userId,
            'phone_number': phone,
            'full_name': name,
            'dob': DateTime.now().toIso8601String().split('T')[0],
            'is_lifetime_paid': true,
            'payment_id': orderId,
          });

          await Supabase.instance.client.from('user_payments').insert({
            'user_phone': phone,
            'cashfree_order_id': orderId,
            'amount': 29.00,
            'payment_status': 'PAID',
            'payment_gateway': 'CASHFREE',
          });
        } catch (e) {
          debugPrint('Error updating core user payment state: $e');
        }

        if (!mounted) return;
        Navigator.pop(context);

        // Open Full Kinship Registration Form Wizard
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SmartKinshipRegistrationWizard(),
          ),
        );

        widget.onPaymentSuccess?.call();
      },
      onFailure: (errorMsg) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        HapticHelper.error();
        AppToast.showError(context, 'പേയ്‌മെന്റ് പരാജയപ്പെട്ടു: $errorMsg');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 38,
            backgroundColor: Color(0xFFF1F5F9),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 44,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'കുറിച്ച്യർ പബ്ലിക് ഹബ് ലൈഫ്ടൈം മെമ്പർഷിപ്പ്',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '₹29 ഒരു തവണ മാത്രം നൽകി തറവാട് വംശാവലി നെറ്റ്‌വർക്കിലേക്ക് പ്രവേശിക്കൂ. Cashfree (UPI / GPay / PhonePe / Card) വഴി സുരക്ഷിതമായി പേയ്‌മെന്റ് ചെയ്യാം.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'പേര് (Full Name)',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _startCashfreePayment,
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
                  ? 'ക്യാഷ്ഫ്രീ പേയ്‌മെന്റ് പ്രോസസ്സ് ചെയ്യുന്നു...'
                  : 'Cashfree വഴി ₹29 നൽകുക (Pay ₹29)',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
