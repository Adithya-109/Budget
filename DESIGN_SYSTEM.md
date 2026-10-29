# SplitBurn — Master UI/UX Design System & 120Hz Impeller Animation Specification

This document defines the complete visual language, semantic color tokens (Dark Mode & Light Mode), component blueprints, GLSL fragment shaders, and 120fps physics animations for **SplitBurn**.

Use this specification alongside `CLAUDE.md` to build all Flutter (`lib/`) and native iOS (`ios/`) user interfaces.

## 1. Visual Direction & Core Philosophy

SplitBurn combines three design paradigms tailored for college students, hostel residents, and flatmates:

1. **Obsidian Matte Glass (Dark Mode) & Warm Ceramic Alabaster (Light Mode):** Eliminates harsh `#000000` OLED smearing at night and blinding `#FFFFFF` glare during the day.

2. **Swiss Neo-Minimalist Bento Grids:** High-density financial data (receipt splits, net-share bars, recurring roommate bills) sits inside crisp `1px` architectural cells with zero visual clutter.

3. **Tactile Neo-Brutalist Micro-Interactions:** Quirky student features—like **The Nudge Bot's** thermal-printed "Survival Receipt" and the **Free Trial Graveyard**—use physical spring motion, 3D gyroscope tilt, and stepped haptic feedback.

## 2. Global Semantic Tokens (Dark Mode vs. Light Mode)

### 2.1 Color Palette Matrix

| **Token Group** | **Token Name** | **Dark Mode (Obsidian Matte)** | **Light Mode (Warm Alabaster)** | **Component Usage** | 
|---|---|---|---|---|
| **Canvas** | `canvas` | `#0E1014` | `#F7F5F0` | Root `Scaffold` background | 
| **Surface 1** | `surfacePrimary` | `#161920` | `#FFFFFF` | Standard Bento cards, receipt rows | 
| **Surface 2** | `surfaceElevated` | `#1E222B` | `#F0EDE6` | Secondary pills, inactive toggles | 
| **Glass HUD** | `surfaceGlass` | `#1E222B` (75% alpha + Blur 24) | `#FFFFFF` (85% alpha + Blur 20) | True Liquid Balance card, Voice HUD | 
| **Border** | `hairlineBorder` | `#FFFFFF` (8% alpha) | `#141619` (8% alpha) | `1px` Bento cell & card outlines | 
| **Border Focus** | `specularBorder` | `#FFFFFF` (18% alpha) | `#141619` (15% alpha) | Top-left glass specular edge | 
| **Text 1** | `textPrimary` | `#F3F4F6` | `#111317` | Balances, titles, primary amounts | 
| **Text 2** | `textSecondary` | `#9CA3AF` | `#525866` | Subtitles, split ratios, metadata | 
| **Text 3** | `textMuted` | `#6B7280` | `#8A909E` | Settled IOUs, disabled roommates | 
| **Safe Burn** | `safeMint` | `#34D399` | `#059669` | Safe-to-Spend ring & positive buffer | 
| **Survival** | `survivalMagma` | `#FB7185` to `#F97316` | `#E11D48` to `#EA580C` | Days-Until-Broke deficit alert state | 
| **Receivable** | `owedToMe` | `#4ADE80` | `#16A34A` | `+` friend debt badges & incoming edges | 
| **Payable** | `iOwe` | `#F87171` | `#DC2626` | `-` friend debt badges & outgoing edges | 
| **Trial Shield** | `trialAmber` | `#FBBF24` | `#D97706` | $< 48\text{h}$ Free Trial expiration aura | 
| **Receipt Paper** | `thermalPaper` | `#F4F1EA` | `#F4F1EA` | Physical thermal paper card surface | 

### 2.2 Typography Scale & OpenType Features

* **Display & Live Balances (`Plus Jakarta Sans`):**

  * Hero Daily Burn (`36sp`, `FontWeight.w800`, `letterSpacing: -1.2`, `FontFeature.tabularFigures()`)

  * Card Balances (`24sp`, `FontWeight.w700`, `letterSpacing: -0.6`, `FontFeature.tabularFigures()`)

* **UI & Navigation (`Inter`):**

  * Section Headers (`13sp`, `FontWeight.w700`, `letterSpacing: 0.8`, uppercase)

  * Body & Line Items (`15sp`, `FontWeight.w500`)

  * Friend Chips & Badges (`12sp`, `FontWeight.w600`)

