import '../models/order.dart';

abstract class OrderRepository {
  Future<String> createOrder(Order order);
  Stream<List<Order>> getOrders(String userId);
  Future<Order?> getOrderById(String orderId);
  Future<void> updateOrderStatus(String orderId, String status);
}
