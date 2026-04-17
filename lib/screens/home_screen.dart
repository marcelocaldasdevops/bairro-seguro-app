import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'package:translator/translator.dart';
import '../helpers/utils.dart';
import '../widgets/skeleton_incident.dart';
import '../widgets/incident_list_item.dart';
import 'profile_screen.dart';

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
  int _currentIndex = 0;
  bool _isLoadingIncidents = false;

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
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.indigo,
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigoAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
          ),
          SizedBox(height: 12),
          Text(_userProfile?['name'] ?? 'Usuário',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(_userProfile?['email'] ?? '',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoadingIncidents = true);
    try {
      final data = await widget.apiService.getIncidents();
      print('Incidentes carregados: ${data.length}');
      setState(() {
        _incidents = data;
        _isLoadingIncidents = false;
      });
    } catch (e) {
      print('Erro ao carregar incidentes: $e');
      setState(() => _isLoadingIncidents = false);
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
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: AssetImage('assets/images/logo.png'),
              ),
            ),
            SizedBox(width: 12),
            Text('Bairro Seguro',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                )),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            _buildDrawerHeader(),
            ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('Configurações'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Ajuda'),
              onTap: () => Navigator.pop(context),
            ),
            Divider(),
            Spacer(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Sair',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: _logout,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMapView(),
          _buildListView(),
          ProfileScreen(
              apiService: widget.apiService,
              showAppBar: false), // Using ProfileScreen as a widget
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(Icons.map_outlined, size: 28),
            ),
            selectedIcon: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(Icons.map, size: 28),
            ),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(Icons.list_alt_rounded, size: 28),
            ),
            selectedIcon: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(Icons.list_alt_rounded, size: 28),
            ),
            label: 'Incidentes',
          ),
          NavigationDestination(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(Icons.person_outline, size: 28),
            ),
            selectedIcon: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(Icons.person, size: 28),
            ),
            label: 'Perfil',
          ),
        ],
        height: 80,
      ),
      floatingActionButton: _currentIndex == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      Center(child: CircularProgressIndicator()),
                );

                try {
                  final profile = await widget.apiService.getProfile();
                  Navigator.pop(context); // Close loading dialog

                  if (profile['is_profile_complete'] == true) {
                    Navigator.pushNamed(context, '/report')
                        .then((_) => _loadIncidents());
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
              label: Text('Relatar',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              icon: Icon(Icons.add_location_alt_rounded, size: 24),
              extendedPadding: EdgeInsets.symmetric(horizontal: 20),
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
            Text(
                'Para manter a segurança da nossa comunidade, solicitamos que você complete seu cadastro antes de relatar um incidente.'),
            SizedBox(height: 16),
            Text('Campos necessários:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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

  Widget _buildMapView() {
    return FlutterMap(
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
              final lat =
                  double.parse(incident['location']['latitude'].toString());
              final lng =
                  double.parse(incident['location']['longitude'].toString());

              return Marker(
                point: LatLng(lat, lng),
                width: 52,
                height: 52,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showIncidentDetails(incident);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getSeverityColor(incident['severity_level'])
                          .withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3))
                      ],
                    ),
                    child: Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
              );
            } catch (e) {
              return Marker(point: LatLng(0, 0), child: SizedBox.shrink());
            }
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    if (_isLoadingIncidents) {
      return ListView.builder(
        itemCount: 6,
        padding: EdgeInsets.only(top: 16),
        itemBuilder: (context, index) => const SkeletonIncident(),
      );
    }

    if (_incidents.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(height: 16),
            Text('Nenhum incidente relatado no momento',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIncidents,
      child: ListView.builder(
        itemCount: _incidents.length,
        padding: EdgeInsets.only(top: 16, bottom: 80),
        itemBuilder: (context, index) {
          final incident = _incidents[index];
          return IncidentListItem(
            incident: incident,
            onTap: () {
              HapticFeedback.lightImpact();

              // 1. Pegar coordenadas do incidente
              final lat =
                  double.parse(incident['location']['latitude'].toString());
              final lng =
                  double.parse(incident['location']['longitude'].toString());
              final incidentPoint = LatLng(lat, lng);

              // 2. Mudar para a aba do Mapa (índice 0)
              setState(() => _currentIndex = 0);

              // 3. Mover o mapa para o ponto e mostrar detalhes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapController.move(incidentPoint, 15);
                _showIncidentDetails(incident);
              });
            },
          );
        },
      ),
    );
  }

  void _showIncidentDetails(dynamic incident) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(incident['severity_level'])
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: _getSeverityColor(incident['severity_level']),
                    size: 32,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getSeverityText(incident['severity_level']),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getSeverityColor(incident['severity_level']),
                        ),
                      ),
                      Text(
                        'Incidente Relatado',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Descrição:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              incident['description'],
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Data e Hora: ${Utils.formatDateTime(incident['datetime'])}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Bairro: ${incident['neighborhood'] ?? 'Não informado'}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
