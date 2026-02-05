import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> getProducts();
  Future<Product?> getProduct(String id);
  Future<void> addProduct(Product product); // For sellers later
}

class ProductRepositoryImpl implements ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepositoryImpl(this._firestore);

  @override
  Stream<List<Product>> getProducts() {
    return _firestore.collection('products')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
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
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(FirebaseFirestore.instance);
});

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getProducts();
});
