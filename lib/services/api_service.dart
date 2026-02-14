import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:8000/api'; // iOS Simulator
  
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
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
    final response = await http.post(
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
    final response = await http.get(
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
    final response = await http.patch(
      Uri.parse('$baseUrl/users/${profile['id']}/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar perfil');
    }
  }

  Future<List<dynamic>> getIncidents() async {
    final response = await http.get(
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
    final response = await http.post(
      Uri.parse('$baseUrl/incidents/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData[0] ?? errorData['non_field_errors']?[0] ?? 'Erro ao criar incidente');
    }
  }
}
