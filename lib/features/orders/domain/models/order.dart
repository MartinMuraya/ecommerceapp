import 'package:cloud_firestore/cloud_firestore.dart';
import '../../cart/domain/models/cart_item.dart';

class Order {
  final String id;
  final String buyerId;
  final List<CartItem> items;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.buyerId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'items': items.map((e) => {
        'productId': e.product.id,
        'title': e.product.title,
        'quantity': e.quantity,
        'price': e.product.price,
      }).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
