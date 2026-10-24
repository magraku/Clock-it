import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/goals.dart';

/// Where one account's goals and hours live.
abstract class HoursStore {
  Future<UserData?> load();
  Future<void> save(UserData data);

  /// Copies saved elsewhere (another phone), as they arrive.
  Stream<UserData> changes() => const Stream.empty();
}

/// One document per account: `users/{uid}` (see `models/goals.dart`).
/// Documents from before goals existed read as a single "SFP" goal.
/// Firestore caches it on the phone, so the app keeps working offline and
/// syncs when the connection comes back.
class FirestoreHoursStore extends HoursStore {
  FirestoreHoursStore(String uid, {FirebaseFirestore? db})
      : _doc = (db ?? FirebaseFirestore.instance).collection('users').doc(uid);

  final DocumentReference<Map<String, dynamic>> _doc;

  static UserData? _parse(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return UserData.fromJson(json);
    } on Object {
      return null;
    }
  }

  @override
  Future<UserData?> load() async => _parse((await _doc.get()).data());

  @override
  Future<void> save(UserData data) => _doc.set(data.toJson());

  @override
  Stream<UserData> changes() => _doc
      .snapshots()
      .where((s) => !s.metadata.hasPendingWrites)
      .map((s) => _parse(s.data()))
      .where((d) => d != null)
      .cast<UserData>();

  Future<void> delete() => _doc.delete();
}

/// Hours kept only on this device. With the default key, these are the
/// hours from before accounts existed, which a new account adopts once (see
/// [LocalHoursStore.takeLegacy]); the web build keeps each demo account
/// under its own key.
class LocalHoursStore extends HoursStore {
  LocalHoursStore({String key = legacyKey}) : _dataKey = key;

  /// Same key as the web version.
  static const legacyKey = 'sfp-v1';

  final String _dataKey;

  @override
  Future<UserData?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_dataKey);
    if (raw == null) return null;
    try {
      return UserData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(UserData data) async {
    await (await SharedPreferences.getInstance())
        .setString(_dataKey, jsonEncode(data.toJson()));
  }

  /// Returns the phone-only hours, if any, and forgets them so no other
  /// account picks them up.
  Future<UserData?> takeLegacy() async {
    final data = await load();
    await (await SharedPreferences.getInstance()).remove(_dataKey);
    final hours = data?.home.hours;
    return hours == null || (hours.days.isEmpty && hours.openSince == null) ? null : data;
  }
}