* **Monospace Receipts & Countdown Timers (`JetBrains Mono`):**

  * Thermal Receipt Rows & OCR Prices (`13sp`, `FontWeight.w500`, `FontFeature.tabularFigures()`)

  * Trial Graveyard Countdowns (`14sp`, `FontWeight.w700`, `FontFeature.tabularFigures()`)

### 2.3 Flutter `ThemeExtension` Implementation (`lib/theme/splitburn_theme.dart`)

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

@immutable
class SplitBurnTokens extends ThemeExtension<SplitBurnTokens> {
  final Color canvas;
  final Color surfacePrimary;
  final Color surfaceElevated;
  final Color surfaceGlass;
  final Color hairlineBorder;
  final Color specularBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color safeMint;
  final Color survivalMagma;
  final Color owedToMe;
  final Color iOwe;
  final Color trialAmber;
  final Color thermalPaper;

  const SplitBurnTokens({
    required this.canvas,
    required this.surfacePrimary,
    required this.surfaceElevated,
    required this.surfaceGlass,
    required this.hairlineBorder,
    required this.specularBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.safeMint,
    required this.survivalMagma,
    required this.owedToMe,
    required this.iOwe,
    required this.trialAmber,
    required this.thermalPaper,
  });

  static const dark = SplitBurnTokens(
    canvas: Color(0xFF0E1014),
    surfacePrimary: Color(0xFF161920),
    surfaceElevated: Color(0xFF1E222B),
    surfaceGlass: Color(0xBF1E222B),
    hairlineBorder: Color(0x14FFFFFF),
    specularBorder: Color(0x2EFFFFFF),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
    safeMint: Color(0xFF34D399),
    survivalMagma: Color(0xFFFB7185),
    owedToMe: Color(0xFF4ADE80),
    iOwe: Color(0xFFF87171),
    trialAmber: Color(0xFFFBBF24),
    thermalPaper: Color(0xFFF4F1EA),
  );

  static const light = SplitBurnTokens(
    canvas: Color(0xFFF7F5F0),
    surfacePrimary: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF0EDE6),
    surfaceGlass: Color(0xD9FFFFFF),
    hairlineBorder: Color(0x14141619),
    specularBorder: Color(0x26141619),
    textPrimary: Color(0xFF111317),
    textSecondary: Color(0xFF525866),
    textMuted: Color(0xFF8A909E),
    safeMint: Color(0xFF059669),
    survivalMagma: Color(0xFFE11D48),
    owedToMe: Color(0xFF16A34A),
    iOwe: Color(0xFFDC2626),
    trialAmber: Color(0xFFD97706),
    thermalPaper: Color(0xFFF4F1EA),
  );

  @override
  SplitBurnTokens copyWith({
    Color? canvas,
    Color? surfacePrimary,
    Color? surfaceElevated,
    Color? surfaceGlass,
    Color? hairlineBorder,
    Color? specularBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? safeMint,
    Color? survivalMagma,
    Color? owedToMe,
    Color? iOwe,
    Color? trialAmber,
    Color? thermalPaper,
  }) {
    return SplitBurnTokens(
      canvas: canvas ?? this.canvas,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      hairlineBorder: hairlineBorder ?? this.hairlineBorder,
      specularBorder: specularBorder ?? this.specularBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      safeMint: safeMint ?? this.safeMint,
      survivalMagma: survivalMagma ?? this.survivalMagma,
      owedToMe: owedToMe ?? this.owedToMe,
      iOwe: iOwe ?? this.iOwe,
      trialAmber: trialAmber ?? this.trialAmber,
      thermalPaper: thermalPaper ?? this.thermalPaper,
    );
  }

  @override
  SplitBurnTokens lerp(ThemeExtension<SplitBurnTokens>? other, double t) {
    if (other is! SplitBurnTokens) return this;
    return SplitBurnTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      hairlineBorder: Color.lerp(hairlineBorder, other.hairlineBorder, t)!,
      specularBorder: Color.lerp(specularBorder, other.specularBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      safeMint: Color.lerp(safeMint, other.safeMint, t)!,
      survivalMagma: Color.lerp(survivalMagma, other.survivalMagma, t)!,
      owedToMe: Color.lerp(owedToMe, other.owedToMe, t)!,
      iOwe: Color.lerp(iOwe, other.iOwe, t)!,
      trialAmber: Color.lerp(trialAmber, other.trialAmber, t)!,
      thermalPaper: Color.lerp(thermalPaper, other.thermalPaper, t)!,
    );
  }
}

