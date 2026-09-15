import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'duo/duo_fold_view.dart';
import 'duo/duo_shader.dart';
import 'duo/fold_controller.dart';
import 'duo/fold_settings_sheet.dart';
import 'feed/feed_screen.dart';
import 'theme/halo_theme.dart';

class HaloApp extends StatelessWidget {
  const HaloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Halo',
      debugShowCheckedModeBanner: false,
      theme: HaloTheme.light(),
      darkTheme: HaloTheme.dark(),
      // O escuro é o modo desenhado primeiro, mas quem decide é o sistema.
      themeMode: ThemeMode.system,
      home: const DuoStage(),
    );
  }
}

/// Junta as três peças: o shader, o controle da curvatura e o mockup.
///
/// O mockup fica dentro do [DuoFoldView] e curva; os ajustes abrem por cima, a
/// partir do perfil, e não curvam — são o painel do simulador e precisam
/// continuar legíveis exatamente quando a tela está mais distorcida.
class DuoStage extends StatefulWidget {
  const DuoStage({super.key});

  @override
  State<DuoStage> createState() => _DuoStageState();
}

class _DuoStageState extends State<DuoStage> with WidgetsBindingObserver {
  final DuoShaderLoader _shaderLoader = DuoShaderLoader();
  final FoldController _controller = FoldController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shaderLoader.load();
  }

  /// Movimento reduzido chega por dois caminhos e ler um só derruba em silêncio
  /// os usuários da outra plataforma: `disableAnimationsOf` carrega o "Remover
  /// animações" do Android, `reduceMotion` carrega o "Reduzir movimento" do
  /// iOS.
  void _syncReduceMotion() {
    _controller.setReduceMotion(
      MediaQuery.disableAnimationsOf(context) ||
          WidgetsBinding.instance.accessibilityFeatures.reduceMotion,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncReduceMotion();

    // O app abre já lendo o movimento: o efeito é o produto, e escondê-lo
    // atrás de um botão faria a primeira tela ser a menos interessante que ele
    // tem. Não roda quando movimento reduzido está ligado — `useSensor` recusa
    // sozinho nesse caso.
    _controller.useSensor();
  }

  @override
  void didChangeAccessibilityFeatures() => setState(_syncReduceMotion);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Um sensor ligado com o app em segundo plano é bateria gasta com ninguém
    // olhando. Ao voltar, ele religa sozinho, porque a inclinação é o modo
    // padrão e o usuário não pediu para sair dele.
    if (state == AppLifecycleState.resumed) {
      if (_controller.source == FoldSource.sensor) _controller.useSensor();
    } else {
      _controller.sensor.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _shaderLoader.dispose();
    super.dispose();
  }

  void _openSettings() {
    showFoldSettings(
      context,
      controller: _controller,
      shaderLoader: _shaderLoader,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: scheme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        // O void que o shader revela nas quinas. Fica atrás de tudo, para a
        // borda curvada fundir com algo em vez de com o fundo do tema.
        color: HaloTheme.voidColor,
        child: ListenableBuilder(
          listenable: Listenable.merge([_controller, _shaderLoader]),
          builder: (context, child) => DuoFoldView(
            loader: _shaderLoader,
            tiltDegrees: _controller.tiltDegrees,
            config: _controller.config,
            child: child!,
          ),
          child: FeedScreen(onOpenSettings: _openSettings),
        ),
      ),
    );
  }
}
