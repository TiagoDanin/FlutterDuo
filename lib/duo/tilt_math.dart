import 'dart:math' as math;

/// Inclinação lateral a partir da gravidade no referencial do aparelho.
///
/// O `-gx` não é ajuste de gosto, e este sinal já se inverteu duas vezes: o
/// acelerômetro não mede a gravidade, mede a **reação** a ela. Deitado com a
/// tela para cima ele lê `+z`, apontando para fora da tela — para cima no
/// mundo, o oposto da gravidade.
///
/// Levantar a aresta direita faz esse vetor pender para a direita, então `gx`
/// fica positivo. Sem inverter, o ângulo sairia positivo, o que põe a dobradiça
/// na direita — e aí quem dobra é o lado esquerdo, o oposto do lado levantado.
///
/// Este arquivo não importa Flutter de propósito: é o que permite verificá-lo
/// com `dart run tool/check_tilt.dart`, sem SDK e sem framework de teste.
double tiltAngleFromGravity(double gx, double gz) => math.atan2(-gx, gz);
