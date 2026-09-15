import 'dart:math' as math;

/// Lateral tilt from gravity in the device frame. The `-gx` is not taste: the
/// accelerometer measures the *reaction* to gravity, so unflipped the folding
/// side would be the wrong one. Kept Flutter-free so the check can run it.
double tiltAngleFromGravity(double gx, double gz) => math.atan2(-gx, gz);
