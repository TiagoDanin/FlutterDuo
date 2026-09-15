import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tela cheia de verdade: sem barra de status, sem barra de navegação.
  //
  // É uma exceção deliberada a `layout-chrome`, registrada em `STACK.md`. O
  // app inteiro é uma superfície para ser olhada, e o efeito acontece
  // justamente nas bordas — deixar duas faixas do sistema por cima delas
  // esconde a parte que importa. `immersiveSticky` devolve as barras num
  // deslize e as retira sozinho depois, então nada fica inalcançável.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Trava em retrato. Exceção deliberada a `layout-orientation`, também em
  // `STACK.md`: o movimento é a entrada primária, e a rotação automática
  // competiria com ela — o aparelho giraria a UI no meio do gesto.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const HaloApp());
}
