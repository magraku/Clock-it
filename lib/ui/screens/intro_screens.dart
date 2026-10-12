import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../state/app_state.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

/// Artboard of the first two screens in the design, in points.
const _introSize = Size(314, 619);
const _logoSize = 222.4;

Route<void> fadeRoute(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
    );

/// Screen 1: logo over the soft background while data loads.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final minimum = Future<void>.delayed(const Duration(milliseconds: 1300));
    await widget.state.load();
    final seen = await widget.state.hasSeenWelcome();
    if (!mounted) return;
    await Future.wait([
      precacheImage(const AssetImage(Assets.bgMain), context),
      precacheImage(const AssetImage(Assets.paper), context),
      minimum,
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(
      seen ? HomeScreen(state: widget.state) : WelcomeScreen(state: widget.state),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(Assets.bgSoft), context);
    // Warm up the SVG so the Hero flight doesn't flash.
    const loader = SvgAssetLoader(Assets.logo);
    svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Backdrop(
        image: Assets.bgSoft,
        child: DesignCanvas(
          size: _introSize,
          child: Stack(children: [
            Positioned(
              left: 43.6,
              top: 191.4,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (_, t, child) => Opacity(
                  opacity: t.clamp(0, 1),
                  child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
                ),
                child: const ClockItLogo(size: _logoSize),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Screen 2: Log in / Sign in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.state});

  final AppState state;

  Future<void> _continue(BuildContext context) async {
    // TODO(firebase): real authentication. For now the data stays on this
    // phone and both buttons just open the app.
    await state.markWelcomeSeen();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(HomeScreen(state: state)));
  }

  @override
  Widget build(BuildContext context) {
    final pink = Palette.pink.withValues(alpha: 0.75);
    return Scaffold(
      body: Backdrop(
        image: Assets.bgSoft,
        child: DesignCanvas(
          size: _introSize,
          child: Stack(children: [
            const Positioned(left: 44.4, top: 126.9, child: ClockItLogo(size: _logoSize)),
            Positioned(
              left: 35.4,
              top: 414.6,
              width: 243.3,
              height: 46.6,
              child: DesignButton(
                label: Str.logIn,
                color: pink,
                radius: 9.4,
                onTap: () => _continue(context),
              ),
            ),
            Positioned(
              left: 35.4,
              top: 482.5,
              width: 243.3,
              height: 46.6,
              child: DesignButton(
                label: Str.signIn,
                color: pink,
                radius: 9.4,
                onTap: () => _continue(context),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
