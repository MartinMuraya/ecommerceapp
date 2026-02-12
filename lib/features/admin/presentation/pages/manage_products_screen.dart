import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/data/repositories/product_repository.dart';

class ManageProductsScreen extends ConsumerWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider((category: null, search: null)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/add-product'),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: SizedBox(
                width: 50,
                height: 50,
                child: product.images.isNotEmpty 
                  ? Image.network(product.images.first, fit: BoxFit.cover)
                  : const Icon(Icons.image_not_supported),
              ),
              title: Text(product.title),
              subtitle: Text('${product.currency} ${product.price} - Stock: ${product.stock}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => context.push('/admin/edit-product/${product.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, ref, product),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete ${product.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(productRepositoryProvider).deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
