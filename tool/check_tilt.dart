// ignore_for_file: avoid_print — é um script de linha de comando; a saída é
// o produto dele.

// Check da conversão gravidade -> inclinação.
//
// Roda com:  dart run tool/check_tilt.dart
//
// Existe porque este sinal já se inverteu duas vezes, e quando inverte o efeito
// dobra o lado errado — algo que só se percebe com o aparelho na mão. É o menor
// check que falha antes disso chegar lá.
//
// Sem framework de propósito: o projeto não tem suíte de testes, e um arquivo
// que roda com `dart run` não pede nenhuma.

import 'dart:math' as math;

import 'package:flutter_duo/duo/tilt_math.dart';

int _failures = 0;

void check(String what, bool ok) {
  if (!ok) _failures++;
  print('${ok ? 'ok   ' : 'FALHA'}  $what');
}

/// A gravidade que o acelerômetro reporta com o aparelho inclinado por `graus`
/// em torno do eixo vertical da tela. Positivo levanta a aresta direita.
///
/// O acelerômetro mede a reação à gravidade, então o vetor aponta para cima no
/// mundo: `+z` com o aparelho deitado e a tela para cima.
({double gx, double gz}) gravityAtTilt(double degrees) {
  final a = degrees * math.pi / 180;
  return (gx: 9.81 * math.sin(a), gz: 9.81 * math.cos(a));
}

void main() {
  print('=== deitado, tela para cima ===');
  check('nivelado dá zero', tiltAngleFromGravity(0, 9.81).abs() < 1e-9);

  print('\n=== o lado levantado é o lado que dobra ===');
  // Dobradiça = sinal do ângulo: positivo põe a dobradiça na direita, e quem
  // dobra é o lado OPOSTO a ela. Levantar a direita tem que dar negativo.
  final right = gravityAtTilt(30);
  final left = gravityAtTilt(-30);

  check(
    'levantar a direita dá ângulo negativo (dobradiça à esquerda)',
    tiltAngleFromGravity(right.gx, right.gz) < 0,
  );
  check(
    'levantar a esquerda dá ângulo positivo (dobradiça à direita)',
    tiltAngleFromGravity(left.gx, left.gz) > 0,
  );

  print('\n=== o ângulo bate com a inclinação aplicada ===');
  for (final degrees in [-60.0, -30.0, -5.0, 5.0, 30.0, 60.0]) {
    final g = gravityAtTilt(degrees);
    final measured = tiltAngleFromGravity(g.gx, g.gz) * 180 / math.pi;
    check(
      '${degrees.toStringAsFixed(0)}° medido como '
      '${measured.toStringAsFixed(1)}°',
      (measured + degrees).abs() < 0.01,
    );
  }

  print('\n=== monotônico: mais inclinação, mais ângulo ===');
  var previous = double.infinity;
  var monotonic = true;
  for (var d = -80; d <= 80; d += 5) {
    final g = gravityAtTilt(d.toDouble());
    final measured = tiltAngleFromGravity(g.gx, g.gz);
    if (measured > previous) monotonic = false;
    previous = measured;
  }
  check('sem inversões ao longo da faixa', monotonic);

  print('\n${_failures == 0 ? 'TUDO OK' : '$_failures FALHARAM'}');
  if (_failures > 0) throw StateError('$_failures verificações falharam');
}
