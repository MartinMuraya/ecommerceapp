abstract class PaymentRepository {
  Future<void> initiateMpesaPayment({required String phoneNumber, required double amount, required String orderId});
  Future<String> createStripePaymentIntent({required double amount, required String currency});
}
