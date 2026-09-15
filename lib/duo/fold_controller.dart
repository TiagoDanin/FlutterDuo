import 'package:flutter/foundation.dart';

import 'duo_fold_config.dart';
import 'tilt_sensor.dart';

/// What is driving the panel.
enum FoldSource {
  /// Device movement. What the app exists for, and how it opens.
  sensor,

  /// Manual control. Required by `a11y-gesture`, the destination of
  /// `motion-reduced`, and the only mode on a device without the sensor.
  manual,
}

/// Single source of the effect's angle, from the sensor or the finger.
///
/// The UI watches only this. Nothing reads the accelerometer directly, because
/// what matters is the panel's angle, not the raw sample.
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

  /// Panel rotation in degrees. Positive takes the right edge away from the
  /// viewer and puts the hinge on the right.
  double get tiltDegrees => _tiltDegrees;

  bool _reduceMotion = false;

  /// With reduce motion on, the sensor drives nothing: the screen must not move
  /// because the user moved the device. Manual stays, since there the movement
  /// is asked for.
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

  /// Hands the panel to the sensor. This is how the app opens: the effect is
  /// the product, and hiding it behind a button would make the first screen the
  /// least interesting one it has.
  Future<void> useSensor() async {
    if (_reduceMotion) return;
    _source = FoldSource.sensor;
    notifyListeners();
    await sensor.start();
  }

  /// Returns the panel to manual control and releases the hardware.
  Future<void> useManual() async {
    _source = FoldSource.manual;
    notifyListeners();
    await sensor.stop();
  }

  /// Makes the current pose the reference one.
  ///
  /// Exists because the zero pose is not a property of the world: it is however
  /// the user happened to be holding the device. Shifting in your chair has to
  /// be recoverable.
  void calibrate() {
    if (_source != FoldSource.sensor) return;
    sensor.calibrate();
  }

  /// Ignored while the sensor is driving, so the two do not fight over the same
  /// value.
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

    // Absent, failing or still starting: the panel returns to facing front
    // rather than freezing at an angle nobody asked for.
    _apply(sensor.isLive ? sensor.reading.degrees : 0);
  }

  void _apply(double degrees) {
    // A twentieth of a degree is far below what any pixel can show; repainting
    // the whole screen for less is work thrown away.
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
