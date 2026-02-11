import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final user = ref.watch(firebaseAuthProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to Add Product screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Product feature coming soon.')),
              );
            },
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          // Filter products belonging to this seller
          final sellerProducts = products.where((p) => p.sellerId == user?.uid).toList();

          if (sellerProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('You haven\'t added any products yet.'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                       // TODO: Navigate to Add Product screen
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Product'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sellerProducts.length,
            itemBuilder: (context, index) {
              final product = sellerProducts[index];
              return Card(
                child: ListTile(
                  leading: product.images.isNotEmpty
                      ? Image.network(product.images.first, width: 50, height: 50, fit: BoxFit.cover)
                      : Container(width: 50, height: 50, color: Colors.grey[200]),
                  title: Text(product.title),
                  subtitle: Text('KES ${product.price.toStringAsFixed(0)} | Stock: ${product.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          // TODO: Edit product
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          // TODO: Delete product
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
