import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/app_user.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn?>((ref) {
  if (kIsWeb) {
    // On Web, GoogleSignIn() throws an assertion if clientId is not set in index.html
    // To prevent the app from crashing on start, we return null until the user adds the ID.
    return null; 
  }
  return GoogleSignIn();
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
    ref.watch(firestoreProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final appUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authStateProvider).when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(authRepositoryProvider).getAppUserStream(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (err, stack) => Stream.error(err, stack),
  );
});
final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(authRepositoryProvider).getAllUsers();
});
