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
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print(e);
    }
  }

  void _submit() async {
    if (_descriptionController.text.isEmpty) return;
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
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Relatar Incidente')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: FlutterMap(
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
                        width: 40,
                        height: 40,
                        child: Icon(Icons.location_on, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Descrição'),
                    maxLines: 3,
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _severity,
                    items: [
                      DropdownMenuItem(value: 'LOW', child: Text('Baixo')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Médio')),
                      DropdownMenuItem(value: 'HIGH', child: Text('Alto')),
                    ],
                    onChanged: (v) => setState(() => _severity = v!),
                  ),
                  SizedBox(height: 30),
                  _isLoading 
                    ? CircularProgressIndicator() 
                    : ElevatedButton(onPressed: _submit, child: Text('Enviar')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
