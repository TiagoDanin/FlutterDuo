import 'package:flutter/material.dart';

import '../../theme/halo_theme.dart';
import '../mockup_notice.dart';
import '../post.dart';
import '../sample_feed.dart';
import 'halo_photo.dart';

/// Horizontal story rail — the app's only horizontal scroll, sitting inside an
/// item that does not scroll vertically on its own. Nesting across axes is
/// allowed; along the same one is not.
class StoryRail extends StatelessWidget {
  const StoryRail({super.key, required this.stories});

  final List<Story> stories;

  @override
  Widget build(BuildContext context) {
    // Intrinsic height, not computed: adding the parts by hand gives a number
    // that breaks the moment text scales up. A `ListView` would demand that
    // height upfront, and a fixed handful of items does not need virtualising.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: HaloSpacing.gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, story) in stories.indexed) ...[
            if (index > 0) const SizedBox(width: HaloSpacing.sm),
            _StoryItem(story: story),
          ],
        ],
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final author = story.author;

    // Seen and unseen differ by the ring's presence, not its saturation:
    // colour may not carry a state on its own.
    final ring = story.seen
        ? null
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.primary.withValues(alpha: 0.35)],
          );

    return Semantics(
      button: true,
      label: story.isMine
          ? 'Seu story'
          : 'Story de ${author.name}, ${story.seen ? 'já visto' : 'não visto'}',
      child: InkWell(
        onTap: () => showMockupNotice(
          context,
          story.isMine ? 'o seu story' : 'o story de ${author.name}',
        ),
        borderRadius: BorderRadius.circular(HaloTouch.storyAvatar),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: HaloSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                // The "seen" border takes layout space, so the padding
                // shrinks to match: both states need the same diameter, or the
                // rail ends up with avatars of different heights.
                padding: EdgeInsets.all(story.seen ? 1 : 2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ring,
                  border: story.seen
                      ? Border.all(color: scheme.outline, width: 1.5)
                      : null,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface,
                  ),
                  child: HaloAvatar(
                    url: SampleFeed.avatarUrl(author),
                    name: author.name,
                    size: HaloTouch.storyAvatar,
                  ),
                ),
              ),
              const SizedBox(height: HaloSpacing.xxs),
              SizedBox(
                width: HaloTouch.storyAvatar + HaloSpacing.xs,
                child: Text(
                  story.isMine ? 'Seu story' : author.handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: story.seen
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
