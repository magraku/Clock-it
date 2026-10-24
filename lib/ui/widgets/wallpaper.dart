import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/goals.dart';
import '../theme.dart';
import 'common.dart';

/// The focus screen's background: the app's own photo, or one of the
/// painted wallpapers. Each painted one takes the hourglass print's shapes
/// and lays the app's colours over them like drops of paint bleeding into
/// wet paper, with the same grain as the photos.
class WallpaperBackdrop extends StatelessWidget {
  const WallpaperBackdrop({super.key, required this.style, required this.child});

  final WallpaperStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (style == WallpaperStyle.photo) return Backdrop(image: Assets.bgMain, child: child);
    return Stack(children: [
      // Its own layer: the timer animating on top doesn't repaint the grain.
      Positioned.fill(
        child: RepaintBoundary(
          child: CustomPaint(painter: WallpaperPainter(style), isComplex: true),
        ),
      ),
      child,
    ]);
  }
}

/// Small preview for picking a wallpaper.
class WallpaperSwatch extends StatelessWidget {
  const WallpaperSwatch({super.key, required this.style});

  final WallpaperStyle style;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: style == WallpaperStyle.photo
          ? const Image(image: AssetImage(Assets.bgMain), fit: BoxFit.cover)
          : CustomPaint(painter: WallpaperPainter(style), child: const SizedBox.expand()),
    );
  }
}

/// Paints [style] as a phone-sized PNG (1290 × 2796, an iPhone 15 Pro Max
/// screen), for saving and setting on the lock screen.
Future<Uint8List> wallpaperPng(WallpaperStyle style) async {
  const size = Size(1290, 2796);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & size);
  if (style == WallpaperStyle.photo) {
    // The photo is a plain asset; scale it to cover the screen.
    final data = await _loadPhoto();
    paintImage(canvas: canvas, rect: Offset.zero & size, image: data, fit: BoxFit.cover);
  } else {
    WallpaperPainter(style).paint(canvas, size);
  }
  final image = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

Future<ui.Image> _loadPhoto() async {
  final stream = const AssetImage(Assets.bgMain).resolve(ImageConfiguration.empty);
  final done = Completer<ui.Image>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener((info, _) {
    done.complete(info.image);
    stream.removeListener(listener);
  }, onError: (e, s) => done.completeError(e, s));
  stream.addListener(listener);
  return done.future;
}

/// One look per style, all from the same three layers: a wash, soft blots
/// of colour, and hourglass shapes; then grain on top.
class WallpaperPainter extends CustomPainter {
  WallpaperPainter(this.style);

  final WallpaperStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Everything is laid out on a 100-wide grid so swatches match the export.
    final u = w / 100;
    final look = _looks[style]!;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: look.wash,
        ).createShader(Offset.zero & size),
    );

    // Paint drops: big, blurred, overlapping, so their edges bleed together.
    for (final b in look.blots) {
      final c = Offset(b.x * w, b.y * h);
      final r = b.r * w;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [b.color, b.color.withValues(alpha: 0)],
            stops: const [0.35, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18),
      );
    }

    for (final g in look.glasses) {
      final rect = Rect.fromCenter(center: Offset(g.x * w, g.y * h), width: g.size * u, height: g.size * u * 1.46);
      final body = _glass(rect, curved: g.curved);
      if (g.fill != null) {
        canvas.drawPath(
          body,
          Paint()
            ..color = g.fill!
            ..maskFilter = g.soft ? MaskFilter.blur(BlurStyle.normal, rect.width * 0.08) : null,
        );
      }
      if (g.ink != null) {
        final ink = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rect.width * 0.035
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = g.ink!;
        canvas.drawPath(body, ink);
        // The caps top and bottom, a little wider than the glass.
        final over = rect.width * 0.08;
        canvas
          ..drawLine(Offset(rect.left - over, rect.top), Offset(rect.right + over, rect.top), ink)
          ..drawLine(Offset(rect.left - over, rect.bottom), Offset(rect.right + over, rect.bottom), ink);
      }
    }

    // Grain, like the photos: fixed seed, so it never flickers.
    final rnd = Random(7);
    final dot = Paint();
    final count = (w * h / 40).round().clamp(500, 40000);
    for (var i = 0; i < count; i++) {
      final light = rnd.nextBool();
      dot.color = (light ? Colors.white : Colors.black).withValues(alpha: 0.035 + rnd.nextDouble() * 0.03);
      canvas.drawCircle(Offset(rnd.nextDouble() * w, rnd.nextDouble() * h), u * 0.18, dot);
    }
  }

  /// The print's hourglass in [r]: curved bulbs, or two straight triangles.
  static Path _glass(Rect r, {required bool curved}) {
    final l = r.left, t = r.top, rt = r.right, b = r.bottom, cx = r.center.dx, cy = r.center.dy;
    final neck = r.width * 0.06;
    if (!curved) {
      return Path()
        ..moveTo(l, t)
        ..lineTo(rt, t)
        ..lineTo(cx + neck, cy)
        ..lineTo(rt, b)
        ..lineTo(l, b)
        ..lineTo(cx - neck, cy)
        ..close();
    }
    final dy = r.height * 0.16;
    return Path()
      ..moveTo(l, t)
      ..lineTo(rt, t)
      ..cubicTo(rt, cy - dy, cx + neck, cy - dy * 0.4, cx + neck, cy)
      ..cubicTo(cx + neck, cy + dy * 0.4, rt, cy + dy, rt, b)
      ..lineTo(l, b)
      ..cubicTo(l, cy + dy, cx - neck, cy + dy * 0.4, cx - neck, cy)
      ..cubicTo(cx - neck, cy - dy * 0.4, l, cy - dy, l, t)
      ..close();
  }

  @override
  bool shouldRepaint(WallpaperPainter old) => old.style != style;
}

