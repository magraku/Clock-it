import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The app's background: plum marbling that drifts very slowly
/// (`shaders/flow.frag`), with fixed grain on top.
///
/// It repaints about 20 times a second instead of every frame: the motion is
/// slow enough that more would only cost battery. It holds still when its
/// screen is hidden (another tab), with reduced motion, and in tests.
class FlowBackground extends StatefulWidget {
  const FlowBackground({super.key, this.child});

  final Widget? child;

  /// Seconds per loop of the motion.
  static const period = 30.0;

  /// Off in tests (see `test/flutter_test_config.dart`), so screens settle.
  static bool animate = true;

  static Future<ui.FragmentProgram>? _program;

  /// Loaded once and shared by every screen.
  static Future<ui.FragmentProgram> get program => _program ??= ui.FragmentProgram.fromAsset('shaders/flow.frag');

  /// One shared clock, so the flow carries on across screens.
  static final _clock = Stopwatch()..start();

  /// Where the flow is now, in seconds.
  static double get now => _clock.elapsedMicroseconds / 1e6;

  @override
  State<FlowBackground> createState() => _FlowBackgroundState();
}

class _FlowBackgroundState extends State<FlowBackground> {
  ui.FragmentShader? _shader;
  Timer? _timer;
  final _time = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    FlowBackground.program.then((p) {
      if (mounted) setState(() => _shader = p.fragmentShader());
    }, onError: (Object _) {
      // No shader (an old renderer): the still gradient stays.
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final moving = FlowBackground.animate &&
        TickerMode.valuesOf(context).enabled &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (moving && _timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
      _tick();
    } else if (!moving) {
      _timer?.cancel();
      _timer = null;
      _tick();
    }
  }

  void _tick() => _time.value = FlowBackground.now;

  @override
  void dispose() {
    _timer?.cancel();
    _time.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    return Stack(fit: StackFit.passthrough, children: [
      Positioned.fill(
        // Its own layer: what moves on top doesn't repaint it, and it
        // doesn't repaint what's on top.
        child: RepaintBoundary(
          child: CustomPaint(painter: FlowPainter(_shader, _time, dpr)),
        ),
      ),
      if (widget.child != null) widget.child!,
    ]);
  }
}

/// Paints one moment of the flow, or the still gradient without a shader.
class FlowPainter extends CustomPainter {
  FlowPainter(this.shader, this.time, this.dpr) : super(repaint: time);

  final ui.FragmentShader? shader;
  final ValueNotifier<double> time;
  final double dpr;

  /// Before the shader loads, or if it can't: the same colours, still.
  static const _fallback = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Palette.butter, Palette.plumDark, Palette.plum, Palette.rose, Palette.lavender],
    stops: [0, 0.35, 0.55, 0.78, 1],
  );

  @override
  void paint(Canvas canvas, Size size) {
    paintFlow(canvas, size, shader, time.value, dpr);
  }

  /// Also used to save the background as a still wallpaper.
  static void paintFlow(Canvas canvas, Size size, ui.FragmentShader? shader, double t, double grain) {
    final rect = Offset.zero & size;
    if (shader == null) {
      canvas.drawRect(rect, Paint()..shader = _fallback.createShader(rect));
      return;
    }
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, t)
      ..setFloat(3, FlowBackground.period)
      ..setFloat(4, grain);
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(FlowPainter old) => old.shader != shader || old.dpr != dpr;
}
