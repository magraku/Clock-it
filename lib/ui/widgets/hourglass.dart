import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/goals.dart';
import '../theme.dart';

/// The focus timer's hourglass, in one of four [HourglassStyle]s.
///
/// Before the timer starts ([ready]) the sand rests at the bottom; when it
/// starts, the glass turns over and the sand begins to fall. [progress] goes
/// from 0 (full top) to 1 (all fallen) and is read every frame while running,
/// so the sand sinks smoothly instead of once a second.
class Hourglass extends StatefulWidget {
  const Hourglass({
    super.key,
    required this.style,
    required this.progress,
    required this.running,
    this.ready = false,
    this.sand = Palette.inkDeep,
  });

  final HourglassStyle style;
  final double Function() progress;
  final bool running;
  final bool ready;

  /// Sand colour for the styles drawn on the box (all but classic).
  final Color sand;

  /// Width / height of the drawing.
  static const aspect = 100 / 146;

  @override
  State<Hourglass> createState() => _HourglassState();
}

class _HourglassState extends State<Hourglass> with TickerProviderStateMixin {
  late final _flow = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Hourglass old) {
    super.didUpdateWidget(old);
    if (old.ready && !widget.ready && widget.running) _flip.forward(from: 0);
    _sync();
  }

  void _sync() {
    if (widget.running && !_flow.isAnimating) _flow.repeat();
    if (!widget.running && _flow.isAnimating) _flow.stop();
  }

  @override
  void dispose() {
    _flow.dispose();
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AspectRatio(
      aspectRatio: Hourglass.aspect,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flow, _flip]),
        builder: (context, _) {
          final flipping = !still && _flip.isAnimating;
          final progress = widget.ready || flipping ? 1.0 : widget.progress().clamp(0.0, 1.0);
          final turn = flipping ? Curves.easeInOutBack.transform(_flip.value) * pi : 0.0;
          return Transform.rotate(
            angle: turn,
            child: CustomPaint(
              painter: _HourglassPainter(
                style: widget.style,
                sand: widget.sand,
                progress: progress,
                flow: still ? 0 : _flow.value,
                falling: widget.running && !flipping && progress < 1,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Small preview for picking a style.
class HourglassSwatch extends StatelessWidget {
  const HourglassSwatch({super.key, required this.style, required this.sand});

  final HourglassStyle style;
  final Color sand;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: Hourglass.aspect,
        child: CustomPaint(
          painter: _HourglassPainter(style: style, sand: sand, progress: 0.4, flow: 0, falling: false),
        ),
      );
}

// Drawing units: 100 × 146.
const _top = 12.0, _neck = 73.0, _bottom = 134.0;

class _HourglassPainter extends CustomPainter {
  _HourglassPainter({
    required this.style,
    required this.sand,
    required this.progress,
    required this.flow,
    required this.falling,
  });

  final HourglassStyle style;
  final Color sand;
  final double progress;
  final double flow;
  final bool falling;

  static const _ink = Palette.inkDeep;
  static const _cream = Color(0xFFF1E8D0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 146);
    switch (style) {
      case HourglassStyle.classic:
        _classic(canvas);
      case HourglassStyle.crystal:
        _crystal(canvas);
      case HourglassStyle.line:
        _line(canvas);
      case HourglassStyle.grains:
        _grains(canvas);
    }
  }

  /// The design's reference print: cream glass on a dark panel, dark sand.
  void _classic(Canvas canvas) {
    final panel = Paint()..color = _ink;
    final glass = Paint()..color = _cream;
    canvas.drawRRect(RRect.fromLTRBR(0, 0, 100, 146, const Radius.circular(4)), panel);
    canvas.drawRect(const Rect.fromLTRB(4, 3, 96, 9), glass);
    canvas.drawRect(const Rect.fromLTRB(4, 137, 96, 143), glass);
    final body = _curvedBody(9, 4.5);
    canvas.drawPath(body, glass);
    _sand(canvas, body, panel);
  }

  /// Two round glass bulbs between dark wooden caps and posts.
  void _crystal(Canvas canvas) {
    final wood = Paint()..color = _ink;
    final body = Path.combine(
      PathOperation.union,
      Path()
        ..addOval(const Rect.fromLTRB(15, _top, 85, _neck + 2))
        ..addOval(const Rect.fromLTRB(15, _neck - 2, 85, _bottom)),
      Path()..addRect(const Rect.fromLTRB(46, _neck - 12, 54, _neck + 12)),
    );
    canvas.drawPath(body, Paint()..color = Colors.white.withValues(alpha: 0.5));
    _sand(canvas, body, Paint()..color = sand);
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _ink,
    );
    // Shine on each bulb.
    final shine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawArc(const Rect.fromLTRB(22, 19, 78, 68), pi * 1.1, 0.7, false, shine);
    canvas.drawArc(const Rect.fromLTRB(22, 78, 78, 127), pi * 1.1, 0.5, false, shine);
    // Posts, then the caps over them.
    canvas.drawRRect(RRect.fromLTRBR(5, 6, 10, 140, const Radius.circular(2.5)), wood);
    canvas.drawRRect(RRect.fromLTRBR(90, 6, 95, 140, const Radius.circular(2.5)), wood);
    canvas.drawRRect(RRect.fromLTRBR(0, 1, 100, 10, const Radius.circular(4)), wood);
    canvas.drawRRect(RRect.fromLTRBR(0, 136, 100, 145, const Radius.circular(4)), wood);
  }

  /// Geometric: two triangles in a thick line, flat sand.
  void _line(Canvas canvas) {
    final body = Path()
      ..moveTo(14, _top + 3)
      ..lineTo(86, _top + 3)
      ..lineTo(53, _neck)
      ..lineTo(86, _bottom - 3)
      ..lineTo(14, _bottom - 3)
      ..lineTo(47, _neck)
      ..close();
    _sand(canvas, body, Paint()..color = sand, dotted: true);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    canvas.drawPath(body, ink);
    canvas.drawLine(const Offset(6, 7), const Offset(94, 7), ink..strokeWidth = 5);
    canvas.drawLine(const Offset(6, 139), const Offset(94, 139), ink);
  }

  /// The print's outline, with sand made of grains that drop one by one.
  void _grains(Canvas canvas) {
    final body = _curvedBody(12, 5);
    canvas.drawPath(body, Paint()..color = Colors.white.withValues(alpha: 0.35));
    final grain = Paint()..color = sand;
    canvas
      ..save()
      ..clipPath(_sandRegion(body));
    for (var y = _top; y < _bottom; y += 4.2) {
      final odd = ((y - _top) / 4.2).round().isOdd;
      for (var x = odd ? 4.0 : 6.1; x < 100; x += 4.2) {
        canvas.drawCircle(Offset(x, y), 1.75, grain);
      }
    }
    canvas.restore();
    if (falling) {
      final end = _moundPeak - 2;
      for (var k = 0; k < 4; k++) {
        final t = (flow + k / 4) % 1;
        canvas.drawCircle(Offset(50 + sin((t + k) * 9) * 0.8, _neck + t * (end - _neck)), 1.6, grain);
      }
    }
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = _ink;
    canvas.drawPath(body, ink);
    canvas.drawLine(const Offset(8, 6), const Offset(92, 6), ink..strokeWidth = 4);
    canvas.drawLine(const Offset(8, 140), const Offset(92, 140), ink);
  }

  /// The print's silhouette, [side] in from the edges, [neck] half wide.
  static Path _curvedBody(double side, double neck) => Path()
    ..moveTo(side, _top)
    ..lineTo(100 - side, _top)
    ..cubicTo(100 - side, 44, 50 + neck, 54, 50 + neck, _neck)
    ..cubicTo(50 + neck, 92, 100 - side, 102, 100 - side, _bottom)
    ..lineTo(side, _bottom)
    ..cubicTo(side, 102, 50 - neck, 92, 50 - neck, _neck)
    ..cubicTo(50 - neck, 54, side, 44, side, _top)
    ..close();

  double get _moundPeak => _bottom - (_bottom - _neck - 14) * pow(progress, 0.8);

  /// Top sand sinking toward the neck (its surface dipping in the middle)
  /// and the heap growing below, both inside [body].
  Path _sandRegion(Path body) {
    final region = Path();
    final left = 1 - progress;
    if (left > 0.001) {
      final level = _neck - (_neck - _top - 8) * pow(left, 0.75);
      final dip = 7 * left + 2;
      region.addPath(
        Path()
          ..moveTo(0, level - dip * 0.4)
          ..quadraticBezierTo(50, level + dip, 100, level - dip * 0.4)
          ..lineTo(100, _neck + 1)
          ..lineTo(0, _neck + 1)
          ..close(),
        Offset.zero,
      );
    }
    if (progress > 0.001) {
      final shoulder = min(_bottom, _moundPeak + 16);
      region.addPath(
        Path()
          ..moveTo(0, shoulder)
          ..quadraticBezierTo(50, _moundPeak - 10, 100, shoulder)
          ..lineTo(100, _bottom + 1)
          ..lineTo(0, _bottom + 1)
          ..close(),
        Offset.zero,
      );
    }
    return Path.combine(PathOperation.intersect, region, body);
  }

  void _sand(Canvas canvas, Path body, Paint paint, {bool dotted = false}) {
    canvas.drawPath(_sandRegion(body), paint);
    if (!falling) return;
    // The thin stream through the neck: dashes, or dots for the line style.
    final end = _moundPeak - 4;
    final stream = Paint()
      ..color = paint.color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var y = _neck - 2 + flow * 6; y < end; y += 6) {
      if (dotted) {
        canvas.drawCircle(Offset(50, y), 1.3, stream);
      } else {
        canvas.drawLine(Offset(50, y), Offset(50, min(y + 3.5, end)), stream);
      }
    }
  }

  @override
  bool shouldRepaint(_HourglassPainter old) =>
      old.progress != progress ||
      old.flow != flow ||
      old.falling != falling ||
      old.style != style ||
      old.sand != sand;
}
