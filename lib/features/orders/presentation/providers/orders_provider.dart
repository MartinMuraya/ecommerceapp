import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/order.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final ordersProvider = StreamProvider<List<Order>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(orderRepositoryProvider).getOrders(user.uid);
});
