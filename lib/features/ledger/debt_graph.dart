import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/money.dart';
import '../../domain/debt_simplifier.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

/// Spatial "who owes whom" graph (DESIGN_SYSTEM §3 Page 3, §5.2).
///
/// People sit on a circle ([self] at the top); each debt is a curved arrow
/// from debtor to creditor with an amount pill and particles flowing along
/// it, faster for bigger debts. Flipping [simplified] plays the 3-stage
/// collapse: edges that disappear retract (0–250 ms), the direct
/// replacements grow (200–550 ms), then their amounts pop in with a medium
/// haptic (500–750 ms).
class DebtGraphView extends StatefulWidget {
  const DebtGraphView({
    super.key,
    required this.people,
    required this.rawDebts,
    required this.simplifiedDebts,
    required this.simplified,
    required this.symbol,
    this.self,
    this.height = 300,
  });

  /// Everyone to draw, in display order.
  final List<String> people;
  final List<Debt<String>> rawDebts;
  final List<Debt<String>> simplifiedDebts;
  final bool simplified;
  final String symbol;

  /// The user (edges into them are green, out of them red).
  final String? self;
  final double height;

  /// Opposite and repeated debts between the same pair, merged for drawing.
  static List<Debt<String>> mergePairs(List<Debt<String>> debts) {
    final net = <(String, String), int>{};
    for (final d in debts) {
      if (d.from == d.to || d.amountMinor == 0) continue;
      final forward = d.from.compareTo(d.to) < 0;
      final key = forward ? (d.from, d.to) : (d.to, d.from);
      net[key] = (net[key] ?? 0) + (forward ? d.amountMinor : -d.amountMinor);
    }
    return [
      for (final MapEntry(key: (a, b), value: v) in net.entries)
        if (v > 0)
          Debt(from: a, to: b, amountMinor: v)
        else if (v < 0)
          Debt(from: b, to: a, amountMinor: -v),
    ];
  }

  @override
  State<DebtGraphView> createState() => _DebtGraphViewState();
}

