import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qejani/features/auth/presentation/providers/auth_providers.dart';
import 'package:qejani/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qejani/features/auth/domain/models/app_user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    setState(() => _isLoading = true);
    final appUser = ref.read(appUserProvider).value;
    if (appUser != null) {
      final updatedUser = appUser.copyWith(
        displayName: _displayNameController.text,
        phoneNumber: _phoneController.text,
      );
      // In a real app, AuthRepository would have an updateAppUser method
      await ref.read(firestoreProvider)
          .collection('users')
          .doc(appUser.uid)
          .update(updatedUser.toMap());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(appUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: appUserAsync.when(
        data: (appUser) {
          if (appUser == null) return const Center(child: Text('User not found'));
          
          if (_displayNameController.text.isEmpty) {
            _displayNameController.text = appUser.displayName;
            _phoneController.text = appUser.phoneNumber ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 24),
                Text(
                  appUser.email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(appUser.role.toUpperCase()),
                  backgroundColor: appUser.isAdmin ? Colors.red[100] : Colors.blue[100],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator() 
                    : const Text('Save Changes'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
