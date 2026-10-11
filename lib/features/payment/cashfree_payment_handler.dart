import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';

class CashfreePaymentHandler {
  final CFPaymentGatewayService _cfPaymentGatewayService =
      CFPaymentGatewayService();
  final BuildContext context;
  final Function(String orderId) onPaymentSuccess;
  final Function(String errorMessage) onPaymentFailure;

  CashfreePaymentHandler({
    required this.context,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
  }) {
    _cfPaymentGatewayService.setCallback(
      (orderId) {
        onPaymentSuccess(orderId);
      },
      (errorResponse, orderId) {
        onPaymentFailure(
          errorResponse.getMessage() ?? "പേയ്മെന്റ് പരാജയപ്പെട്ടു",
        );
      },
    );
  }

  /// Cashfree Session ID വെച്ച് പേയ്മെന്റ് വിൻഡോ ഓപ്പൺ ചെയ്യുന്നു
  void initiateCashfreePayment({
    required String orderId,
    required String paymentSessionId,
    CFEnvironment environment = CFEnvironment.PRODUCTION,
  }) {
    try {
      var session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();

      // ignore: deprecated_member_use
      var dropCheckout = CFDropCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      _cfPaymentGatewayService.doPayment(dropCheckout);
    } catch (e) {
      onPaymentFailure(e.toString());
    }
  }
}
