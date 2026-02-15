
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../payments/data/repositories/payment_repository_impl.dart';
import '../../../orders/data/repositories/order_repository_impl.dart';
import '../../../orders/domain/models/order.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';

enum PaymentMethod { mpesa, stripe }

class CheckoutState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String? currentOrderId;
  final String? stripeClientSecret; // For web payment handling

  CheckoutState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.currentOrderId,
    this.stripeClientSecret,
  });

  CheckoutState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? currentOrderId,
    String? stripeClientSecret,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      stripeClientSecret: stripeClientSecret ?? this.stripeClientSecret,
    );
  }
}

class CheckoutController extends StateNotifier<CheckoutState> {
  final Ref _ref;

  CheckoutController(this._ref) : super(CheckoutState());

  Future<void> processPayment({
    required PaymentMethod method,
    required double amount,
    required String currency,
    String? phoneNumber, // For M-Pesa
  }) async {
    state = CheckoutState(isLoading: true);
    try {
      final user = _ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception("User must be logged in to checkout");

      final cartItems = _ref.read(cartProvider);
      if (cartItems.isEmpty) throw Exception("Cart is empty");

      final orderRepo = _ref.read(orderRepositoryProvider);
      final paymentRepo = _ref.read(paymentRepositoryProvider);

      // Create initial order record
      final order = Order(
        id: '', // Will be set by Firestore
        buyerId: user.uid,
        items: cartItems,
        totalAmount: amount,
        status: 'pending',
        paymentMethod: method == PaymentMethod.mpesa ? 'mpesa' : 'stripe',
        createdAt: DateTime.now(),
      );

      final orderId = await orderRepo.createOrder(order);

      if (method == PaymentMethod.mpesa) {
        if (phoneNumber == null || phoneNumber.isEmpty) {
          throw Exception("Phone number is required for M-Pesa");
        }
        
        await paymentRepo.initiateMpesaPayment(
          phoneNumber: phoneNumber,
          amount: amount,
          orderId: orderId,
        );
        state = CheckoutState(isSuccess: true, isLoading: false, currentOrderId: orderId);
      } else if (method == PaymentMethod.stripe) {
        final clientSecret = await paymentRepo.createStripePaymentIntent(
          amount: amount,
          currency: currency,
        );
        
        if (kIsWeb) {
          // For web: Payment sheet is not supported
          // We'll handle this differently - show a message or redirect to Stripe Checkout
          // For now, we'll just mark the order as pending and provide the client secret
          // The UI can handle the web payment flow separately
          state = CheckoutState(
            isLoading: false,
            isSuccess: false,
            currentOrderId: orderId,
            stripeClientSecret: clientSecret,
            error: 'WEB_PAYMENT_REQUIRED', // Special flag for web payment handling
          );
        } else {
          // Mobile/Desktop: Use payment sheet
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: 'Qejani',
            ),
          );

          await Stripe.instance.presentPaymentSheet();

          // If we reach here, payment is successful
          // Update order status locally (backend webhook should also do it)
          await orderRepo.updateOrderStatus(orderId, 'paid');
          
          state = CheckoutState(isSuccess: true, isLoading: false, currentOrderId: orderId);
        }
      }

    } catch (e) {
      state = CheckoutState(isLoading: false, error: e.toString());
    }
  }
}

final checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>((ref) {
  return CheckoutController(ref);
});
