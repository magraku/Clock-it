import '../data/accounts.dart';
import '../data/hours_store.dart';
import 'app_state.dart';

/// What the screens need to sign people in and open their hours.
/// Tests pass fakes; `main.dart` passes the Firebase ones.
class Services {
  const Services({
    required this.accounts,
    required this.storeFor,
    required this.legacy,
    this.clock,
  });

  final AccountService accounts;
  final HoursStore Function(Account) storeFor;

  /// Hours saved on this phone before accounts existed.
  final LocalHoursStore legacy;
  final DateTime Function()? clock;

  /// Loads [account]'s hours. A brand-new account takes over the hours that
  /// were on this phone, so nothing logged before the update is lost.
  Future<AppState> open(Account account, {bool isNew = false}) async {
    final state = AppState(storeFor(account), account: account, clock: clock);
    await state.load(adopt: isNew ? await legacy.takeLegacy() : null);
    return state;
  }
}
