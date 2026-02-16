import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class ReportIncidentScreen extends StatefulWidget {
  final ApiService apiService;
  ReportIncidentScreen({required this.apiService});

  @override
  _ReportIncidentScreenState createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _descriptionController = TextEditingController();
  final MapController _mapController = MapController();
  String _severity = 'LOW';
  LatLng _selectedLocation = LatLng(-23.550520, -46.633308);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLocation;
      });
      _mapController.move(newLocation, 15);
    } catch (e) {
      print('Erro ao obter localização: $e');
    }
  }

  void _submit() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, digite uma descrição.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.apiService.createIncident({
        'description': _descriptionController.text,
        'severity_level': _severity,
        'location': {
          'latitude': _selectedLocation.latitude,
          'longitude': _selectedLocation.longitude,
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incidente relatado com sucesso!')),
      );
      Navigator.pop(context, true); // Return true to signal success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Relatar Incidente'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 350,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation,
                      initialZoom: 15,
                      onTap: (_, latlng) => setState(() => _selectedLocation = latlng),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'br.com.bairroseguro.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation,
                            width: 50,
                            height: 50,
                            child: Icon(Icons.location_on, color: Colors.indigo, size: 50),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Toque no mapa para ajustar o local exato',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter_map',
                      onPressed: _determinePosition,
                      child: Icon(Icons.my_location),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descrição do ocorrido',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _severity,
                    decoration: InputDecoration(
                      labelText: 'Nível de Gravidade',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      prefixIcon: Icon(Icons.priority_high_rounded),
                    ),
                    items: [
                      DropdownMenuItem(value: 'LOW', child: Text('Baixo')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Médio')),
                      DropdownMenuItem(value: 'HIGH', child: Text('Alto')),
                    ],
                    onChanged: (v) => setState(() => _severity = v!),
                  ),
                  SizedBox(height: 32),
                  _isLoading 
                    ? Center(child: CircularProgressIndicator()) 
                    : ElevatedButton(
                        onPressed: _submit,
                        child: Text('Enviar Relato', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
