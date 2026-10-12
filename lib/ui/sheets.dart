import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../logic/time_math.dart';
import '../state/app_state.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets/common.dart';

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Palette.cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (c) => MediaQuery(
      data: MediaQuery.of(c).copyWith(
        textScaler: MediaQuery.textScalerOf(c).clamp(maxScaleFactor: 1.4),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
            child: builder(c),
          ),
        ),
      ),
    ),
  );
}

const _title = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Palette.navy, height: 1.15);
const _body = TextStyle(fontSize: 16, color: Palette.navy, height: 1.3);
final _muted = TextStyle(fontSize: 14, color: Palette.navy.withValues(alpha: 0.65), height: 1.3);

class _SheetButton extends StatelessWidget {
  const _SheetButton(this.label, {required this.onTap, this.color = Palette.green, this.filled = true});

  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.9) : Colors.transparent,
          border: filled ? null : Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ── Day ──────────────────────────────────────────────────────────────────────

Future<void> showDaySheet(BuildContext context, AppState state, DateTime date) =>
    _showSheet(context, (_) => _DaySheet(state: state, date: date));

class _DaySheet extends StatefulWidget {
  const _DaySheet({required this.state, required this.date});

  final AppState state;
  final DateTime date;

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  late final String _key = dayKey(widget.date);
  late final String _initial = fmtHours(widget.state.savedMinutes(_key));
  late final TextEditingController _ctrl = TextEditingController(text: _initial);
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final text = _ctrl.text.trim();
    if (text == _initial) return Navigator.pop(context);
    final minutes = text.isEmpty ? 0 : parseDuration(text);
    if (minutes == null) {
      setState(() => _error = Str.invalidDuration);
      return;
    }
    widget.state.setDay(_key, minutes);
    Navigator.pop(context);
  }

  void _delete() {
    widget.state.setDay(_key, 0);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.date;
    final entry = widget.state.data.days[_key];
    final sessions = entry?.sessions ?? const [];
    final open = widget.state.data.openSince;
    final runningHere = open != null && dayKeyOf(open) == _key;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${Str.weekdaysLong[d.weekday - 1]}, ${Str.monthsLong[d.month - 1]} ${d.day}', style: _title),
        const SizedBox(height: 18),
        if (sessions.isNotEmpty) ...[
          Text(Str.sessions, style: _muted),
          const SizedBox(height: 6),
          for (final s in sessions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Text('${clockTime(s.start)} – ${clockTime(s.end)}', style: _body),
                const Spacer(),
                Text(fmtHours(s.minutes).isEmpty ? '0m' : fmtHours(s.minutes),
                    style: _body.copyWith(fontWeight: FontWeight.w600)),
              ]),
            ),
          if ((entry?.manualMinutes ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                const Text(Str.manual, style: _body),
                const Spacer(),
                Text(fmtHours(entry!.manualMinutes.toDouble()),
                    style: _body.copyWith(fontWeight: FontWeight.w600)),
              ]),
            ),
          const SizedBox(height: 14),
        ],
        if (runningHere) ...[
          Text(Str.runningSince(clockTime(open)), style: _muted),
          const SizedBox(height: 14),
        ],
        Text(Str.hoursThatDay, style: _muted),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          style: const TextStyle(fontSize: 22, color: Palette.navy, fontWeight: FontWeight.w600),
          decoration: InputDecoration(hintText: Str.durationHint, errorText: _error),
        ),
        const SizedBox(height: 8),
        Text(Str.formats, style: _muted),
        if (sessions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(Str.editReplacesSessions, style: _muted),
        ],
        const SizedBox(height: 20),
        Row(children: [
          if (entry != null) ...[
            Expanded(child: _SheetButton(Str.delete, onTap: _delete, color: Palette.coral, filled: false)),
            const SizedBox(width: 12),
          ],
          Expanded(child: _SheetButton(Str.save, onTap: _save)),
        ]),
      ],
    );
  }
}

// ── Goal ─────────────────────────────────────────────────────────────────────

