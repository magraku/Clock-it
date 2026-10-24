import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's real fonts so layout in tests matches the device
/// (by default tests render every glyph as a 1em square).
Future<void> loadAppFonts() async {
  const families = {
    'Epilogue': ['Epilogue-Regular.otf', 'Epilogue-SemiBold.otf', 'Epilogue-Bold.otf'],
    'Anton': ['Anton-Regular.ttf'],
    'Outfit': ['Outfit-Variable.ttf'],
  };
  for (final e in families.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }
  // Material icons ship with the Flutter SDK.
  final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final icons = File('$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}
