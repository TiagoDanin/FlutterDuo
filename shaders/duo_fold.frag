#version 460 core
#include <flutter/runtime_effect.glsl>

// One side of the panel folding back, seen head-on.
//
// A vertical edge is the hinge and stays put; only the opposite side turns,
// receding. Projected from a fixed eye, the panel becomes a quadrilateral —
// what falls outside it is background, and background is black.

uniform vec2  uSize;          // 0,1: canvas size in logical pixels
uniform float uTiltDegrees;   // 2: signed rotation, in degrees
uniform float uEyeDistancePx; // 3: viewer-to-plane distance, in px
uniform float uBlurSpread;    // 4: blur radius gained per px of recession
uniform float uDarkening;     // 5: light lost per px of blur radius
uniform float uCornerRadius;  // 6: max corner radius, in px
uniform float uRimLight;      // 7: glass glow on the edge, 0..1
uniform float uSpreadWidth;   // 8: how far the dispersion reaches, in px
uniform float uSpreadStrength;// 9: how much light survives outside, 0..1
uniform sampler2D uTexture;   // snapshot of the rendered UI

out vec4 fragColor;

const float kEps         = 1e-4;
const float kMaxTiltDeg  = 80.0;

// Literal count is a Flutter requirement, and 48 is where grain stops showing.
// A mip pyramid would be cheaper, but AnimatedSampler hands over one texture
// with no mips, so this pays in samples instead.
const int   kMaxTaps     = 48;

const float kGoldenAngle = 2.39996322972865;
const float kTau         = 6.28318530717959;
const float kEdgeFeather = 1.0;

// Corner rounding reaches its maximum at half the turn, then holds. Spread over
// the whole turn, the corner keeps changing shape the entire time.
const float kRoundSaturation = 0.5;

// Early-out margin. Must exceed uSpreadWidth or the dispersion gets cut short.
const float kSpreadGuard = 420.0;

// Without a cap, a long reach asks for a huge disc and 48 taps bring the grain
// back.
const float kSpreadBlurCap = 55.0;

// Clamped because disc samples escape the rectangle near the edges. The
// quadrilateral clip runs later, so whatever clamping invents lands outside it.
vec3 samplePanel(vec2 pixel) {
    return texture(uTexture, clamp(pixel / uSize, 0.0, 1.0)).rgb;
}

