import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models.dart';

class WorkCard extends StatelessWidget {
  const WorkCard({super.key, required this.work, required this.onLike});

  final Work work;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width =
            constraints.hasBoundedWidth ? constraints.maxWidth : null;
        final height =
            constraints.hasBoundedHeight ? constraints.maxHeight : null;
        final memCacheWidth = width == null
            ? null
            : (width * dpr).round().clamp(1, 16384) as int;
        final memCacheHeight = height == null
            ? null
            : (height * dpr).round().clamp(1, 16384) as int;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(theme, memCacheWidth, memCacheHeight),
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
            ],
          ),
        );
      },
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

  Widget _loadingPlaceholder(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildImage(ThemeData theme, int? memCacheWidth, int? memCacheHeight) {
    final src = work.imageUrl.trim();
    if (src.isEmpty) return _fallback(theme);

    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        fit: BoxFit.cover,
        cacheWidth: memCacheWidth,
        cacheHeight: memCacheHeight,
        errorBuilder: (_, __, ___) => _fallback(theme),
      );
    }

    return CachedNetworkImage(
      imageUrl: src,
      fit: BoxFit.cover,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (_, __) => _loadingPlaceholder(theme),
      errorWidget: (_, __, ___) => _fallback(theme),
      fadeInDuration: const Duration(milliseconds: 120),
    );
  }
}
