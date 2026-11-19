Future<void> clearWebCache({
  required Future<void> Function() waitForPendingWrites,
  required Future<void> Function() terminate,
  required Future<void> Function() clearPersistence,
  required void Function() reload,
  Duration timeout = const Duration(seconds: 3),
}) async {
  try {
    await waitForPendingWrites().timeout(timeout);
  } on Object {
    // Offline writes must not prevent removing a signed-out user's cache.
  }
  await terminate();
  await clearPersistence();
  reload();
}
