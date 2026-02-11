import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/seller.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl(this._firebaseAuth, this._googleSignIn, this._firestore);

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    UserCredential? userCredential;
    try {
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('[AUTH_SIGNUP_UNKNOWN] ${e.toString()}');
    }
      
    try {
      if (userCredential.user != null) {
        // Create user document in Firestore
        final appUser = AppUser(
          uid: userCredential.user!.uid,
          email: email,
          displayName: email.split('@')[0],
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(appUser.uid).set(appUser.toMap());
      }
      return userCredential.user;
    } catch (e) {
      throw Exception('[FIRESTORE_USER_CREATE] ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if document exists, if not create it
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
           final appUser = AppUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            photoURL: user.photoURL,
            createdAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
        }
      }

      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<AppUser?> getAppUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> updateRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  @override
  Future<void> becomeSeller(String uid, Seller seller) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), {'role': 'seller'});
    batch.set(_firestore.collection('sellers').doc(uid), seller.toMap());
    await batch.commit();
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    debugPrint('FirebaseAuthException: code=${e.code}, message=${e.message}');
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'email-already-in-use':
        return Exception('The account already exists for that email.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'invalid-email':
        return Exception('The email address is invalid.');
      default:
        return Exception('[FIREBASE_AUTH_ERR_${e.code}] ${e.message ?? 'Authentication failed.'}');
    }
  }
}
