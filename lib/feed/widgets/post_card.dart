import 'package:flutter/material.dart';

import '../../theme/halo_theme.dart';
import '../mockup_notice.dart';
import '../post.dart';
import '../sample_feed.dart';
import 'halo_photo.dart';

/// A feed cell: header, photo, actions, caption.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onToggleLike,
    required this.onToggleSave,
  });

  final Post post;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;

  /// 4:5 — the tallest common ratio, so the most photo per scroll. Fixed,
  /// because the box exists before the bytes.
  static const double _photoAspect = 4 / 5;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(post: post),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: HaloSpacing.sm),
            child: AspectRatio(
              aspectRatio: _photoAspect,
              child: HaloPhoto(
                url: post.photoUrl,
                description: post.photoDescription,
              ),
            ),
          ),
          _PostActions(
            post: post,
            onToggleLike: onToggleLike,
            onToggleSave: onToggleSave,
          ),
          _PostCaption(post: post),
        ],
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HaloSpacing.sm,
        HaloSpacing.sm,
        HaloSpacing.xs,
        HaloSpacing.sm,
      ),
      child: Row(
        children: [
          HaloAvatar(
            url: SampleFeed.avatarUrl(post.author),
            name: post.author.name,
          ),
          const SizedBox(width: HaloSpacing.sm),
          // Expanded, not a fixed width: at the largest accessibility step
          // the name and place take far more line than at the default.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  post.place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showMockupNotice(context),
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: 'Mais opções do post',
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    required this.onToggleLike,
    required this.onToggleSave,
  });

  final Post post;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HaloSpacing.xs,
        vertical: HaloSpacing.xxs,
      ),
      child: Row(
        children: [
          _ActionButton(
            icon: post.liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            // Red is what a like already means everywhere. A second brand red
            // would be a new colour doing no new work.
            color: post.liked ? scheme.error : scheme.onSurface,
            // The label says what will happen, not the current state.
            label: post.liked ? 'Descurtir' : 'Curtir',
            isToggled: post.liked,
            onPressed: onToggleLike,
          ),
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            color: scheme.onSurface,
            label: 'Comentar',
            onPressed: () => showMockupNotice(context),
          ),
          _ActionButton(
            icon: Icons.send_outlined,
            color: scheme.onSurface,
            label: 'Compartilhar',
            onPressed: () => showMockupNotice(context),
          ),
          const Spacer(),
          _ActionButton(
            icon: post.saved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: post.saved ? scheme.primary : scheme.onSurface,
            label: post.saved ? 'Remover dos salvos' : 'Salvar',
            isToggled: post.saved,
            onPressed: onToggleSave,
          ),
        ],
      ),
    );
  }
}

/// An action icon with a full touch target. The icon draws at 24, the target
/// is 48 — `button-target` and `touch-floor` are about the second measurement,
/// not the first.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
    this.isToggled,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onPressed;

  /// Set when the control has an on/off state, so a screen reader announces
  /// the value and not just the name (`a11y-name`).
  final bool? isToggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isToggled,
      label: label,
      child: ExcludeSemantics(
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: color,
          tooltip: label,
          constraints: const BoxConstraints(
            minWidth: HaloTouch.minTarget,
            minHeight: HaloTouch.minTarget,
          ),
        ),
      ),
    );
  }
}

class _PostCaption extends StatelessWidget {
  const _PostCaption({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HaloSpacing.sm,
        HaloSpacing.xxs,
        HaloSpacing.sm,
        HaloSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // The figure, not the word (`copy-numbers`).
            '${_thousands(post.likes)} curtidas',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: HaloSpacing.xxs),
          // The caption is the longest text here. No maxLines: truncating it
          // would need a screen this mockup does not have.
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: post.author.handle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '  '),
                TextSpan(text: post.caption),
              ],
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: HaloSpacing.xs),
          Text(
            '${_thousands(post.comments)} comentários · ${post.postedAgo}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// pt-BR thousands separator: a dot before every group of three that closes
/// the string. Enough for a one-screen mockup; a real app would use `intl` with
/// the system locale, which is a new dependency.
String _thousands(int value) => value.toString().replaceAllMapped(
  RegExp(r'\d(?=(\d{3})+$)'),
  (m) => '${m[0]}.',
);