class _DebtGraphViewState extends State<DebtGraphView>
    with TickerProviderStateMixin {
  late final AnimationController _collapse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
    value: 1,
  )..addListener(_maybeHaptic);
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool _hapticFired = true;

  /// Edges before the latest toggle (what retracts).
  List<Debt<String>> _from = const [];

  List<Debt<String>> get _shown =>
      widget.simplified ? widget.simplifiedDebts : widget.rawDebts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _flow.stop();
    } else if (!_flow.isAnimating) {
      _flow.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant DebtGraphView old) {
    super.didUpdateWidget(old);
    if (old.simplified != widget.simplified) {
      _from = old.simplified ? old.simplifiedDebts : old.rawDebts;
      _hapticFired = false;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _collapse.value = 1;
      } else {
        _collapse.forward(from: 0);
      }
    }
  }

  void _maybeHaptic() {
    if (!_hapticFired && _collapse.value >= 500 / 750) {
      _hapticFired = true;
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _collapse.dispose();
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final people = widget.people;
    return SizedBox(
      key: const Key('debt-graph'),
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = Size(box.maxWidth, widget.height);
          final positions = _layout(people, size);
          final shown = _shown;
          final animating = _collapse.value < 1;
          final retracting = animating
              ? [
                  for (final d in _from)
                    if (!shown.contains(d)) d,
                ]
              : const <Debt<String>>[];
          final growing = {
            if (animating)
              for (final d in shown)
                if (!_from.contains(d)) d,
          };
          return AnimatedBuilder(
            animation: Listenable.merge([_collapse, _flow]),
            builder: (context, _) {
              final t = _collapse.value * 750;
              double phase(double start, double end) =>
                  ((t - start) / (end - start)).clamp(0.0, 1.0);
              final retract = 1 - phase(0, 250);
              final grow = Curves.easeOutCubic.transform(phase(200, 550));
              final pop = Curves.elasticOut.transform(phase(500, 750));
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _EdgePainter(
                        positions: positions,
                        edges: [
                          for (final d in retracting) (d, retract, false),
                          for (final d in shown)
                            (d, growing.contains(d) ? grow : 1.0, true),
                        ],
                        flow: _flow.value,
                        colorFor: (d) => d.to == widget.self
                            ? sb.owedToMe
                            : d.from == widget.self
                            ? sb.iOwe
                            : sb.textSecondary,
                        particle: sb.textPrimary,
                      ),
                    ),
                  ),
                  for (final d in shown)
                    if (positions[d.from] != null && positions[d.to] != null)
                      _AmountBadge(
                        at: _midpoint(positions[d.from]!, positions[d.to]!),
                        scale: growing.contains(d) ? pop : 1,
                        text: Money.format(
                          d.amountMinor,
                          symbol: widget.symbol,
                        ),
                        color: d.to == widget.self
                            ? sb.owedToMe
                            : d.from == widget.self
                            ? sb.iOwe
                            : sb.textSecondary,
                      ),
                  for (final p in people)
                    if (positions[p] case final at?)
                      Positioned(
                        left: at.dx - 36,
                        top: at.dy - 22,
                        width: 72,
                        child: Column(
                          children: [
                            FriendAvatar(
                              p,
                              size: 44,
                              ring: p == widget.self ? sb.accent : null,
                            ),
                            const SizedBox(height: 3),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: sb.surfacePrimary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  p,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: SbType.chip.copyWith(
                                    color: sb.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Circle layout, [DebtGraphView.self] (or the first person) on top.
  Map<String, Offset> _layout(List<String> people, Size size) {
    final ordered = [
      if (widget.self != null && people.contains(widget.self)) widget.self!,
      for (final p in people)
        if (p != widget.self) p,
    ];
    final center = Offset(size.width / 2, size.height / 2 - 6);
    final radius = math.min(size.width / 2 - 44, size.height / 2 - 40);
    return {
      for (var i = 0; i < ordered.length; i++)
        ordered[i]: ordered.length == 1
            ? center
            : center +
                  Offset.fromDirection(
                    -math.pi / 2 + 2 * math.pi * i / ordered.length,
                    radius,
                  ),
    };
  }

  static Offset _midpoint(Offset a, Offset b) {
    final control = _EdgePainter.controlPoint(a, b);
    // Quadratic Bézier at t = 0.5.
    return a * 0.25 + control * 0.5 + b * 0.25;
  }
}

class _AmountBadge extends StatelessWidget {
  const _AmountBadge({
    required this.at,
    required this.scale,
    required this.text,
    required this.color,
  });

  final Offset at;
  final double scale;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return Positioned(
      left: at.dx - 50,
      top: at.dy - 12,
      width: 100,
      height: 24,
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: sb.surfacePrimary,
              borderRadius: BorderRadius.circular(SbRadius.pill),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(text, style: SbType.chip.copyWith(color: color)),
            ),
          ),
        ),
      ),
    );
  }
}

/// (edge, drawn fraction, has particles)
typedef _Edge = (Debt<String>, double, bool);

class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.positions,
    required this.edges,
    required this.flow,
    required this.colorFor,
    required this.particle,
  });

  final Map<String, Offset> positions;
  final List<_Edge> edges;
  final double flow;
  final Color Function(Debt<String>) colorFor;
  final Color particle;

  /// Bends every edge to its right, so A→B and B→A never overlap.
  static Offset controlPoint(Offset a, Offset b) {
    final mid = (a + b) / 2;
    final d = b - a;
    final normal = Offset(-d.dy, d.dx) / (d.distance == 0 ? 1 : d.distance);
    return mid + normal * (d.distance * 0.18);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final maxAmount = edges.fold<int>(
      1,
      (m, e) => math.max(m, e.$1.amountMinor),
    );
    for (final (debt, fraction, live) in edges) {
      final a = positions[debt.from];
      final b = positions[debt.to];
      if (a == null || b == null || fraction <= 0) continue;
      // Stop short of the avatars.
      final dir = (b - a) / math.max((b - a).distance, 1);
      final start = a + dir * 26;
      final end = b - dir * 28;
      final control = controlPoint(start, end);
      final full = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      final metric = full.computeMetrics().first;
      final drawn = metric.extractPath(0, metric.length * fraction);
      final color = colorFor(debt);
      final weight = debt.amountMinor / maxAmount;
      canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 + 1.8 * weight
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(start, end, [
            color.withValues(alpha: 0.35),
            color,
          ]),
      );
      if (fraction >= 1) {
        final tip = metric.getTangentForOffset(metric.length)!;
        _arrowHead(canvas, tip.position, tip.vector, color);
      }
      if (live && fraction >= 1) {
        // Bigger debts flow faster (1–3 laps per cycle).
        final laps = 1 + (2 * weight).round();
        for (var k = 0; k < 2; k++) {
          final t = (flow * laps + k / 2) % 1.0;
          final p = metric.getTangentForOffset(metric.length * t)!.position;
          canvas.drawCircle(
            p,
            2.6,
            Paint()..color = particle.withValues(alpha: 0.75),
          );
        }
      }
    }
  }

  void _arrowHead(Canvas canvas, Offset at, Offset direction, Color color) {
    final angle = direction.direction;
    const length = 9.0;
    final path = Path()
      ..moveTo(at.dx, at.dy)
      ..lineTo(
        at.dx - length * math.cos(angle - 0.45),
        at.dy - length * math.sin(angle - 0.45),
      )
      ..lineTo(
        at.dx - length * math.cos(angle + 0.45),
        at.dy - length * math.sin(angle + 0.45),
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_EdgePainter old) => true;
}
