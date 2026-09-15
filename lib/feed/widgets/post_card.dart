import 'package:flutter/material.dart';

import '../../theme/halo_theme.dart';
import '../mockup_notice.dart';
import '../post.dart';
import '../sample_feed.dart';
import 'halo_photo.dart';

/// Uma célula do feed: cabeçalho, foto, ações, legenda.
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

  /// Proporção 4:5, a mais alta que o Instagram aceita e a que dá mais altura
  /// de foto por rolagem. Fixa, porque a caixa existe antes dos bytes.
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
          // Expanded, não largura fixa: no maior passo de acessibilidade o
          // nome e o local ocupam bem mais linha do que no padrão.
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
            // Vermelho é o significado que curtir já tem em toda rede social.
            // Inventar um segundo vermelho de marca seria cor nova sem
            // trabalho novo.
            color: post.liked ? scheme.error : scheme.onSurface,
            // O rótulo diz o que vai acontecer, não o estado atual.
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

/// Um ícone de ação com alvo de toque completo.
///
/// A altura desenhada do ícone é 24; o alvo é 48. `button-target` e
/// `touch-floor` falam da segunda medida, não da primeira.
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

  /// Preenchido quando o controle tem estado ligado/desligado, para o leitor de
  /// tela anunciar o valor e não só o nome (`a11y-name`).
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
            // A figura, não a palavra (`copy-numbers`).
            '${_thousands(post.likes)} curtidas',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: HaloSpacing.xxs),
          // A legenda é o texto mais longo da tela. Sem maxLines: cortá-la com
          // "ver mais" pediria uma tela que não existe neste mockup.
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

/// Separador de milhar em pt-BR: ponto antes de cada grupo de três que fecha a
/// string. Suficiente para um mockup de uma tela; um app de verdade usaria
/// `intl` com o locale do sistema (`l10n-formats`), que é dependência nova.
String _thousands(int value) => value.toString().replaceAllMapped(
  RegExp(r'\d(?=(\d{3})+$)'),
  (m) => '${m[0]}.',
);
