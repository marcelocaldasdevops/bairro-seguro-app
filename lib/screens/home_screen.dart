import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;
  HomeScreen({required this.apiService});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _incidents = [];
  LatLng _center = LatLng(-23.550520, -46.633308);
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _determinePosition();
  }

  Future<void> _loadIncidents() async {
    try {
      final data = await widget.apiService.getIncidents();
      setState(() => _incidents = data);
    } catch (e) {
      print(e);
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
      appBar: AppBar(title: Text('Bairro Seguro')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.bairroseguro.mobile',
          ),
          MarkerLayer(
            markers: _incidents.map((incident) {
              return Marker(
                point: LatLng(
                  double.parse(incident['location']['latitude'].toString()),
                  double.parse(incident['location']['longitude'].toString()),
                ),
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
                            Text(incident['severity_level'], 
                              style: TextStyle(fontWeight: FontWeight.bold, 
                              color: _getSeverityColor(incident['severity_level']))),
                            SizedBox(height: 8),
                            Text(incident['description']),
                            SizedBox(height: 16),
                            Text('Relatado em: ${incident['datetime']}', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final profile = await widget.apiService.getProfile();
          if (profile['is_profile_complete']) {
            Navigator.pushNamed(context, '/report').then((_) => _loadIncidents());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Complete seu perfil antes de relatar um incidente')),
            );
            Navigator.pushNamed(context, '/profile');
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
