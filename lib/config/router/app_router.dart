import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qejani/features/auth/presentation/pages/login_screen.dart';
import 'package:qejani/features/auth/presentation/pages/signup_screen.dart';
import 'package:qejani/features/home/presentation/pages/home_screen.dart';
import 'package:qejani/features/products/presentation/pages/product_details_screen.dart';
import 'package:qejani/features/cart/presentation/pages/cart_screen.dart';
import 'package:qejani/features/checkout/presentation/pages/checkout_screen.dart';
import 'package:qejani/features/orders/presentation/pages/orders_screen.dart';
import 'package:qejani/features/auth/presentation/pages/profile_screen.dart';
import 'package:qejani/features/admin/presentation/pages/admin_dashboard_screen.dart';
import 'package:qejani/features/admin/presentation/pages/manage_products_screen.dart';
import 'package:qejani/features/admin/presentation/pages/product_form_screen.dart';
import 'package:qejani/features/admin/presentation/pages/manage_orders_screen.dart';
import 'package:qejani/features/admin/presentation/pages/manage_users_screen.dart';
import 'package:qejani/features/home/presentation/pages/main_screen.dart';
import 'package:qejani/features/auth/presentation/providers/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final appUser = ref.watch(appUserProvider).value;

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isSigningUp = state.uri.toString() == '/signup';

      if (!isLoggedIn && !isLoggingIn && !isSigningUp) {
        return '/login';
      }

      if (isLoggedIn && (isLoggingIn || isSigningUp)) {
        // Redirect to respective dashboard after login
        if (appUser != null) {
          return appUser.isAdmin ? '/admin' : '/';
        }
        // If appUser not yet loaded, wait at root
        return '/';
      }

      final isAdminPath = state.uri.toString().startsWith('/admin');
      if (isAdminPath && (appUser == null || !appUser.isAdmin)) {
        return '/';
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStream(ref.watch(authStateProvider.stream)),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailsScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'manage-products',
            builder: (context, state) => const ManageProductsScreen(),
          ),
          GoRoute(
            path: 'add-product',
            builder: (context, state) => const ProductFormScreen(),
          ),
          GoRoute(
            path: 'edit-product/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductFormScreen(productId: id);
            },
          ),
          GoRoute(
            path: 'manage-orders',
            builder: (context, state) => const ManageOrdersScreen(),
          ),
          GoRoute(
            path: 'manage-users',
            builder: (context, state) => const ManageUsersScreen(),
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

