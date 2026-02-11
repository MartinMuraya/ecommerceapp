import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../cart/domain/models/cart_item.dart';
import '../../../products/domain/models/product.dart';

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
      'createdAt': createdAt,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      buyerId: map['buyerId'] ?? '',
      items: (map['items'] as List? ?? []).map((e) => CartItem(
        product: Product(
          id: e['productId'],
          title: e['title'],
          price: (e['price'] as num).toDouble(),
          // Other product fields are missing in the order summary, 
          // might need a lightweight Product model or just enough fields.
          description: '',
          currency: 'KES',
          category: '',
          images: [],
          stock: 0,
          sellerId: '',
          isAvailable: true,
        ),
        quantity: e['quantity'] ?? 0,
      )).toList(),
      totalAmount: (map['totalAmount'] as num? ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
