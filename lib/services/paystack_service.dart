import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:flutter_paystack_plus/src/non_web_pay_compnt.dart';

/// Unified PaystackService for both web and mobile using flutter_paystack_plus
class PaystackService {
  /// Initiates a Paystack payment.
  ///
  /// For web: uses FlutterPaystackPlus.openPaystackPopup
  /// For mobile: pushes PaystackPayNow widget onto the navigation stack
  static Future<void> checkout({
    required BuildContext context,
    required String publicKey,
    required int amount,
    required String email,
    required String reference,
    String currency = 'NGN',
    String? callBackUrl,
    Map<String, dynamic>? metadata,
    required VoidCallback onSuccess,
    required VoidCallback onClosed,
  }) async {
    final amountStr = amount.toString();
    if (kIsWeb) {
      // Web: use the static popup
      await FlutterPaystackPlus.openPaystackPopup(
        customerEmail: email,
        amount: amountStr,
        reference: reference,
        publicKey: publicKey,
        currency: currency,
        metadata: metadata,
        onClosed: onClosed,
        onSuccess: onSuccess,
      );
    } else {
      // Mobile: push the PaystackPayNow widget
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PaystackPayNow(
            secretKey: publicKey,
            email: email,
            reference: reference,
            currency: currency,
            amount: amountStr,
            callbackUrl: callBackUrl ?? '',
            metadata: metadata,
            transactionCompleted: onSuccess,
            transactionNotCompleted: onClosed,
          ),
        ),
      );
    }
  }
}
