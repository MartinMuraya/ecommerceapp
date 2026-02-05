import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';

class AuthState {
  final bool isLoading;
  final String? error;

  AuthState({this.isLoading = false, this.error});
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(AuthState());

  Future<void> signIn(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
      state = AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
    }
  }

  Future<void> signUp(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      await _authRepository.signUpWithEmailAndPassword(email, password);
      state = AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = AuthState(isLoading: true);
    try {
      await _authRepository.signInWithGoogle();
      state = AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
