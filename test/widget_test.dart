import 'package:flutter_test/flutter_test.dart';
import 'package:vorflux/main.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    await tester.pumpWidget(const VorfluxApp());
    expect(find.text('Vorflux'), findsOneWidget);
  });
}
