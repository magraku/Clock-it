import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/accounts.dart';
import '../logic/time_math.dart';
import '../state/app_state.dart';
import '../state/session.dart';
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
  const _SheetButton(
    this.label, {
    required this.onTap,
    this.color = Palette.green,
    this.filled = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool filled;

  /// Shows a spinner and ignores taps while something is in flight.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Pressable(
      onTap: busy ? null : onTap,
      semanticLabel: label,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.9) : Colors.transparent,
          border: filled ? null : Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: busy
            ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
            : Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}

/// Small text link, e.g. "Forgot your password?".
class _LinkButton extends StatelessWidget {
  const _LinkButton(this.label, {required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: Palette.navy),
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.newPassword,
    required this.onSubmitted,
    this.errorText,
  });

  final TextEditingController controller;
  final bool newPassword;
  final VoidCallback onSubmitted;
  final String? errorText;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _hidden,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: [widget.newPassword ? AutofillHints.newPassword : AutofillHints.password],
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => widget.onSubmitted(),
      style: _body.copyWith(fontSize: 18),
      decoration: InputDecoration(
        hintText: widget.newPassword ? Str.passwordHint : Str.password,
        errorText: widget.errorText,
        errorMaxLines: 3,
        suffixIcon: IconButton(
          tooltip: Str.password,
          color: Palette.navy,
          icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

// ── Account ──────────────────────────────────────────────────────────────────

/// Log in ([signUp] false) or create an account. Returns the account's
/// hours, already loaded, or null if the sheet was closed.
Future<AppState?> showAccountSheet(BuildContext context, Services services, {required bool signUp}) =>
    _showSheet<AppState>(context, (_) => _AccountSheet(services: services, signUp: signUp));

class _AccountSheet extends StatefulWidget {
  const _AccountSheet({required this.services, required this.signUp});

  final Services services;
  final bool signUp;

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  late bool _signUp = widget.signUp;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = Str.authMissing);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    final services = widget.services;
    final isNew = _signUp;
    try {
      final account =
          isNew ? await services.accounts.signUp(email, password) : await services.accounts.logIn(email, password);
      final state = await services.open(account, isNew: isNew);
      TextInput.finishAutofillContext();
      if (mounted) {
        Navigator.pop(context, state);
      } else {
        // Closed while loading: don't leave someone signed in behind the welcome screen.
        state.dispose();
        await services.accounts.logOut();
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is AuthFailure ? e.message : Str.authGeneric;
      });
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = Str.authInvalidEmail);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.services.accounts.sendPasswordReset(email);
      if (mounted) setState(() => _notice = Str.resetSent);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e is AuthFailure ? e.message : Str.authGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode() => setState(() {
        _signUp = !_signUp;
        _error = null;
        _notice = null;
      });

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_signUp ? Str.signUpTitle : Str.logInTitle, style: _title),
          if (_signUp) ...[
            const SizedBox(height: 8),
            Text(Str.signUpHelp, style: _muted),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            style: _body.copyWith(fontSize: 18),
            decoration: const InputDecoration(hintText: Str.email),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _password,
            newPassword: _signUp,
            onSubmitted: _submit,
            errorText: _error,
          ),
          if (_notice != null) ...[
            const SizedBox(height: 10),
            Text(_notice!, style: _body.copyWith(color: Palette.green, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 18),
          _SheetButton(
            _signUp ? Str.createAccount : Str.logIn,
            onTap: _submit,
            color: Palette.pink,
            busy: _busy,
          ),
          const SizedBox(height: 6),
          if (!_signUp) _LinkButton(Str.forgotPassword, onTap: _busy ? null : _reset),
          _LinkButton(_signUp ? Str.haveAccount : Str.noAccount, onTap: _busy ? null : _toggleMode),
        ],
      ),
    );
  }
}

/// Asks for the password and deletes the account. Returns true when done.
Future<bool> showDeleteAccountSheet(BuildContext context, AccountService accounts) async =>
    await _showSheet<bool>(context, (_) => _DeleteAccountSheet(accounts: accounts)) ?? false;

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet({required this.accounts});

  final AccountService accounts;

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() => _error = Str.authMissing);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.accounts.deleteAccount(_password.text);
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is AuthFailure ? e.message : Str.authGeneric;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(Str.deleteAccount, style: _title),
        const SizedBox(height: 8),
        Text(Str.deleteAccountHelp, style: _muted),
        const SizedBox(height: 18),
        _PasswordField(controller: _password, newPassword: false, onSubmitted: _delete, errorText: _error),
        const SizedBox(height: 18),
        _SheetButton(Str.deleteAccount, onTap: _delete, color: Palette.coral, busy: _busy),
      ],
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

Future<void> showMenuSheet(
  BuildContext context,
  AppState state, {
  required VoidCallback onLogOut,
  required VoidCallback onDeleteAccount,
}) async {
  final choice = await _showSheet<String>(context, (c) {
    Widget item(IconData icon, String label, String value) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Palette.navy),
          title: Text(label, style: _body.copyWith(fontSize: 18)),
          onTap: () => Navigator.pop(c, value),
        );
    final email = state.account?.email ?? '';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (email.isNotEmpty) Text(email, style: _muted, overflow: TextOverflow.ellipsis),
      item(Icons.today_outlined, Str.today, 'today'),
      item(Icons.flag_outlined, Str.changeGoal, 'goal'),
      item(Icons.save_alt_outlined, Str.backup, 'backup'),
      const Divider(height: 12),
      item(Icons.logout, Str.logOut, 'logout'),
      item(Icons.person_remove_outlined, Str.deleteAccount, 'delete'),
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
    case 'logout':
      onLogOut();
    case 'delete':
      onDeleteAccount();
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
