import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'duo_fold_config.dart';
import 'tilt_math.dart';

/// `sensors_plus` cannot query hardware presence, so absence and failure arrive
/// through the same channel. They stay apart because what the user does next
/// differs: absence is final, failure is worth retrying.
enum TiltStatus {
  /// Not asked for yet. Holding the hardware before anyone wants it is battery
  /// spent with nobody watching.
  idle,

  /// Subscribed, waiting for the first sample.
  starting,

  /// Samples arriving; tilt is driving the effect.
  running,

  /// No accelerometer on this device. Nothing to retry.
  absent,

  /// Errored, or stopped responding after having worked. Retryable.
  failing,
}

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

  /// Lateral tilt in degrees, relative to the calibrated pose. Positive raises
  /// the left edge, negative the right.
  final double degrees;

  /// The filter is still converging — usable, not yet final.
  final bool isSettling;

  /// Whether gravity can measure this tilt right now. Upright it cannot, and
  /// there the angle stops updating rather than being guessed.
  final bool isReadable;
}

/// Measures lateral tilt against gravity — no integration, so no drift. Two
/// details separate steady from jittery: gravity has to be isolated from hand
/// movement, and upright there is no measurement at all.
class TiltSensor extends ChangeNotifier {
  TiltSensor({
    Duration samplingPeriod = SensorInterval.gameInterval,
    Duration startupTimeout = const Duration(milliseconds: 1200),
  }) : _samplingPeriod = samplingPeriod,
       _startupTimeout = startupTimeout;

  /// 50 Hz, well under the 200 Hz ceiling Android 12 puts on a listener without
  /// the high-sampling-rate permission.
  final Duration _samplingPeriod;
  final Duration _startupTimeout;

  /// Below this, in m/s², the vector is not gravity: free fall or a hard shake.
  static const double _gravityFloor = 5;

  /// Below this, in m/s², too little gravity remains in the measured plane to
  /// say anything about the angle.
  static const double _readableFloor = 2;

  /// Plain low-pass. With no integration there is nothing to correct, only
  /// noise to smooth.
  static const double _smoothing = 0.25;

  static const int _settleSamples = 10;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<UserAccelerometerEvent>? _userAccelSub;
  Timer? _startupTimer;

  TiltStatus _status = TiltStatus.idle;
  TiltStatus get status => _status;

  TiltReading _reading = TiltReading.flat;
  TiltReading get reading => _reading;

  bool get isLive => _status == TiltStatus.running;

  /// Latest linear acceleration — hand movement, without gravity.
  double _ux = 0, _uy = 0, _uz = 0;
  bool _hasUserAccel = false;

  /// Smoothed angle in radians, already relative to the reference.
  double _angle = 0;
  int _samples = 0;

  /// Raw gravity angle at the reference pose.
  double? _reference;
  bool _recalibrate = false;

  Future<void> start() async {
    if (_status == TiltStatus.starting || _status == TiltStatus.running) return;

    _setStatus(TiltStatus.starting);
    _samples = 0;

    // The startup window is what tells "not there" from "there and broken": no
    // sample at all within it means no hardware.
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

      // Linear acceleration is what lets the hand be discounted. Without it the
      // angle still works, only shakier, so its failure does not take the
      // effect down.
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

  /// Makes the current pose the reference — the one where the panel faces front
  /// and the effect disappears.
  void calibrate() {
    _angle = 0;
    _reference = null;
    _recalibrate = true;
    _samples = 0;
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
    // Gravity is what remains once hand movement is taken out. This subtraction
    // is why walking or gesturing does not move the angle.
    final gx = _hasUserAccel ? event.x - _ux : event.x;
    final gy = _hasUserAccel ? event.y - _uy : event.y;
    final gz = _hasUserAccel ? event.z - _uz : event.z;

    if (math.sqrt(gx * gx + gy * gy + gz * gz) < _gravityFloor) {
      _publish(readable: false);
      return;
    }

    // Only the share of gravity this axis moves. Upright it vanishes, and with
    // it any chance of measuring.
    if (math.sqrt(gx * gx + gz * gz) < _readableFloor) {
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

    // The limit comes from the config rather than a local constant: the manual
    // slider and the shader use the same one, and two 80s in different files
    // diverge the day someone edits one.
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
