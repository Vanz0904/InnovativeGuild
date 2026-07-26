import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';

class PaymentResult {
  final bool success;
  final String? errorMessage;
  const PaymentResult({required this.success, this.errorMessage});
}

class PaymentService {
  final ApiClient client;
  PaymentService(this.client);

  /// Full flow: ask our backend for a tx_ref -> open Flutterwave's
  /// hosted checkout -> ask our backend to independently re-verify
  /// with Flutterwave before trusting the result.
  Future<PaymentResult> payForTransaction({
    required BuildContext context,
    required String transactionReference,
  }) async {
    try {
      final config = await client.get('/payments/config');
      final publicKey = config['publicKey'] as String?;

      if (publicKey == null || publicKey.isEmpty || publicKey.contains('xxxx')) {
        return const PaymentResult(
          success: false,
          errorMessage: 'Flutterwave is not configured yet. Add FLW_PUBLIC_KEY to the backend .env file.',
        );
      }

      final initiate = await client.post('/payments/initiate', body: {
        'transactionReference': transactionReference,
      });

      final txRef = initiate['txRef'] as String;
      final amount = (initiate['amount'] as num).toDouble();
      final currency = initiate['currency'] as String? ?? 'MWK';
      final customer = initiate['customer'] as Map<String, dynamic>;

      final flutterwaveCustomer = Customer(
        name: customer['name'] as String? ?? 'SafeGuard User',
        phoneNumber: customer['phoneNumber'] as String? ?? '',
        email: customer['email'] as String? ?? '',
      );

      final flutterwave = Flutterwave(
        
        publicKey: publicKey,
        currency: currency,
        redirectUrl: AppConfig.flutterwaveRedirectUrl,
        txRef: txRef,
        amount: amount.toStringAsFixed(2),
        customer: flutterwaveCustomer,
        paymentOptions: (initiate['paymentOptions'] as String?) ?? 'card,mobilemoneymalawi,banktransfer',
        customization: Customization(title: 'SafeGuard Escrow Payment'),
        isTestMode: true, // flip to false only once you're using live FLW keys
      );

      final ChargeResponse? response = await flutterwave.charge(context);

      if (response == null || response.success != true) {
        return const PaymentResult(success: false, errorMessage: 'Payment was not completed.');
      }

      // Ask OUR server to independently confirm with Flutterwave —
      // never trust the client-side response alone for releasing an
      // escrow payment.
      await client.post('/payments/verify', body: {
        'transactionReference': transactionReference,
        'flwTransactionId': response.transactionId,
        'txRef': response.txRef ?? txRef,
      });

      return const PaymentResult(success: true);
    } catch (e) {
      return PaymentResult(success: false, errorMessage: e.toString());
    }
  }
}
