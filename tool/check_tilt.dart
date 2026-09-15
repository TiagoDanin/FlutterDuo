// ignore_for_file: avoid_print — a command-line script; the output is the
// point.

// Check for the gravity-to-tilt conversion.
//
// Run with:  dart run tool/check_tilt.dart
//
// Exists because this sign has inverted twice, and when it does the effect
// folds the wrong side — something only visible with the device in hand.
//
// No framework on purpose: the project has no test suite, and a file that runs
// under `dart run` does not ask for one.

import 'dart:math' as math;

import 'package:flutter_duo/duo/tilt_math.dart';

int _failures = 0;

void check(String what, bool ok) {
  if (!ok) _failures++;
  print('${ok ? 'ok  ' : 'FAIL'}  $what');
}

/// The gravity an accelerometer reports with the device tilted by `degrees`.
/// Positive raises the right edge.
///
/// It measures the reaction to gravity, so the vector points up in the world:
/// `+z` lying flat, screen up.
({double gx, double gz}) gravityAtTilt(double degrees) {
  final a = degrees * math.pi / 180;
  return (gx: 9.81 * math.sin(a), gz: 9.81 * math.cos(a));
}

void main() {
  print('=== flat, screen up ===');
  check('level reads zero', tiltAngleFromGravity(0, 9.81).abs() < 1e-9);

  print('\n=== the raised side is the side that folds ===');
  // The hinge follows the sign: positive puts it on the right, and the side
  // that folds is the one opposite it. Raising the right must read negative.
  final right = gravityAtTilt(30);
  final left = gravityAtTilt(-30);

  check(
    'raising the right reads negative (hinge left)',
    tiltAngleFromGravity(right.gx, right.gz) < 0,
  );
  check(
    'raising the left reads positive (hinge right)',
    tiltAngleFromGravity(left.gx, left.gz) > 0,
  );

  print('\n=== the angle matches the tilt applied ===');
  for (final degrees in [-60.0, -30.0, -5.0, 5.0, 30.0, 60.0]) {
    final g = gravityAtTilt(degrees);
    final measured = tiltAngleFromGravity(g.gx, g.gz) * 180 / math.pi;
    check(
      '${degrees.toStringAsFixed(0)}° reads as '
      '${measured.toStringAsFixed(1)}°',
      (measured + degrees).abs() < 0.01,
    );
  }

  print('\n=== monotonic: more tilt, more angle ===');
  var previous = double.infinity;
  var monotonic = true;
  for (var d = -80; d <= 80; d += 5) {
    final g = gravityAtTilt(d.toDouble());
    final measured = tiltAngleFromGravity(g.gx, g.gz);
    if (measured > previous) monotonic = false;
    previous = measured;
  }
  check('no inversions across the range', monotonic);

  print('\n${_failures == 0 ? 'ALL OK' : '$_failures FAILED'}');
  if (_failures > 0) throw StateError('$_failures checks failed');
}
