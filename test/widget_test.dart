import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/main.dart';

void main() {
  testWidgets('menampilkan Home SONORA dan membuka Library', (tester) async {
    await tester.pumpWidget(const SonoraApp());
    expect(find.text('SONORA'), findsOneWidget);
    expect(find.text('Pratinjau antarmuka'), findsOneWidget);
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Pustaka musik'), findsOneWidget);
  });
}
