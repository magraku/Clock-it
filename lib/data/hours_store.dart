import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hours_data.dart';

/// Where one account's hours live.
abstract class HoursStore {
  Future<HoursData?> load();
  Future<void> save(HoursData data);

  /// Copies saved elsewhere (another phone), as they arrive.
  Stream<HoursData> changes() => const Stream.empty();
}

/// One document per account: `users/{uid}`, same JSON as the web version.
/// Firestore caches it on the phone, so the app keeps working offline and
/// syncs when the connection comes back.
class FirestoreHoursStore extends HoursStore {
  FirestoreHoursStore(String uid, {FirebaseFirestore? db})
      : _doc = (db ?? FirebaseFirestore.instance).collection('users').doc(uid);

  final DocumentReference<Map<String, dynamic>> _doc;

  static HoursData? _parse(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return HoursData.fromJson(json);
    } on Object {
      return null;
    }
  }

  @override
  Future<HoursData?> load() async => _parse((await _doc.get()).data());

  @override
  Future<void> save(HoursData data) => _doc.set(data.toJson());

  @override
  Stream<HoursData> changes() => _doc
      .snapshots()
      .where((s) => !s.metadata.hasPendingWrites)
      .map((s) => _parse(s.data()))
      .where((d) => d != null)
      .cast<HoursData>();

  Future<void> delete() => _doc.delete();
}

/// Hours kept only on this phone, from before accounts existed. A new
/// account adopts them once (see [LocalHoursStore.takeLegacy]).
class LocalHoursStore extends HoursStore {
  /// Same key as the web version.
  static const _dataKey = 'sfp-v1';

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

  /// Returns the phone-only hours, if any, and forgets them so no other
  /// account picks them up.
  Future<HoursData?> takeLegacy() async {
    final data = await load();
    await (await SharedPreferences.getInstance()).remove(_dataKey);
    return data == null || (data.days.isEmpty && data.openSince == null) ? null : data;
  }
}
