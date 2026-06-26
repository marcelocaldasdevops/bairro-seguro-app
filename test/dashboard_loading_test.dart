import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bairro_seguro/screens/dashboard_screen.dart';
import 'package:bairro_seguro/services/api_service.dart';
import 'package:bairro_seguro/widgets/app_states.dart';

class MockApiService extends ApiService {
  @override
  Future<Map<String, dynamic>> getDashboardSummary({
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    return {
      'status': 'Seguro',
      'safety_percentage': 95,
      'radius_km': 1.0,
      'critical_alerts': [],
      'attention_zones': [],
    };
  }
}

void main() {
  testWidgets('DashboardScreen deve destravar o loading e exibir fallback mesmo se a geolocalizacao falhar/sofrer timeout', (WidgetTester tester) async {
    // Configura o mock do canal de geolocalização para simular permissão negada
    // de modo que o Geolocator retorne imediatamente sem travar
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermission') {
          return 0; // denied
        }
        if (methodCall.method == 'requestPermission') {
          return 0; // denied
        }
        return null;
      },
    );

    final mockApiService = MockApiService();

    // Pump o DashboardScreen
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardScreen(apiService: mockApiService),
      ),
    ));

    // No primeiro frame, deve mostrar o AppLoadingState
    expect(find.byType(AppLoadingState), findsOneWidget);

    // Aguarda a conclusão de todos os microtasks e animações (o geolocator responderá negado e a API retornará os dados mockados)
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // O loading deve ter sumido
    expect(find.byType(AppLoadingState), findsNothing);

    // O status e o raio de fallback do mockApiService devem ser renderizados na tela
    expect(find.text('Seguro'), findsOneWidget);
    expect(find.text('1.0km'), findsOneWidget);
  });
}
