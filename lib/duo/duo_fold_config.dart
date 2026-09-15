import 'package:flutter/foundation.dart';

/// Physical parameters of `shaders/duo_fold.frag`: where the viewer is, how
/// much the glass scatters and absorbs. The order matches the uniforms and is a
/// contract — floats go by index, and reordering breaks the effect silently.
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

  /// Viewer-to-plane distance, in **screen widths** — perspective strength
  /// comes from the ratio of distance to object size, so the effect matches on
  /// any phone. Raising it flattens perspective; it does not touch the blur.
  final double eyeDistanceFactor;

  /// Blur radius per pixel of recession. Low by arithmetic: recession reaches
  /// ~540 px, so 0.12 gave a 60 px blur at middling angles and wiped the screen
  /// out instead of suggesting distance.
  final double blurSpread;

  /// Light lost per pixel of blur radius. Same arithmetic: against a large
  /// radius, any generous value saturates to black.
  final double darkening;

  /// **Maximum** corner radius, in logical px. The shader starts at zero
  /// head-on and reaches this at half the turn. Rounding happens in panel
  /// space, before projection, so corners become ellipses at an angle.
  final double cornerRadius;

  /// Glass glow along the edge, 0..1. A glass border does not end, it lights
  /// up — that thread is what separates glass from a cut-out.
  final double rimLight;

  /// How far light spreads past the edge, in px. Generous on purpose: too
  /// short reads as a contour rather than a dispersion, and the background
  /// returns to black right against the edge.
  final double spreadWidth;

  /// Brightness of the dispersion trail, 0..1 — not its reach. Past ~0.4 with
  /// a light UI behind it, this stops looking like glass and starts looking
  /// like neon.
  final double spreadStrength;

  /// Maximum rotation, in degrees. Well past 45° because it is at the end of
  /// the range that the panel goes near edge-on, and that is what sells the 3D.
  static const double maxTiltDegrees = 80;

  double eyeDistancePixels(double screenWidth) =>
      eyeDistanceFactor * screenWidth;
}
