import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FocusModeStatus {
  const FocusModeStatus(
      {this.supported = false,
      this.enabled = false,
      this.granted = false,
      this.exact = false,
      this.active = false});
  final bool supported, enabled, granted, exact, active;
  bool get ready => granted && exact;
}

abstract class FocusMode {
  const FocusMode();
  Future<FocusModeStatus> status();
  Future<void> setEnabled(bool enabled);
  Future<void> requestAccess();
  Future<void> sync(List<int> endsAt);
}

class NoFocusMode extends FocusMode {
  const NoFocusMode();
  @override
  Future<FocusModeStatus> status() async => const FocusModeStatus();
  @override
  Future<void> setEnabled(bool enabled) async {}
  @override
  Future<void> requestAccess() async {}
  @override
  Future<void> sync(List<int> endsAt) async {}
}

class LocalFocusMode extends FocusMode {
  const LocalFocusMode();
  static const _channel = MethodChannel('clockit/focus');
  bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<T?> _call<T>(String method, [Object? args]) async {
    if (!_android) return null;
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<FocusModeStatus> status() async {
    final data = await _call<Map<Object?, Object?>>('status');
    return FocusModeStatus(
        supported: data?['supported'] == true,
        enabled: data?['enabled'] == true,
        granted: data?['granted'] == true,
        exact: data?['exact'] == true,
        active: data?['active'] == true);
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await _call<void>('enable', enabled);
  }

  @override
  Future<void> requestAccess() async {
    await _call<void>('requestAccess');
  }

  @override
  Future<void> sync(List<int> endsAt) async {
    await _call<void>('sync', endsAt);
  }
}
