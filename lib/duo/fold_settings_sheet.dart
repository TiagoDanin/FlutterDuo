import 'package:flutter/material.dart';

import '../theme/halo_theme.dart';
import 'duo_fold_config.dart';
import 'duo_shader.dart';
import 'fold_controller.dart';
import 'tilt_sensor.dart';

/// The effect's settings, opened from the profile. They sit **outside**
/// `DuoFoldView`: routed through the panel, the controls would be blurred and
/// displaced exactly when they are needed most.
Future<void> showFoldSettings(
  BuildContext context, {
  required FoldController controller,
  required DuoShaderLoader shaderLoader,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(borderRadius: HaloRadius.sheet),
    builder: (context) =>
        FoldSettingsSheet(controller: controller, shaderLoader: shaderLoader),
  );
}

class FoldSettingsSheet extends StatelessWidget {
  const FoldSettingsSheet({
    super.key,
    required this.controller,
    required this.shaderLoader,
  });

  final FoldController controller;
  final DuoShaderLoader shaderLoader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        controller.sensor,
        shaderLoader,
      ]),
      builder: (context, _) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              HaloSpacing.lg,
              0,
              HaloSpacing.lg,
              HaloSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vidro',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: HaloSpacing.md),
                _StatusCard(controller: controller, shaderLoader: shaderLoader),
                _SensorActions(controller: controller),
                const SizedBox(height: HaloSpacing.lg),
                _SourceSwitch(controller: controller),
                const SizedBox(height: HaloSpacing.sm),
                _TiltSlider(controller: controller),
                const SizedBox(height: HaloSpacing.xs),
                _TiltReadout(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The sentence for the current state. Each `sense-states` state gets its own,
/// because what the user does next differs in each — a generic message here
/// would be the same as having no state at all.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.controller, required this.shaderLoader});

  final FoldController controller;
  final DuoShaderLoader shaderLoader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, message, tone) = _describe(scheme);

    return Container(
      padding: const EdgeInsets.all(HaloSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: HaloRadius.photo,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tone),
          const SizedBox(width: HaloSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: tone),
            ),
          ),
        ],
      ),
    );
  }

  /// Order matters: what blocks the whole effect comes before what merely
  /// changes who drives it.
  (IconData, String, Color) _describe(ColorScheme scheme) {
    if (shaderLoader.status == DuoShaderStatus.unsupported) {
      return (
        Icons.layers_clear_rounded,
        'Este aparelho não compilou o shader, então o vidro não aparece. O '
            'resto do mockup funciona.',
        scheme.error,
      );
    }
    if (shaderLoader.status == DuoShaderStatus.loading) {
      return (
        Icons.hourglass_empty_rounded,
        'Compilando o shader.',
        scheme.onSurfaceVariant,
      );
    }
    if (controller.reduceMotion) {
      return (
        Icons.accessibility_new_rounded,
        'Movimento reduzido está ligado no sistema, então o aparelho não gira '
            'o vidro. Use o controle abaixo.',
        scheme.onSurfaceVariant,
      );
    }

    if (controller.source == FoldSource.manual) {
      return (
        Icons.tune_rounded,
        'Controle manual. Arraste para girar o vidro.',
        scheme.onSurfaceVariant,
      );
    }

    return switch (controller.sensor.status) {
      TiltStatus.absent => (
        Icons.sensors_off_rounded,
        'Este aparelho não tem giroscópio. O vidro fica no controle manual.',
        scheme.error,
      ),
      TiltStatus.failing => (
        Icons.error_outline_rounded,
        'O sensor de movimento parou de responder.',
        scheme.error,
      ),
      TiltStatus.starting => (
        Icons.sensors_rounded,
        'Procurando o sensor de movimento.',
        scheme.onSurfaceVariant,
      ),
      TiltStatus.idle => (
        Icons.sensors_rounded,
        'O sensor está desligado.',
        scheme.onSurfaceVariant,
      ),
      TiltStatus.running when controller.sensor.reading.isSettling => (
        Icons.sensors_rounded,
        'Calibrando. Segure o aparelho parado, na posição em que você quer que '
            'a tela fique reta.',
        scheme.onSurfaceVariant,
      ),
      // Upright, the gesture's axis runs nearly parallel to gravity and it
      // has nothing left to say. The angle stops rather than being guessed.
      TiltStatus.running when !controller.sensor.reading.isReadable => (
        Icons.gps_not_fixed_rounded,
        'Nesta posição a gravidade não consegue medir a inclinação. Deite um '
            'pouco o aparelho e ela volta.',
        scheme.onSurfaceVariant,
      ),
      TiltStatus.running => (
        Icons.sensors_rounded,
        'Levante um dos lados do aparelho. O lado levantado é o que dobra para '
            'trás.',
        scheme.primary,
      ),
    };
  }
}

