import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../products/domain/models/product.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final appUserAsync = ref.watch(appUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qejani'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              context.push('/cart');
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              appUserAsync.when(
                data: (appUser) {
                  if (appUser?.role == 'seller') {
                    return PopupMenuItem(
                      child: const Text('Seller Dashboard'),
                      onTap: () {
                        context.push('/seller-dashboard');
                      },
                    );
                  } else {
                    return PopupMenuItem(
                      child: const Text('Become a Seller'),
                      onTap: () {
                        context.push('/become-seller');
                      },
                    );
                  }
                },
                loading: () => const PopupMenuItem(enabled: false, child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => const PopupMenuItem(enabled: false, child: Text('Error loading profile')),
              ),
              PopupMenuItem(
                child: const Text('My Orders'),
                onTap: () {
                  context.push('/orders');
                },
              ),
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ],
            icon: CircleAvatar(
              radius: 16,
               backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? const Icon(Icons.person, size: 16) : null,
            ),
          )
        ],
      ),
      body: productsAsync.when(
        data: (products) {
            if (products.isEmpty) {
                return const Center(child: Text('No products found'));
            }
            return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(product: product);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
             context.push('/product/${product.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: product.images.isNotEmpty
                  ? Image.network(product.images.first, fit: BoxFit.cover)
                  : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 50, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.currency} ${product.price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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

