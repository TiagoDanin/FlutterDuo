import 'package:flutter/material.dart';

/// Diz que o toque não leva a lugar nenhum.
///
/// O mockup não tem telas para abrir, e um toque que não responde é pior do que
/// um que diz a verdade. Existe num arquivo só porque três lugares precisam
/// dele — antes eram duas cópias idênticas da mesma função em arquivos
/// diferentes, mais uma variante.
void showMockupNotice(BuildContext context, [String? what]) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        what == null
            ? 'Este é um mockup: a ação não leva a nenhuma tela.'
            : 'Este é um mockup: $what não existe.',
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}
