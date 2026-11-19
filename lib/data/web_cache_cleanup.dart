Future<void> flushWebWrites({
  required Future<void> Function() waitForPendingWrites,
  Duration timeout = const Duration(seconds: 3),
}) async {
  try {
    await waitForPendingWrites().timeout(timeout);
  } on Object {
    // Offline writes must not prevent removing a signed-out user's cache.
  }
}

Future<void> clearWebCache({
  required Future<void> Function() terminate,
  required Future<void> Function() clearPersistence,
  required void Function() reload,
}) async {
  await terminate();
  await clearPersistence();
  reload();
}
