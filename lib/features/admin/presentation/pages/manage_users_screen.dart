import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/models/app_user.dart';
import 'package:intl/intl.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: usersAsync.when(
        data: (users) {
          final buyers = users.where((u) => u.role == 'buyer').toList();
          if (buyers.isEmpty) {
            return const Center(child: Text('No buyers registered yet.'));
          }
          return ListView.builder(
            itemCount: buyers.length,
            itemBuilder: (context, index) {
              final user = buyers[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user.displayName),
                subtitle: Text(user.email),
                trailing: Text(
                  'Joined ${DateFormat('MMM yyyy').format(user.createdAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
