# FlutterDuo

The *iPhone Duo effect* in Flutter: a GLSL fragment shader projects the UI as a
panel folding in space, and the angle comes from the **device's physical tilt**.

**Raise one side of the device — that side is the one that folds back.**

The panel's content is **Halo**, a mockup of a photo social network that does
not exist, with photos from Unsplash. It is there because a coloured rectangle
reveals nothing about the effect: you need small text beside large photos, round
avatars and fixed chrome to see what the reprojection does to a real hierarchy.

Android only.

## The effect

```
UI → perspective projection → rounded quadrilateral → clip → background
```

One vertical edge is the **hinge** and it does not move; only the opposite side
turns, receding from the viewer. One side folds at a time — which one comes from
the sign of the tilt.

Projected from a stationary eye 2.4 screen-widths away, the panel stops being a
rectangle. **What falls outside it is background, and background is black**:
that is not an edge defect, it is the effect. At 45° roughly 40% of the screen
is background.

Distance from the hinge drives everything else:

| | |
|---|---|
| **Blur** | opens with distance from the hinge; golden-angle spiral disc, 48 taps with per-pixel rotation |
| **Darkening** | scattering light costs brightness, so it tracks the blur |
| **Corners** | grow from zero and saturate at half the turn; rounded in panel space, so they become ellipses at an angle |
| **Edge** | a thread of light — the border of a glass panel does not end, it lights up |
| **Dispersion** | light leaks past the edge and dies within ~150px, instead of stopping dead at black |

Inverting the projection (screen pixel → panel point) has a **closed form**, no
iterative search: isolating the distance to the hinge, it comes out linear once
you multiply through by the denominator.

At zero angle the shader early-returns pixel-perfect. It still stays in the path
at all times — toggling it by angle swaps the image, and sensor noise around any
threshold alternated the two every frame, which showed up as the border
flickering between straight and round.

## How the tilt is read

Plain accelerometer. Gravity measures the tilt directly: you only need to see
which way it leans inside the device's frame. No integration, so no drift and
nothing to re-centre on its own.

```
gravity = accelerometer − userAccelerometer     discounting hand movement
angle   = atan2(−gx, gz)                        relative to the calibrated pose
```

The subtraction matters: the raw accelerometer hands back gravity and motion
summed together, and without isolating it, walking or gesturing moves the angle.

So does the minus sign on `gx`: the accelerometer measures the **reaction** to
gravity, so the vector points up in the world. Without it, the side that folds
is the opposite of the one raised. That sign has already inverted twice — it is
what the check verifies.

**There is a pose where the measurement does not exist.** With the device
upright, the gesture's axis runs nearly parallel to gravity and too little of it
remains in the measured plane. There the angle **stops** updating rather than
being guessed, and the settings sheet says so.

## When the sensor will not do

Tilt is never the only route:

- **No accelerometer** — no sample within the startup window, and the motion
  option disappears rather than sitting there greyed out.
- **Reduce motion enabled system-wide** — the sensor steps aside. Read through
  both channels, `MediaQuery.disableAnimationsOf` and
  `AccessibilityFeatures.reduceMotion`, because reading only one silently drops
  the other platform's users.
- **No shader support** — the settings say so and the mockup stays usable.

A manual control in degrees is always available, under the profile icon.

## Run

```sh
flutter pub get
flutter run
```

Settings open from **profile**, in the bottom bar. They sit outside the folding
area: routed through the panel, the controls would be blurred and displaced
exactly when you need them most.

## Verify

```sh
flutter analyze
dart run tool/check_tilt.dart      # the accelerometer sign
flutter build apk --debug          # compiles the GLSL through impellerc
```

There is no test suite. The build is what catches a shader error before runtime,
and the check covers the one piece of logic that has already broken twice and
whose symptom only shows with the device in hand.

## Layout

```
shaders/duo_fold.frag        the effect
lib/duo/
  tilt_math.dart             gravity → angle, free of Flutter imports
  tilt_sensor.dart           the sensor and the states it actually has
  fold_controller.dart       single source of the angle, sensor or finger
  duo_fold_config.dart       the shader's physical parameters
  duo_shader.dart            FragmentProgram loading and lifetime
  duo_fold_view.dart         applies the shader over the widget tree
  fold_settings_sheet.dart   sensor state, calibrate, manual control
lib/feed/                    the Halo mockup
lib/theme/halo_theme.dart    colour, spacing, radius and touch tokens
tool/check_tilt.dart         sign check, runs under dart run
```

`tilt_math.dart` is separate because `tilt_sensor.dart` pulls in Flutter through
its import chain, and without isolating the formula the check would need the SDK
to resolve `dart:ui`.

## Design

The UI follows the [Trunative](https://github.com/TiagoDanin/Trunative) skill. The
briefs it requires live in `.trunative/`: `PRODUCT.md`, `DESIGN.md` (design.md
format) and `STACK.md`, which also holds the shader's uniform contract and the
exceptions taken on purpose, each with its date and reason — the portrait lock,
because auto-rotation would fight the gesture, and immersive full screen,
because the effect lives at the screen edges and the system bars cover exactly
the part that matters.
