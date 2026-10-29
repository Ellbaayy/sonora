import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('aplikasi membuka Home SONORA lalu berpindah tab', (
    tester,
  ) async {
    final harness = await createHarness(
      seeds: [audioDraft('a.mp3', title: 'Alpha')],
    );
    await pumpApp(tester, harness);

    expect(find.text('SONORA'), findsOneWidget);
    expect(find.text('Dengarkan yang\nkamu simpan.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Library')));
    await tester.pumpAndSettle();
    expect(find.text('Pustaka musik'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Settings')));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
