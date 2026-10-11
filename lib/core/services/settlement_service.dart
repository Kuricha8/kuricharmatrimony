import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../utils/mock_data.dart';
import 'notification_manager.dart';

/// Handles the strict financial arbitration rules for Escrow payouts
/// when a Mutual Agreement is cancelled.
class SettlementService {
  SettlementService._();
  static final SettlementService instance = SettlementService._();

  /// Executes the arbitration payout logic based on Admin's verdict.
  Future<void> executeArbitration({
    required MutualAgreement agreement,
    required DisputeStatus verdict,
  }) async {
    assert(
      verdict == DisputeStatus.resolvedBrideDefaulted ||
          verdict == DisputeStatus.resolvedGroomDefaulted,
      'Invalid verdict. Must select a defaulter.',
    );

    // 1. Update the agreement state in the database
    final updatedAgreement = agreement.copyWith(
      disputeStatus: verdict,
      totalEscrowBalance: 0, // Escrow is drained
    );
    MockData().updateAgreement(updatedAgreement);

    // 2. Identify the Innocent Party and Defaulter
    final bool brideDefaulted = verdict == DisputeStatus.resolvedBrideDefaulted;
    final String defaulterId = brideDefaulted
        ? agreement.brideId
        : agreement.groomId;
    final String innocentId = brideDefaulted
        ? agreement.groomId
        : agreement.brideId;

    // 3. Execute the Escrow Payouts (Mocking Cashfree Payout API)
    _executePayout(
      userId: innocentId,
      amount: 9000,
      description: 'Refund (₹7,000) + Arbitration Compensation (₹2,000)',
    );

    _sweepToAdminWallet(
      amount: 5000,
      description: 'Platform Arbitration Fee (swept from Defaulter)',
    );

    // 4. Dispatch Verdict Notifications & Emails
    final innocentName = _getUserName(innocentId);
    final defaulterName = _getUserName(defaulterId);

    // To Innocent
    NotificationManager.instance.sendTargetedTestNotification(
      target: innocentId,
      title: 'Dispute Resolved',
      body:
          '[DISPUTE RESOLVED] You were found innocent. ₹9,000 has been transferred to your bank account.',
    );
    _sendOfficialEmail(
      userId: innocentId,
      subject: 'Dispute Resolution: Favorable Verdict',
      body:
          'Dear $innocentName,\n\nThe Admin has reviewed the cancellation request. The other party ($defaulterName) was found at fault. We have initiated a payout of ₹9,000 to your verified bank account. This includes your ₹7,000 deposit and ₹2,000 in compensation.',
    );

    // To Defaulter
    NotificationManager.instance.sendTargetedTestNotification(
      target: defaulterId,
      title: 'Dispute Resolved',
      body:
          '[DISPUTE RESOLVED] You were marked as the defaulter. Your ₹7,000 escrow deposit has been forfeited.',
    );
    _sendOfficialEmail(
      userId: defaulterId,
      subject: 'Dispute Resolution: Unfavorable Verdict',
      body:
          'Dear $defaulterName,\n\nThe Admin has reviewed the cancellation request and assigned fault to you. Your ₹7,000 escrow deposit is forfeited. ₹2,000 was awarded to $innocentName as compensation, and ₹5,000 was withheld as platform arbitration fees.',
    );
  }

  // --- Mock Helpers ---

  void _executePayout({
    required String userId,
    required int amount,
    required String description,
  }) {
    debugPrint('===================================================');
    debugPrint('[CASHFREE PAYOUT ENGINE] Processing Payout');
    debugPrint('User ID     : $userId');
    debugPrint('Amount      : ₹$amount');
    debugPrint('Description : $description');
    debugPrint('Status      : SUCCESS');
    debugPrint('===================================================');
  }

  void _sweepToAdminWallet({required int amount, required String description}) {
    debugPrint('===================================================');
    debugPrint('[CASHFREE SETTLEMENT ENGINE] Sweeping to Admin');
    debugPrint('Amount      : ₹$amount');
    debugPrint('Description : $description');
    debugPrint('Status      : SUCCESS');
    debugPrint('===================================================');
  }

  void _sendOfficialEmail({
    required String userId,
    required String subject,
    required String body,
  }) {
    debugPrint('---------------------------------------------------');
    debugPrint('📧 EMAIL DISPATCHED TO: $userId');
    debugPrint('Subject: $subject');
    debugPrint('Body: \n$body');
    debugPrint('---------------------------------------------------');
  }

  String _getUserName(String userId) {
    final user = MockData().profiles.firstWhere(
      (p) => p.id == userId,
      orElse: () => MockData().currentUser!,
    );
    return user.name;
  }
}
