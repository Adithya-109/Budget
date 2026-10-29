import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

import '../../ui/theme.dart';

/// Drives a 0…1 ratio with a damped spring (DESIGN_SYSTEM §5.1): mass 1,
/// stiffness 180, damping 19 (ζ ≈ 0.71, one small overshoot). Retargeting
/// keeps the current velocity so rapid updates never jump.
class SafeSpendSpring extends StatefulWidget {
  const SafeSpendSpring({
    super.key,
    required this.targetRatio,
    required this.builder,
  });

  final double targetRatio;
  final Widget Function(BuildContext context, double animatedRatio) builder;

  static const spring = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 19.0,
  );

  @override
  State<SafeSpendSpring> createState() => _SafeSpendSpringState();
}

class _SafeSpendSpringState extends State<SafeSpendSpring>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
  )..addListener(() => setState(() {}));

  double get _ratio => _controller.value.clamp(0.0, 1.15);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // First target here, not initState: reduced motion is a MediaQuery read.
    if (!_started) {
      _started = true;
      _animateTo(widget.targetRatio, velocity: 0);
    }
  }

  @override
  void didUpdateWidget(covariant SafeSpendSpring oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.targetRatio - widget.targetRatio).abs() > 0.001) {
      _animateTo(widget.targetRatio, velocity: _controller.velocity);
    }
  }

  void _animateTo(double target, {required double velocity}) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = target;
      return;
    }
    _controller.animateWith(
      SpringSimulation(
        SafeSpendSpring.spring,
        _controller.value,
        target,
        velocity,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _ratio);
}

/// 260° open arc with the gap at the bottom; the filled part uses a sweep
/// gradient (mint when safe, magma in Survival Mode).
class ArcGaugePainter extends CustomPainter {
  ArcGaugePainter({
    required this.ratio,
    required this.track,
    required this.colors,
    this.strokeWidth = 14,
  });

  final double ratio;
  final Color track;
  final List<Color> colors;
  final double strokeWidth;

  static const sweepDegrees = 260.0;
  static const _start = (90 + (360 - sweepDegrees) / 2) * math.pi / 180;
  static const _sweep = sweepDegrees * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    ).deflate(strokeWidth / 2 + 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, base..color = track);
    final value = ratio.clamp(0.0, 1.0);
    if (value <= 0.001) return;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: _start,
        endAngle: _start + _sweep,
        colors: colors,
        tileMode: TileMode.clamp,
      ).createShader(rect);
    canvas.drawArc(rect, _start, _sweep * value, false, fill);
  }

  @override
  bool shouldRepaint(ArcGaugePainter old) =>
      old.ratio != ratio ||
      old.track != track ||
      old.strokeWidth != strokeWidth ||
      !_sameColors(old.colors, colors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Ambient glow behind the gauge, rendered by `shaders/survival_aura.frag`
/// (DESIGN_SYSTEM §4). Falls back to a radial gradient where the shader
/// can't load (some test and web renderers). Still with reduced motion.
class SurvivalAura extends StatefulWidget {
  const SurvivalAura({super.key, required this.burnRatio});

  /// 0 = Safe Mint, 1 = Survival Magma.
  final double burnRatio;

  static Future<ui.FragmentProgram?>? _program;

  static Future<ui.FragmentProgram?> _load() =>
      _program ??= ui.FragmentProgram.fromAsset('shaders/survival_aura.frag')
          .then<ui.FragmentProgram?>((p) => p)
          .catchError((Object _) => null);

  @override
  State<SurvivalAura> createState() => _SurvivalAuraState();
}

class _SurvivalAuraState extends State<SurvivalAura>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  late final Ticker _ticker = createTicker(
    (elapsed) => setState(() => _time = elapsed.inMicroseconds / 1e6),
  );
  double _time = 0;

  @override
  void initState() {
    super.initState();
    SurvivalAura._load().then((program) {
      if (!mounted || program == null) return;
      setState(() => _program = program);
      _syncTicker();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  void _syncTicker() {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final run = _program != null && !still;
    if (run && !_ticker.isActive) _ticker.start();
    if (!run && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final program = _program;
    return IgnorePointer(
      child: CustomPaint(
        painter: program == null
            ? _GradientAuraPainter(
                Color.lerp(
                  sb.safeMint,
                  sb.survivalMagma,
                  widget.burnRatio,
                )!.withValues(alpha: context.isDark ? 0.22 : 0.14),
              )
            : _ShaderAuraPainter(
                program.fragmentShader(),
                time: _time,
                burnRatio: widget.burnRatio,
                dark: context.isDark,
              ),
        size: Size.infinite,
      ),
    );
  }
}

class _ShaderAuraPainter extends CustomPainter {
  _ShaderAuraPainter(
    this.shader, {
    required this.time,
    required this.burnRatio,
    required this.dark,
  });

  final ui.FragmentShader shader;
  final double time;
  final double burnRatio;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, burnRatio)
      ..setFloat(4, dark ? 1 : 0);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShaderAuraPainter old) =>
      old.time != time || old.burnRatio != burnRatio || old.dark != dark;
}

class _GradientAuraPainter extends CustomPainter {
  _GradientAuraPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 1],
          radius: 0.55,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GradientAuraPainter old) => old.color != color;
}