```

## 3. Page-by-Page Structural Blueprints

### Page 1: Core Dashboard ("Obsidian & Alabaster Glass")

* **Header Bar:** User avatar + greeting on left; allowance cycle badge (`18d left`) + Circular Reveal Theme Toggle button on right.

* **True Liquid Balance Glass Card:**

  * Primary metric: $\text{True Spendable Cash} = \text{Bank Balance} - \text{Money I Owe}$.

  * Secondary floating pill (top-right): `+₹1,350 Friends Owe You` (tapping opens Page 3 Debt Graph).

  * Sub-row: `Bank: ₹9,100` $\cdot$ `You Owe: -₹650`.

* **Safe-to-Spend Today Radial Gauge:**

  * Custom 260-degree open arc gauge powered by a damped spring physics controller (`SpringSimulation`).

  * Center typography: `SAFE TO SPEND TODAY`, `₹469/day`, and dynamic recalibration subtitle (`Tomorrow's limit adjusts to ₹455 if you spend ₹650 today`).

* **Days-Until-Broke Velocity Meter:**

  * Horizontal velocity progress bar comparing `Days Until Broke` ($\text{True Spendable Cash} / \text{7-Day Avg Personal Burn}$) against `Days Remaining in Month`.

  * Automatically shifts to **Survival Mode** when $\text{Days Until Broke} < \text{Days Remaining}$.

* **Bottom Natural Language Command Pill:**

  * Docked frosted pill with live voice waveform trigger and camera OCR shortcut.

### Page 2: AI Receipt Scanner & Net-Share Split Engine ("Swiss Bento Grid")

* **Top Net-Share Impact Bar:**

  * Dual-segment horizontal proportion bar showing `My Personal Budget Share (₹320 / 26.7%)` in solid emerald vs. `Floating Friend IOUs (₹880 / 73.3%)` in hatched amber.

* **Interactive OCR Receipt Bento List:**

  * Each scanned line item renders as a Bento card with dish title, price, assigned friend avatar bubbles, and per-person split math.

  * Proportional Tax/GST & Tip toggle automatically distributes extra charges weighted by each person's item subtotal.

* **Magnetic Avatar Dock:**

  * Floating bottom bar containing group members (`Me`, `Rahul`, `Priya`, `Chaitanya`, `+ Web Link`). Tapping an item while a friend is active snaps their avatar bubble onto the dish.

### Page 3: Multiplayer Debt Graph & Min-Cash-Flow Simplifier ("Aero Spatial UI")

* **Interactive Force-Directed Node Canvas:**

  * Renders user and friends as spatial nodes connected by curved quadratic Bézier paths.

  * Animated directional particles flow from debtor to creditor with speed proportional to debt weight.

* **"Simplify Group Debts" Header Switch:**

  * Runs the Min-Cash-Flow graph algorithm to reduce $N$ tangled roommate IOUs into the minimum required transfers, triggering the 3-stage edge collapse animation.

* **Direct Settlement Queue:**

  * Action cards with one-tap **Nudge Bot**, **Copy Zero-Install Web Link**, and pre-filled **UPI / Venmo / Apple Cash** deep-link buttons.

### Page 4: "The Nudge Bot" & Broke-Student Meme Receipt Studio ("Tactile Neo-Brutalism")

* **Tone Selector Segmented Bar:**

  * `Polite & Casual` | `Broke Student Meme Receipt` | `1st-of-the-Month Digest`.

* **Thermal Printer Slot & Serrated Survival Receipt (`RepaintBoundary`):**

  * Styled as a "Nutrition Facts: Hostel Survival Deficit" thermal paper slip with zig-zag serrated top and bottom edges (`CustomClipper`).

  * Lists every micro-debt (`₹40 Shared Auto`, `₹110 Late Night Maggi`, `₹275 Domino's Split`), `SURVIVAL DEFICIT: 100%`, `EXCUSES REMAINING: 0%`, and a scannable UPI QR code.

  * Responds to device gyroscope/touch drag with a 3D perspective tilt and diagonal specular sheen.

### Page 5: "Free Trial Graveyard" & Flatmate Recurring Hub ("Nordic Calm")

* **48-Hour Trial Shield Banner:**

  * High-priority card with a breathing amber shader border for trials expiring within 48 hours, featuring a one-tap **Cancel & Bury in Graveyard** action and a **Total Saved From Forgotten Trials (`₹4,200`)** counter badge.

