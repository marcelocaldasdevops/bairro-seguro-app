import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'package:translator/translator.dart';
import '../helpers/utils.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;
  HomeScreen({required this.apiService});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final translator = GoogleTranslator();
  Map<String, String> _translatedSeverities = {};
  List<dynamic> _incidents = [];
  Map<String, dynamic>? _userProfile;
  LatLng _center = LatLng(-23.550520, -46.633308);
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _loadProfile();
    _determinePosition();
    _preloadTranslations();
  }

  Future<void> _preloadTranslations() async {
    try {
      final high = await translator.translate('HIGH', from: 'en', to: 'pt');
      final medium = await translator.translate('MEDIUM', from: 'en', to: 'pt');
      final low = await translator.translate('LOW', from: 'en', to: 'pt');

      setState(() {
        _translatedSeverities = {
          'HIGH': high.text,
          'MEDIUM': medium.text,
          'LOW': low.text,
        };
      });
    } catch (e) {
      print('Erro ao traduzir: $e');
    }
  }

  String _getSeverityText(String severity) {
    return _translatedSeverities[severity] ?? severity;
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.apiService.getProfile();
      setState(() => _userProfile = profile);
    } catch (e) {
      print('Erro ao carregar perfil: $e');
    }
  }

  void _logout() {
    widget.apiService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      accountName: Text(_userProfile?['name'] ?? 'Usuário'),
      accountEmail: Text(_userProfile?['email'] ?? ''),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.person, size: 40, color: Colors.indigo),
      ),
      decoration: BoxDecoration(
        color: Colors.indigo,
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigoAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Future<void> _loadIncidents() async {
    try {
      final data = await widget.apiService.getIncidents();
      print('Incidentes carregados: ${data.length}');
      setState(() => _incidents = data);
    } catch (e) {
      print('Erro ao carregar incidentes: $e');
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
      _mapController.move(_center, 15);
    });
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'HIGH': return Colors.red;
      case 'MEDIUM': return Colors.orange;
      case 'LOW': return Colors.green;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bairro Seguro', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            _buildDrawerHeader(),
            ListTile(
              leading: Icon(Icons.home_outlined),
              title: Text('Início'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Meu Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            Divider(),
            Spacer(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Sair', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: _logout,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'br.com.bairroseguro.app',
          ),
          MarkerLayer(
            markers: _incidents.map((incident) {
              try {
                final lat = double.parse(incident['location']['latitude'].toString());
                final lng = double.parse(incident['location']['longitude'].toString());
                
                return Marker(
                  point: LatLng(lat, lng),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Container(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  _getSeverityText(incident['severity_level']),
                                style: TextStyle(fontWeight: FontWeight.bold, 
                                color: _getSeverityColor(incident['severity_level']))),
                              SizedBox(height: 8),
                              Text(incident['description']),
                              SizedBox(height: 16),
                              Text('Relatado em: ${Utils.formatDateTime(incident['datetime'])}', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getSeverityColor(incident['severity_level']),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                );
              } catch (e) {
                print('Erro ao carregar marcador: $e');
                return Marker(point: LatLng(0, 0), child: SizedBox.shrink());
              }
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(child: CircularProgressIndicator()),
          );
          
          try {
            final profile = await widget.apiService.getProfile();
            Navigator.pop(context); // Close loading dialog
            
            if (profile['is_profile_complete'] == true) {
              Navigator.pushNamed(context, '/report').then((_) => _loadIncidents());
            } else {
              _showIncompleteProfileModal();
            }
          } catch (e) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao verificar perfil: $e')),
            );
          }
        },
        label: Text('Relatar Incidente', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: Icon(Icons.add_location_alt_rounded),
        elevation: 4,
      ),
    );
  }

  void _showIncompleteProfileModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Perfil Incompleto'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para manter a segurança da nossa comunidade, solicitamos que você complete seu cadastro antes de relatar um incidente.'),
            SizedBox(height: 16),
            Text('Campos necessários:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 8),
            _buildRequirementItem('Nome Completo'),
            _buildRequirementItem('CPF'),
            _buildRequirementItem('Bairro'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Depois', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
            child: Text('Completar Perfil'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.indigo),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
