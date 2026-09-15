import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

enum DuoShaderStatus { loading, ready, unsupported }

/// Loads `shaders/duo_fold.frag` once and keeps the instance.
///
/// Compiling is expensive and recreating the shader per frame would throw that
/// away, so it is built once and only the uniforms change.
class DuoShaderLoader extends ChangeNotifier {
  DuoShaderStatus _status = DuoShaderStatus.loading;
  DuoShaderStatus get status => _status;

  /// Non-null means ready: only assigned on the success path.
  ui.FragmentShader? _shader;
  ui.FragmentShader? get shader => _shader;

  Future<void> load() async {
    if (_status != DuoShaderStatus.loading) return;
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/duo_fold.frag',
      );
      _shader = program.fragmentShader();
      _status = DuoShaderStatus.ready;
    } catch (_) {
      // Happens for real: a GLSL compile error on device, or a GPU refusing the
      // program. Without a shader the app still works, it just does not fold.
      _status = DuoShaderStatus.unsupported;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }
}
