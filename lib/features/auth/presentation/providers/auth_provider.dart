import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/auth_repository.dart';

/// Provider exposing the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// StreamProvider exposing the [User] authentication state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Notifier handling the authentication process state.
class AuthNotifier extends Notifier<AsyncValue<User?>> {
  late final AuthRepository _repository;

  @override
  AsyncValue<User?> build() {
    _repository = ref.watch(authRepositoryProvider);
    return AsyncValue.data(_repository.currentUser);
  }

  Future<void> signIn(
    String email, 
    String password, {
    required void Function() onSuccess, 
    required void Function(String error) onFailure,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithEmailAndPassword(email, password);
      state = AsyncValue.data(user);
      onSuccess();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      onFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> signUp(
    String email, 
    String name, 
    String password, {
    required void Function() onSuccess, 
    required void Function(String error) onFailure,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signUpWithEmailAndPassword(email, name, password);
      state = AsyncValue.data(user);
      onSuccess();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      onFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> resetPassword(
    String email, {
    required void Function() onSuccess, 
    required void Function(String error) onFailure,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
      onSuccess();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      onFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> signInWithGoogle({
    required void Function() onSuccess,
    required void Function(String error) onFailure,
    void Function()? onCancel,
    bool isLogin = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithGoogle(isLogin: isLogin);
      if (user != null) {
        state = AsyncValue.data(user);
        onSuccess();
      } else {
        // User cancelled the sign-in flow — silently reset state
        state = AsyncValue.data(_repository.currentUser);
        if (onCancel != null) onCancel();
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      onFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> signInWithApple({
    required void Function() onSuccess,
    required void Function(String error) onFailure,
    void Function()? onCancel,
    bool isLogin = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithApple(isLogin: isLogin);
      if (user != null) {
        state = AsyncValue.data(user);
        onSuccess();
      } else {
        // User cancelled the sign-in flow
        state = AsyncValue.data(_repository.currentUser);
        if (onCancel != null) onCancel();
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      onFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> updateProfileName(
    String name, {
    required void Function() onSuccess,
    required void Function(String error) onFailure,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateDisplayName(name);
      state = AsyncValue.data(_repository.currentUser);
      onSuccess();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      onFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> reauthenticateAndChangePassword({
    required String currentPassword,
    required String newPassword,
    required void Function() onSuccess,
    required void Function(String error) onFailure,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.reauthenticateAndChangePassword(currentPassword, newPassword);
      state = AsyncValue.data(_repository.currentUser);
      onSuccess();
    } catch (e) {
      state = AsyncValue.data(_repository.currentUser);
      onFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> updatePassword(
    String newPassword, {
    required void Function() onSuccess,
    required void Function(String error) onFailure,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePassword(newPassword);
      state = AsyncValue.data(_repository.currentUser);
      onSuccess();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      onFailure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}

/// Provider exposing the [AuthNotifier].
/// Not autoDispose — auth state must persist for the entire app session.
final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<User?>>(AuthNotifier.new);
