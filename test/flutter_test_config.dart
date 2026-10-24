import 'dart:async';

import 'package:clock_it/ui/widgets/flow_background.dart';

/// Runs before every test file: the moving background holds still, so
/// `pumpAndSettle` can finish.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  FlowBackground.animate = false;
  await testMain();
}
