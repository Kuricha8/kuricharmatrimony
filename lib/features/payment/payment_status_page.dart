import 'package:flutter/material.dart';

enum PaymentStatus { success, failed, processing }

class PaymentStatusPage extends StatelessWidget {
  final PaymentStatus status;
  final String packageName;
  final VoidCallback onHomePressed;
  final VoidCallback onRetryPressed;

  const PaymentStatusPage({
    super.key,
    required this.status,
    required this.packageName,
    required this.onHomePressed,
    required this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              _buildStatusIcon(),
              const SizedBox(height: 24),
              _buildTitle(theme),
              const SizedBox(height: 12),
              _buildSubtitle(),
              const Spacer(),
              _buildActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case PaymentStatus.success:
        return const Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 96,
        );
      case PaymentStatus.failed:
        return const Icon(Icons.cancel_rounded, color: Colors.red, size: 96);
      case PaymentStatus.processing:
        return const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(strokeWidth: 6, color: Colors.amber),
        );
    }
  }

  Widget _buildTitle(ThemeData theme) {
    String text;
    switch (status) {
      case PaymentStatus.success:
        text = 'Payment Successful!';
        break;
      case PaymentStatus.failed:
        text = 'Payment Failed';
        break;
      case PaymentStatus.processing:
        text = 'Processing Payment...';
        break;
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF5C3E00),
      ),
    );
  }

  Widget _buildSubtitle() {
    String text;
    switch (status) {
      case PaymentStatus.success:
        text =
            'Your premium package "$packageName" is now active. You have unlocked all premium benefits!';
        break;
      case PaymentStatus.failed:
        text =
            'The transaction could not be completed. Please check your bank details or try using a different payment method.';
        break;
      case PaymentStatus.processing:
        text =
            'Waiting for bank confirmation. Please do not close the app or navigate away.';
        break;
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (status == PaymentStatus.processing) return const SizedBox.shrink();
    final isSuccess = status == PaymentStatus.success;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isSuccess ? onHomePressed : onRetryPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isSuccess ? 'Go to Home' : 'Retry',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
