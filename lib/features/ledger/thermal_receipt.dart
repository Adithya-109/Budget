import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/theme.dart';

/// Thermal printer slot + receipt (DESIGN_SYSTEM §5.3): the paper feeds out
/// in 12 mechanical steps with 6 selection-click haptics, tilts in 3D under
/// a drag and catches a diagonal foil sheen. A new [key] reprints it.
class ThermalReceiptInteractiveCard extends StatefulWidget {
  const ThermalReceiptInteractiveCard({super.key, required this.receiptChild});

  final Widget receiptChild;

  @override
  State<ThermalReceiptInteractiveCard> createState() =>
      _ThermalReceiptInteractiveCardState();
}

class _ThermalReceiptInteractiveCardState
    extends State<ThermalReceiptInteractiveCard>
    with SingleTickerProviderStateMixin {
  static const _steps = 12;
  static const _clicks = 6;

  late final AnimationController _feed = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..addListener(_tick);
  Offset _tilt = Offset.zero;
  int _clicked = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_feed.status == AnimationStatus.dismissed) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _feed.value = 1;
      } else {
        _feed.forward(from: 0);
      }
    }
  }

  /// Haptics ride the animation (no timers): one click per sixth of the feed.
  void _tick() {
    final due = (_feed.value * _clicks).floor().clamp(0, _clicks);
    while (_clicked < due) {
      _clicked++;
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _feed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The printer slot the paper comes out of.
        Container(
          width: 300,
          height: 14,
          decoration: BoxDecoration(
            color: context.isDark ? Colors.black : sb.textPrimary,
            borderRadius: BorderRadius.circular(SbRadius.pill),
            border: Border.all(color: sb.specularBorder),
          ),
        ),
        GestureDetector(
          onPanUpdate: (d) => setState(() {
            _tilt = Offset(
              (_tilt.dx + d.delta.dx * 0.008).clamp(-1.0, 1.0),
              (_tilt.dy + d.delta.dy * 0.008).clamp(-1.0, 1.0),
            );
          }),
          onPanEnd: (_) => setState(() => _tilt = Offset.zero),
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _feed,
              builder: (context, child) {
                final stepped = (_feed.value * _steps).floor() / _steps;
                final matrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(-_tilt.dy * 0.16)
                  ..rotateY(_tilt.dx * 0.16);
                return FractionalTranslation(
                  translation: Offset(0, stepped - 1),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: matrix,
                    child: child,
                  ),
                );
              },
              // Room for the paper's shadow inside the clip.
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _PaperShadow()),
                    ),
                    widget.receiptChild,
                    Positioned.fill(
                      child: IgnorePointer(child: _Sheen(tilt: _tilt)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A soft shadow in the shape of the torn paper, so the receipt lifts off
/// the alabaster canvas in light mode (kept out of the exported PNG).
class _PaperShadow extends CustomPainter {
  const _PaperShadow();

  @override
  void paint(Canvas canvas, Size size) {
    final path = const SerratedEdgeClipper().getClip(size);
    canvas.drawShadow(path, Colors.black, 6, false);
  }

  @override
  bool shouldRepaint(_PaperShadow old) => false;
}

/// Diagonal foil reflection that slides with the tilt.
class _Sheen extends StatelessWidget {
  const _Sheen({required this.tilt});

  final Offset tilt;

  @override
  Widget build(BuildContext context) {
    final shift = (tilt.dx - tilt.dy) * 0.6;
    final strength = math.min(1.0, tilt.distance * 1.5);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1 + shift, -1),
          end: Alignment(1 + shift, 1),
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.10 + 0.25 * strength),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.35, 0.5, 0.65],
        ),
      ),
    );
  }
}

/// Zig-zag (serrated) top and bottom edges of torn thermal paper.
class SerratedEdgeClipper extends CustomClipper<Path> {
  const SerratedEdgeClipper({this.tooth = 10, this.depth = 6});

  final double tooth;
  final double depth;

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, depth);
    final teeth = (size.width / tooth).ceil();
    final step = size.width / teeth;
    for (var i = 0; i < teeth; i++) {
      path
        ..lineTo(step * i + step / 2, 0)
        ..lineTo(step * (i + 1), depth);
    }
    path.lineTo(size.width, size.height - depth);
    for (var i = teeth; i > 0; i--) {
      path
        ..lineTo(step * i - step / 2, size.height)
        ..lineTo(step * (i - 1), size.height - depth);
    }
    return path..close();
  }

  @override
  bool shouldReclip(SerratedEdgeClipper old) =>
      old.tooth != tooth || old.depth != depth;
}
