import 'package:flutter/foundation.dart';

import 'duo_fold_config.dart';
import 'tilt_sensor.dart';

/// Quem está dirigindo o vidro.
enum FoldSource {
  /// A rotação do aparelho. O modo para o qual o app existe, e o modo em que
  /// ele abre.
  sensor,

  /// O controle manual. É a rota que `a11y-gesture` exige, o destino de
  /// `motion-reduced`, e o único modo possível num aparelho sem giroscópio.
  manual,
}

/// Estado único do efeito, venha ele do sensor ou do dedo.
///
/// A UI observa só isto. Nada no app lê o giroscópio direto, porque o que
/// importa é o ângulo do vidro, não a leitura crua.
class FoldController extends ChangeNotifier {
  FoldController({TiltSensor? sensor, DuoFoldConfig? config})
    : sensor = sensor ?? TiltSensor(),
      config = config ?? const DuoFoldConfig() {
    this.sensor.addListener(_onSensorChanged);
  }

  final TiltSensor sensor;
  final DuoFoldConfig config;

  FoldSource _source = FoldSource.sensor;
  FoldSource get source => _source;

  double _tiltDegrees = 0;

  /// Rotação do painel em graus. Positivo leva a aresta direita para longe do
  /// observador, e a dobradiça para a direita.
  double get tiltDegrees => _tiltDegrees;

  bool _reduceMotion = false;

  /// Com movimento reduzido ligado, o sensor não dirige nada: a tela não pode
  /// se mexer porque o usuário mexeu o aparelho. O controle manual continua,
  /// porque ele é o usuário pedindo o movimento de propósito.
  bool get reduceMotion => _reduceMotion;

  void setReduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    if (value && _source == FoldSource.sensor) {
      useManual();
    } else {
      notifyListeners();
    }
  }

  /// Passa o vidro para o sensor.
  ///
  /// É o estado em que o app abre: o efeito é o produto, e escondê-lo atrás de
  /// um botão faria a primeira tela ser a menos interessante que ele tem.
  Future<void> useSensor() async {
    if (_reduceMotion) return;
    _source = FoldSource.sensor;
    notifyListeners();
    await sensor.start();
  }

  /// Devolve o vidro ao controle manual e solta o hardware.
  Future<void> useManual() async {
    _source = FoldSource.manual;
    notifyListeners();
    await sensor.stop();
  }

  /// Faz da pose atual a pose de referência, em que o vidro está encostado no
  /// plano e o efeito desaparece.
  ///
  /// Existe porque a pose zero não é uma propriedade do mundo: é onde o usuário
  /// estava segurando o aparelho quando começou. Quem muda de posição na
  /// cadeira precisa poder dizer "é aqui agora".
  void calibrate() {
    if (_source != FoldSource.sensor) return;
    sensor.calibrate();
  }

  /// Move o painel pelo controle manual. Ignorado enquanto o sensor manda, para
  /// os dois não disputarem o mesmo valor.
  void setManualTilt(double degrees) {
    if (_source != FoldSource.manual) return;
    _apply(
      degrees.clamp(
        -DuoFoldConfig.maxTiltDegrees,
        DuoFoldConfig.maxTiltDegrees,
      ),
    );
  }

  void _onSensorChanged() {
    if (_source != FoldSource.sensor) return;

    if (sensor.isLive) {
      _apply(sensor.reading.degrees);
    } else {
      // Sensor ausente, falhando ou ainda subindo: o painel volta a ficar de
      // frente em vez de congelar num ângulo que ninguém pediu.
      _apply(0);
    }
  }

  void _apply(double degrees) {
    // Um vigésimo de grau é bem menos do que qualquer pixel consegue mostrar;
    // abaixo disso repintar a tela inteira é trabalho jogado fora.
    if ((_tiltDegrees - degrees).abs() < 0.05) return;
    _tiltDegrees = degrees;
    notifyListeners();
  }

  @override
  void dispose() {
    sensor.removeListener(_onSensorChanged);
    sensor.dispose();
    super.dispose();
  }
}
