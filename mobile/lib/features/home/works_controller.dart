import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../auth/auth_controller.dart';
import 'models.dart';
import 'works_service.dart';

class WorksState {
  const WorksState({
    required this.isLoading,
    required this.error,
    required this.works,
  });

  final bool isLoading;
  final String? error;
  final List<Work> works;

  factory WorksState.initial() =>
      const WorksState(isLoading: false, error: null, works: <Work>[]);

  WorksState copyWith({
    bool? isLoading,
    String? error,
    List<Work>? works,
    bool clearError = false,
  }) {
    return WorksState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      works: works ?? this.works,
    );
  }
}

final worksServiceProvider = Provider<WorksService>((ref) {
  return const WorksService();
});

final worksControllerProvider =
    StateNotifierProvider<WorksController, WorksState>((ref) {
      return WorksController(ref, ref.read(worksServiceProvider));
    });

class WorksController extends StateNotifier<WorksState> {
  WorksController(this._ref, this._service) : super(WorksState.initial()) {
    // コンストラクタ内でasyncを直接呼ぶのを避け、次のイベントループで初期取得。
    Future.microtask(refresh);
  }

  final Ref _ref;
  final WorksService _service;

  Future<void> refresh() async {
    final auth = _ref.read(authControllerProvider);
    final user = auth.user;
    if (user == null) {
      state = state.copyWith(works: <Work>[], clearError: true);
      return;
    }

    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final works = await _service.getWorks(userId: user.id);
      state = state.copyWith(isLoading: false, works: works);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> swipe({required Work work, required bool isLike}) async {
    final auth = _ref.read(authControllerProvider);
    final user = auth.user;
    if (user == null) return;

    // 先にUIを進める
    state = state.copyWith(
      works: state.works.where((w) => w.id != work.id).toList(growable: false),
    );

    try {
      await _service.postSwipe(
        fromUserId: user.id,
        toWorkId: work.id,
        isLike: isLike,
      );
    } catch (e) {
      // 送信失敗はUX優先で復元せず、エラーだけ出す
      state = state.copyWith(error: e.toString());
    }
  }
}
