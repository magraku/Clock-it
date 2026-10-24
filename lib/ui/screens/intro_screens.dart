import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../state/app_state.dart';
import '../../state/session.dart';
import '../motion.dart';
import '../sheets.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

/// Artboard of the first two screens in the design, in points.
const _introSize = Size(314, 619);
const _logoSize = 222.4;

Route<void> fadeRoute(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
    );

/// Opens the main screen for a signed-in account.
void goHome(BuildContext context, Services services, AppState state) {
  Navigator.of(context).pushAndRemoveUntil(
    fadeRoute(MainShell(services: services, state: state)),
    (_) => false,
  );
}

/// Screen 1: logo over the soft background while data loads.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.services});

  final Services services;

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
    final services = widget.services;
    final account = await services.accounts.restore();
    final state = account == null ? null : await services.open(account);
    if (!mounted) return;
    await Future.wait([
      precacheImage(const AssetImage(Assets.bgMain), context),
      precacheImage(const AssetImage(Assets.paper), context),
      minimum,
    ]);
    if (!mounted) return;
    if (state != null) {
      goHome(context, services, state);
    } else {
      Navigator.of(context).pushReplacement(fadeRoute(WelcomeScreen(services: services)));
    }
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

/// Screen 2: Log in (existing account) / Sign in (new account).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.services});

  final Services services;

  Future<void> _continue(BuildContext context, {required bool signUp}) async {
    final state = await showAccountSheet(context, services, signUp: signUp);
    if (state == null || !context.mounted) return;
    goHome(context, services, state);
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
              // The buttons rise in once the logo has landed.
              child: Entrance(
                delay: const Duration(milliseconds: 380),
                child: DesignButton(
                  label: Str.logIn,
                  color: pink,
                  radius: 9.4,
                  onTap: () => _continue(context, signUp: false),
                ),
              ),
            ),
            Positioned(
              left: 35.4,
              top: 482.5,
              width: 243.3,
              height: 46.6,
              child: Entrance(
                delay: const Duration(milliseconds: 460),
                child: DesignButton(
                  label: Str.signUp,
                  color: pink,
                  radius: 9.4,
                  onTap: () => _continue(context, signUp: true),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
