import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/order.dart';
import '../../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepositoryImpl(this._firestore);

  @override
  Future<String> createOrder(Order order) async {
    final docRef = _firestore.collection('orders').doc();
    // We update the order id with the doc id if it's empty, but usually the UI doesn't know the ID yet.
    // However, the toMap might need to use FieldValue.serverTimestamp() for the actual storage.
    final data = order.toMap();
    data['createdAt'] = FieldValue.serverTimestamp(); // Ensure server timestamp on creation
    data['id'] = docRef.id;
    
    await docRef.set(data);
    return docRef.id;
  }

  @override
  Stream<List<Order>> getOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Order.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<Order>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Order.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (doc.exists) {
      return Order.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(FirebaseFirestore.instance);
});
