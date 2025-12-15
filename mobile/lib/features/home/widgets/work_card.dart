import 'package:flutter/material.dart';

import '../models.dart';

class WorkCard extends StatelessWidget {
  const WorkCard({super.key, required this.work, required this.onLike});

  final Work work;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (work.imageUrl.trim().isNotEmpty)
            Image.network(
              work.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(theme),
            )
          else
            _fallback(theme),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xAA000000),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  work.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  work.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: IconButton.filledTonal(
              onPressed: onLike,
              icon: const Icon(Icons.favorite),
              tooltip: 'いいね',
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 72,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
