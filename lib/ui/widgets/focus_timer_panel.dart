import 'package:flutter/material.dart';

import '../../models/goals.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../strings.dart';
import '../theme.dart';
import 'common.dart';
import 'hourglass.dart';

class FocusTimerPanel extends StatelessWidget {
  const FocusTimerPanel(
      {super.key,
      required this.state,
      required this.goal,
      required this.minutes,
      required this.onPick,
      required this.onToggle,
      required this.onStop,
      required this.onMoon});

  final AppState state;
  final Goal goal;
  final int minutes;
  final ValueChanged<int> onPick;
  final VoidCallback onToggle, onStop, onMoon;

  @override
  Widget build(BuildContext context) {
    final timer = goal.timer;
    final running = timer?.running ?? false;
    final left = timer?.remainingMs(state.now.millisecondsSinceEpoch) ?? minutes * 60000;
    final seconds = (left / 1000).ceil();
    final time = '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final action = timer == null
        ? Str.start
        : running
            ? Str.pause
            : Str.resume;
    final hint = timer == null
        ? Str.tapGlass
        : running
            ? Str.tapPause
            : Str.tapResume;
    final progress = timer?.progress(state.now.millisecondsSinceEpoch) ?? 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(Str.focusTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: Palette.cream)),
      const SizedBox(height: 8),
      Text(Str.focusSubtitle,
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Palette.cream)),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
            color: Palette.cream, borderRadius: BorderRadius.circular(30), boxShadow: Surface.shadow),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
                running
                    ? Icons.auto_awesome
                    : timer == null
                        ? Icons.hourglass_top_rounded
                        : Icons.pause_circle_outline,
                size: 15,
                color: Palette.plum),
            const SizedBox(width: 8),
            Flexible(
                child: Text(
                    timer == null
                        ? Str.focusReady
                        : running
                            ? Str.focusRunning
                            : Str.focusPaused,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: Palette.plum))),
            const SizedBox(width: 8),
            IconButton(
                onPressed: onMoon,
                tooltip: Str.moonHint,
                icon: const Icon(Icons.dark_mode_outlined, size: 20),
                color: Palette.plum),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            for (final m in [10, 15, 20, 30])
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Pressable(
                  onTap: timer == null ? () => onPick(m) : null,
                  selected: (timer == null ? minutes : timer.totalMs ~/ 60000) == m,
                  semanticLabel: Str.minutesLong(m),
                  child: AnimatedContainer(
                    duration: Motion.reduced(context) ? Duration.zero : Motion.standard,
                    curve: Motion.ease,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                        color: (timer == null ? minutes : timer.totalMs ~/ 60000) == m
                            ? Palette.ink
                            : Palette.mist,
                        borderRadius: BorderRadius.circular(14)),
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(Str.minutesChip(m),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: (timer == null ? minutes : timer.totalMs ~/ 60000) == m
                                    ? Palette.cream
                                    : Palette.ink))),
                  ),
                ),
              )),
          ]),
          const SizedBox(height: 22),
          Pressable(
            semanticLabel: '$action. ${timer == null ? Str.readyToStart(minutes) : Str.timerSemantics(time)}',
            onTap: onToggle,
            focusRadius: 90,
            child: SizedBox(
              height: 160,
              width: 190,
              child: Stack(alignment: Alignment.center, children: [
                AnimatedContainer(
                  duration: Motion.reduced(context) ? Duration.zero : Motion.slow,
                  width: running ? 148 : 138,
                  height: running ? 148 : 138,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: goal.color.color.withValues(alpha: running ? 0.28 : 0.16)),
                ),
                Positioned(
                    bottom: 1,
                    child: Container(
                        width: 92,
                        height: 9,
                        decoration: BoxDecoration(
                            color: Palette.ink.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(40)))),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Hourglass(
                      style: state.hourglass,
                      sand: Palette.plum,
                      progress: () => timer?.progress(state.now.millisecondsSinceEpoch) ?? 0,
                      running: running,
                      ready: timer == null,
                    )),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
              label: timer == null ? Str.minutesLong(minutes) : Str.timerSemantics(time),
              excludeSemantics: true,
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(time,
                      style: outfit(62, weight: 500)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()])))),
          const SizedBox(height: 8),
          Text(hint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Palette.plum)),
          const SizedBox(height: 18),
          Semantics(
              label: Str.focusTimeLeft,
              value: '${((1 - progress) * 100).round()}%',
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                      value: 1 - progress,
                      minHeight: 4,
                      backgroundColor: Palette.mist,
                      color: Palette.plum))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: FilledButton.icon(
                    onPressed: onToggle,
                    style: FilledButton.styleFrom(
                        backgroundColor: Palette.ink,
                        foregroundColor: Palette.cream,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(action))),
            if (timer != null) ...[
              const SizedBox(width: 10),
              IconButton.filledTonal(
                  onPressed: onStop,
                  tooltip: Str.stop,
                  style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      backgroundColor: Palette.mist,
                      foregroundColor: Palette.ink),
                  icon: const Icon(Icons.stop_rounded)),
            ],
          ]),
          const SizedBox(height: 20),
          Text(Str.glassStyle, style: const TextStyle(fontSize: 11, color: Palette.plum)),
          const SizedBox(height: 9),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final style in HourglassStyle.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Pressable(
                  onTap: () => state.setHourglass(style),
                  selected: state.hourglass == style,
                  semanticLabel: Str.hourglassStyle(Str.hourglassNames[style.index]),
                  child: AnimatedContainer(
                    duration: Motion.reduced(context) ? Duration.zero : Motion.quick,
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color:
                            state.hourglass == style ? Palette.butter : Palette.mist.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: state.hourglass == style ? Palette.plum : Colors.transparent)),
                    child: HourglassSwatch(style: style, sand: Palette.plum),
                  ),
                ),
              ),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      Pressable(
          onTap: onMoon,
          semanticLabel: '${Str.moonMode}. ${Str.moonHint}',
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Palette.lavender, borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                const Icon(Icons.dark_mode_outlined, color: Palette.ink, size: 27),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(Str.moonMode,
                      style: const TextStyle(color: Palette.ink, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(Str.moonHint, style: const TextStyle(color: Palette.ink, fontSize: 11)),
                ])),
                const Icon(Icons.chevron_right, color: Palette.ink),
              ]))),
      const SizedBox(height: 14),
      Text(Str.focusSaved,
          textAlign: TextAlign.center, style: const TextStyle(color: Palette.cream, fontSize: 11)),
    ]);
  }
}
