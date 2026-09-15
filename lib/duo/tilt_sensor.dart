import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'duo_fold_config.dart';
import 'tilt_math.dart';

/// Os estados de `sense-states`, traduzidos para o que este app pode
/// distinguir de fato.
///
/// `sensors_plus` não expõe consulta de presença de hardware, então ausência e
/// falha chegam pelo mesmo caminho: nenhum evento dentro da janela de partida,
/// ou um erro no stream. Ficam separados porque o que o usuário faz a seguir é
/// diferente — ausência é definitiva, falha é tentável de novo.
enum TiltStatus {
  /// Ainda não pedimos o sensor. Segurar o hardware antes de alguém pedir é
  /// bateria gasta sem ninguém olhando.
  idle,

  /// Assinamos os streams e estamos esperando a primeira amostra.
  starting,

  /// Chegando amostras. A inclinação está dirigindo o efeito.
  running,

  /// O aparelho não tem acelerômetro. Não há nada para tentar de novo.
  absent,

  /// O sensor respondeu com erro, ou parou de responder depois de ter
  /// funcionado. Tentável de novo.
  failing,
}

/// Uma leitura de inclinação.
@immutable
class TiltReading {
  const TiltReading({
    required this.degrees,
    required this.isSettling,
    required this.isReadable,
  });

  static const TiltReading flat = TiltReading(
    degrees: 0,
    isSettling: true,
    isReadable: false,
  );

  /// Inclinação lateral, em graus, relativa à pose calibrada. Positivo levanta
  /// a aresta esquerda; negativo levanta a direita.
  final double degrees;

  /// O filtro ainda está convergindo. É o estado *imprecise* de
  /// `sense-states`: o valor já serve, mas ainda não é o definitivo.
  final bool isSettling;

  /// A gravidade consegue medir esta inclinação agora.
  ///
  /// Com o aparelho **de pé** ela não consegue: o eixo do gesto fica quase
  /// paralelo à gravidade e sobra pouco dela no plano medido. Ali o ângulo
  /// não é estimado nem chutado — ele simplesmente para de atualizar, e a
  /// interface diz isso (`sense-accuracy`).
  final bool isReadable;
}

/// Mede o quanto o aparelho está inclinado lateralmente, contra a gravidade.
///
/// O gesto é **inclinar** — levantar um dos lados do aparelho —, e a gravidade
/// mede isso diretamente: basta ver para que lado ela pende dentro do
/// referencial do aparelho. Não há integração, então não há deriva, e não há
/// nada para recalibrar sozinho ao longo do tempo.
///
/// Duas sutilezas fazem a diferença entre uma leitura estável e uma tremida:
///
///  · **A gravidade precisa ser isolada.** O acelerômetro entrega gravidade
///    mais o movimento da mão somados. Subtraindo a aceleração linear, que o
///    sistema já separa, sobra só a gravidade — e sacudir o aparelho deixa de
///    mexer no ângulo.
///  · **Há uma pose em que a medida não existe.** Com o aparelho de pé, o eixo
///    do gesto fica quase paralelo à gravidade e não sobra o suficiente dela no
///    plano medido. Ali o ângulo não é estimado: ele para de atualizar, e a
///    interface avisa. Chutar seria pior do que não responder.
class TiltSensor extends ChangeNotifier {
  TiltSensor({
    Duration samplingPeriod = SensorInterval.gameInterval,
    Duration startupTimeout = const Duration(milliseconds: 1200),
  }) : _samplingPeriod = samplingPeriod,
       _startupTimeout = startupTimeout;

  /// 50 Hz por padrão, bem abaixo do teto de 200 Hz que o Android 12 impõe a
  /// um listener sem a permissão de alta taxa de amostragem.
  final Duration _samplingPeriod;
  final Duration _startupTimeout;

  /// Abaixo desta magnitude, em m/s², o vetor não é a gravidade: o aparelho
  /// está em queda ou sendo sacudido com força.
  static const double _gravityFloor = 5;

  /// Abaixo desta magnitude, em m/s², a gravidade no plano medido é pequena
  /// demais para dizer alguma coisa sobre o ângulo.
  static const double _readableFloor = 2;

  /// Quanto da nova medida entra por amostra. Passa-baixa simples: sem
  /// integração, não há o que corrigir, só ruído a suavizar.
  static const double _smoothing = 0.25;

  /// Quantas amostras o filtro precisa antes de parar de se declarar impreciso.
  static const int _settleSamples = 10;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<UserAccelerometerEvent>? _userAccelSub;
  Timer? _startupTimer;

  TiltStatus _status = TiltStatus.idle;
  TiltStatus get status => _status;

  TiltReading _reading = TiltReading.flat;
  TiltReading get reading => _reading;

  bool get isLive => _status == TiltStatus.running;

  /// Última aceleração linear conhecida — o movimento da mão, sem gravidade.
  double _ux = 0, _uy = 0, _uz = 0;
  bool _hasUserAccel = false;

  /// Ângulo suavizado, em radianos, já relativo à referência.
  double _angle = 0;
  int _samples = 0;

