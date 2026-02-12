import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> getProducts({String? category, String? search});
  Future<Product?> getProduct(String id);
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
}

class ProductRepositoryImpl implements ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepositoryImpl(this._firestore);

  @override
  Stream<List<Product>> getProducts({String? category, String? search}) {
    Query query = _firestore.collection('products');

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      final products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
      
      if (search != null && search.isNotEmpty) {
        return products.where((p) => 
          p.title.toLowerCase().contains(search.toLowerCase()) || 
          p.description.toLowerCase().contains(search.toLowerCase())
        ).toList();
      }
      
      return products;
    });
  }

  @override
  Future<Product?> getProduct(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (doc.exists) {
      return Product.fromFirestore(doc);
    }
    return null;
  }

  @override
  Future<void> addProduct(Product product) async {
    await _firestore.collection('products').add(product.toMap());
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _firestore.collection('products').doc(product.id).update(product.toMap());
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).delete();
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(FirebaseFirestore.instance);
});

final productsStreamProvider = StreamProvider.family<List<Product>, ({String? category, String? search})>((ref, filter) {
  return ref.watch(productRepositoryProvider).getProducts(
    category: filter.category,
    search: filter.search,
  );
});
