import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../strings.dart';
import 'common.dart';

/// A screen's title in a pill that ends under the logo, like "STUDY HOURS"
/// in the design. The pill fits the text and the pair stays centred; a long
/// title first shrinks the logo, then its own font, so the logo never
/// covers a letter. Lays out on a [width] × [maxLogo] design-point strip.
class TitleHeader extends StatelessWidget {
  const TitleHeader({super.key, required this.text, required this.color, this.width = 314, this.onEdit});

  final String text;
  final Color color;
  final double width;

  /// When set, the pill shows a pencil and tapping it edits (the goal).
  final VoidCallback? onEdit;

  static const _pencil = 22.0; // icon plus its gap

  static const maxLogo = 104.0;
  static const _minLogo = 70.0;
  static const _maxFont = 25.0, _minFont = 13.0;
  static const _margin = 20.0; // to the screen edges
  static const _padLeft = 15.5; // pill edge to text
  static const _gap = 8.0; // text to the logo's clock face

  static TextStyle _style(double size) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: Palette.navyText, height: 1);

  @override
  Widget build(BuildContext context) {
    // Measured in the app's font, not the platform default.
    final base = DefaultTextStyle.of(context).style;
    double textWidth(double size) => (TextPainter(
          text: TextSpan(text: text, style: base.merge(_style(size))),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout())
            .width;

    final room = width - 2 * _margin;
    final extra = onEdit == null ? 0.0 : _pencil;
    double groupWidth(double font, double logo) => _padLeft + textWidth(font) + extra + _gap + logo;

    var font = _maxFont, logo = maxLogo;
    while (groupWidth(font, logo) > room && logo > _minLogo) {
      logo = max(_minLogo, logo - 2);
    }
    while (groupWidth(font, logo) > room && font > _minFont) {
      font -= 0.5;
    }
    final group = min(room, groupWidth(font, logo));
    final left = (width - group) / 2;
    const centerY = maxLogo / 2;
    final pillHeight = max(36.0, font * 2);
    final logoLeft = left + group - logo;

    return SizedBox(
      width: width,
      height: maxLogo,
      child: Stack(children: [
        Positioned(
          left: left,
          top: centerY - pillHeight / 2,
          // Runs under the logo to its centre.
          width: logoLeft + logo / 2 - left,
          height: pillHeight,
          child: _pill(font, logo),
        ),
        Positioned(
          left: logoLeft,
          top: centerY - logo / 2,
          child: Opacity(opacity: 0.85, child: ClockItLogo(size: logo, hero: false)),
        ),
      ]),
    );
  }

  Widget _pill(double font, double logo) {
    final title = Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: _style(font));
    final pill = Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12.8),
      ),
      padding: EdgeInsets.only(left: _padLeft, right: _gap + logo / 2),
      alignment: Alignment.centerLeft,
      child: onEdit == null
          ? title
          : Row(children: [
              Flexible(child: title),
              const SizedBox(width: 6),
              const Icon(Icons.edit_outlined, size: _pencil - 6, color: Palette.navyText),
            ]),
    );
    final heading = Semantics(header: true, label: text, child: ExcludeSemantics(child: pill));
    if (onEdit == null) return heading;
    return Pressable(onTap: onEdit, semanticLabel: '$text. ${Str.editGoal}', child: pill);
  }
}
