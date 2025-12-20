import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../works_controller.dart';
import 'work_card.dart';
import '../../../widgets/inline_error_banner.dart';

class WorkSwipeDeck extends ConsumerStatefulWidget {
  const WorkSwipeDeck({super.key});

  @override
  ConsumerState<WorkSwipeDeck> createState() => _WorkSwipeDeckState();
}

class _WorkSwipeDeckState extends ConsumerState<WorkSwipeDeck> {
  Size _lastCardSize = Size.zero;
  String? _lastPrefetchSignature;

  void _schedulePrefetch(List<Work> works, Size cardSize) {
    if (works.isEmpty || !cardSize.isFinite) return;
    final signature =
        '${works.first.id}:${works.length}:${cardSize.width.round()}x${cardSize.height.round()}';
    if (_lastPrefetchSignature == signature) return;
    _lastPrefetchSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefetchWorks(context, works, cardSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(worksControllerProvider);
    final error = state.error;

    Widget withErrorBanner(Widget child) {
      if (error == null || error.isEmpty) return child;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: InlineErrorBanner(message: error),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      );
    }

    if (state.isLoading && state.works.isEmpty) {
      return withErrorBanner(
        const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.works.isEmpty) {
      return withErrorBanner(
        Center(
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
        ),
      );
    }

    final top = state.works.first;

    return withErrorBanner(
      Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardSize = constraints.biggest;
            if (cardSize.isFinite && _lastCardSize != cardSize) {
              _lastCardSize = cardSize;
            }
            _schedulePrefetch(state.works, cardSize);

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
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> _prefetchWorks(
  BuildContext context,
  List<Work> works,
  Size cardSize, {
  int ahead = 2,
}) async {
  if (works.isEmpty || !cardSize.isFinite) return;
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final memCacheWidth = (cardSize.width * dpr).round().clamp(1, 16384) as int;
  final memCacheHeight = (cardSize.height * dpr).round().clamp(1, 16384) as int;
  final end = min(ahead, works.length - 1);
  for (var i = 0; i <= end; i++) {
    final provider =
        _buildImageProvider(works[i].imageUrl, memCacheWidth, memCacheHeight);
    if (provider == null) continue;
    await precacheImage(provider, context);
  }
}

ImageProvider? _buildImageProvider(
  String rawUrl,
  int memCacheWidth,
  int memCacheHeight,
) {
  final src = rawUrl.trim();
  if (src.isEmpty) return null;
  if (src.startsWith('assets/')) {
    return ResizeImage(
      AssetImage(src),
      width: memCacheWidth,
      height: memCacheHeight,
    );
  }
  return ResizeImage(
    CachedNetworkImageProvider(src),
    width: memCacheWidth,
    height: memCacheHeight,
  );
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
        icon: Icons.star,
        label: 'いいね',
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        icon: Icons.close,
        label: 'スキップ',
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: theme.colorScheme.onSurface),
              const SizedBox(height: 6),
              Text(label, style: theme.textTheme.labelLarge),
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
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.12),
          ),
        ],
      ),
      child: child,
    );
  }
}
