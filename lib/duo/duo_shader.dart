import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

enum DuoShaderStatus { loading, ready, unsupported }

/// Carrega `shaders/duo_fold.frag` uma vez e guarda a instância.
///
/// Compilar o programa é caro e recriar o [ui.FragmentShader] a cada frame
/// jogaria fora a compilação, então o shader é criado uma vez e só os uniforms
/// mudam.
class DuoShaderLoader extends ChangeNotifier {
  DuoShaderStatus _status = DuoShaderStatus.loading;
  DuoShaderStatus get status => _status;

  /// Não-nulo equivale a pronto: só é atribuído no caminho de sucesso.
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
      // Acontece de verdade: erro de compilação do GLSL no aparelho, ou uma GPU
      // que recusa o programa. Sem shader o app continua usável, só não dobra.
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
