import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app's motion identity: one signature curve, three durations and one
/// entrance (rise + fade). Paper-like: quick, light, a touch of overshoot.
abstract final class Motion {
  static const quick = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 480);

  /// Signature curve for on-screen changes.
  static const ease = Cubic(0.2, 0, 0, 1);

  /// Things arriving: fast start, soft landing.
  static const enter = Cubic(0.05, 0.7, 0.1, 1);

  /// Things leaving: gentle start, quick departure.
  static const exit = Cubic(0.3, 0, 1, 1);

  /// Small overshoot for releases and confirmations.
  static const pop = Cubic(0.175, 0.885, 0.32, 1.275);

  /// Respects the system "reduce motion" setting.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Rises [offset] points and fades in once, after [delay].
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 14,
    this.duration = Motion.slow,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  // The delay is the first stretch of one longer run, so no timer is left
  // behind if the widget goes away early.
  late final _c = AnimationController(vsync: this, duration: widget.delay + widget.duration)..forward();
  late final _t = CurvedAnimation(
    parent: _c,
    curve: Interval(widget.delay.inMicroseconds / _c.duration!.inMicroseconds, 1, curve: Motion.enter),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (_, child) => Opacity(
        opacity: _t.value.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - _t.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Shakes sideways each time [trigger] changes to a non-null value (e.g. a
/// new error message): three shrinking swings.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child, this.distance = 10});

  final Object? trigger;
  final Widget child;
  final double distance;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    final fresh = widget.trigger != null && old.trigger != widget.trigger;
    if (fresh && !Motion.reduced(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        final dx = math.sin(t * math.pi * 6) * (1 - t) * widget.distance;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Repeats [builder] with a 0→1 phase while [active]; idle otherwise, so
/// screens can still settle.
class Loop extends StatefulWidget {
  const Loop({
    super.key,
    required this.active,
    required this.builder,
    this.period = const Duration(milliseconds: 1800),
  });

  final bool active;
  final Duration period;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<Loop> createState() => _LoopState();

  /// 0→1→0 sine over one phase, for breathing.
  static double pulse(double t) => (1 - math.cos(t * 2 * math.pi)) / 2;
}

class _LoopState extends State<Loop> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.period);

  void _sync() {
    if (widget.active && !Motion.reduced(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Loop old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => widget.builder(context, _c.value),
    );
  }
}
