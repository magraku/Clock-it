import 'package:clock_it/data/accounts.dart';
import 'package:clock_it/data/demo_accounts.dart';
import 'package:clock_it/data/hours_store.dart';
import 'package:clock_it/models/goals.dart';
import 'package:clock_it/models/hours_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  LocalHoursStore storeFor(Account a) => LocalHoursStore(key: DemoAccountService.demoHoursKey(a));

  test('web demo accounts keep their hours apart and are remembered', () async {
    final accounts = DemoAccountService();
    final ana = await accounts.signUp('Ana@mail.com', 'secret1');
    await storeFor(ana).save(UserData.starter(sfp: HoursData(goalHours: 100)));
    expect((await accounts.restore())?.email, 'ana@mail.com');

    await accounts.logOut();
    expect(await accounts.restore(), isNull);
    final bea = await accounts.signUp('bea@mail.com', 'secret2');
    expect(await storeFor(bea).load(), isNull);

    await accounts.logOut();
    final again = await accounts.logIn('ana@mail.com', 'anything');
    expect((await storeFor(again).load())!.home.hours.goalHours, 100);
  });

  test('web demo accounts reject unknown emails, repeats and short passwords', () async {
    final accounts = DemoAccountService();
    await expectLater(accounts.logIn('nobody@mail.com', 'secret1'), throwsA(isA<AuthFailure>()));
    await expectLater(accounts.signUp('not-an-email', 'secret1'), throwsA(isA<AuthFailure>()));
    await expectLater(accounts.signUp('ana@mail.com', '123'), throwsA(isA<AuthFailure>()));
    await accounts.signUp('ana@mail.com', 'secret1');
    await expectLater(accounts.signUp('ana@mail.com', 'secret1'), throwsA(isA<AuthFailure>()));
  });

  test('deleting a web demo account removes its hours', () async {
    final accounts = DemoAccountService();
    final ana = await accounts.signUp('ana@mail.com', 'secret1');
    await storeFor(ana).save(UserData.starter(sfp: HoursData(goalHours: 100)));
    await accounts.deleteAccount('secret1');
    expect(await storeFor(ana).load(), isNull);
    await expectLater(accounts.logIn('ana@mail.com', 'secret1'), throwsA(isA<AuthFailure>()));
  });
}
