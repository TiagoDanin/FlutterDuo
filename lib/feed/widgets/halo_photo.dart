import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/halo_theme.dart';

/// A feed photo, with the three states it actually has.
///
/// The box exists before the bytes (`icon-reserve`): the parent reserves the
/// ratio, so nothing shifts when a photo lands. That matters more here than
/// usual — a layout still settling under the fold reads as a defect.
class HaloPhoto extends StatelessWidget {
  const HaloPhoto({super.key, required this.url, required this.description});

  final String url;

  /// What the photo shows, for those who cannot see it. Empty would mark
  /// decoration, which this never is: the photo is the post.
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      image: true,
      label: description,
      child: ClipRRect(
        borderRadius: HaloRadius.photo,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          // A rectangle shaped like the photo, not a spinner over it
          // (`state-loading`). Static, because a looping shimmer next to text
          // being read is what `motion-loop` rules out.
          placeholder: (context, _) =>
              ColoredBox(color: scheme.surfaceContainerHigh),
          errorWidget: (context, _, _) => const _PhotoError(),
          fadeInDuration: const Duration(milliseconds: 180),
          fadeOutDuration: Duration.zero,
        ),
      ),
    );
  }
}

/// The photo did not arrive. Says what failed and stops promising.
///
/// No retry button: `cached_network_image` already retries when the cell
/// returns to screen, and a button that changes nothing is the second failure
/// `state-retry` warns about.
class _PhotoError extends StatelessWidget {
  const _PhotoError();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(HaloSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 28,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: HaloSpacing.xs),
              Text(
                'A foto não carregou',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round avatar. Same three states as the photo, at icon scale: no room for a
/// sentence, so failure becomes an initial.
class HaloAvatar extends StatelessWidget {
  const HaloAvatar({
    super.key,
    required this.url,
    required this.name,
    this.size = HaloTouch.avatar,
  });

  final String url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, _) =>
              ColoredBox(color: scheme.surfaceContainerHigh),
          errorWidget: (context, _, _) => _AvatarFallback(name: name),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