class _Blot {
  const _Blot(this.x, this.y, this.r, this.color);

  /// Centre as a fraction of the width and height; radius of the width.
  final double x, y, r;
  final Color color;
}

class _Glass {
  const _Glass(this.x, this.y, this.size, {this.curved = true, this.fill, this.ink, this.soft = false});

  /// Centre as a fraction of the screen; [size] wide on the 100 grid.
  final double x, y, size;
  final bool curved;
  final Color? fill, ink;

  /// Blurred edges, as if painted wet.
  final bool soft;
}

class _Look {
  const _Look({required this.wash, required this.blots, required this.glasses});

  final List<Color> wash;
  final List<_Blot> blots;
  final List<_Glass> glasses;
}

const _cream = Palette.cream;
const _navy = Palette.navyDeep;

final _looks = <WallpaperStyle, _Look>{
  // Pink and orange drops meeting in the middle, one big glass in their glow.
  WallpaperStyle.drop: _Look(
    wash: const [_cream, Color(0xFFF6E7EC)],
    blots: [
      _Blot(0.2, 0.28, 0.75, Palette.pink.withValues(alpha: 0.85)),
      _Blot(0.85, 0.5, 0.7, Palette.orange.withValues(alpha: 0.7)),
      _Blot(0.35, 0.82, 0.6, Palette.coral.withValues(alpha: 0.35)),
      _Blot(0.7, 0.12, 0.35, Palette.yellow.withValues(alpha: 0.9)),
    ],
    glasses: [
      _Glass(0.5, 0.56, 46, fill: _cream.withValues(alpha: 0.35), ink: _navy.withValues(alpha: 0.75)),
    ],
  ),
  // Night for the lock screen: deep navy, warm drops low, a cream glass.
  WallpaperStyle.dusk: _Look(
    wash: const [Color(0xFF1F2B44), _navy],
    blots: [
      _Blot(0.15, 0.85, 0.7, Palette.coral.withValues(alpha: 0.75)),
      _Blot(0.9, 0.72, 0.6, Palette.orange.withValues(alpha: 0.55)),
      _Blot(0.6, 1.0, 0.55, Palette.pink.withValues(alpha: 0.5)),
      _Blot(0.8, 0.15, 0.3, Palette.pink.withValues(alpha: 0.2)),
    ],
    glasses: [
      _Glass(0.5, 0.58, 40, fill: _cream.withValues(alpha: 0.12), ink: _cream.withValues(alpha: 0.85)),
    ],
  ),
  // Fresh: yellow and green drops, two soft glasses leaning on each other.
  WallpaperStyle.meadow: _Look(
    wash: const [Color(0xFFFBF8E3), _cream],
    blots: [
      const _Blot(0.85, 0.25, 0.7, Palette.yellow),
      _Blot(0.1, 0.6, 0.75, Palette.green.withValues(alpha: 0.6)),
      _Blot(0.7, 0.95, 0.55, Palette.green.withValues(alpha: 0.45)),
    ],
    glasses: [
      _Glass(0.38, 0.5, 40, fill: Palette.green.withValues(alpha: 0.55), soft: true),
      _Glass(0.64, 0.62, 30, curved: false, fill: Palette.orange.withValues(alpha: 0.5), soft: true),
    ],
  ),
  // The shapes repeated: a loose pattern of small glasses over pink.
  WallpaperStyle.pattern: _Look(
    wash: const [Color(0xFFFBE9F7), Color(0xFFF7E4D9)],
    blots: [
      _Blot(0.1, 0.1, 0.6, Palette.pink.withValues(alpha: 0.7)),
      _Blot(0.95, 0.9, 0.7, Palette.orange.withValues(alpha: 0.5)),
    ],
    glasses: [
      // Four per row, three on the offset rows, so none is cut at the edge.
      for (var row = 0; row < 7; row++)
        for (var col = 0; col < (row.isOdd ? 3 : 4); col++)
          _Glass(
            0.12 + col * 0.26 + (row.isOdd ? 0.13 : 0),
            0.07 + row * 0.145,
            11,
            curved: (row + col).isEven,
            ink: _navy.withValues(alpha: 0.28),
            fill: [Palette.yellow, Palette.pink, Palette.green, Palette.orange][(row + col) % 4].withValues(alpha: 0.45),
          ),
    ],
  ),
};
