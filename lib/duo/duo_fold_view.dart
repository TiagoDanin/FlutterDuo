import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

import 'duo_fold_config.dart';
import 'duo_shader.dart';

/// Applies `duo_fold.frag` over [child].
///
/// It animates nothing on its own: [tiltDegrees] arrives already computed and
/// it repaints. The shader stays in the path at all times — toggling it by
/// angle swaps the image, and sensor noise around any threshold alternated the
/// two every frame, which showed as the border flickering straight to round.
class DuoFoldView extends StatelessWidget {
  const DuoFoldView({
    super.key,
    required this.loader,
    required this.tiltDegrees,
    required this.child,
    this.config = const DuoFoldConfig(),
  });

  final DuoShaderLoader loader;

  /// Panel rotation in degrees. The sign picks which vertical edge stays put:
  /// positive pins the right and folds the left back. One side at a time.
  final double tiltDegrees;

  final DuoFoldConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shader = loader.shader;

    // No shader — still loading, or unsupported — and the screen is the screen.
    // The settings sheet is what reports that, not this.
    if (shader == null) return child;

    // The hinge side is not sent: the shader derives it from the tilt's sign.
    return AnimatedSampler((ui.Image image, Size size, ui.Canvas canvas) {
      shader
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, tiltDegrees)
        ..setFloat(3, config.eyeDistancePixels(size.width))
        ..setFloat(4, config.blurSpread)
        ..setFloat(5, config.darkening)
        ..setFloat(6, config.cornerRadius)
        ..setFloat(7, config.rimLight)
        ..setFloat(8, config.spreadWidth)
        ..setFloat(9, config.spreadStrength)
        ..setImageSampler(0, image);

      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    }, child: child);
  }
}
