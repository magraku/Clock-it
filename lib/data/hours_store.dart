import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/hours_data.dart';

/// Where the data lives. Today only [LocalHoursStore]; a Firebase-backed
/// store can implement the same interface later.
abstract class HoursStore {
  Future<HoursData?> load();
  Future<void> save(HoursData data);
  Future<bool> hasSeenWelcome();
  Future<void> markWelcomeSeen();
}

class LocalHoursStore implements HoursStore {
  /// Same key as the web version.
  static const _dataKey = 'sfp-v1';
  static const _welcomeKey = 'clockit-welcome-seen';

  @override
  Future<HoursData?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_dataKey);
    if (raw == null) return null;
    try {
      return HoursData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(HoursData data) async {
    await (await SharedPreferences.getInstance())
        .setString(_dataKey, jsonEncode(data.toJson()));
  }

  @override
  Future<bool> hasSeenWelcome() async =>
      (await SharedPreferences.getInstance()).getBool(_welcomeKey) ?? false;

  @override
  Future<void> markWelcomeSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_welcomeKey, true);
}
