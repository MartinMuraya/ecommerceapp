import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/seller.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<User?> signInWithEmailAndPassword(String email, String password);
  Future<User?> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<User?> signInWithGoogle();
  Future<AppUser?> getAppUser(String uid);
  Stream<AppUser?> getAppUserStream(String uid);
  Future<void> updateRole(String uid, String role);
  Future<void> becomeSeller(String uid, Seller seller);
  Stream<List<AppUser>> getAllUsers();
  Future<void> initializeProfile(User user);
}
