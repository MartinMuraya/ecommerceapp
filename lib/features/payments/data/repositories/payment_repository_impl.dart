import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFunctions _functions;

  PaymentRepositoryImpl(this._functions);

  @override
  Future<void> initiateMpesaPayment({required String phoneNumber, required double amount, required String orderId}) async {
    try {
      final callable = _functions.httpsCallable('initiateMpesaPayment');
      await callable.call({
        'phoneNumber': phoneNumber,
        'amount': amount,
        'orderId': orderId,
      });
    } catch (e) {
      throw Exception('M-Pesa Payment Failed: $e');
    }
  }

  @override
  Future<String> createStripePaymentIntent({required double amount, required String currency}) async {
    try {
      final callable = _functions.httpsCallable('createStripePaymentIntent');
      final result = await callable.call({
        'amount': amount,
        'currency': currency,
      });
      return result.data['clientSecret'];
    } catch (e) {
      throw Exception('Stripe Payment Intent Creation Failed: $e');
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(FirebaseFunctions.instance);
});
