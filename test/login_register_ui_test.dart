import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bairro_seguro/screens/login_screen.dart';
import 'package:bairro_seguro/screens/register_screen.dart';
import 'package:bairro_seguro/services/api_service.dart';

void main() {
  final apiService = ApiService();

  testWidgets('LoginScreen shows asterisks and toggles password visibility', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(apiService: apiService),
    ));

    // Verify fields have asterisks
    expect(find.text('E-mail *'), findsOneWidget);
    expect(find.text('Senha *'), findsOneWidget);

    // Verify password visibility toggle is present
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    
    // Tap eye icon to toggle visibility
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    // Verify it toggled to visible icon
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('RegisterScreen shows asterisks, confirm password, and no toggle button', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RegisterScreen(apiService: apiService),
    ));

    // Verify fields have asterisks
    expect(find.text('Nome de Usuário *'), findsOneWidget);
    expect(find.text('E-mail *'), findsOneWidget);
    expect(find.text('Senha *'), findsOneWidget);
    expect(find.text('Confirmar Senha *'), findsOneWidget);

    // Verify optional fields are displayed directly
    expect(find.text('Nome Completo'), findsOneWidget);
    expect(find.text('CPF'), findsOneWidget);
    expect(find.text('Bairro'), findsOneWidget);

    // Verify the optional toggle button is gone
    expect(find.text('Configurar perfil agora (opcional)'), findsNothing);

    // Verify eye icons on both password fields
    expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));
  });
}
