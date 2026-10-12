import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class Assets {
  static const bgSoft = 'assets/images/bg_soft.jpg';
  static const bgMain = 'assets/images/bg_main.jpg';
  static const paper = 'assets/images/calendar_paper.png';
  static const logo = 'assets/images/logo.svg';
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
        child: MediaQuery.withNoTextScaling(
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    );
  }
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
  const ClockItLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'logo',
      child: SvgPicture.asset(Assets.logo, width: size, height: size),
    );
  }
}

/// Shrinks slightly while pressed and gives a light haptic tap.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
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
    this.textColor = Colors.white,
    this.subtitle,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final double radius;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
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
