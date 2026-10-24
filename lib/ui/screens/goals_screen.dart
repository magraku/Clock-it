import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/goals.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../sheets.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/goal_card.dart';
import '../widgets/nav_bar.dart';

/// Design points (314 wide); 12 pt less than the artboard at the top,
/// where the status bar is.
const _width = 314.0;
const _createButton = Rect.fromLTWH(42.8, 20.7, 229.6, 89.1);

/// The four cards of the design ("STUDY HOURS", "SFP", "GYM TIME",
/// "ME TIME"); more goals repeat the pattern further down.
const _slots = [
  CardSlot(
    Rect.fromLTWH(20.3, 128.5, 105.6, 112.5),
    textAlign: TextAlign.center,
    alignment: Alignment.center,
    padding: EdgeInsets.all(8),
  ),
  CardSlot(
    Rect.fromLTWH(146.8, 142.4, 140.1, 120.8),
    textAlign: TextAlign.center,
    alignment: Alignment(0, 0.45),
    padding: EdgeInsets.fromLTRB(12, 10, 12, 30),
  ),
  CardSlot(
    Rect.fromLTWH(42.8, 252.2, 134.6, 103.5),
    shape: CardShape.notchTopRight,
    notch: Size(64.9, 32.5),
    textAlign: TextAlign.left,
    alignment: Alignment(-1, 0.55),
    padding: EdgeInsets.fromLTRB(17, 36, 12, 10),
  ),
  CardSlot(
    Rect.fromLTWH(171.4, 310.3, 104.1, 134.6),
    shape: CardShape.notchTopLeft,
    notch: Size(33, 64.7),
    textAlign: TextAlign.right,
    alignment: Alignment(1, 0.3),
    padding: EdgeInsets.fromLTRB(10, 68, 9, 30),
  ),
];
const _gap = 12.0;

/// The design's four cards first; every further goal reuses the next shape
/// in turn and sits as high as it can without coming within [_gap] of
/// another card, so the column stays packed with no big holes.
List<CardSlot> _layout(int count) {
  final slots = <CardSlot>[];
  for (var i = 0; i < count; i++) {
    final t = _slots[i % _slots.length];
    if (i < _slots.length) {
      slots.add(t);
      continue;
    }
    slots.add(_at(t, _lowestFree(t, slots, slots.length)));
  }
  // Spread leftover space: cards with room below move to the middle of it,
  // so a hole becomes two small gaps instead of one big one.
  for (var pass = 0; pass < 4; pass++) {
    for (var i = _slots.length; i < count; i++) {
      final lo = _lowestFree(slots[i], slots, i);
      final hi = _highestFree(slots[i], slots, i);
      if (hi != null && hi > lo) slots[i] = _at(slots[i], (lo + hi) / 2);
    }
  }
  return slots;
}

CardSlot _at(CardSlot t, double top) => CardSlot(
      Rect.fromLTWH(t.rect.left, top, t.rect.width, t.rect.height),
      shape: t.shape,
      notch: t.notch,
      textAlign: t.textAlign,
      alignment: t.alignment,
      padding: t.padding,
    );

bool _sideBySide(Rect a, Rect b) => a.left < b.right + _gap && b.left < a.right + _gap;

/// The highest top for [t] that clears the cards before index [upTo].
double _lowestFree(CardSlot t, List<CardSlot> slots, int upTo) {
  var top = 0.0;
  final mine = _at(t, 0).parts(Offset.zero);
  for (var j = 0; j < upTo; j++) {
    for (final a in mine) {
      for (final b in slots[j].parts(Offset.zero)) {
        if (_sideBySide(a, b)) top = max(top, b.bottom + _gap - a.top);
      }
    }
  }
  return top;
}

