import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qejani/core/constants/app_constants.dart';
import 'package:qejani/features/auth/presentation/providers/auth_providers.dart';
import 'package:qejani/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qejani/features/products/data/repositories/product_repository.dart';
import 'package:qejani/features/orders/presentation/providers/orders_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider((category: null, search: null)));
    final allOrdersAsync = ref.watch(adminOrdersProvider); 
    final allUsersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _StatCard(
                  title: 'Products',
                  value: productsAsync.when(
                    data: (products) => products.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '!',
                  ),
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Orders',
                  value: allOrdersAsync.when(
                    data: (orders) => orders.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '!',
                  ),
                  icon: Icons.shopping_cart,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Revenue',
                  value: allOrdersAsync.when(
                    data: (orders) {
                      final revenue = orders.fold(0.0, (sum, order) => sum + order.totalAmount);
                      return 'KES ${revenue.toStringAsFixed(0)}';
                    },
                    loading: () => '...',
                    error: (_, __) => '!',
                  ),
                  icon: Icons.payments,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: 'Users',
                  value: allUsersAsync.when(
                    data: (users) => users.where((u) => u.role == 'buyer').length.toString(),
                    loading: () => '...',
                    error: (_, __) => '!',
                  ),
                  icon: Icons.people,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Quick Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_box, color: Colors.teal),
                    title: const Text('Add New Product'),
                    onTap: () => context.push('/admin/add-product'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.list_alt, color: Colors.indigo),
                    title: const Text('Bulk Manage Products'),
                    onTap: () => context.push('/admin/manage-products'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.deepOrange),
                    title: const Text('Order Processing'),
                    onTap: () => context.push('/admin/manage-orders'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.people_alt, color: Colors.purple),
                    title: const Text('User Management'),
                    onTap: () => context.push('/admin/manage-users'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
