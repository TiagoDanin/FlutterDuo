import 'package:flutter/material.dart';

import '../../theme/halo_theme.dart';
import '../mockup_notice.dart';
import '../post.dart';
import '../sample_feed.dart';
import 'halo_photo.dart';

/// Trilho horizontal de stories.
///
/// É a única rolagem horizontal do app, e ela está dentro de um item que não
/// rola verticalmente por conta própria — `layout-column` permite aninhar em
/// eixos diferentes, não no mesmo.
class StoryRail extends StatelessWidget {
  const StoryRail({super.key, required this.stories});

  final List<Story> stories;

  @override
  Widget build(BuildContext context) {
    // Altura intrínseca, não calculada. Somar avatar, anéis, folgas e a linha
    // do rótulo à mão dá um número que fica errado assim que o usuário aumenta
    // o texto ou alguém mexe numa borda — e o erro aparece como overflow, não
    // como aviso. Aqui a Column mede o próprio conteúdo e cresce com ele.
    //
    // Um `ListView` exigiria essa altura adiantada. Sem virtualização porque o
    // trilho tem seis itens fixos: `list-virtualisation` fala de listas que
    // crescem, e esta não cresce.
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

    // Visto e não visto se distinguem pela presença do anel, não pela
    // saturação dele: `color-*` não deixa a cor carregar um estado sozinha.
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
                // A borda do estado "visto" ocupa layout, então o padding
                // encolhe na mesma medida: os dois estados precisam ter o
                // mesmo diâmetro, senão o trilho fica com avatares de alturas
                // diferentes.
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
