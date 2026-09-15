import 'package:flutter/material.dart';

import '../theme/halo_theme.dart';
import 'mockup_notice.dart';
import 'post.dart';
import 'sample_feed.dart';
import 'widgets/post_card.dart';
import 'widgets/story_rail.dart';

/// The Halo feed — the content the shader folds.
///
/// States, named before the happy path (`state-set`): loading, empty, error,
/// offline and partial do not apply, since the feed is constant and local with
/// no request to fail. The only async state is each photo, inside its cell.
/// Permission does not apply either: the sensor belongs to the settings.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.onOpenSettings});

  /// Called when the profile is tapped.
  ///
  /// The feed does not open settings itself: it lives inside the folding area,
  /// and a sheet opened from here would inherit the distortion. `DuoStage`
  /// opens it from outside.
  final VoidCallback onOpenSettings;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late List<Post> _posts = SampleFeed.posts();
  final List<Story> _stories = SampleFeed.stories();

  void _toggleLike(int index) {
    setState(() {
      final post = _posts[index];
      _posts = [..._posts]
        ..[index] = post.copyWith(
          liked: !post.liked,
          likes: post.liked ? post.likes - 1 : post.likes + 1,
        );
    });
  }

  void _toggleSave(int index) {
    setState(() {
      final post = _posts[index];
      _posts = [..._posts]..[index] = post.copyWith(saved: !post.saved);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          const _HaloAppBar(),
          SliverToBoxAdapter(child: StoryRail(stories: _stories)),
          // No divider between rail and feed: it touched the first card and
          // read as part of it. Space already separates them, and a line here
          // only competed with the card's own border.
          const SliverToBoxAdapter(child: SizedBox(height: HaloSpacing.sm)),
          SliverList.separated(
            itemCount: _posts.length,
            separatorBuilder: (_, _) => const SizedBox(height: HaloSpacing.sm),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HaloSpacing.gutter,
              ),
              child: PostCard(
                post: _posts[index],
                onToggleLike: () => _toggleLike(index),
                onToggleSave: () => _toggleSave(index),
              ),
            ),
          ),
          // The end of the list is a drawn state, not a cut (`list-end`).
          const SliverToBoxAdapter(child: _FeedEnd()),
        ],
      ),
      bottomNavigationBar: _HaloNavigationBar(
        onOpenProfile: widget.onOpenSettings,
      ),
    );
  }
}

class _HaloAppBar extends StatelessWidget {
  const _HaloAppBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SliverAppBar(
      floating: true,
      titleSpacing: HaloSpacing.gutter,
      title: Row(
        children: [
          Icon(Icons.blur_circular_rounded, color: scheme.primary, size: 26),
          const SizedBox(width: HaloSpacing.xs),
          Text(
            'Halo',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => showMockupNotice(context),
          icon: const Icon(Icons.favorite_border_rounded),
          tooltip: 'Atividade',
        ),
        IconButton(
          onPressed: () => showMockupNotice(context),
          icon: const Icon(Icons.mail_outline_rounded),
          tooltip: 'Mensagens',
        ),
        const SizedBox(width: HaloSpacing.xxs),
      ],
    );
  }
}

class _FeedEnd extends StatelessWidget {
  const _FeedEnd();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HaloSpacing.gutter,
        HaloSpacing.xl,
        HaloSpacing.gutter,
        HaloSpacing.xxl,
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: scheme.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(height: HaloSpacing.xs),
          Text(
            'Você viu tudo',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: HaloSpacing.xxs),
          Text(
            'Três posts é todo o mockup.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The mockup's bottom bar.
///
/// Three destinations are scenery and navigate nowhere. Profile is the only
/// real one: it opens the fold settings, the only thing here that is actually
/// configurable.
class _HaloNavigationBar extends StatelessWidget {
  const _HaloNavigationBar({required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  static const int _profileIndex = 3;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == _profileIndex) {
          onOpenProfile();
        } else {
          showMockupNotice(context);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_filled),
          label: 'Início',
          tooltip: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_rounded),
          label: 'Buscar',
          tooltip: 'Buscar',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_box_outlined),
          label: 'Publicar',
          tooltip: 'Publicar',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Perfil',
          tooltip: 'Perfil e ajustes da curvatura',
        ),
      ],
    );
  }
}
