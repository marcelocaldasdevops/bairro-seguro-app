import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bairro_seguro/services/api_service.dart';

void main() {
  test('Deve renovar o access token automaticamente apos erro 401 e repetir a chamada com sucesso', () async {
    SharedPreferences.setMockInitialValues({});
    final apiService = ApiService();

    // 1. Realizar login com as credenciais padrões
    final loginResult = await apiService.login('admin@admin.com', 'Teste123456#');
    expect(loginResult, isNotNull);
    expect(loginResult['token'], isNotNull);
    expect(loginResult['refresh'], isNotNull);

    // 2. Chamar getProfile com token válido original
    final profileOriginal = await apiService.getProfile();
    expect(profileOriginal['username'], equals('admin'));

    // 3. Simular a expiração do access token substituindo-o por um valor inválido
    apiService.token = 'invalid_access_token_simulating_expiration';

    // 4. Chamar getProfile novamente. O interceptor 401 deve:
    //   a) Detectar o erro 401
    //   b) Chamar o endpoint /api/users/token/refresh/ enviando o refresh token válido
    //   c) Obter o novo access token e atualizá-lo localmente
    //   d) Repetir a chamada original getProfile com sucesso transparente
    final profileAfterRefresh = await apiService.getProfile();
    expect(profileAfterRefresh['username'], equals('admin'));
  });
}
