import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../motion.dart';
import '../theme.dart';

abstract final class Assets {
  static const bgSoft = 'assets/images/bg_soft.jpg';
  static const bgMain = 'assets/images/bg_main.jpg';
  static const paper = 'assets/images/calendar_paper.png';
  static const logo = 'assets/images/logo.svg';

  /// Just the handwriting, without the clock face (Goals screen).
  static const logoScript = 'assets/images/logo_script.svg';
}

/// Lays out [child] on a fixed artboard of [size] points (the design's own
/// coordinates) and scales it uniformly to fit the screen. Everything is drawn
/// as vectors/text at the final scale, so it stays sharp on any density.
class DesignCanvas extends StatelessWidget {
  const DesignCanvas({
    super.key,
    required this.size,
    required this.child,
    this.alignment = Alignment.center,
  });

  final Size size;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    // SizedBox.expand: FittedBox only scales when its own size is forced.
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: alignment,
        child: MediaQuery.withClampedTextScaling(
          // The phone's text size, up to 130%: past that the design's boxes can't hold it.
          maxScaleFactor: 1.3,
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    );
  }
}

/// Lays [child] out at the box's width and its own height, then shrinks it
/// to fit the box when needed: with a large text size, a fixed design box
/// shows smaller text instead of overflowing.
class ShrinkToFit extends StatelessWidget {
  const ShrinkToFit({super.key, required this.child, this.alignment = Alignment.topLeft});

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: SizedBox(width: c.maxWidth, child: child),
        ),
      );
}

/// Full-bleed grainy gradient background.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.image, required this.child});

  final String image;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
      child: child,
    );
  }
}

class ClockItLogo extends StatelessWidget {
  const ClockItLogo({super.key, required this.size, this.hero = true});

  final double size;

  /// Flies between the splash and welcome screens. Off for the small logo
  /// on inner screens, so two never share the tag.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(Assets.logo, width: size, height: size);
    return hero ? Hero(tag: 'logo', child: logo) : logo;
  }
}

/// Dips while pressed and springs back with a slight overshoot on release,
/// with a light haptic tap. Reachable
/// with the keyboard (Tab, then Enter or Space), with a visible focus ring,
/// and dims a little under a mouse pointer.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.longPressHint,
    this.semanticLabel,
    this.selected,
    this.focusRadius = 12.8,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// What a long press does, for screen readers ("Edit goal").
  final String? longPressHint;

  /// Replaces what the child would read out, so it isn't read twice.
  final String? semanticLabel;

  /// For choices like the timer chips: read out as selected or not.
  final bool? selected;
  final double focusRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false, _hover = false, _focus = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  void _tap() {
    HapticFeedback.lightImpact();
    widget.onTap!();
  }

  Object? _activate() {
    if (widget.onTap != null) _tap();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.semanticLabel;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: label,
      onLongPressHint: widget.longPressHint,
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        mouseCursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {
          // Space, and Enter on phones and desktop.
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _activate()),
          // Enter on the web.
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => _activate()),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onTap == null ? null : _tap,
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: _down ? 0.95 : 1,
            // Quick dip in, slower springy settle out.
            duration: _down ? const Duration(milliseconds: 90) : Motion.standard,
            curve: _down ? Curves.easeOut : Motion.pop,
            child: AnimatedOpacity(
              opacity: _hover && !_down ? 0.88 : 1,
              duration: const Duration(milliseconds: 120),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.focusRadius),
                  border: _focus ? Border.all(color: const Color(0xFF1F2E4D), width: 3) : null,
                ),
                child: label == null ? widget.child : ExcludeSemantics(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded, softly transparent button used across the design.
class DesignButton extends StatelessWidget {
  const DesignButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.radius = 12,
    this.fontSize = 25,
    this.fontWeight = FontWeight.w400,
    this.textColor,
    this.subtitle,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final double radius;
  final double fontSize;
  final FontWeight fontWeight;

  /// Defaults to whatever reads on [color].
  final Color? textColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textColor = this.textColor ?? onColor(color);
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      focusRadius: radius,
      child: AnimatedContainer(
        duration: Motion.standard,
        curve: Motion.ease,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: textColor,
                height: 1.05,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: fontSize * 0.46,
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1.1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
