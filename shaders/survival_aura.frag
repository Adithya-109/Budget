// Ambient aura behind the Safe-to-Spend gauge (DESIGN_SYSTEM.md §4): Safe
// Mint at uBurnRatio 0, pulsing Survival Magma at 1.
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uBurnRatio; // 0.0 = Safe Mint, 1.0 = Survival Mode Magma
uniform float uIsDark;    // 1.0 = Dark Mode, 0.0 = Light Mode

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 centered = uv - 0.5;
    float dist = length(centered);

    // Organic slow motion field
    float n = noise(centered * 3.5 + vec2(uTime * 0.25, -uTime * 0.18));
    float radialMask = smoothstep(0.55, 0.05, dist + n * 0.12);

    vec3 safeColor = mix(vec3(0.02, 0.59, 0.41), vec3(0.20, 0.83, 0.60), uIsDark);
    vec3 survivalColorA = vec3(0.98, 0.44, 0.52); // #FB7185 Coral
    vec3 survivalColorB = vec3(0.98, 0.45, 0.09); // #F97316 Magma Orange
    vec3 survivalColor = mix(survivalColorA, survivalColorB, sin(uTime * 2.2 + n * 3.0) * 0.5 + 0.5);

    vec3 finalRgb = mix(safeColor, survivalColor, clamp(uBurnRatio, 0.0, 1.0));
    float alphaScale = mix(0.14, 0.26, uIsDark) * (1.0 + 0.25 * uBurnRatio * sin(uTime * 3.0));

    fragColor = vec4(finalRgb * radialMask * alphaScale, radialMask * alphaScale);
}