* **Flatmate Recurring Utility Splitters:**

  * Cards for monthly shared expenses (Wi-Fi, Electricity, Maid/Cook) with toggleable friend avatars. Toggling a roommate to **"Away on Semester Break"** dims their avatar and redistributes their share across active flatmates.

### Page 6: OS-Level Extensions ("Zero-Click Titanium OS")

* **iOS Lock Screen & Home Screen `WidgetKit` Tiles:**

  * Reads `financial_summary_view` directly from the shared App Group SQLite WAL file (`group.com.splitburn.app/finance.sqlite`) in $< 15\text{ms}$.

* **Action Button Voice HUD (`AppIntents`):**

  * Translucent overlay showing live speech-to-token crystallization (`[₹450]` $\cdot$ `[Domino's]` $\cdot$ `[@Rahul, @Priya]`).

* **Zero-Install Mobile Web Ledger:**

  * Lightweight responsive web view opened via WhatsApp/iMessage links so Android/iOS friends can inspect the receipt and tap **Pay via UPI / GPay / PhonePe / Apple Cash** without installing the app.

## 4. Custom Impeller GLSL Fragment Shader (`shaders/survival_aura.frag`)

Add `shaders/survival_aura.frag` to `pubspec.yaml` under `flutter: shaders:`. This shader renders the ambient background aura behind the Safe-to-Spend gauge and smoothly transitions between **Safe Mint** and **Survival Mode Magma** when `uBurnRatio` crosses $1.0$.

```glsl
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

    // Safe Mint vs Survival Magma palettes
    vec3 safeColor = mix(vec3(0.02, 0.59, 0.41), vec3(0.20, 0.83, 0.60), uIsDark);
    vec3 survivalColorA = vec3(0.98, 0.44, 0.52); // #FB7185 Coral
    vec3 survivalColorB = vec3(0.98, 0.45, 0.09); // #F97316 Magma Orange
    vec3 survivalColor = mix(survivalColorA, survivalColorB, sin(uTime * 2.2 + n * 3.0) * 0.5 + 0.5);

    vec3 finalRgb = mix(safeColor, survivalColor, clamp(uBurnRatio, 0.0, 1.0));
    float alphaScale = mix(0.14, 0.26, uIsDark) * (1.0 + 0.25 * uBurnRatio * sin(uTime * 3.0));

    fragColor = vec4(finalRgb * radialMask * alphaScale, radialMask * alphaScale);
}

```

## 5. 120Hz Animation & Physics Implementation Specifications

### 5.1 Safe-to-Spend Spring Gauge (`SpringSimulation`)

Never animate the daily burn ring with a linear curve. Use Flutter's physical `SpringSimulation` governed by the damped harmonic oscillator equation: 

$$
m \frac{d^2x}{dt^2} + c \frac{dx}{dt} + kx = 0
$$

 where mass $m = 1.0$, stiffness $k = 180.0$, and damping coefficient $c = 19.0$ (underdamped ratio $\zeta = \frac{c}{2\sqrt{mk}} \approx 0.708$).

```dart
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class SafeSpendSpringController extends StatefulWidget {
  final double targetRatio; // 0.0 to 1.0
  final Widget Function(BuildContext context, double animatedRatio) builder;

  const SafeSpendSpringController({
    super.key,
    required this.targetRatio,
    required this.builder,
  });

  @override
  State<SafeSpendSpringController> createState() => _SafeSpendSpringControllerState();
}

class _SafeSpendSpringControllerState extends State<SafeSpendSpringController>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _currentRatio = 0.0;

  static const _spring = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 19.0,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() => _currentRatio = _controller.value.clamp(0.0, 1.15));
      });
    _animateTo(widget.targetRatio, velocity: 0.0);
  }

  @override
  void didUpdateWidget(covariant SafeSpendSpringController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.targetRatio - widget.targetRatio).abs() > 0.001) {
      _animateTo(widget.targetRatio, velocity: _controller.velocity);
    }
  }

  void _animateTo(double target, {required double velocity}) {
    final simulation = SpringSimulation(_spring, _currentRatio, target, velocity);
    _controller.animateWith(simulation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _currentRatio);
}

```

### 5.2 Force-Directed Debt Graph & 3-Stage Simplification Collapse

In Page 3, model each friend avatar node $i$ with position $\mathbf{p}_i$ and velocity $\mathbf{v}_i$. On each 120Hz `Ticker` tick ($\Delta t \approx 8.33\text{ms}$):

