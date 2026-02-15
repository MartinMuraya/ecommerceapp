import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Stripe
  try {
    Stripe.publishableKey = 'pk_test_51SYHLFRz28pDJMKod27YcQ9iM7OhG40JdqVgIRzDz7d8dYMg6u8bHl5wwlSqAtfaaPzx4vfRICtxr5Ji0hQfOyW300zsYjhvcB';
  } catch (e) {
    debugPrint('Stripe initialization failed: $e');
  }

  // We will initialize Firebase once we have the options file. 
  // For now, we wrap in try-catch or comment out until 'flutterfire configure' is run.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase not initialized: $e');
  }

  runApp(const ProviderScope(child: QejaniApp()));
}

class QejaniApp extends ConsumerWidget {
  const QejaniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Qejani',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
