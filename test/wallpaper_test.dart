import 'package:clock_it/models/goals.dart';
import 'package:clock_it/ui/widgets/wallpaper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('each painted wallpaper saves as a phone-sized PNG', (tester) async {
    for (final style in WallpaperStyle.values.where((s) => s != WallpaperStyle.photo)) {
      final png = (await tester.runAsync(() => wallpaperPng(style)))!;
      // PNG signature, then the IHDR size: 1290 × 2796.
      expect(png.sublist(1, 4), 'PNG'.codeUnits, reason: style.name);
      final header = png.buffer.asByteData(png.offsetInBytes);
      expect([header.getUint32(16), header.getUint32(20)], [1290, 2796], reason: style.name);
    }
  });
}