/// The sensor's two actions: re-anchor and restart. Restart exists because
/// tapping an already-selected segment fires nothing — `SegmentedButton` only
/// reports changes — which left no way back from a stopped sensor.
class _SensorActions extends StatelessWidget {
  const _SensorActions({required this.controller});

  final FoldController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.sensor.status;
    if (controller.source != FoldSource.sensor ||
        controller.reduceMotion ||
        status == TiltStatus.absent) {
      return const SizedBox.shrink();
    }

    final stalled = status == TiltStatus.idle || status == TiltStatus.failing;

    return Padding(
      padding: const EdgeInsets.only(top: HaloSpacing.xxs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: stalled ? controller.useSensor : controller.calibrate,
          icon: Icon(
            stalled ? Icons.refresh_rounded : Icons.center_focus_strong_rounded,
            size: 18,
          ),
          label: Text(stalled ? 'Ligar o sensor' : 'Calibrar aqui'),
        ),
      ),
    );
  }
}

/// How much and which way, in numbers. Not decoration: without it there is no
/// telling whether the sensor reads the rotation the device actually has, and
/// the reading is half of what this app does.
class _TiltReadout extends StatelessWidget {
  const _TiltReadout({required this.controller});

  final FoldController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final degrees = controller.tiltDegrees;
    final hinge = degrees.abs() < 0.5
        ? 'sem dobradiça'
        : degrees > 0
        ? 'dobradiça à direita'
        : 'dobradiça à esquerda';

    final style = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Semantics(
      liveRegion: true,
      label: 'Vidro girado ${degrees.abs().round()} graus, $hinge',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(hinge, style: style),
            Text('${degrees.round()}°', style: style),
          ],
        ),
      ),
    );
  }
}

class _TiltSlider extends StatelessWidget {
  const _TiltSlider({required this.controller});

  final FoldController controller;

  @override
  Widget build(BuildContext context) {
    final isManual = controller.source == FoldSource.manual;
    const limit = DuoFoldConfig.maxTiltDegrees;

    return Semantics(
      slider: true,
      label: 'Rotação do vidro',
      value: '${controller.tiltDegrees.round()} graus',
      child: ExcludeSemantics(
        child: Slider(
          value: controller.tiltDegrees.clamp(-limit, limit),
          min: -limit,
          max: limit,
          // Disabled while the sensor drives, or the two would fight over the
          // same value. The disabled state is visible, not silent.
          onChanged: isManual ? controller.setManualTilt : null,
          label: '${controller.tiltDegrees.round()}°',
        ),
      ),
    );
  }
}

class _SourceSwitch extends StatelessWidget {
  const _SourceSwitch({required this.controller});

  final FoldController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Under reduce motion the sensor option is removed, not greyed out: a
    // dead button explaining itself is what `sense-absent` says not to draw.
    final sensorAvailable =
        !controller.reduceMotion &&
        controller.sensor.status != TiltStatus.absent;

    if (!sensorAvailable) {
      return Text(
        'Controle manual',
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<FoldSource>(
        segments: const [
          ButtonSegment(
            value: FoldSource.sensor,
            label: Text('Movimento', maxLines: 1),
          ),
          ButtonSegment(
            value: FoldSource.manual,
            label: Text('Manual', maxLines: 1),
          ),
        ],
        selected: {controller.source},
        showSelectedIcon: false,
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(theme.textTheme.labelLarge),
        ),
        onSelectionChanged: (selection) {
          if (selection.first == FoldSource.sensor) {
            controller.useSensor();
          } else {
            controller.useManual();
          }
        },
      ),
    );
  }
}
