import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';


import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Tenta pegar do .env, se não existir usa um valor padrão
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'https://35.193.57.27/api';
  
 
  
  String? _token;

  // Cliente HTTP que aceita certificados auto-assinados
  http.Client get _client {
    final ioc = HttpClient();
    ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  void setToken(String token) {
    _token = token;
  }

  void logout() {
    _token = null;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/users/login/'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Erro no login');
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/users/'),
      headers: _headers,
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro no registro');
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

  Future<void> createIncident(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/incidents/'),
      headers: _headers,
      body: jsonEncode(data),
    );
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
  }
}
