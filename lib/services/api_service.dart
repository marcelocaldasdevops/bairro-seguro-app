import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static const _tokenStorageKey = 'bairro_seguro_token';

  // Tenta pegar do .env, se não existir usa um valor padrão
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  String? _token;

  // Cliente HTTP que aceita certificados auto-assinados
  http.Client get _client {
    final ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenStorageKey, token);
  }

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenStorageKey);
    if (savedToken == null || savedToken.isEmpty) {
      return false;
    }
    _token = savedToken;

    try {
      await getProfile();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenStorageKey);
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
      await setToken(data['token']);
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
    final response = await _client.get(
      Uri.parse('$baseUrl/users/me/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar perfil');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final profile = await getProfile();
    final response = await _client.patch(
      Uri.parse('$baseUrl/users/${profile['id']}/'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar perfil');
    }
  }

  Future<List<dynamic>> getIncidents() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/incidents/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar incidentes');
    }
  }

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/incidents/dashboard/'),
      headers: _headers,
    );

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
    final response = await _client.get(uri, headers: _headers);

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
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar ocorrências do mapa');
  }

  Future<List<dynamic>> getIncidentComments(int incidentId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/incidents/$incidentId/comments/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar comentários');
  }

  Future<void> confirmIncident(int incidentId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/incidents/$incidentId/confirm/'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao confirmar ocorrência');
    }
  }

  Future<void> unconfirmIncident(int incidentId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/incidents/$incidentId/confirm/'),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Erro ao remover confirmação');
    }
  }

  Future<void> createComment(int incidentId, String content) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/incidents/$incidentId/comments/'),
      headers: _headers,
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar comentário');
    }
  }

  Future<Map<String, dynamic>> createIncident(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/incidents/'),
      headers: _headers,
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

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao enviar anexo');
  }

  Future<Map<String, dynamic>> getIncidentDetails(int incidentId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/incidents/$incidentId/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar detalhes da ocorrência');
  }
}