1. **Coulomb Node Repulsion:** 

   $$
   \mathbf{F}_{\text{repel}}(i, j) = \frac{k_r}{\Vert{}\mathbf{p}_i - \mathbf{p}_j\Vert{}^2 + \epsilon} \hat{\mathbf{r}}_{ij}
   $$

2. **Hooke Edge Attraction:** 

   $$
   \mathbf{F}_{\text{spring}}(i, j) = k_s \left(\Vert{}\mathbf{p}_j - \mathbf{p}_i\Vert{} - L_0\right) \hat{\mathbf{r}}_{ij}
   $$

3. **3-Stage Collapse Choreography (`750ms` total when "Simplify Debts" is toggled):**

   * **Phase 1 (`0ms` to `250ms`):** Multi-hop edges scheduled for removal animate their `PathMetric.extractPath(0, length * (1.0 - t))` so they retract into the intermediary node.

   * **Phase 2 (`200ms` to `550ms`):** The simplified direct edge grows outward from debtor to creditor using `Curves.easeOutCubic`.

   * **Phase 3 (`500ms` to `750ms`):** Fire `HapticFeedback.mediumImpact()` and pop in the consolidated `₹` pill badge using `Curves.elasticOut`.

### 5.3 Thermal Printer Stepper & 3D Gyroscope Card Tilt (Page 4: The Nudge Bot)

When switching Nudge Bot tones or generating a receipt, extrude the receipt downward in 6 discrete mechanical stepper ticks accompanied by `HapticFeedback.selectionClick()`, and apply a 3D perspective `Matrix4` tilt with a dynamic foil reflection gradient:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThermalReceiptInteractiveCard extends StatefulWidget {
  final Widget receiptChild;
  const ThermalReceiptInteractiveCard({super.key, required this.receiptChild});

  @override
  State<ThermalReceiptInteractiveCard> createState() =>
      _ThermalReceiptInteractiveCardState();
}

class _ThermalReceiptInteractiveCardState
    extends State<ThermalReceiptInteractiveCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _feedController;
  Offset _tilt = Offset.zero;
  Timer? _hapticTimer;

  @override
  void initState() {
    super.initState();
    _feedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    triggerThermalFeed();
  }

  void triggerThermalFeed() {
    _feedController.forward(from: 0.0);
    int ticks = 0;
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 85), (timer) {
      HapticFeedback.selectionClick();
      ticks++;
      if (ticks >= 6) timer.cancel();
    });
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _feedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _tilt = Offset(
            (_tilt.dx + details.delta.dx * 0.008).clamp(-1.0, 1.0),
            (_tilt.dy + details.delta.dy * 0.008).clamp(-1.0, 1.0),
          );
        });
      },
      onPanEnd: (_) => setState(() => _tilt = Offset.zero),
      child: AnimatedBuilder(
        animation: _feedController,
        builder: (context, child) {
          // Stepped thermal paper feed quantization (12 mechanical steps)
          final steppedT = (_feedController.value * 12).floor() / 12.0;
          final translateY = (1.0 - steppedT) * -180.0;

          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(-_tilt.dy * 0.16)
            ..rotateY(_tilt.dx * 0.16);

          return ClipRect(
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: Transform(
                alignment: Alignment.center,
                transform: matrix,
                child: child,
              ),
            ),
          );
        },
        child: widget.receiptChild,
      ),
    );
  }
}