Future<void> showGoalSheet(BuildContext context, AppState state) =>
    _showSheet(context, (_) => _GoalSheet(state: state));

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({required this.state});

  final AppState state;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: _trim(widget.state.data.goalHours),
  );
  String? _error;

  static String _trim(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final v = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) {
      setState(() => _error = Str.invalidGoal);
      return;
    }
    widget.state.setGoal(v);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.state.summary;
    String need(int days) {
      final v = summary.needPerDay(days);
      return v == null ? '—' : fmtPerDay(v);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(Str.monthlyGoal, style: _title),
        const SizedBox(height: 18),
        TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          style: const TextStyle(fontSize: 22, color: Palette.navy, fontWeight: FontWeight.w600),
          decoration: InputDecoration(hintText: Str.goalHint, suffixText: 'h', errorText: _error),
        ),
        const SizedBox(height: 14),
        Text('${Str.monFri}: ${need(summary.weekdaysLeft)}/day · ${Str.everyday}: ${need(summary.daysLeft)}/day',
            style: _muted),
        Text(Str.daysLeft(summary.weekdaysLeft, summary.daysLeft), style: _muted),
        const SizedBox(height: 20),
        _SheetButton(Str.save, onTap: _save),
      ],
    );
  }
}

// ── Menu ─────────────────────────────────────────────────────────────────────

Future<void> showMenuSheet(BuildContext context, AppState state) async {
  final choice = await _showSheet<String>(context, (c) {
    Widget item(IconData icon, String label, String value) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Palette.navy),
          title: Text(label, style: _body.copyWith(fontSize: 18)),
          onTap: () => Navigator.pop(c, value),
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      item(Icons.today_outlined, Str.today, 'today'),
      item(Icons.flag_outlined, Str.changeGoal, 'goal'),
      item(Icons.save_alt_outlined, Str.backup, 'backup'),
    ]);
  });
  if (!context.mounted) return;
  switch (choice) {
    case 'today':
      state.goToToday();
    case 'goal':
      await showGoalSheet(context, state);
    case 'backup':
      await showBackupSheet(context, state);
  }
}

// ── Backup ───────────────────────────────────────────────────────────────────

Future<void> showBackupSheet(BuildContext context, AppState state) =>
    _showSheet(context, (_) => _BackupSheet(state: state));

class _BackupSheet extends StatelessWidget {
  const _BackupSheet({required this.state});

  final AppState state;

  /// Closes the sheet, then shows [msg] on the screen underneath.
  void _closeWith(BuildContext context, String msg) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.navy,
    ));
  }

  Future<void> _export(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/clock-it-backup-${dayKey(state.now)}.json');
    await file.writeAsString(state.exportJson());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      sharePositionOrigin: origin,
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: state.exportJson()));
    if (!context.mounted) return;
    _closeWith(context, Str.copied);
  }

  Future<void> _importFile(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    final bytes = res?.files.single.bytes;
    if (bytes == null || !context.mounted) return;
    await _restore(context, utf8.decode(bytes, allowMalformed: true));
  }

  Future<void> _paste(BuildContext context) async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (!context.mounted) return;
    await _restore(context, text ?? '');
  }

  Future<void> _restore(BuildContext context, String text) async {
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (c) => AlertDialog.adaptive(
        content: const Text(Str.importConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(Str.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text(Str.replace)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    _closeWith(context, state.importJson(text) ? Str.imported : Str.importFailed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(Str.backup, style: _title),
        const SizedBox(height: 10),
        Text(Str.backupHelp, style: _muted),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Builder(builder: (c) => _SheetButton(Str.exportFile, onTap: () => _export(c)))),
          const SizedBox(width: 12),
          Expanded(child: _SheetButton(Str.copyJson, onTap: () => _copy(context), color: Palette.navy, filled: false)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _SheetButton(Str.importFile, onTap: () => _importFile(context), color: Palette.navy)),
          const SizedBox(width: 12),
          Expanded(child: _SheetButton(Str.pasteJson, onTap: () => _paste(context), color: Palette.navy, filled: false)),
        ]),
      ],
    );
  }
}
