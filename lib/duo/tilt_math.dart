import 'dart:math' as math;

/// Lateral tilt from gravity in the device frame.
///
/// The `-gx` is not taste, and this sign has already inverted twice: the
/// accelerometer measures the *reaction* to gravity, so raising the right edge
/// makes `gx` positive and, unflipped, the folding side would be the left one.
///
/// No Flutter imports on purpose — that is what lets
/// `dart run tool/check_tilt.dart` verify it without the SDK.
double tiltAngleFromGravity(double gx, double gz) => math.atan2(-gx, gz);
