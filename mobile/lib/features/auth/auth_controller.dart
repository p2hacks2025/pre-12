import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'auth_service.dart';
import 'models.dart';

class AuthState {
  const AuthState({
    required this.user,
    required this.isLoading,
    required this.error,
  });

  final DummyUser? user;
  final bool isLoading;
  final String? error;

  factory AuthState.signedOut() =>
      const AuthState(user: null, isLoading: false, error: null);

  AuthState copyWith({
    DummyUser? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authServiceProvider = Provider<DummyAuthService>((ref) {
  return const DummyAuthService();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.read(authServiceProvider));
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._auth) : super(AuthState.signedOut());

  final DummyAuthService _auth;

  Future<void> login(DummyUser user) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _auth.login(user);
      state = AuthState(user: result.user, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void logout() {
    state = AuthState.signedOut();
  }
}
