import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfcard.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfcardpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/mock_data.dart';

class CashfreeService {
  static final CashfreeService _instance = CashfreeService._internal();
  factory CashfreeService() => _instance;
  CashfreeService._internal();

  final CFPaymentGatewayService _cfPaymentGatewayService =
      CFPaymentGatewayService();
  Function()? _onPaymentSuccessCallback;
  Function(String)? _onPaymentFailureCallback;
  String? _lastOrderError;

  String? _currentUserId;
  String? _currentPlanType;

  /// Open checkout with pre-existing session token
  void openCheckout({
    required String orderId,
    required String paymentSessionId,
    required Function(String) onVerify,
    required Function(dynamic) onError,
  }) {
    try {
      if (paymentSessionId.trim().isEmpty || paymentSessionId == 'null') {
        onError("Payment Session ID is missing or invalid.");
        return;
      }

      _cfPaymentGatewayService.setCallback(
        (verifiedOrderId) {
          onVerify(verifiedOrderId);
        },
        (errorResponse, failedOrderId) {
          onError(errorResponse);
        },
      );

      final envSetting = dotenv.env['CASHFREE_ENVIRONMENT'] ?? 'SANDBOX';
      final isProd =
          envSetting.toUpperCase() == 'PROD' ||
          envSetting.toUpperCase() == 'PRODUCTION';
      final cfEnv = isProd ? CFEnvironment.PRODUCTION : CFEnvironment.SANDBOX;

      final session = CFSessionBuilder()
          .setEnvironment(cfEnv)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId.trim())
          .build();

      // ignore: deprecated_member_use
      final cfDropCheckoutPayment = CFDropCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      _cfPaymentGatewayService.doPayment(cfDropCheckoutPayment);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Main method to start subscription checkout (Drop Checkout)
  Future<void> startPayment({
    required String orderId,
    required double orderAmount,
    required String customerId,
    required String customerPhone,
    required String customerName,
    required String customerEmail,
    required String planName,
    required String tierName,
    required int durationMonths,
    required Function() onSuccess,
    required Function(String) onFailure,
  }) async {
    _onPaymentSuccessCallback = onSuccess;
    _onPaymentFailureCallback = onFailure;
    _lastOrderError = null;
    _currentUserId = customerId;
    _currentPlanType = tierName;

    debugPrint("=== [CashfreeService] Starting Payment Process ===");
    debugPrint(
      "Order ID: $orderId, Amount: $orderAmount, Customer: $customerName ($customerPhone)",
    );

    try {
      // 1. Create order and get session ID
      final resData = await _createCashfreeOrder(
        orderId: orderId,
        orderAmount: orderAmount,
        customerId: customerId,
        customerPhone: customerPhone,
        customerName: customerName,
        customerEmail: customerEmail,
        planName: planName,
        tierName: tierName,
        durationMonths: durationMonths,
      );

      if (resData == null) {
        final errorMsg =
            _lastOrderError ??
            'Failed to generate payment session from server.';
        debugPrint("[CashfreeService] Order creation returned null: $errorMsg");
        onFailure(errorMsg);
        return;
      }

      final dataMap = resData is Map<String, dynamic>
          ? resData
          : (resData is Map
                ? Map<String, dynamic>.from(resData)
                : <String, dynamic>{});

      debugPrint("[CashfreeService] Backend Order Data: $dataMap");

      // Extract session ID
      final String sessionId =
          (dataMap['payment_session_id'] ??
                  dataMap['paymentSessionId'] ??
                  dataMap['data']?['payment_session_id'] ??
                  '')
              .toString()
              .trim();

      final String responseOrderId =
          (dataMap['order_id'] ??
                  dataMap['orderId'] ??
                  dataMap['data']?['order_id'] ??
                  orderId)
              .toString()
              .trim();

      // Strict validation: Prevent SDK invocation if token is empty/invalid
      if (sessionId.isEmpty || sessionId == 'null') {
        final errorDetail =
            dataMap['error'] ?? _lastOrderError ?? 'Session token is empty';
        debugPrint(
          "[CashfreeService] CRITICAL: Invalid session token. Raw response: $dataMap",
        );
        onFailure("Payment session initialization failed: $errorDetail");
        return;
      }

      // Determine Environment (Match backend environment)
      final envFromBackend = (dataMap['environment'] ?? '')
          .toString()
          .toUpperCase();
      final envSetting =
          (dotenv.env['CASHFREE_ENVIRONMENT'] ??
                  (envFromBackend.isNotEmpty ? envFromBackend : 'SANDBOX'))
              .trim();
      final isProd =
          envSetting.toUpperCase() == 'PROD' ||
          envSetting.toUpperCase() == 'PRODUCTION';
      final cfEnv = isProd ? CFEnvironment.PRODUCTION : CFEnvironment.SANDBOX;

      debugPrint(
        "[CashfreeService] Session Validated: Order=$responseOrderId, SessionId=$sessionId, Env=$cfEnv",
      );

      final String checkoutUrl =
          (dataMap['checkout_url'] != null &&
              dataMap['checkout_url'].toString().isNotEmpty)
          ? dataMap['checkout_url'].toString()
          : (isProd
                ? 'https://api.cashfree.com/pg/view/sessions/$sessionId'
                : 'https://sandbox.cashfree.com/pg/view/sessions/$sessionId');

      // Web platform handling
      if (kIsWeb) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } else {
          final cfSession = CFSessionBuilder()
              .setEnvironment(cfEnv)
              .setOrderId(responseOrderId)
              .setPaymentSessionId(sessionId)
              .build();
          final cfWebCheckout = CFWebCheckoutPaymentBuilder()
              .setSession(cfSession)
              .build();
          _cfPaymentGatewayService.setCallback(_verifyPayment, _onError);
          _cfPaymentGatewayService.doPayment(cfWebCheckout);
        }
        return;
      }

      // Mobile (Android / iOS) drop checkout
      final session = CFSessionBuilder()
          .setEnvironment(cfEnv)
          .setOrderId(responseOrderId)
          .setPaymentSessionId(sessionId)
          .build();

      // ignore: deprecated_member_use
      final cfDropCheckoutPayment = CFDropCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      _cfPaymentGatewayService.setCallback(_verifyPayment, _onError);
      _cfPaymentGatewayService.doPayment(cfDropCheckoutPayment);
    } on CFException catch (e) {
      debugPrint("[CashfreeService] CFException: ${e.message}");
      onFailure(e.message);
    } catch (e, stack) {
      debugPrint("[CashfreeService] Exception during checkout: $e\n$stack");
      onFailure("Error initiating payment: $e");
    }
  }

  /// Card Payment method
  Future<void> startCardPayment({
    required String orderId,
    required double orderAmount,
    required String customerId,
    required String customerPhone,
    required String customerName,
    required String customerEmail,
    required String cardNumber,
    required String cardHolderName,
    required String cardExpiryMonth,
    required String cardExpiryYear,
    required String cardCvv,
    required String planName,
    required String tierName,
    required int durationMonths,
    required Function() onSuccess,
    required Function(String) onFailure,
  }) async {
    _onPaymentSuccessCallback = onSuccess;
    _onPaymentFailureCallback = onFailure;
    _lastOrderError = null;
    _currentUserId = customerId;
    _currentPlanType = tierName;

    try {
      final resData = await _createCashfreeOrder(
        orderId: orderId,
        orderAmount: orderAmount,
        customerId: customerId,
        customerPhone: customerPhone,
        customerName: customerName,
        customerEmail: customerEmail,
        planName: planName,
        tierName: tierName,
        durationMonths: durationMonths,
      );

      if (resData == null) {
        onFailure(_lastOrderError ?? 'Server returned empty response');
        return;
      }

      final dataMap = resData is Map<String, dynamic>
          ? resData
          : (resData is Map
                ? Map<String, dynamic>.from(resData)
                : <String, dynamic>{});

      final String sessionId =
          (dataMap['payment_session_id'] ??
                  dataMap['paymentSessionId'] ??
                  dataMap['data']?['payment_session_id'] ??
                  '')
              .toString()
              .trim();

      final String responseOrderId =
          (dataMap['order_id'] ??
                  dataMap['orderId'] ??
                  dataMap['data']?['order_id'] ??
                  orderId)
              .toString()
              .trim();

      if (sessionId.isEmpty || sessionId == 'null') {
        onFailure(
          'Payment Session ID is missing in response: ${_lastOrderError ?? dataMap}',
        );
        return;
      }

      final envSetting = dotenv.env['CASHFREE_ENVIRONMENT'] ?? 'SANDBOX';
      final isProd =
          envSetting.toUpperCase() == 'PROD' ||
          envSetting.toUpperCase() == 'PRODUCTION';
      final cfEnv = isProd ? CFEnvironment.PRODUCTION : CFEnvironment.SANDBOX;

      final cfSession = CFSessionBuilder()
          .setEnvironment(cfEnv)
          .setOrderId(responseOrderId)
          .setPaymentSessionId(sessionId)
          .build();

      final card = CFCardBuilder()
          .setCardHolderName(cardHolderName)
          .setCardExpiryMonth(cardExpiryMonth)
          .setCardExpiryYear(cardExpiryYear)
          .setCardCVV(cardCvv)
          .build();

      final cardPayment = CFCardPaymentBuilder()
          .setSession(cfSession)
          .setCard(card)
          .build();

      _cfPaymentGatewayService.setCallback(_verifyPayment, _onError);
      _cfPaymentGatewayService.doPayment(cardPayment);
    } on CFException catch (e) {
      debugPrint("[CashfreeService] Card Payment Error: ${e.message}");
      onFailure(e.message);
    } catch (e) {
      debugPrint("[CashfreeService] Card Payment Error: $e");
      onFailure(e.toString());
    }
  }

  /// UPI Payment method
  Future<void> startUpiPayment({
    required String orderId,
    required double orderAmount,
    required String customerId,
    required String customerPhone,
    required String customerName,
    required String customerEmail,
    required String appName,
    required String planName,
    required String tierName,
    required int durationMonths,
    required Function() onSuccess,
    required Function(String) onFailure,
  }) async {
    return startPayment(
      orderId: orderId,
      orderAmount: orderAmount,
      customerId: customerId,
      customerPhone: customerPhone,
      customerName: customerName,
      customerEmail: customerEmail,
      planName: planName,
      tierName: tierName,
      durationMonths: durationMonths,
      onSuccess: onSuccess,
      onFailure: onFailure,
    );
  }

  /// Initiates a refund for an existing order via Cashfree API
  Future<bool> issueRefund({
    required String orderId,
    required double refundAmount,
    String? refundNote,
  }) async {
    final appId = dotenv.env['CASHFREE_APP_ID'];
    final secretKey = dotenv.env['CASHFREE_SECRET_KEY'];
    final environment = dotenv.env['CASHFREE_ENVIRONMENT'] ?? 'PRODUCTION';

    if (appId == null || secretKey == null) {
      debugPrint(
        "[CashfreeService] Cashfree credentials not found in .env for refund",
      );
      return false;
    }

    final String baseUrl =
        (environment.toUpperCase() == 'PROD' ||
            environment.toUpperCase() == 'PRODUCTION')
        ? 'https://api.cashfree.com/pg/orders/$orderId/refunds'
        : 'https://sandbox.cashfree.com/pg/orders/$orderId/refunds';

    final refundId =
        'refund_${orderId}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-client-id': appId,
          'x-client-secret': secretKey,
          'x-api-version': '2023-08-01',
        },
        body: jsonEncode({
          "refund_amount": refundAmount,
          "refund_id": refundId,
          "refund_note": refundNote ?? "Admin requested refund",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("[CashfreeService] Refund successful for order: $orderId");
        return true;
      } else {
        debugPrint(
          "[CashfreeService] Refund failed (${response.statusCode}): ${response.body}",
        );
        return false;
      }
    } catch (e) {
      debugPrint("[CashfreeService] Refund request error: $e");
      return false;
    }
  }

  /// Calls the Supabase Edge Function to create Cashfree Order, with direct API fallback
  Future<dynamic> _createCashfreeOrder({
    required String orderId,
    required double orderAmount,
    required String customerId,
    required String customerPhone,
    required String customerName,
    required String customerEmail,
    required String planName,
    required String tierName,
    required int durationMonths,
  }) async {
    _lastOrderError = null;

    final validOrderId = orderId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    String cleanPhone = customerPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length > 10)
  { cleanPhone = cleanPhone.substring(cleanPhone.length - 10); }
    if (cleanPhone.length < 10) cleanPhone = "9999999999";

    // 1. Invoke Supabase Edge Function
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final headers = <String, String>{};
      if (session?.accessToken != null && session!.accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
      }

      debugPrint(
        "[CashfreeService] Invoking Edge Function 'create-cashfree-order'...",
      );
      final res = await Supabase.instance.client.functions.invoke(
        'create-cashfree-order',
        headers: headers.isNotEmpty ? headers : null,
        body: {
          'orderId': validOrderId,
          'amount': orderAmount,
          'userId': customerId,
          'userPhone': cleanPhone,
          'userName': customerName,
          'userEmail': customerEmail,
          'planName': planName,
          'tierName': tierName,
          'durationMonths': durationMonths,
        },
      );

      final responseData = res.data;
      debugPrint("[CashfreeService] Edge Function HTTP Status: ${res.status}");
      debugPrint(
        "[CashfreeService] Edge Function Response Data: $responseData",
      );

      if (responseData != null) {
        Map<String, dynamic> dataMap = {};
        if (responseData is Map<String, dynamic>) {
          dataMap = responseData;
        } else if (responseData is Map) {
          dataMap = Map<String, dynamic>.from(responseData);
        } else if (responseData is String) {
          try {
            dataMap = jsonDecode(responseData);
          } catch (_) {}
        }

        final sessionId =
            dataMap['payment_session_id'] ?? dataMap['paymentSessionId'];
        if (sessionId != null && sessionId.toString().trim().isNotEmpty) {
          debugPrint(
            "[CashfreeService] Valid payment_session_id obtained from Edge Function!",
          );
          dataMap['order_id'] ??= validOrderId;
          return dataMap;
        } else if (dataMap['error'] != null) {
          _lastOrderError = dataMap['error'].toString();
        }
      }
    } catch (efErr) {
      debugPrint(
        "[CashfreeService] Edge Function call failed: $efErr. Attempting direct API fallback...",
      );
      _lastOrderError = efErr.toString();
    }

    // 2. Direct Cashfree PG Gateway API Fallback
    try {
      String appId =
          (dotenv.env['CASHFREE_APP_ID'] ??
                  "TEST11126249ee0a29c851378c6515fe94262111")
              .trim();
      String secretKey =
          (dotenv.env['CASHFREE_SECRET_KEY'] ??
                  "cfsk_ma_test_56dcce3661b2d5519f688c23f01540c4_10bea3ee")
              .trim();
      String envSetting = (dotenv.env['CASHFREE_ENVIRONMENT'] ?? 'SANDBOX')
          .trim();

      final isProd =
          envSetting.toUpperCase() == 'PROD' ||
          envSetting.toUpperCase() == 'PRODUCTION';
      final baseUrl = isProd
          ? "https://api.cashfree.com/pg/orders"
          : "https://sandbox.cashfree.com/pg/orders";

      debugPrint(
        "[CashfreeService] Direct API Call -> $baseUrl (Env: $envSetting)",
      );

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-client-id': appId,
          'x-client-secret': secretKey,
          'x-api-version': '2023-08-01',
        },
        body: jsonEncode({
          "order_id": validOrderId,
          "order_amount": double.parse(orderAmount.toStringAsFixed(2)),
          "order_currency": "INR",
          "order_note": planName.isNotEmpty
              ? "Subscription: $planName"
              : "Subscription Payment",
          "customer_details": {
            "customer_id": customerId.isNotEmpty
                ? customerId
                : "cust_${DateTime.now().millisecondsSinceEpoch}",
            "customer_phone": cleanPhone,
            "customer_email": customerEmail.isNotEmpty
                ? customerEmail
                : "user@kurichiyarmatrimony.in",
            "customer_name": customerName.isNotEmpty
                ? customerName
                : "Customer",
          },
          "order_meta": {
            "return_url":
                "https://kuricharmatrimony.vercel.app/#/payment-status?order_id={order_id}",
          },
        }),
      );

      final responseBody = jsonDecode(response.body);
      debugPrint(
        "[CashfreeService] Direct API Response (${response.statusCode}): $responseBody",
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseBody is Map) {
        final Map<String, dynamic> dataMap = Map<String, dynamic>.from(
          responseBody,
        );
        final sessionId = dataMap['payment_session_id'];
        if (sessionId != null && sessionId.toString().trim().isNotEmpty) {
          dataMap['order_id'] = validOrderId;
          dataMap['environment'] = isProd ? "PRODUCTION" : "SANDBOX";
          dataMap['checkout_url'] = isProd
              ? 'https://api.cashfree.com/pg/view/sessions/$sessionId'
              : 'https://sandbox.cashfree.com/pg/view/sessions/$sessionId';
          return dataMap;
        }
      }

      _lastOrderError =
          responseBody['message'] ??
          responseBody['error'] ??
          'Direct API failed with status ${response.statusCode}';
      return null;
    } catch (directErr) {
      debugPrint("[CashfreeService] Direct API Exception: $directErr");
      _lastOrderError = directErr.toString();
      return null;
    }
  }

  Future<void> _verifyPayment(String orderId) async {
    debugPrint(
      "[CashfreeService] Payment SDK success callback received for order: $orderId. Verifying on server...",
    );
    try {
      final uid =
          _currentUserId ?? Supabase.instance.client.auth.currentUser?.id;
      final payload = {
        'orderId': orderId,
        'userId': uid,
        'planType': _currentPlanType ?? 'Gold',
      };

      dynamic res;
      try {
        res = await Supabase.instance.client.functions.invoke(
          'verify-cashfree-order',
          body: payload,
        );
      } catch (_) {
        res = await Supabase.instance.client.functions.invoke(
          'verify-payment',
          body: payload,
        );
      }

      if (res.status == 200) {
        debugPrint(
          "[CashfreeService] Payment verification succeeded on server!",
        );
        _onPaymentSuccessCallback?.call();
        try {
          await MockData().refreshCurrentUserProfile();
        } catch (e) {
          debugPrint('Error refreshing profile after payment success: $e');
        }
      } else {
        throw Exception(
          res.data?.toString() ?? 'Verification HTTP ${res.status}',
        );
      }
    } catch (e) {
      debugPrint("[CashfreeService] Verification Error: $e");
      _onPaymentFailureCallback?.call(
        "Payment completed, but verification timed out. Your subscription will activate shortly.",
      );
    }
  }

  void _onError(CFErrorResponse errorResponse, String orderId) {
    debugPrint(
      "[CashfreeService] SDK Payment Failed -> Message: ${errorResponse.getMessage()}, Code: ${errorResponse.getCode()}, Status: ${errorResponse.getStatus()}",
    );
    final msg = errorResponse.getMessage() ?? "Payment failed";
    final code = (errorResponse.getCode() ?? "").toLowerCase();

    if (code.contains("cancelled") ||
        code.contains("user_cancelled") ||
        msg.toLowerCase().contains("cancelled") ||
        msg.toLowerCase().contains("user_dropped") ||
        msg.toLowerCase().contains("payment cancelled")) {
      _onPaymentFailureCallback?.call("Payment was cancelled.");
    } else {
      _onPaymentFailureCallback?.call(msg);
    }
  }
}
