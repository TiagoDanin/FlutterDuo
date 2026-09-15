import 'package:flutter/foundation.dart';

/// Parâmetros físicos do `shaders/duo_fold.frag`.
///
/// Descrevem a cena — onde está o observador, o quanto o vidro espalha e
/// absorve —, não o desenho que sai dela. A ordem bate com os uniforms e é
/// contrato: os floats vão por índice, e trocá-la quebra o efeito em silêncio.
@immutable
class DuoFoldConfig {
  const DuoFoldConfig({
    this.eyeDistanceFactor = 2.4,
    this.blurSpread = 0.045,
    this.darkening = 0.005,
    this.cornerRadius = 52,
    this.rimLight = 0.18,
    this.spreadWidth = 150,
    this.spreadStrength = 0.5,
  });

  /// Distância do observador ao plano, em **larguras de tela**.
  ///
  /// Em larguras, e não em milímetros, porque a força da perspectiva vem da
  /// razão entre distância e tamanho do objeto — assim o efeito fica igual em
  /// qualquer telefone. Aumentar achata a perspectiva; não mexe no borrão.
  final double eyeDistanceFactor;

  /// Raio de borrão por pixel de afastamento.
  ///
  /// Baixo por aritmética: o afastamento chega perto de meia largura de tela,
  /// uns 540 px, então 0.12 dava borrão de 60 px em ângulos médios e apagava a
  /// tela em vez de sugerir distância.
  final double blurSpread;

  /// Luz perdida por pixel de raio de borrão. Mesma aritmética: multiplicado
  /// por um raio grande, qualquer valor generoso satura em preto.
  final double darkening;

  /// Raio **máximo** dos cantos, em px lógicos.
  ///
  /// O shader parte de zero com o painel de frente — onde o canto visível é o
  /// da tela do aparelho — e chega aqui na metade do giro. O arredondamento é
  /// feito no espaço do painel, antes da projeção, então em ângulo os cantos
  /// viram elipses sozinhos.
  final double cornerRadius;

  /// Brilho do vidro na aresta, 0..1. A borda de um painel de vidro não
  /// termina, ela acende — é esse fio que separa "vidro" de "recorte".
  final double rimLight;

  /// Alcance da dispersão para fora da aresta, em px.
  ///
  /// Generoso de propósito: curto demais produz um contorno em volta do painel,
  /// não uma dispersão, e o fundo volta a ser preto encostado na aresta.
  final double spreadWidth;

  /// Brilho do rastro da dispersão, 0..1 — não confundir com o alcance.
  ///
  /// Passando de ~0.4 com uma UI clara atrás, deixa de parecer vidro e vira
  /// neon.
  final double spreadStrength;

  /// Rotação máxima, em graus. Bem além de 45° porque é no fim da faixa que o
  /// painel fica quase de perfil, e é o quase-perfil que vende o 3D.
  static const double maxTiltDegrees = 80;

  double eyeDistancePixels(double screenWidth) =>
      eyeDistanceFactor * screenWidth;
}
