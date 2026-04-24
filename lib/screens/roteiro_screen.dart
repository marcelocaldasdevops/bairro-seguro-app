import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import 'incident_details_screen.dart';

class RoteiroScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback? onCreateIncident;
  final VoidCallback? onIncidentChanged;
  final int refreshToken;

  const RoteiroScreen({
    super.key,
    required this.apiService,
    this.onCreateIncident,
    this.onIncidentChanged,
    this.refreshToken = 0,
  });

  @override
  State<RoteiroScreen> createState() => _RoteiroScreenState();
}

class _RoteiroScreenState extends State<RoteiroScreen> {
  static const _categories = ['TODOS', 'ASSALTO', 'INFRAESTRUTURA'];
  static const _criticalities = ['HIGH', 'MEDIUM', 'LOW'];
  static const _radiusOptions = ['0.5', '1.0', '2.0', '5.0'];

  String _selectedCategory = 'TODOS';
  String _selectedCriticality = 'HIGH';
  String _selectedRadius = '1.0';
  int _mode = 0;
  bool _isLoading = true;
  List<dynamic> _feed = [];
  List<dynamic> _mapIncidents = [];

  int get _resolvedCount => _feed.where((item) => (item['status'] ?? '') == 'RESOLVED').length;

  String get _avgResponseLabel {
    if (_feed.isEmpty) return '12min';
    final base = 8 + (_feed.length * 2);
    return '${base}min';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RoteiroScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    var hasError = false;
    try {
      final feed = await widget.apiService.getFeed(
        category: _selectedCategory,
        radiusKm: _selectedRadius,
      );
      if (mounted) {
        setState(() => _feed = feed);
      }
    } catch (_) {
      hasError = true;
    }

    try {
      final mapIncidents = await widget.apiService.getMapIncidents(
        criticality: _selectedCriticality,
      );
      if (mounted) {
        setState(() => _mapIncidents = mapIncidents);
      }
    } catch (_) {
      hasError = true;
    }

    if (mounted && hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível carregar o roteiro.')),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _labelForCategory(String category) {
    switch (category) {
      case 'ASSALTO':
        return 'Assaltos';
      case 'INFRAESTRUTURA':
        return 'Infraestrutura';
      default:
        return 'Todos';
    }
  }

  Color _criticalityColor(String value) {
    switch (value) {
      case 'HIGH':
        return const Color(0xFFF5B0AC);
      case 'MEDIUM':
        return const Color(0xFFFFC928);
      default:
        return const Color(0xFF54E4B4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Feed')),
                  ButtonSegment(value: 1, label: Text('Mapa')),
                ],
                selected: {_mode},
                onSelectionChanged: (values) {
                  setState(() => _mode = values.first);
                },
              ),
              const SizedBox(height: 16),
              if (_mode == 0) _buildFeedFilters() else _buildMapFilters(),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _mode == 0
                  ? RefreshIndicator(onRefresh: _load, child: _buildFeed())
                  : _buildMap(),
        ),
      ],
    );
  }

  Widget _buildFeedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((category) {
              final isSelected = category == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(_labelForCategory(category)),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                    _load();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Raio de monitoramento', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _radiusOptions.map((radius) {
                  final isSelected = radius == _selectedRadius;
                  return ChoiceChip(
                    label: Text('${radius}km'),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedRadius = radius);
                      _load();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF20293A),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estatísticas do Dia',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _StatMini(
                      title: 'Relatos resolvidos',
                      value: '${(_resolvedCount * 14).clamp(0, 84)}%',
                      accent: const Color(0xFF54E4B4),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _StatMini(
                      title: 'Tempo médio resposta',
                      value: _avgResponseLabel,
                      accent: const Color(0xFFA9B8FF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _criticalities.map((criticality) {
          final isSelected = criticality == _selectedCriticality;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(criticality == 'HIGH' ? 'Crítico' : criticality == 'MEDIUM' ? 'Médio' : 'Atenção'),
              selected: isSelected,
              selectedColor: _criticalityColor(criticality).withOpacity(0.2),
              onSelected: (_) {
                setState(() => _selectedCriticality = criticality);
                _load();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeed() {
    if (_feed.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(child: Text('Nenhuma ocorrência encontrada para os filtros atuais.')),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      itemCount: _feed.length,
      itemBuilder: (context, index) {
        final incident = _feed[index] as Map<String, dynamic>;
        final color = _criticalityColor((incident['criticality'] ?? incident['severity_level']).toString());
        return GestureDetector(
          onTap: () => _openIncidentDetails(incident),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color == const Color(0xFFF5B0AC)
                  ? const Color(0xFF311318)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _labelForCategory((incident['category'] ?? 'TODOS').toString()),
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    Text(incident['datetime']?.toString().substring(0, 16) ?? ''),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  incident['title'] ?? 'Ocorrência',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color == const Color(0xFFF5B0AC) ? Colors.white : null,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident['address'] ?? incident['reference_point'] ?? 'Localização no mapa',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color == const Color(0xFFF5B0AC) ? Colors.white70 : null,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  incident['description'] ?? '',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color == const Color(0xFFF5B0AC) ? Colors.white : null,
                      ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text('${incident['confirmations_count'] ?? 0}'),
                    const SizedBox(width: 18),
                    const Icon(Icons.chat_bubble_outline, size: 18),
                    const SizedBox(width: 6),
                    Text('${incident['comments_count'] ?? 0}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _openIncidentDetails(incident),
                      child: const Text('DETALHES'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap() {
    final markers = _mapIncidents.map((item) {
      final incident = item as Map<String, dynamic>;
      final location = incident['location'] as Map<String, dynamic>?;
      final latitude = double.tryParse(location?['latitude']?.toString() ?? '') ?? -3.10;
      final longitude = double.tryParse(location?['longitude']?.toString() ?? '') ?? -59.97;
      final color = _criticalityColor((incident['criticality'] ?? incident['severity_level']).toString());

      return Marker(
        point: LatLng(latitude, longitude),
        width: 42,
        height: 42,
        child: GestureDetector(
          onTap: () {
            _openIncidentDetails(incident);
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.black87),
          ),
        ),
      );
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-3.10194, -59.97416),
            initialZoom: 12.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.com.bairroseguro.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        const Positioned(
          right: 16,
          top: 18,
          child: Column(
            children: [
              _MapAction(icon: Icons.layers_outlined),
              SizedBox(height: 12),
              _MapAction(icon: Icons.add),
              SizedBox(height: 12),
              _MapAction(icon: Icons.remove),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton.extended(
            onPressed: widget.onCreateIncident,
            label: const Text('Reportar'),
            icon: const Icon(Icons.campaign_outlined),
          ),
        ),
      ],
    );
  }

  Future<void> _openIncidentDetails(Map<String, dynamic> incident) async {
    final id = incident['id'];
    if (id is! int) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentDetailsScreen(
          apiService: widget.apiService,
          incidentId: id,
          onIncidentChanged: _load,
        ),
      ),
    );
    await _load();
    widget.onIncidentChanged?.call();
  }
}

class _StatMini extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;

  const _StatMini({
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _MapAction extends StatelessWidget {
  final IconData icon;

  const _MapAction({required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xD91A2029),
      child: Icon(icon, color: Colors.white),
    );
  }
}
