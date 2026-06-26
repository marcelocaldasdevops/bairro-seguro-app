import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static const _tokenStorageKey = 'bairro_seguro_token';
  static const _refreshTokenStorageKey = 'bairro_seguro_refresh_token';

  static const String _compiledBaseUrl = String.fromEnvironment('BASE_URL');

  // Tenta pegar do compilado, senão do .env, senão valor padrão
  static String get baseUrl {
    if (_compiledBaseUrl.isNotEmpty) return _compiledBaseUrl;
    if (dotenv.isInitialized && dotenv.env['BASE_URL'] != null) {
      return dotenv.env['BASE_URL']!;
    }
    return 'http://10.0.2.2:8000/api';
  }

  String? _token;
  String? _refreshToken;

  @visibleForTesting
  set token(String? value) => _token = value;

  // Cliente HTTP que aceita certificados auto-assinados
  http.Client get _client {
    final ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  Future<void> setTokens({required String token, required String refreshToken}) async {
    _token = token;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenStorageKey, token);
    await prefs.setString(_refreshTokenStorageKey, refreshToken);
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      return false;
    }

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/token/refresh/'),
        headers: _publicJsonHeaders,
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenStorageKey, _token!);
        debugPrint('Token JWT de acesso renovado com sucesso.');
        return true;
      }
    } catch (e) {
      debugPrint('Erro ao renovar token JWT: $e');
    }
    return false;
  }

  Future<http.Response> _get(Uri url) async {
    var response = await _client.get(url, headers: _headers);
    if (response.statusCode == 401) {
      final success = await refreshAccessToken();
      if (success) {
        response = await _client.get(url, headers: _headers);
      }
    }
    return response;
  }

  Future<http.Response> _post(Uri url, {Object? body}) async {
    var response = await _client.post(url, headers: _headers, body: body);
    if (response.statusCode == 401) {
      final success = await refreshAccessToken();
      if (success) {
        response = await _client.post(url, headers: _headers, body: body);
      }
    }
    return response;
  }

  Future<http.Response> _delete(Uri url) async {
    var response = await _client.delete(url, headers: _headers);
    if (response.statusCode == 401) {
      final success = await refreshAccessToken();
      if (success) {
        response = await _client.delete(url, headers: _headers);
      }
    }
    return response;
  }

  Future<http.Response> _patch(Uri url, {Object? body}) async {
    var response = await _client.patch(url, headers: _headers, body: body);
    if (response.statusCode == 401) {
      final success = await refreshAccessToken();
      if (success) {
        response = await _client.patch(url, headers: _headers, body: body);
      }
    }
    return response;
  }

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenStorageKey);
    final savedRefreshToken = prefs.getString(_refreshTokenStorageKey);
    if (savedToken == null || savedToken.isEmpty) {
      return false;
    }
    _token = savedToken;
    _refreshToken = savedRefreshToken;

    try {
      await getProfile();
      return true;
    } catch (_) {
      try {
        final success = await refreshAccessToken();
        if (success) {
          return true;
        }
      } catch (e) {
        debugPrint('Erro ao renovar sessao na restauracao: $e');
      }
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenStorageKey);
    await prefs.remove(_refreshTokenStorageKey);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Map<String, String> get _publicJsonHeaders => {
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/users/login/'),
      headers: _publicJsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setTokens(token: data['token'], refreshToken: data['refresh'] ?? '');
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Erro no login');
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/users/'),
      headers: _publicJsonHeaders,
      body: jsonEncode(
          {'username': username, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      // Debug: mostra o erro real do servidor
      final errorBody =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};
      String errorMessage = 'Erro no registro';

      if (errorBody is Map) {
        // Formata os erros de validação do Django
        final errors = <String>[];
        errorBody.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            errors.add('$key: ${value.join(', ')}');
          } else if (value is String) {
            errors.add('$key: $value');
          }
        });
        if (errors.isNotEmpty) {
          errorMessage = errors.join('\n');
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _get(
      Uri.parse('$baseUrl/users/me/'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar perfil');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final profile = await getProfile();
    final response = await _patch(
      Uri.parse('$baseUrl/users/${profile['id']}/'),
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar perfil');
    }
  }

  Future<List<dynamic>> getIncidents() async {
    final response = await _get(
      Uri.parse('$baseUrl/incidents/'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar incidentes');
    }
  }

  Future<Map<String, dynamic>> getDashboardSummary({
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final query = <String, String>{};
    if (latitude != null) query['latitude'] = latitude.toString();
    if (longitude != null) query['longitude'] = longitude.toString();
    if (radiusKm != null) query['radius_km'] = radiusKm.toString();

    final uri = Uri.parse('$baseUrl/incidents/dashboard/').replace(queryParameters: query);
    final response = await _get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar dashboard');
  }

  Future<List<dynamic>> getFeed({
    String? category,
    String? radiusKm,
  }) async {
    final query = <String, String>{};
    if (category != null && category.isNotEmpty && category != 'TODOS') {
      query['category'] = category;
    }
    if (radiusKm != null && radiusKm.isNotEmpty) {
      query['radius_km'] = radiusKm;
    }

    final uri = Uri.parse('$baseUrl/incidents/feed/').replace(queryParameters: query);
    final response = await _get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar feed');
  }

  Future<List<dynamic>> getMapIncidents({String? criticality}) async {
    final query = <String, String>{};
    if (criticality != null && criticality.isNotEmpty) {
      query['criticality'] = criticality;
    }

    final uri = Uri.parse('$baseUrl/incidents/map/').replace(queryParameters: query);
    final response = await _get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar ocorrências do mapa');
  }

  Future<List<dynamic>> getIncidentComments(int incidentId) async {
    final response = await _get(
      Uri.parse('$baseUrl/incidents/$incidentId/comments/'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar comentários');
  }

  Future<void> confirmIncident(int incidentId) async {
    final response = await _post(
      Uri.parse('$baseUrl/incidents/$incidentId/confirm/'),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao confirmar ocorrência');
    }
  }

  Future<void> unconfirmIncident(int incidentId) async {
    final response = await _delete(
      Uri.parse('$baseUrl/incidents/$incidentId/confirm/'),
    );

    if (response.statusCode != 204) {
      throw Exception('Erro ao remover confirmação');
    }
  }

  Future<void> createComment(int incidentId, String content) async {
    final response = await _post(
      Uri.parse('$baseUrl/incidents/$incidentId/comments/'),
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar comentário');
    }
  }

  Future<Map<String, dynamic>> createIncident(Map<String, dynamic> data) async {
    final response = await _post(
      Uri.parse('$baseUrl/incidents/'),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      // Tenta extrair a mensagem de erro mais específica
      String errorMessage = 'Erro ao criar incidente';

      if (errorData is Map) {
        // Verifica se há erro de validação
        if (errorData.containsKey('non_field_errors')) {
          errorMessage = errorData['non_field_errors'][0];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        } else {
          // Pega o primeiro erro encontrado
          final firstKey = errorData.keys.first;
          final firstError = errorData[firstKey];
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = '$firstKey: ${firstError[0]}';
          } else {
            errorMessage = '$firstKey: $firstError';
          }
        }
      } else if (errorData is List && errorData.isNotEmpty) {
        errorMessage = errorData[0].toString();
      }

      throw Exception(errorMessage);
    }

    throw Exception('Erro ao criar incidente');
  }

  Future<Map<String, dynamic>> uploadIncidentAttachment({
    required int incidentId,
    required File file,
    String attachmentType = 'IMAGE',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/incidents/$incidentId/attachments/'),
    );
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.fields['attachment_type'] = attachmentType;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var streamed = await _client.send(request);
    var response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401) {
      final success = await refreshAccessToken();
      if (success) {
        final retryRequest = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/incidents/$incidentId/attachments/'),
        );
        if (_token != null) {
          retryRequest.headers['Authorization'] = 'Bearer $_token';
        }
        retryRequest.fields['attachment_type'] = attachmentType;
        retryRequest.files.add(await http.MultipartFile.fromPath('file', file.path));
        streamed = await _client.send(retryRequest);
        response = await http.Response.fromStream(streamed);
      }
    }

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao enviar anexo');
  }

  Future<Map<String, dynamic>> getIncidentDetails(int incidentId) async {
    final response = await _get(
      Uri.parse('$baseUrl/incidents/$incidentId/'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar detalhes da ocorrência');
  }
}
