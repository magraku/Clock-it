#version 460 core

// The app's moving background: liquid marbling in the plum palette, after the
// reference on the design's 4th artboard. Butter at the top fading through
// olive into dark plum ridges, pale pink and mid plum in the middle, lavender
// with a little turquoise at the bottom. Fixed grain on top.
//
// The noise is sampled along a circle, so the motion loops seamlessly every
// uPeriod seconds.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;     // canvas size in logical pixels
uniform float uTime;    // seconds
uniform float uPeriod;  // seconds per loop
uniform float uGrain;   // pixels per grain dot (device pixel ratio)

out vec4 fragColor;

const vec3 plumDark = vec3(0.231, 0.122, 0.180); // #3B1F2E
const vec3 plum     = vec3(0.478, 0.290, 0.420); // #7A4A6B
const vec3 rose     = vec3(0.949, 0.769, 0.827); // #F2C4D3
const vec3 butter   = vec3(0.910, 0.878, 0.541); // #E8E08A
const vec3 lavender = vec3(0.812, 0.784, 1.000); // #CFC8FF
const vec3 teal     = vec3(0.620, 0.902, 0.878); // #9EE6E0

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  // Three soft octaves: big shapes, no fine crumbs.
  for (int i = 0; i < 3; i++) {
    v += a * noise(p);
    p = mat2(1.6, 1.2, -1.2, 1.6) * p;
    a *= 0.42;
  }
  return v;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  // Same scale whatever the screen's shape; tall phones show more of it.
  vec2 p = frag / uSize.x * 1.25;

  float a = 6.2831853 * uTime / uPeriod;
  vec2 drift = vec2(cos(a), sin(a)) * 0.35;

  // Two rounds of domain warping give the folded, marbled bands.
  vec2 q = vec2(fbm(p + drift), fbm(p + vec2(5.2, 1.3) - drift));
  vec2 r = vec2(fbm(p + 3.0 * q + vec2(1.7, 9.2) + drift * 0.6),
                fbm(p + 3.0 * q + vec2(8.3, 2.8) - drift * 0.6));
  float f = fbm(p + 2.6 * r);

  // Lighter toward the top, so butter sits up there as in the reference.
  float v = clamp((f - 0.38) * 3.0 + (0.5 - uv.y) * 1.1 + 0.5, 0.0, 1.0);

  vec3 c = lavender;
  // Wide, overlapping steps: edges melt into each other like wet paint.
  c = mix(c, rose, smoothstep(0.08, 0.32, v));
  c = mix(c, plum, smoothstep(0.30, 0.48, v));
  c = mix(c, plumDark, smoothstep(0.44, 0.58, v));
  c = mix(c, mix(plumDark, butter, 0.45), smoothstep(0.56, 0.70, v)); // olive shadow
  c = mix(c, butter, smoothstep(0.66, 0.90, v));

  // A soft turquoise pool low down, where the lavender is.
  float pool = smoothstep(0.55, 0.85, r.x) * smoothstep(0.55, 1.0, uv.y) * (1.0 - smoothstep(0.2, 0.4, v));
  c = mix(c, teal, pool * 0.7);

  // Fixed grain: tied to the pixel, not to time, so it never crawls.
  float g = hash(floor(frag * uGrain / 1.5)) - 0.5;
  c += g * 0.07;

  fragColor = vec4(c, 1.0);
}
