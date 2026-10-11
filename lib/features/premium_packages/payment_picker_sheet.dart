import 'package:flutter/material.dart';
import 'card_form_widget.dart';

class PaymentPickerSheet extends StatefulWidget {
  final double amount;
  final Function(String paymentType, Map<String, dynamic> paymentData)
  onPaymentSelected;

  const PaymentPickerSheet({
    super.key,
    required this.amount,
    required this.onPaymentSelected,
  });

  @override
  State<PaymentPickerSheet> createState() => _PaymentPickerSheetState();
}

class _PaymentPickerSheetState extends State<PaymentPickerSheet> {
  String _selectedMethod = 'card';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo_kym.png',
                        height: 48,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.favorite,
                              color: Color(0xFFD4AF37),
                              size: 48,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kurichiyar Matrimony',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Color(0xFF5C3E00),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Complete Payment of ₹${widget.amount.toInt()}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C3E00),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PaymentMethodChip(
                    label: 'Card',
                    icon: Icons.credit_card,
                    isSelected: _selectedMethod == 'card',
                    onTap: () => setState(() => _selectedMethod = 'card'),
                  ),
                  _PaymentMethodChip(
                    label: 'UPI',
                    icon: Icons.qr_code,
                    isSelected: _selectedMethod == 'upi',
                    onTap: () => setState(() => _selectedMethod = 'upi'),
                  ),
                  _PaymentMethodChip(
                    label: 'Net Banking',
                    icon: Icons.account_balance,
                    isSelected: _selectedMethod == 'netbanking',
                    onTap: () => setState(() => _selectedMethod = 'netbanking'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedMethod == 'card')
                CardFormWidget(
                  onPay: (cardNumber, expiry, cvv, name) {
                    widget.onPaymentSelected('card', {
                      'cardNumber': cardNumber,
                      'expiry': expiry,
                      'cvv': cvv,
                      'name': name,
                    });
                  },
                )
              else if (_selectedMethod == 'upi')
                _buildUpiPlaceholder()
              else if (_selectedMethod == 'netbanking')
                _buildNetBankingPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpiPlaceholder() {
    return Column(
      children: [
        const Text('Scan QR or enter UPI ID'),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Enter UPI ID (e.g. name@bank)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () =>
              widget.onPaymentSelected('upi', {'upiId': 'simulated@upi'}),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000080),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text(
            'Pay with UPI',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildNetBankingPlaceholder() {
    return Column(
      children: [
        const Text('Select your Bank'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('SBI'),
              onPressed: () => _payNb('SBI'),
            ),
            ActionChip(
              label: const Text('HDFC'),
              onPressed: () => _payNb('HDFC'),
            ),
            ActionChip(
              label: const Text('ICICI'),
              onPressed: () => _payNb('ICICI'),
            ),
            ActionChip(
              label: const Text('Axis'),
              onPressed: () => _payNb('Axis'),
            ),
          ],
        ),
      ],
    );
  }

  void _payNb(String bank) {
    widget.onPaymentSelected('netbanking', {'bank': bank});
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB8860B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFB8860B) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFB8860B).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
