import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../orders/data/repositories/order_repository_impl.dart';
import '../../../../core/constants/app_constants.dart';

class ManageOrdersScreen extends ConsumerWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider); 

    return Scaffold(
      appBar: AppBar(title: const Text('Manage All Orders')),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty 
          ? const Center(child: Text('No orders yet.'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ExpansionTile(
                  title: Text('Order #${order.id.substring(0, 8)}'),
                  subtitle: Text('Status: ${order.status.toUpperCase()}'),
                  trailing: Text('${order.totalAmount} ${AppConstants.currency}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...order.items.map((item) => Text('${item.product.title} x ${item.quantity}')),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Update Status: '),
                              DropdownButton<String>(
                                value: ['pending', 'processing', 'shipped', 'delivered', 'cancelled'].contains(order.status) ? order.status : 'pending',
                                items: ['pending', 'processing', 'shipped', 'delivered', 'cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    ref.read(orderRepositoryProvider).updateOrderStatus(order.id, newStatus);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}


