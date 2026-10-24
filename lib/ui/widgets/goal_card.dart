import 'package:flutter/material.dart';

import '../../models/goals.dart';
import '../strings.dart';
import '../theme.dart';
import 'common.dart';

enum CardShape { rect, notchTopRight, notchTopLeft }

/// One card slot on the Goals screen, in design points.
class CardSlot {
  const CardSlot(
    this.rect, {
    this.shape = CardShape.rect,
    this.notch = Size.zero,
    required this.textAlign,
    required this.alignment,
    required this.padding,
  });

  final Rect rect;
  final CardShape shape;

  /// Width and depth of the corner cut out of an L-shaped card.
  final Size notch;
  final TextAlign textAlign;
  final Alignment alignment;
  final EdgeInsets padding;

  /// The solid parts of the card, for keeping cards apart.
  List<Rect> parts(Offset at) {
    final r = rect.shift(at);
    return switch (shape) {
      CardShape.rect => [r],
      CardShape.notchTopRight => [
          Rect.fromLTRB(r.left, r.top, r.left + r.width - notch.width, r.bottom),
          Rect.fromLTRB(r.left, r.top + notch.height, r.right, r.bottom),
        ],
      CardShape.notchTopLeft => [
          Rect.fromLTRB(r.left + notch.width, r.top, r.right, r.bottom),
          Rect.fromLTRB(r.left, r.top + notch.height, r.right, r.bottom),
        ],
    };
  }
}

/// Rounded card, optionally with one top corner cut out (with soft inner
/// and outer corners), like "GYM TIME" and "ME TIME" in the design.
class GoalCardBorder extends ShapeBorder {
  const GoalCardBorder({this.shape = CardShape.rect, this.notch = Size.zero, this.radius = 12.8});

  final CardShape shape;
  final Size notch;
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    if (shape == CardShape.rect) {
      return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    }
    final w = rect.width, h = rect.height, nx = w - notch.width, ny = notch.height;
    final R = Radius.circular(radius);
    const ri = 10.0;
    const r = Radius.circular(ri);
    // Notch at the top right; mirrored for the top left.
    final path = Path()
      ..moveTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: R)
      ..lineTo(nx - ri, 0)
      ..arcToPoint(Offset(nx, ri), radius: r)
      ..lineTo(nx, ny - ri)
      ..arcToPoint(Offset(nx + ri, ny), radius: r, clockwise: false)
      ..lineTo(w - radius, ny)
      ..arcToPoint(Offset(w, ny + radius), radius: R)
      ..lineTo(w, h - radius)
      ..arcToPoint(Offset(w - radius, h), radius: R)
      ..lineTo(radius, h)
      ..arcToPoint(Offset(0, h - radius), radius: R)
      ..close();
    final flip = shape == CardShape.notchTopLeft
        ? (Matrix4.diagonal3Values(-1, 1, 1)..setTranslationRaw(w, 0, 0))
        : Matrix4.identity();
    return path.transform(flip.storage).shift(rect.topLeft);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => GoalCardBorder(shape: shape, notch: notch * t, radius: radius * t);
}

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.slot,
    required this.isHome,
    required this.onTap,
    required this.onLongPress,
  });

  final Goal goal;
  final CardSlot slot;
  final bool isHome;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      longPressHint: Str.editGoal,
      semanticLabel: '${goal.name}${isHome ? ', ${Str.onHome}' : ''}',
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: goal.color.color.withValues(alpha: 0.8),
          shape: GoalCardBorder(shape: slot.shape, notch: slot.notch),
        ),
        child: Stack(children: [
          Positioned.fill(
            child: Padding(
              padding: slot.padding,
              child: Align(
                alignment: slot.alignment,
                child: FitText(
                  // One word per line, as in the design ("GYM / TIME").
                  goal.name.toUpperCase().split(RegExp(r'\s+')).join('\n'),
                  textAlign: slot.textAlign,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: Palette.navyText,
                    height: 0.92,
                  ),
                ),
              ),
            ),
          ),
          if (isHome)
            const Positioned(
              right: 9,
              bottom: 9,
              child: Icon(Icons.home, color: Palette.navyText, size: 26),
            ),
        ]),
      ),
    );
  }
}

/// Wraps by words and shrinks the font until the text fits its box.
class FitText extends StatelessWidget {
  const FitText(this.text, {super.key, required this.style, this.textAlign = TextAlign.left, this.maxLines = 4});

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    // Measured in the app's font, not the platform default.
    final style = DefaultTextStyle.of(context).style.merge(this.style);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(builder: (context, c) {
      var size = style.fontSize ?? 14;
      while (size > 9) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: style.copyWith(fontSize: size)),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          textAlign: textAlign,
          maxLines: maxLines,
        )..layout(maxWidth: c.maxWidth);
        final wordsFit = !text.split(RegExp(r'\s+')).any((w) {
          final wp = TextPainter(
              text: TextSpan(text: w, style: style.copyWith(fontSize: size)),
              textDirection: TextDirection.ltr,
              textScaler: scaler)
            ..layout();
          return wp.width > c.maxWidth;
        });
        if (!tp.didExceedMaxLines && tp.height <= c.maxHeight && wordsFit) break;
        size -= 1;
      }
      return Text(text, textAlign: textAlign, maxLines: maxLines, style: style.copyWith(fontSize: size));
    });
  }
}
