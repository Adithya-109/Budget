import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Circular-reveal theme switch (DESIGN_SYSTEM §3 Page 1 header): freezes
/// the current frame, applies the new theme underneath, then opens a growing
/// circle in the frozen frame from where the user tapped.
///
/// Sits in `MaterialApp.builder`, so it covers every route and sheet.
class ThemeReveal extends StatefulWidget {
  const ThemeReveal({super.key, required this.child});

  final Widget child;

  static ThemeRevealState of(BuildContext context) =>
      context.findAncestorStateOfType<ThemeRevealState>()!;

  @override
  State<ThemeReveal> createState() => ThemeRevealState();
}

class ThemeRevealState extends State<ThemeReveal>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  ui.Image? _frozen;
  Offset _center = Offset.zero;

  /// Runs [switchTheme] behind a reveal centred on [globalCenter]. Falls back
  /// to an instant switch with reduced motion or when nothing is painted.
  Future<void> run(Offset globalCenter, VoidCallback switchTheme) async {
    final boundary =
        _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (_reveal.isAnimating ||
        MediaQuery.disableAnimationsOf(context) ||
        boundary == null ||
        boundary.debugNeedsPaint) {
      switchTheme();
      return;
    }
    final image = await boundary.toImage(
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      _frozen = image;
      _center = boundary.globalToLocal(globalCenter);
    });
    switchTheme();
    await _reveal.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _frozen?.dispose();
      _frozen = null;
    });
  }

  @override
  void dispose() {
    _reveal.dispose();
    _frozen?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frozen = _frozen;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (frozen != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _reveal,
                builder: (context, _) => ClipPath(
                  clipper: _HoleClipper(
                    _center,
                    Curves.easeInOutCubic.transform(_reveal.value),
                  ),
                  child: RawImage(image: frozen, fit: BoxFit.fill),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The frozen old frame with a growing circular hole.
class _HoleClipper extends CustomClipper<Path> {
  _HoleClipper(this.center, this.t);

  final Offset center;
  final double t;

  @override
  Path getClip(Size size) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final maxRadius = corners
        .map((c) => (c - center).distance)
        .reduce(math.max);
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: maxRadius * t));
  }

  @override
  bool shouldReclip(_HoleClipper old) => old.t != t || old.center != center;
}
