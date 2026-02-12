import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qejani/features/auth/presentation/providers/auth_providers.dart';
import 'package:qejani/features/home/presentation/pages/home_screen.dart';
import 'package:qejani/features/admin/presentation/pages/admin_dashboard_screen.dart';
import 'package:qejani/features/admin/presentation/pages/manage_products_screen.dart';
import 'package:qejani/features/admin/presentation/pages/manage_orders_screen.dart';
import 'package:qejani/features/cart/presentation/pages/cart_screen.dart';
import 'package:qejani/features/orders/presentation/pages/orders_screen.dart';
import 'package:qejani/features/auth/presentation/pages/profile_screen.dart';
import 'package:qejani/features/auth/presentation/controllers/auth_controller.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  bool _showTimeoutAction = false;

  @override
  void initState() {
    super.initState();
    // After 8 seconds of loading, show a retry/timeout option
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _showTimeoutAction = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(appUserProvider);

    return appUserAsync.when(
      data: (appUser) {
        debugPrint('MAIN_SCREEN_DEBUG: appUser data received: ${appUser?.uid}, role: ${appUser?.role}');
        if (appUser == null) {
          final authUser = ref.read(firebaseAuthProvider).currentUser;
          debugPrint('MAIN_SCREEN_DEBUG: authUser is ${authUser?.uid}');
          
          if (authUser != null) {
            // Trigger profile creation/fetch
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint('MAIN_SCREEN_DEBUG: Initializing profile for ${authUser.uid}');
              ref.read(authRepositoryProvider).initializeProfile(authUser);
            });

            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      const Text(
                        'Syncing with profile...',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This is taking longer than usual. We\'re trying to reach the servers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      if (_showTimeoutAction) ...[
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(appUserProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Connection Now'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                          icon: const Icon(Icons.logout),
                          label: const Text('Try Different Account'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        final isAdmin = appUser.isAdmin;
        
        final List<Widget> screens = isAdmin 
          ? [
              const AdminDashboardScreen(),
              const ManageProductsScreen(),
              const ManageOrdersScreen(),
              const HomeScreen(),
              const ProfileScreen(),
            ]
          : [
              const HomeScreen(),
              const CartScreen(),
              const OrdersScreen(),
              const ProfileScreen(),
            ];

        final List<BottomNavigationBarItem> items = isAdmin
          ? [
              const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              const BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Products'),
              const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
              const BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Shop'),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ]
          : [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
              const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            items: items,
          ),
        );
      },
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading your workspace...', style: TextStyle(color: Colors.grey)),
              if (_showTimeoutAction) ...[
                 const SizedBox(height: 24),
                 ElevatedButton(
                   onPressed: () => ref.invalidate(appUserProvider),
                   child: const Text('Retry Connection'),
                 ),
                 TextButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  child: const Text('Cancel / Logout'),
                ),
              ],
            ],
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_outlined, color: Colors.orange, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Connection Problem',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  err.toString().contains('network-request-failed') || err.toString().contains('unavailable')
                    ? 'We can\'t reach our servers. Please check if your firewall or anti-virus is blocking googleapis.com.'
                    : 'We can\'t reach our servers right now. This usually happens if your internet is down or if a firewall is blocking the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error details: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(appUserProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  child: const Text('Logout and try a different account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
