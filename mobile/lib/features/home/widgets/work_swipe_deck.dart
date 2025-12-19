import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../works_controller.dart';
import 'work_card.dart';

class WorkSwipeDeck extends ConsumerWidget {
  const WorkSwipeDeck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(worksControllerProvider);

    // ConsumerWidgetでもref.listenは利用可能。
    // エラーが変化したときだけ、フレーム後にSnackBar表示する。
    ref.listen<WorksState>(worksControllerProvider, (prev, next) {
      final err = next.error;
      if (err == null || err.isEmpty) return;
      if (prev?.error == err) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      });
    });

    if (state.isLoading && state.works.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.works.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('表示する作品がありません'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(worksControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('更新'),
            ),
          ],
        ),
      );
    }

    final top = state.works.first;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: _DismissibleTopCard(
                  work: top,
                  onSwipe: (isLike) => ref
                      .read(worksControllerProvider.notifier)
                      .swipe(work: top, isLike: isLike),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Center(
                    child: Text(
                      '右スワイプ：いいね / 左スワイプ：スキップ',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DismissibleTopCard extends ConsumerWidget {
  const _DismissibleTopCard({required this.work, required this.onSwipe});

  final Work work;
  final Future<void> Function(bool isLike) onSwipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey<String>('work-${work.id}'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.25,
        DismissDirection.endToStart: 0.25,
      },
      onDismissed: (direction) {
        final isLike = direction == DismissDirection.startToEnd;
        onSwipe(isLike);
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        icon: Icons.diamond,
        label: '素敵！',
        color: const Color(0xFFFFD700), // Gold/Yellow
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        icon: Icons.close,
        label: 'スキップ',
        color: const Color(0xFF6A8594), // Dull Blue (Kusumi Blue)
      ),
      child: _CardFrame(
        child: WorkCard(work: work, onLike: () => onSwipe(true)),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.color,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.9), // Slightly transparent
        borderRadius: BorderRadius.circular(20),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.15),
          ),
        ],
      ),
      child: child,
    );
  }
}