// Rotates the sampling disc per pixel. A few-tap disc always draws rings;
// turning each pixel by a different amount trades them for grain — which is
// what frosted glass looks like anyway.
float pixelJitter(vec2 pixel) {
    vec3 p = fract(pixel.xyx * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

// Signed distance to a rounded rectangle: negative inside, positive outside.
// Measured in PANEL space, before projection, so the corners deform with
// everything else and become ellipses at an angle.
float roundedRectDistance(vec2 fromCenter, vec2 halfSize, float radius) {
    float r = clamp(radius, 0.0, min(halfSize.x, halfSize.y));
    vec2 q = abs(fromCenter) - halfSize + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// A glass edge does not end, it lights up.
vec3 applyRim(vec3 color, float distance, float feather) {
    if (uRimLight <= 0.0) return color;

    // A PEAK on the edge, dying on both sides. As a rising smoothstep it stayed
    // at 1 everywhere outside, which turned the dispersion into a neon halo.
    float width = max(uCornerRadius * 0.12, feather * 2.0);
    float rim = 1.0 - clamp(abs(distance) / width, 0.0, 1.0);

    return clamp(color + vec3(pow(rim, 3.0) * uRimLight), 0.0, 1.0);
}

// Inverts the projection across the width.
//
// A point `a` px from the hinge sits at x3d = hingeX + side*a*cos(tilt) and
// z3d = -a*sin(tilt), projected by s = D / (D + a*sin(tilt)). Equating to the
// screen x and isolating `a` gives a closed form — no iterative search.
float panelAlong(float screenX, float hingeX, float side, float tilt) {
    float eyeX = uSize.x * 0.5;
    float sx = screenX - eyeX;
    float k  = hingeX - eyeX;

    float denominator = sx * sin(tilt) - uEyeDistancePx * side * cos(tilt);
    if (abs(denominator) < kEps) {
        return -1.0; // degenerate: treat as background
    }
    return uEyeDistancePx * (k - sx) / denominator;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    if (uSize.x <= 1.0 || uSize.y <= 1.0) {
        fragColor = texture(uTexture, fragCoord / max(uSize, vec2(1.0)));
        return;
    }

    float tilt = radians(clamp(abs(uTiltDegrees), 0.0, kMaxTiltDeg));

    // Head-on: the panel fills the screen exactly. Pixel-perfect bypass.
    if (tilt < kEps) {
        fragColor = texture(uTexture, fragCoord / uSize);
        return;
    }

    // Which edge stays put comes from the SIGN of the rotation, not a separate
    // uniform: a derived value travelling beside its source can disagree with
    // it, and then the panel folds one way with the hinge on the other.
    float hingeOnRight  = step(0.0, uTiltDegrees);
    float hingeX        = mix(0.0, uSize.x, hingeOnRight);
    float awayFromHinge = mix(1.0, -1.0, hingeOnRight);

    float along = panelAlong(fragCoord.x, hingeX, awayFromHinge, tilt);

    // Too far past the width to be worth the rest. The margin is the
    // dispersion's, which still needs content to scatter.
    if (along < -kSpreadGuard || along > uSize.x + kSpreadGuard) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    float away   = max(along, 0.0) * sin(tilt);
    float shrink = uEyeDistancePx / max(uEyeDistancePx + away, kEps);

    // Undoing the vertical shrink gives the height on the panel. It shrinks
    // about the eye, so that is where the maths starts.
    float eyeY   = uSize.y * 0.5;
    float panelY = eyeY + (fragCoord.y - eyeY) / max(shrink, kEps);

    if (panelY < -kSpreadGuard || panelY > uSize.y + kSpreadGuard) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // `along` is measured from the hinge, so walking back that far from it
    // returns the image coordinate.
    vec2 source = vec2(hingeX + awayFromHinge * along, panelY);

    // Feathering is divided by the shrink: on the receding side one screen
    // pixel covers more panel, and without this the far edge reads harder.
    float feather = kEdgeFeather / max(shrink, kEps);

    // The corner grows FROM ZERO and saturates at half the turn.
    //
    // Starting at zero keeps the entry continuous: head-on, the visible corner
    // is the device's own, and drawing a rounded clip there would stack one
    // corner on another and pop in whole the instant the angle left zero.
    float roundProgress = clamp(
        abs(uTiltDegrees) / (kMaxTiltDeg * kRoundSaturation),
        0.0,
        1.0
    );

    // Smoothstepped twice: once to kill the derivative corners, again to flatten
    // the start. The corner has to be slow leaving nothing, or its arrival is
    // what you notice instead of the turn.
    roundProgress = roundProgress * roundProgress * (3.0 - 2.0 * roundProgress);
    roundProgress = roundProgress * roundProgress * (3.0 - 2.0 * roundProgress);

    float distance = roundedRectDistance(
        source - uSize * 0.5,
        uSize * 0.5,
        uCornerRadius * roundProgress
    );

    // 0 inside, 1 outside, smooth across the edge.
    float outside = smoothstep(-feather, feather, distance);

    // Dispersion: glass does not stop dead at black. `fade` is exactly 1 on the
    // edge, which is what avoids a step between content and halo.
    float fade = 1.0 - clamp(distance / max(uSpreadWidth, kEps), 0.0, 1.0);

    // A low exponent keeps the trail LONG. High, it died within a few pixels and
    // left a contour rather than a dispersion.
    fade = pow(max(fade, 0.0), 1.7);

    if (outside >= 1.0 && fade <= 0.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    float radius = uBlurSpread * away;
    float attenuation = max(1.0 - uDarkening * radius, 0.0);

    // Outside the edge the blur opens much wider: what shows there is not the
    // content, it is light scattered from it. One sampling serves both cases.
    float sampleRadius = max(
        radius,
        outside * min(uSpreadWidth * 0.75, kSpreadBlurCap)
    );

    // Sampled from a point pinned to the edge: outside the panel there is no
    // content, and it is the edge colour that should bleed.
    vec2 tap = clamp(source, vec2(0.5), uSize - vec2(0.5));

    // How much of this colour survives: all of it inside, the trail outside.
    float energy = attenuation * mix(1.0, fade * uSpreadStrength, outside);

    vec3 color;
    if (sampleRadius < 0.5) {
        color = samplePanel(tap);
    } else {
        // Golden-angle spiral: samples spread without stacking, and sqrt on the
        // radius keeps density uniform per area.
        //
        // Tap count should track the radius, but Flutter demands a literal loop
        // bound — so it always runs 48 and zeroes the weight of the surplus.
        // The boundary weight is fractional, or the blur jumps each time the
        // count crosses an integer.
        float wantedTaps = clamp(sampleRadius * 2.4, 8.0, float(kMaxTaps));
        float spin = pixelJitter(fragCoord) * kTau;

        vec3  accumulated = vec3(0.0);
        float weightSum = 0.0;

        for (int i = 0; i < kMaxTaps; i++) {
            float index  = float(i);
            float weight = clamp(wantedTaps - index, 0.0, 1.0);
            float r      = sampleRadius * sqrt((index + 0.5) / wantedTaps);
            float angle  = index * kGoldenAngle + spin;

            accumulated += samplePanel(tap + r * vec2(cos(angle), sin(angle)))
                         * weight;
            weightSum += weight;
        }

        color = accumulated / max(weightSum, kEps);
    }

    fragColor = vec4(applyRim(color * energy, distance, feather), 1.0);
}
