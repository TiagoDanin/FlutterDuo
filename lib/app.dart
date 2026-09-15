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
      // Dark was designed first, but the system decides.
      themeMode: ThemeMode.system,
      home: const DuoStage(),
    );
  }
}

/// Wires the three pieces together: shader, angle controller and mockup.
///
/// The mockup sits inside [DuoFoldView] and folds; the settings open over it,
/// from the profile, and do not — they are the simulator's panel and must stay
/// legible exactly when the screen is most distorted.
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

  /// Reduce motion arrives through two channels, and reading one silently
  /// drops the other platform's users.
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

    // The app opens already reading movement: the effect is the product, and
    // hiding it behind a button would make the first screen the least
    // interesting one. `useSensor` declines on its own under reduce motion.
    _controller.useSensor();
  }

  @override
  void didChangeAccessibilityFeatures() => setState(_syncReduceMotion);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A sensor running in the background is battery spent with nobody
    // watching. It resumes on return, since tilt is the default mode.
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
        // The void the shader reveals around the panel. Behind everything, so
        // the folded edge blends into it rather than into the theme.
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
