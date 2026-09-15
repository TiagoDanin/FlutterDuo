import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

import 'duo_fold_config.dart';
import 'duo_shader.dart';

/// Aplica `duo_fold.frag` sobre [child].
///
/// O widget não anima nada por conta própria: ele recebe [tiltDegrees] já
/// calculado e repinta. Quem produz o valor é o `FoldController`, seja a
/// partir do sensor ou do controle manual.
///
/// O shader fica **sempre** no caminho enquanto existe, mesmo com o painel de
/// frente. Ligar e desligar conforme o ângulo parece economia, mas troca a
/// imagem: pela textura de um lado, direto do outro. Perto de qualquer limiar,
/// o ruído do sensor alternava os dois a cada frame e a borda piscava entre
/// reta e redonda. Sai barato porque o shader faz bypass pixel-perfect no
/// ângulo zero; o que sobra é o snapshot da árvore.
class DuoFoldView extends StatelessWidget {
  const DuoFoldView({
    super.key,
    required this.loader,
    required this.tiltDegrees,
    required this.child,
    this.config = const DuoFoldConfig(),
  });

  final DuoShaderLoader loader;

  /// Rotação do painel em graus. O sinal decide qual aresta vertical fica
  /// parada: positivo prende a direita e dobra o lado esquerdo para trás,
  /// negativo faz o contrário. Um lado de cada vez.
  final double tiltDegrees;

  final DuoFoldConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shader = loader.shader;

    // Sem shader — ainda carregando, ou aparelho sem suporte — a tela é a tela.
    // Não há estado de erro desenhado aqui: os ajustes é que contam isso.
    if (shader == null) return child;

    // A dobradiça não é enviada: o shader a deriva do sinal de `uTiltDegrees`.
    return AnimatedSampler((ui.Image image, Size size, ui.Canvas canvas) {
      shader
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, tiltDegrees)
        ..setFloat(3, config.eyeDistancePixels(size.width))
        ..setFloat(4, config.blurSpread)
        ..setFloat(5, config.darkening)
        ..setFloat(6, config.cornerRadius)
        ..setFloat(7, config.rimLight)
        ..setFloat(8, config.spreadWidth)
        ..setFloat(9, config.spreadStrength)
        ..setImageSampler(0, image);

      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    }, child: child);
  }
}
