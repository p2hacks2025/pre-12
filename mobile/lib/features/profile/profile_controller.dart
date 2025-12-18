import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../auth/auth_controller.dart';
import 'profile_models.dart';
import 'profile_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileState {
  const ProfileState({
    required this.isLoading,
    required this.error,
    required this.profile,
  });

  final bool isLoading;
  final String? error;
  final UserProfile? profile;

  factory ProfileState.initial() =>
      const ProfileState(isLoading: false, error: null, profile: null);

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    UserProfile? profile,
    bool clearError = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      profile: profile ?? this.profile,
    );
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  return const ProfileService();
});

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      return ProfileController(ref, ref.read(profileServiceProvider));
    });

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._ref, this._service) : super(ProfileState.initial());

  final Ref _ref;
  final ProfileService _service;

  Future<void> refresh() async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null) {
      state = state.copyWith(profile: null, clearError: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _service.getMyProfile(userId: user.id);
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<UserProfile?> update({
    required String username,
    required String bio,
    required XFile? icon,
  }) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null) return null;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _service.updateMyProfile(
        userId: user.id,
        username: username,
        bio: bio,
        icon: icon,
      );
      state = state.copyWith(isLoading: false, profile: updated);
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