```

## 6. Master Haptic Choreography Table

| **Screen / Feature** | **User Gesture or Event** | **Native Haptic API** | 
|---|---|---|
| **Page 1: Dashboard** | Burn velocity crosses into Survival Mode | `HapticFeedback.heavyImpact()` | 
| **Page 2: Receipt Split** | Tapping or dropping friend avatar onto dish | `HapticFeedback.lightImpact()` | 
| **Page 3: Debt Graph** | Toggling "Simplify Group Debts" edge collapse | `HapticFeedback.mediumImpact()` | 
| **Page 4: Nudge Bot** | Thermal receipt printing (6 mechanical steps) | `HapticFeedback.selectionClick()` $\times 6$ | 
| **Page 5: Trial Shield** | Swiping to bury a canceled free trial | `HapticFeedback.mediumImpact()` | 
| **Page 6: iOS Shortcut** | Background `AppIntents` SQLite WAL write | `UINotificationFeedbackGenerator().notificationOccurred(.success)` |

## 7. Implementation notes (kept current with the code)

Where each part of this spec lives, and where the code deliberately differs.

| Spec item | Implementation |
|---|---|
| §2.1 tokens, §2.3 `SplitBurnTokens` | `lib/ui/theme.dart`. Extra tokens beyond the matrix: `survivalMagmaEnd` (second gradient stop), `accent` / `onAccent` (primary actions), `info` (neutral charts, links), `nudgeViolet` (Nudge Bot), `shadow` (soft card shadow, transparent in dark). Screens read tokens with `context.sb`, never hard-coded colours. `test/ui_redesign_test.dart` checks WCAG contrast for both modes. |
| §2.2 type scale | Fonts are bundled in `assets/fonts/` (SIL OFL 1.1, licences registered in `main.dart`), not fetched at runtime. Styles are `SbType.*`. JetBrains Mono has no ₹ glyph, so mono styles fall back to Inter. |
| Dark / light mode | `MaterialApp.theme` / `darkTheme` from `buildSplitBurnTheme(Brightness)`. The choice (System / Light / Dark) is a UI preference in SharedPreferences (`lib/ui/theme_mode.dart`), loaded before the first frame. Header toggle and Settings picker switch with the circular reveal in `lib/ui/theme_reveal.dart` (frozen frame + growing hole; instant under reduced motion). |
| Page 1 dashboard | `lib/features/dashboard/`: header with cycle badge and theme toggle, glass True Liquid Balance card (`LiquidBalanceCard`), 260° spring gauge (`SafeSpendSpring`, `ArcGaugePainter` in `spring_gauge.dart`), Days-Until-Broke velocity meter, docked frosted command pill with receipt-scan shortcut. Voice input uses the keyboard's dictation key in the app and Siri / the Action Button through `LogSplitExpenseIntent`; there is no in-app waveform. |
| §4 shader | `shaders/survival_aura.frag`, drawn by `SurvivalAura`. Falls back to a radial gradient wherever the shader can't load (widget tests), and stops animating under reduced motion. |
| §5.1 spring | `SafeSpendSpring` (m 1, k 180, c 19), first target in `didChangeDependencies` so reduced motion can be honoured. |
| Page 2 split | `lib/features/split/split_sheet.dart`: `NetShareImpactBar` (solid emerald vs hatched amber), receipt items as Bento cards with avatar stacks, and the magnetic avatar dock (pick a person, tap their dishes; light haptic). |
| Page 3 / §5.2 debt graph | `lib/features/ledger/debt_graph.dart` (`DebtGraphView`), used on Friends and Group settle-up. Nodes sit on a circle (the user on top) instead of a force-directed simulation: the layout is stable between frames and testable. Curved arrows, particles faster for bigger debts, and the 3-stage 750 ms collapse with a medium haptic at 500 ms. The Friends ledger only knows the user's own IOUs, so there Simplify nets each friend's two directions; Group settle-up shows real friend-to-friend simplification. |
| Page 4 / §5.3 Nudge Bot | `nudge_cards.dart` (thermal paper, serrated `SerratedEdgeClipper`, mono rows, SURVIVAL DEFICIT / EXCUSES REMAINING, a QR code that pays the user's UPI ID or opens the zero-install link) and `thermal_receipt.dart` (12-step feed, 6 selection clicks driven by the animation rather than timers, drag tilt, foil sheen, paper shadow kept outside the exported PNG). |
| Page 5 bills | `lib/features/bills/bills_screen.dart`: breathing amber 48-hour shield banner (Cancel & bury, or swipe), Saved So Far counter (trials buried before they charged), mono countdown tiles, flatmate avatars that toggle "away on semester break". Away is an additive `away` flag in `auto_split_group_json`; `SubscriptionsDao.chargeSplitFor` spreads an away flatmate's share equally over the user and everyone home. |
| Page 6 widget | `ios/BalanceWidgetExtension/BalanceWidget.swift` `Palette` mirrors the tokens and follows the system appearance; Survival Mode paints the magma gradient. |
| Page 6 web ledger | `lib/features/web_ledger/web_ledger_app.dart`: follows the browser's light/dark preference, gradient-rimmed Pay button. |
| §6 haptics | Dashboard heavy impact on entering Survival Mode, receipt dock light impact, graph collapse medium impact, receipt print 6 selection clicks, burying a trial medium impact. The App Intent success haptic is the system's own Shortcuts confirmation. |

