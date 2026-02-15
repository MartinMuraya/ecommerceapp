import '../models/order.dart';

abstract class OrderRepository {
  Future<String> createOrder(Order order);
  Stream<List<Order>> getOrders(String userId);
  Stream<List<Order>> getAllOrders();
  Future<Order?> getOrderById(String orderId);
  Future<void> updateOrderStatus(String orderId, String status);
  Stream<Order?> watchOrder(String orderId);
}