  /// Ângulo bruto da gravidade na pose de referência.
  double? _reference;
  bool _recalibrate = false;

  Future<void> start() async {
    if (_status == TiltStatus.starting || _status == TiltStatus.running) return;

    _setStatus(TiltStatus.starting);
    _samples = 0;

    // Ausência e falha chegam pelo mesmo canal, então a janela de partida é o
    // que separa "não existe" de "existe e quebrou": se nunca chegou amostra
    // nenhuma, o hardware não está lá.
    _startupTimer?.cancel();
    _startupTimer = Timer(_startupTimeout, () {
      if (_status == TiltStatus.starting) {
        _setStatus(TiltStatus.absent);
        _cancelSubscriptions();
      }
    });

    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: _samplingPeriod,
      ).listen(_onAccelerometer, onError: _onSensorError, cancelOnError: false);

      // A aceleração linear é o que permite descontar a mão. Sem ela o ângulo
      // ainda sai, só treme mais, então o erro dela não derruba o efeito.
      _userAccelSub =
          userAccelerometerEventStream(samplingPeriod: _samplingPeriod).listen(
            (event) {
              _ux = event.x;
              _uy = event.y;
              _uz = event.z;
              _hasUserAccel = true;
            },
            onError: (_) {
              _userAccelSub?.cancel();
              _userAccelSub = null;
              _hasUserAccel = false;
            },
            cancelOnError: true,
          );
    } catch (error) {
      _onSensorError(error);
    }
  }

  Future<void> stop() async {
    _startupTimer?.cancel();
    _startupTimer = null;
    await _cancelSubscriptions();
    if (_status != TiltStatus.absent) {
      _setStatus(TiltStatus.idle);
    }
  }

  /// Faz da pose atual a pose de referência, aquela em que o painel está de
  /// frente e o efeito desaparece.
  void calibrate() {
    _angle = 0;
    _reference = null;
    _recalibrate = true;
    _samples = 0;
    // Recém-calibrada, a leitura ainda não sabe se é legível. A próxima
    // amostra resolve isso em milissegundos.
    _reading = const TiltReading(
      degrees: 0,
      isSettling: true,
      isReadable: false,
    );
    notifyListeners();
  }

  Future<void> _cancelSubscriptions() async {
    await _accelSub?.cancel();
    await _userAccelSub?.cancel();
    _accelSub = null;
    _userAccelSub = null;
    _hasUserAccel = false;
  }

  void _onSensorError(Object _) {
    _startupTimer?.cancel();
    _startupTimer = null;
    _setStatus(TiltStatus.failing);
    _cancelSubscriptions();
  }

  void _onAccelerometer(AccelerometerEvent event) {
    // A gravidade é o que sobra quando se tira o movimento da mão. É esta
    // subtração que faz o efeito ignorar quem está andando ou gesticulando.
    final gx = _hasUserAccel ? event.x - _ux : event.x;
    final gy = _hasUserAccel ? event.y - _uy : event.y;
    final gz = _hasUserAccel ? event.z - _uz : event.z;

    if (math.sqrt(gx * gx + gy * gy + gz * gz) < _gravityFloor) {
      // Queda livre, ou sacudida forte demais: o vetor não é a gravidade.
      _publish(readable: false);
      return;
    }

    // Só a parte da gravidade que este eixo de inclinação move. Com o aparelho
    // de pé ela some, e com ela some a possibilidade de medir.
    final inPlane = math.sqrt(gx * gx + gz * gz);
    if (inPlane < _readableFloor) {
      _publish(readable: false);
      return;
    }

    final measured = tiltAngleFromGravity(gx, gz);

    if (_reference == null || _recalibrate) {
      _reference = measured;
      _recalibrate = false;
      _angle = 0;
      _publish(readable: true);
      return;
    }

    // O limite vem do config, e não de uma constante local: o slider manual e o
    // shader usam o mesmo, e dois "80" em arquivos diferentes divergem no dia
    // em que alguém mexer num deles.
    final limit = DuoFoldConfig.maxTiltDegrees * math.pi / 180;

    _angle += _wrap(_wrap(measured - _reference!) - _angle) * _smoothing;
    _angle = _angle.clamp(-limit, limit);

    _publish(readable: true);
  }

  void _publish({required bool readable}) {
    if (_status != TiltStatus.running) {
      _startupTimer?.cancel();
      _startupTimer = null;
      _setStatus(TiltStatus.running);
    }

    if (_samples < _settleSamples) _samples++;

    _reading = TiltReading(
      degrees: _angle * 180 / math.pi,
      isSettling: _samples < _settleSamples,
      isReadable: readable,
    );
    notifyListeners();
  }

  static double _wrap(double radians) {
    var value = radians % (2 * math.pi);
    if (value > math.pi) value -= 2 * math.pi;
    if (value < -math.pi) value += 2 * math.pi;
    return value;
  }

  void _setStatus(TiltStatus next) {
    if (_status == next) return;
    _status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    _accelSub?.cancel();
    _userAccelSub?.cancel();
    super.dispose();
  }
}
