import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qejani/core/constants/app_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/seller.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn? _googleSignIn;
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
      
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final doc = await _firestore.collection('users').doc(uid).get();
        final isAdmin = email.toLowerCase() == AppConstants.adminEmail.toLowerCase();

        if (!doc.exists) {
          final appUser = AppUser(
            uid: uid,
            email: email,
            displayName: email.split('@')[0],
            role: isAdmin ? 'admin' : 'buyer',
            createdAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(uid).set(appUser.toMap());
        } else if (isAdmin && doc.data()?['role'] != 'admin') {
          // Sync admin role if it changed or was incorrect
          await _firestore.collection('users').doc(uid).update({'role': 'admin'});
        }
      }
      
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
        final role = email.toLowerCase() == AppConstants.adminEmail.toLowerCase() ? 'admin' : 'buyer';
        final appUser = AppUser(
          uid: userCredential.user!.uid,
          email: email,
          displayName: email.split('@')[0],
          role: role,
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
    await _googleSignIn?.signOut();
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
    if (_googleSignIn == null) {
      throw Exception('Google Sign-In is not configured for this platform.');
    }
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
  Stream<AppUser?> getAppUserStream(String uid) {
    debugPrint('AUTH_DEBUG: getAppUserStream started for $uid');
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          debugPrint('AUTH_DEBUG: Snapshot received for $uid, exists: ${doc.exists}');
          if (doc.exists) {
            try {
              return AppUser.fromMap(doc.data()!);
            } catch (e) {
              debugPrint('AUTH_DEBUG: Error parsing user data for $uid: $e');
              return null;
            }
          }
          return null;
        }).handleError((error) {
          debugPrint('AUTH_DEBUG: Stream error for $uid: $error');
          // On Web, persistent ERR_CONNECTION_CLOSED can manifest as a stream error
          // Returning null allows the UI to handle it as a missing profile or loading state
          throw error;
        });
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
  @override
  Stream<List<AppUser>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<void> initializeProfile(User user) async {
    debugPrint('AUTH_DEBUG: initializeProfile started for ${user.uid}');
    try {
      // Use GetOptions to allow cache if server is unavailable
      // Combined with a timeout to prevent hanging the UI thread indefinitely
      final doc = await _firestore.collection('users').doc(user.uid).get(
        const GetOptions(source: Source.serverAndCache),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('AUTH_DEBUG: initializeProfile TIMEOUT for ${user.uid}');
        throw Exception('Firestore initialization timed out');
      });
      
      debugPrint('AUTH_DEBUG: Doc check exists: ${doc.exists}');
      
      if (!doc.exists) {
        final isAdmin = user.email?.toLowerCase() == AppConstants.adminEmail.toLowerCase();
        final appUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? user.email?.split('@')[0] ?? 'User',
          role: isAdmin ? 'admin' : 'buyer',
          createdAt: DateTime.now(),
        );
        debugPrint('AUTH_DEBUG: Creating profile document with role: ${appUser.role}');
        await _firestore.collection('users').doc(user.uid).set(appUser.toMap())
            .timeout(const Duration(seconds: 10));
        debugPrint('AUTH_DEBUG: Profile document set successfully');
      } else {
        debugPrint('AUTH_DEBUG: Profile already exists');
      }
    } catch (e) {
      debugPrint('AUTH_DEBUG: initializeProfile ERROR (likely offline or network): $e');
    }
  }
}