/// The lowest top for [slots][i] that stays clear of the cards after it.
double? _highestFree(CardSlot t, List<CardSlot> slots, int i) {
  double? top;
  final mine = _at(t, 0).parts(Offset.zero);
  for (var j = i + 1; j < slots.length; j++) {
    for (final a in mine) {
      for (final b in slots[j].parts(Offset.zero)) {
        if (_sideBySide(a, b)) top = min(top ?? double.infinity, b.top - _gap - a.bottom);
      }
    }
  }
  return top;
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key, required this.state, required this.onOpenGoal});

  final AppState state;
  final ValueChanged<Goal> onOpenGoal;

  Future<void> _create(BuildContext context) async {
    final goal = await showGoalEditor(context, state);
    if (goal != null) onOpenGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    return Backdrop(
      image: Assets.bgSoft,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, c) {
          final s = c.maxWidth / _width;
          return ListenableBuilder(
            listenable: state,
            builder: (context, _) {
              final goals = state.goals;
              final slots = _layout(goals.length);
              final cardsBottom = slots.map((e) => e.rect.bottom).reduce(max);
              final logo = Rect.fromLTWH(61.6, cardsBottom - 16, 219.9, 123.1);
              final height = max(logo.bottom + 8, c.maxHeight / s - NavBar.heightOf(context) / s);
              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: NavBar.heightOf(context)),
                child: SizedBox(
                  width: c.maxWidth,
                  height: height * s,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    child: MediaQuery.withClampedTextScaling(
                      // The phone's text size, up to 130%: past that the design's boxes can't hold it.
                      maxScaleFactor: 1.3,
                      child: SizedBox(
                        width: _width,
                        height: height,
                        child: Stack(children: [
                          Positioned.fromRect(
                            rect: logo,
                            child: ExcludeSemantics(child: SvgPicture.asset(Assets.logoScript)),
                          ),
                          Positioned.fromRect(
                            rect: _createButton,
                            child: Entrance(
                              child: DesignButton(
                                label: Str.createGoal,
                                color: Palette.pink.withValues(alpha: 0.8),
                                radius: 12.8,
                                fontWeight: FontWeight.w600,
                                onTap: () => _create(context),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: _FloatingCards(
                              goals: goals,
                              slots: slots,
                              homeId: state.home.id,
                              onTap: onOpenGoal,
                              onLongPress: (g) => showGoalEditor(context, state, goal: g),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// The cards drift gently around their place and nudge each other away
/// when they get close, so they seem to react to one another without ever
/// touching. They hold still while a finger is down (and a moment after),
/// under a mouse pointer, with a screen reader on, and when the system asks
/// for reduced motion, so they're easy to hit.
class _FloatingCards extends StatefulWidget {
  const _FloatingCards({
    required this.goals,
    required this.slots,
    required this.homeId,
    required this.onTap,
    required this.onLongPress,
  });

  final List<Goal> goals;
  final List<CardSlot> slots;
  final String homeId;
  final ValueChanged<Goal> onTap;
  final ValueChanged<Goal> onLongPress;

  @override
  State<_FloatingCards> createState() => _FloatingCardsState();
}

class _FloatingCardsState extends State<_FloatingCards> with SingleTickerProviderStateMixin {
  static const _drift = 5.0; // how far a card wanders, in points
  static const _minGap = 9.0; // closer than this and they push apart

  late final Ticker _ticker = createTicker(_tick);
  static const _settle = Duration(milliseconds: 1500);
  int _touches = 0;
  bool _hovered = false;
  DateTime _heldUntil = DateTime(0);

  bool get _held => _touches > 0 || _hovered || DateTime.now().isBefore(_heldUntil);

  void _touch(bool down) {
    _touches = down ? _touches + 1 : max(0, _touches - 1);
    if (!down) _heldUntil = DateTime.now().add(_settle);
  }

  final _offsets = ValueNotifier<List<Offset>>([]);
  List<Offset> _vel = [];
  Duration _last = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context) || MediaQuery.accessibleNavigationOf(context);
    if (still && _ticker.isActive) {
      _ticker.stop();
      _offsets.value = List.filled(widget.slots.length, Offset.zero);
    } else if (!still && !_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _offsets.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final n = widget.slots.length;
    var pos = _offsets.value;
    if (pos.length != n) {
      pos = List.filled(n, Offset.zero);
      _vel = List.filled(n, Offset.zero);
    }
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;
    if (_held) {
      _vel = List.filled(n, Offset.zero);
      if (_offsets.value.length != n) _offsets.value = pos;
      return;
    }
    final t = elapsed.inMicroseconds / 1e6;

    final next = List<Offset>.of(pos);
    for (var i = 0; i < n; i++) {
      // Each card wanders on its own slow loop...
      final target = Offset(
        _drift * sin(t * (0.31 + 0.07 * i) + i * 1.7),
        _drift * cos(t * (0.23 + 0.05 * i) + i * 2.3),
      );
      var force = (target - pos[i]) * 2.2 - _vel[i] * 1.6;
      // ...and is pushed back by any card that comes too close.
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        final push = _repulsion(widget.slots[i].parts(pos[i]), widget.slots[j].parts(pos[j]));
        force += push * 40;
      }
      _vel[i] += force * dt;
      next[i] = pos[i] + _vel[i] * dt;
    }
    _offsets.value = next;
  }

  /// Direction and strength to move [a] away from [b] when nearer than [_minGap].
  static Offset _repulsion(List<Rect> a, List<Rect> b) {
    var total = Offset.zero;
    for (final ra in a) {
      for (final rb in b) {
        final dx = max(0.0, max(rb.left - ra.right, ra.left - rb.right));
        final dy = max(0.0, max(rb.top - ra.bottom, ra.top - rb.bottom));
        final gap = sqrt(dx * dx + dy * dy);
        if (gap >= _minGap) continue;
        final away = ra.center - rb.center;
        final len = away.distance;
        if (len == 0) continue;
        total += away / len * ((_minGap - gap) / _minGap);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _touch(true),
      onPointerUp: (_) => _touch(false),
      onPointerCancel: (_) => _touch(false),
      child: MouseRegion(
        // Only over the cards, and never in the way of taps elsewhere.
        opaque: false,
        hitTestBehavior: HitTestBehavior.deferToChild,
        onEnter: (_) => _hovered = true,
        onExit: (_) => _hovered = false,
        child: _cards(),
      ),
    );
  }

  Widget _cards() {
    return ValueListenableBuilder<List<Offset>>(
      valueListenable: _offsets,
      builder: (context, offsets, _) => Stack(children: [
        for (var i = 0; i < widget.goals.length; i++)
          Positioned.fromRect(
            rect: widget.slots[i].rect.shift(i < offsets.length ? offsets[i] : Offset.zero),
            // Cards rise in one after another (a new goal just rises in).
            child: Entrance(
              key: ValueKey(widget.goals[i].id),
              delay: Duration(milliseconds: 80 + 60 * min(i, 5)),
              child: GoalCard(
                goal: widget.goals[i],
                slot: widget.slots[i],
                isHome: widget.goals[i].id == widget.homeId,
                onTap: () => widget.onTap(widget.goals[i]),
                onLongPress: () => widget.onLongPress(widget.goals[i]),
              ),
            ),
          ),
      ]),
    );
  }
}
