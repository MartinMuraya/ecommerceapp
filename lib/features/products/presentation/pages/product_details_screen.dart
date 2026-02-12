
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/product_repository.dart';
import '../../domain/models/product.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';

final productDetailsProvider = FutureProvider.family<Product?, String>((ref, id) {
  return ref.read(productRepositoryProvider).getProduct(id);
});

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailsProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: productAsync.when(
        data: (Product? product) {
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: product.images.isNotEmpty
                          ? PageView.builder(
                              itemCount: product.images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return Image.network(
                                  product.images[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                              Icons.broken_image_outlined,
                                              size: 64,
                                              color: Colors.grey)),
                                );
                              },
                            )
                          : Container(color: Colors.grey[200]),
                    ),
                    if (product.images.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            product.images.length,
                            (index) => Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              width: 8.0,
                              height: 8.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Theme.of(context).primaryColor
                                    : Colors.white.withValues(alpha: 0.8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${product.currency} ${product.price.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(product.description),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Buy Now logic (Add to cart + Navigate to checkout) - For now just empty or navigate
                                ref
                                    .read(cartProvider.notifier)
                                    .addToCart(product);
                                // Navigate to checkout if possible
                                // context.push('/checkout');
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              child: const Text('Buy Now'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('${product.title} added to cart')),
                                );
                              },
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Add to Cart'),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
