import 'package:flutter/material.dart';

/// Spacing scale from `DESIGN.md`. Every gap in the app comes from here.
abstract final class HaloSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Feed's horizontal gutter.
  static const double gutter = md;
}

/// Radii from `DESIGN.md`. Rounding is not decoration here: a sharp corner
/// aliases when the shader reprojects it at a shallow angle.
abstract final class HaloRadius {
  static const BorderRadius photo = BorderRadius.all(Radius.circular(12));
  static const BorderRadius card = BorderRadius.all(Radius.circular(16));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(24),
  );
}

/// Touch targets. iOS asks 44 and Android 48, so 48 satisfies both without
/// branching.
abstract final class HaloTouch {
  static const double minTarget = 48;
  static const double avatar = 40;
  static const double storyAvatar = 64;
}

abstract final class HaloTheme {
  /// The void the shader reveals around the panel. Not a theme colour — it is
  /// the absence of screen, so it is the same in both modes.
  static const Color voidColor = Color(0xFF050810);

  static ThemeData dark() => _build(_darkScheme);
  static ThemeData light() => _build(_lightScheme);

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6E8BFF),
    onPrimary: Color(0xFF06102B),
    primaryContainer: Color(0xFF1B2547),
    onPrimaryContainer: Color(0xFFD7E0FF),
    secondary: Color(0xFF9AA3B2),
    onSecondary: Color(0xFF0B0D12),
    surface: Color(0xFF0B0D12),
    onSurface: Color(0xFFEDF0F5),
    surfaceContainerLowest: Color(0xFF070910),
    surfaceContainer: Color(0xFF14171F),
    surfaceContainerHigh: Color(0xFF1D212B),
    surfaceContainerHighest: Color(0xFF262B37),
    onSurfaceVariant: Color(0xFF9AA3B2),
    outline: Color(0xFF2A3040),
    outlineVariant: Color(0xFF1E232F),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF3B0709),
    inverseSurface: Color(0xFFEDF0F5),
    onInverseSurface: Color(0xFF0B0D12),
  );

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2F4FD8),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDFE5FF),
    onPrimaryContainer: Color(0xFF0A1C6B),
    secondary: Color(0xFF555E6E),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFF7F8FA),
    onSurface: Color(0xFF11141B),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHigh: Color(0xFFEDEFF4),
    surfaceContainerHighest: Color(0xFFE4E7EE),
    onSurfaceVariant: Color(0xFF555E6E),
    // Measured, not eyeballed: at #D7DBE3 the outline sat at 1.31:1 against
    // the light surface and vanished into it.
    outline: Color(0xFFC4CAD6),
    outlineVariant: Color(0xFFDCE0E7),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    inverseSurface: Color(0xFF11141B),
    onInverseSurface: Color(0xFFF7F8FA),
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      // No shadows anywhere: depth is computed by the shader, and a drawn
      // shadow competes with it.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: HaloRadius.card),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.outline,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: HaloRadius.photo),
      ),
      // Weight is structure. No w300: the shader blurs, and a thin stroke
      // blurred disappears before it looks good.
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}
