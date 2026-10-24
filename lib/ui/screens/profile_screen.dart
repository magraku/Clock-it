import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../motion.dart';
import '../sheets.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/nav_bar.dart';
import '../widgets/title_header.dart';
import 'history_screen.dart';

/// Not in the design: built like a goal's screen (title pill and logo, then
/// cards) with the account, the backup and leaving.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state, required this.onLogOut, required this.onDeleteAccount});

  final AppState state;
  final VoidCallback onLogOut;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final email = state.account?.email ?? '';
    return Backdrop(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: NavBar.heightOf(context)),
          child: DesignCanvas(
            size: const Size(314, 600),
            alignment: Alignment.topCenter,
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) => Stack(children: [
                Positioned(
                    left: 0, top: 0, child: TitleHeader(text: Str.tabProfile.toUpperCase(), color: Palette.rose)),
                Positioned(
                  left: 25.1,
                  top: 124.8,
                  width: 271.5,
                  height: 104,
                  child: Entrance(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Palette.rose.withValues(alpha: Surface.alpha),
                        boxShadow: Surface.shadow,
                        borderRadius: BorderRadius.circular(12.8),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: ShrinkToFit(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Str.signedInAs, style: const TextStyle(fontSize: 14, color: Palette.ink)),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                email,
                                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: Palette.ink),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(Str.goalCount(state.goals.length),
                                style: const TextStyle(fontSize: 14, color: Palette.ink)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 25.1,
                  top: 244,
                  width: 271.5,
                  // The rows cascade in under the account card.
                  child: Column(children: [
                    for (final (i, row) in [
                      _Row(
                        icon: Icons.history,
                        label: Str.history,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => HistoryScreen(state: state)),
                        ),
                      ),
                      _Row(
                          icon: Icons.wallpaper, label: Str.wallpaper, onTap: () => showWallpaperSheet(context, state)),
                      _Row(
                          icon: Icons.save_alt_outlined, label: Str.backup, onTap: () => showBackupSheet(context, state)),
                      _Row(icon: Icons.logout, label: Str.logOut, onTap: onLogOut),
                      _Row(
                        icon: Icons.person_remove_outlined,
                        label: Str.deleteAccount,
                        onTap: onDeleteAccount,
                        color: Palette.berry,
                      ),
                    ].indexed) ...[
                      if (i > 0) const SizedBox(height: 10),
                      Entrance(delay: Duration(milliseconds: 60 + 50 * i), child: row),
                    ],
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap, this.color = Palette.ink});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Palette.butter.withValues(alpha: Surface.alpha),
          boxShadow: Surface.shadow,
          borderRadius: BorderRadius.circular(12.8),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
