import 'package:bairro_seguro/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the login screen on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Bairro Seguro'), findsWidgets);
  });
}
