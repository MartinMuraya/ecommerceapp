
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';
import '../../../orders/data/repositories/order_repository_impl.dart';
import '../../../orders/domain/models/order.dart' as order_model;

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.mpesa;
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartTotal = ref.watch(cartTotalProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);

    ref.listen(checkoutControllerProvider, (previous, next) {
      if (next.isSuccess) {
        if (_selectedMethod == PaymentMethod.stripe) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Successful!')),
          );
          ref.read(cartProvider.notifier).clearCart();
          context.go('/orders');
        } else if (_selectedMethod == PaymentMethod.mpesa && next.currentOrderId != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => _PaymentWaitingDialog(orderId: next.currentOrderId!),
          );
        }
      }
      if (next.error != null) {
        // Special handling for web Stripe payment
        if (next.error == 'WEB_PAYMENT_REQUIRED') {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Stripe Payment on Web'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stripe payment sheet is not supported on web.'),
                  SizedBox(height: 16),
                  Text('For now, your order has been created as pending.'),
                  SizedBox(height: 8),
                  Text('To complete payment, you can:'),
                  SizedBox(height: 8),
                  Text('• Use the mobile app'),
                  Text('• Contact support with your order ID'),
                  Text('• Use M-Pesa payment instead'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/orders');
                  },
                  child: const Text('View Orders'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Reset to try M-Pesa instead
                    setState(() {
                      _selectedMethod = PaymentMethod.mpesa;
                    });
                  },
                  child: const Text('Try M-Pesa'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${next.error}')),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Total Amount:'),
                      Text(
                        'KES ${cartTotal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              RadioListTile<PaymentMethod>(
                title: const Text('M-Pesa'),
                value: PaymentMethod.mpesa,
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                  });
                },
              ),
              RadioListTile<PaymentMethod>(
                title: const Text('Credit Card (Stripe)'),
                value: PaymentMethod.stripe,
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              if (_selectedMethod == PaymentMethod.mpesa)
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'M-Pesa Phone Number',
                    hintText: '2547XXXXXXXX',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (!RegExp(r'^(?:254|\+254|0)?(7(?:(?:[129][0-9])|(?:0[0-8])|(4[0-1]))[0-9]{6})$').hasMatch(value)) {
                       return 'Enter a valid M-Pesa number';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: checkoutState.isLoading
                      ? null
                      : () {
                          if (_selectedMethod == PaymentMethod.mpesa) {
                            if (_formKey.currentState!.validate()) {
                              ref
                                  .read(checkoutControllerProvider.notifier)
                                  .processPayment(
                                    method: _selectedMethod,
                                    amount: cartTotal,
                                    currency: 'KES',
                                    phoneNumber: _phoneController.text.trim(),
                                  );
                            }
                          } else {
                            ref
                                .read(checkoutControllerProvider.notifier)
                                .processPayment(
                                  method: _selectedMethod,
                                  amount: cartTotal,
                                  currency: 'KES',
                                );
                          }
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: checkoutState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _selectedMethod == PaymentMethod.mpesa
                              ? 'Pay with M-Pesa'
                              : 'Pay with Card',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentWaitingDialog extends ConsumerWidget {
  final String orderId;

  const _PaymentWaitingDialog({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderStream = ref.watch(orderRepositoryProvider).watchOrder(orderId);

    return AlertDialog(
      title: const Text('Processing Payment'),
      content: StreamBuilder<order_model.Order?>(
        stream: orderStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error checking status: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Waiting for M-Pesa confirmation...'),
                SizedBox(height: 8),
                Text('Check your phone to enter PIN', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            );
          }

          final order = snapshot.data!;
          if (order.status == 'paid') {
            // Use a post-frame callback to navigate to avoid build-time navigation
            WidgetsBinding.instance.addPostFrameCallback((_) {
               Navigator.of(context).pop(); // Close dialog
               ref.read(cartProvider.notifier).clearCart();
               context.go('/orders');
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Payment Received!')),
               );
            });
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text('Payment Successful! Redirecting...'),
              ],
            );
          } else if (order.status == 'failed') {
             WidgetsBinding.instance.addPostFrameCallback((_) {
               Navigator.of(context).pop(); // Close dialog
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Payment Failed. Please try again.')),
               );
             });
             return const Text('Payment Failed');
          }

          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Waiting for M-Pesa confirmation...'),
              SizedBox(height: 8),
              Text('Check your phone to enter PIN', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel Waiting'),
        ),
      ],
    );
  }
}
