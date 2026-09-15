import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/halo_theme.dart';

/// Uma foto do feed, com os três estados que ela realmente tem.
///
/// A caixa existe antes dos bytes (`icon-reserve`): a proporção é reservada
/// pelo pai, então nada no feed se mexe quando uma foto chega. Isso importa
/// mais aqui do que num app comum — um layout que ainda está se acomodando sob
/// a dobra faz o efeito parecer um defeito.
class HaloPhoto extends StatelessWidget {
  const HaloPhoto({super.key, required this.url, required this.description});

  final String url;

  /// O que a foto mostra, para quem não a vê. Vazio marca decoração, e aqui
  /// nunca é o caso: a foto é o conteúdo do post.
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
          // Um retângulo na forma da foto, não um spinner por cima dela
          // (`state-loading`). Parado, porque `motion-loop` não aceita um
          // shimmer em laço ao lado de conteúdo sendo lido — e porque o shader
          // já está redesenhando a tela toda a cada frame.
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

/// A foto não chegou. Diz o que falhou e para de prometer.
///
/// Sem botão de tentar de novo: o `cached_network_image` já tenta quando a
/// célula volta à tela, e um botão que não faz nada de diferente é a segunda
/// falha de que `state-retry` fala.
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

/// Avatar redondo. Mesmos três estados da foto, em escala de ícone: sem
/// espaço para uma frase, então a falha vira uma inicial.
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
