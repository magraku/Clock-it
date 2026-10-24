import 'package:flutter/material.dart';

import '../motion.dart';
import '../strings.dart';
import '../theme.dart';
import 'common.dart';

enum AppTab { goals, home, profile }

/// Pink bottom bar from the design (314 × 60 artboard), full width.
/// Navy throughout (white failed contrast on pink); the current tab sits on
/// a light pill and its label is bold. The pill slides to a newly picked tab
/// and settles with a slight spring; that tab's icon lifts and pops.
class NavBar extends StatelessWidget {
  const NavBar({super.key, required this.current, required this.onTap});

  static const designSize = Size(314, 60);

  /// Left edge of each tab, in design points.
  static const _lefts = {AppTab.goals: 26.0, AppTab.home: 125.0, AppTab.profile: 220.0};

  final AppTab current;
  final ValueChanged<AppTab> onTap;

  /// Height on this screen, so pages can leave room for it.
  static double heightOf(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / designSize.width;
    return designSize.height * s + MediaQuery.paddingOf(context).bottom * 0.35;
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / designSize.width;
    return Container(
      height: heightOf(context),
      // Square corners: a full-width bar, edge to edge.
      color: Palette.pink.withValues(alpha: 0.75),
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: designSize.height * s,
        child: DesignCanvas(
          size: designSize,
          child: Stack(children: [
            AnimatedPositioned(
              left: _lefts[current],
              top: 4,
              width: 60,
              height: 52,
              duration: Motion.slow,
              curve: Motion.pop,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12.8),
                ),
              ),
            ),
            _item(AppTab.goals, Str.tabGoals, (c) => CustomPaint(size: const Size(22, 20.2), painter: _ShelfPainter(c))),
            _item(AppTab.home, Str.tabHome, (c) => Icon(Icons.home, size: 27, color: c)),
            _item(AppTab.profile, Str.tabProfile, (c) => Icon(Icons.person, size: 29, color: c)),
          ]),
        ),
      ),
    );
  }

  Widget _item(AppTab tab, String label, Widget Function(Color) icon) {
    final selected = tab == current;
    return Positioned(
      left: _lefts[tab],
      top: 4,
      width: 60,
      height: 52,
      child: Pressable(
        onTap: () => onTap(tab),
        selected: selected,
        semanticLabel: label,
        child: Column(children: [
          SizedBox(
            height: 34,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AnimatedSlide(
                  offset: Offset(0, selected ? -0.06 : 0),
                  duration: Motion.standard,
                  curve: Motion.pop,
                  child: AnimatedScale(
                    scale: selected ? 1.1 : 1,
                    duration: Motion.standard,
                    curve: Motion.pop,
                    child: icon(Palette.navyText),
                  ),
                ),
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                color: Palette.navyText,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                height: 1,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The "Goals" icon: two upright books and one leaning.
class _ShelfPainter extends CustomPainter {
  _ShelfPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final h = size.height;
    const r = Radius.circular(0.4);
    canvas.drawRRect(RRect.fromLTRBR(0, 0, 4.6, h, r), p);
    canvas.drawRRect(RRect.fromLTRBR(6.2, 0, 10.8, h, r), p);
    canvas.drawPath(
      Path()
        ..moveTo(11.5, 0.6)
        ..lineTo(15.9, 0)
        ..lineTo(21.3, h)
        ..lineTo(16.8, h)
        ..close(),
      p,
    );
  }

  @override
  bool shouldRepaint(_ShelfPainter old) => old.color != color;
}
