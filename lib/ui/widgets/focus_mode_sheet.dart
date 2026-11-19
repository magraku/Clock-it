import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/focus_mode.dart';
import '../../state/app_state.dart';
import '../strings.dart';
import '../theme.dart';

Future<void> showFocusModeSheet(BuildContext context, AppState state) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Palette.cream,
      builder: (_) => _FocusModeSheet(state: state),
    );

class _FocusModeSheet extends StatefulWidget {
  const _FocusModeSheet({required this.state});
  final AppState state;
  @override
  State<_FocusModeSheet> createState() => _FocusModeSheetState();
}

class _FocusModeSheetState extends State<_FocusModeSheet> with WidgetsBindingObserver {
  FocusModeStatus? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.state.syncFocusMode();
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final status = await widget.state.focusMode.status();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _enable(bool value) async {
    setState(() => _busy = true);
    await widget.state.focusMode.setEnabled(value);
    widget.state.syncFocusMode();
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _access() async {
    await widget.state.focusMode.requestAccess();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return SafeArea(
        child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.dark_mode_outlined, size: 36, color: Palette.plum),
        const SizedBox(height: 16),
        Text(Str.moonMode,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Palette.ink)),
        const SizedBox(height: 16),
        if (status == null)
          const Center(child: CircularProgressIndicator())
        else if (status.supported) ...[
          Text(Str.moonAutoHelp),
          const SizedBox(height: 16),
          if (!status.ready) ...[
            Text(Str.moonPermissionHelp),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: _busy ? null : _access,
                icon: const Icon(Icons.settings_outlined),
                label: Flexible(child: Text(!status.granted ? Str.moonAccess : Str.moonExact))),
          ],
          SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(Str.moonAuto),
              value: status.enabled && status.ready,
              onChanged: _busy || !status.ready ? null : _enable),
        ] else ...[
          Text(kIsWeb ? Str.moonWeb : Str.moonManual),
          if (!kIsWeb) ...[
            const SizedBox(height: 16),
            Text(android ? Str.moonAndroid : Str.moonIos),
          ],
        ],
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        Text(Str.lockScreenHelp, style: const TextStyle(fontSize: 12, color: Palette.plum)),
        const SizedBox(height: 16),
        Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => Navigator.pop(context), child: Text(Str.cancel))),
      ]),
    ));
  }
}
