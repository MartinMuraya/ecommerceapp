
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  CheckoutState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  CheckoutState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
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
      } else if (method == PaymentMethod.stripe) {
        final clientSecret = await paymentRepo.createStripePaymentIntent(
          amount: amount,
          currency: currency,
        );
        // TODO: Integrate flutter_stripe to present payment sheet with clientSecret
      }

      state = CheckoutState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = CheckoutState(isLoading: false, error: e.toString());
    }
  }
}

final checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>((ref) {
  return CheckoutController(ref);
});
