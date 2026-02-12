import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../products/domain/models/product.dart';


import '../../../../core/constants/app_constants.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategory;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider((category: _selectedCategory, search: _searchController.text)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qejani'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 50,
            child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = null);
                  },
                ),
                const SizedBox(width: 8),
                ...AppConstants.categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: _selectedCategory == category
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: productsAsync.when(
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
                  itemBuilder: (context, index) => ProductCard(product: products[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
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

