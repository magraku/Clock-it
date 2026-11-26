import 'package:clock_it/data/hours_store.dart';
import 'package:clock_it/models/goals.dart';
import 'package:clock_it/models/hours_data.dart';
import 'package:clock_it/state/app_state.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two devices on one account through [FirestoreHoursStore], each with its own
/// clock: the phone runs five minutes fast.
void main() {
  late FakeFirebaseFirestore db;
  late DateTime realTime;
  late AppState phone;
  late AppState web;

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<UserData> cloud() async => UserData.fromJson((await db.collection('users').doc('u').get()).data()!);

  setUp(() async {
    db = FakeFirebaseFirestore();
    realTime = DateTime(2026, 11, 19, 9);
    phone = AppState(FirestoreHoursStore('u', db: db), clock: () => realTime.add(const Duration(minutes: 5)));
    web = AppState(FirestoreHoursStore('u', db: db), clock: () => realTime);
    await phone.load();
    await web.load();
  });

  tearDown(() {
    phone.dispose();
    web.dispose();
  });

  test('a device whose clock runs ahead keeps the edits of one that runs behind', () async {
    phone.setDay('sfp', '2026-11-17', 120); // real 09:00, stamped 09:05
    await settle();
    expect(web.savedMinutes('sfp', '2026-11-17'), 120);

    realTime = realTime.add(const Duration(minutes: 1));
    web.setDay('sfp', '2026-11-18', 60); // real 09:01
    await settle();
    expect(phone.savedMinutes('sfp', '2026-11-18'), 60);

    realTime = realTime.add(const Duration(minutes: 1));
    phone.setDay('sfp', '2026-11-19', 30); // real 09:02
    await settle();

    final days = (await cloud()).home.hours.days;
    expect({for (final e in days.entries) e.key: e.value.manualMinutes},
        {'2026-11-17': 120, '2026-11-18': 60, '2026-11-19': 30});
    expect(web.savedMinutes('sfp', '2026-11-19'), 30);
    expect(web.savedMinutes('sfp', '2026-11-18'), 60);
  });

  test('a later save stamped earlier, e.g. by an older app version, still wins', () async {
    phone.setDay('sfp', '2026-11-17', 120);
    await settle();

    final fromOldApp = UserData.starter(
      sfp: HoursData(days: {'2026-11-17': DayEntry(manualMinutes: 120), '2026-11-18': DayEntry(manualMinutes: 60)}),
    )..updatedAt = realTime.millisecondsSinceEpoch;
    await db.collection('users').doc('u').set(fromOldApp.toJson());
    await settle();
    expect(phone.savedMinutes('sfp', '2026-11-18'), 60);

    phone.setDay('sfp', '2026-11-19', 30);
    await settle();
    expect((await cloud()).home.hours.days.keys, containsAll(['2026-11-17', '2026-11-18', '2026-11-19']));
  });

  test('each save is stamped after the copy it replaces, whatever the clock says', () async {
    phone.setDay('sfp', '2026-11-17', 120);
    await settle();
    final phoneStamp = (await cloud()).updatedAt;
    web.setDay('sfp', '2026-11-18', 60);
    await settle();
    expect((await cloud()).updatedAt, greaterThan(phoneStamp));
  });
}
