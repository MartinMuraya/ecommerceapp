
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Initiated Successfully!')),
        );
        // Clear cart and navigate home or order success
        ref.read(cartProvider.notifier).clearCart();
        context.go('/orders'); 
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.error}')),
        );
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:'),
                      Text(
                        'KES ${cartTotal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
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
