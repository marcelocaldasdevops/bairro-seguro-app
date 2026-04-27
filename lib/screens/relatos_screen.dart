import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import 'incident_details_screen.dart';

class RelatosScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback? onCreateIncident;
  final VoidCallback? onIncidentChanged;
  final int refreshToken;

  const RelatosScreen({
    super.key,
    required this.apiService,
    this.onCreateIncident,
    this.onIncidentChanged,
    this.refreshToken = 0,
  });

  @override
  State<RelatosScreen> createState() => _RelatosScreenState();
}

class _RelatosScreenState extends State<RelatosScreen> {
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
  void didUpdateWidget(covariant RelatosScreen oldWidget) {
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
                    child: Text(
                      'Relatos Resolvidos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ),
                  Text(
                    '${(_resolvedCount * 14).clamp(0, 84)}%',
                    style: const TextStyle(
                      color: Color(0xFF54E4B4),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: ((_resolvedCount * 14).clamp(0, 84)) / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF54E4B4)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tempo Médio Resposta',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ),
                  Text(
                    _avgResponseLabel,
                    style: const TextStyle(
                      color: Color(0xFFA9B8FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                    Text(
                      _statusLabel((incident['criticality'] ?? incident['severity_level']).toString()).toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Há ${incident['time_ago'] ?? '15 min'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  incident['title'] ?? 'Ocorrência',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color == const Color(0xFFF5B0AC) ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.place_outlined, color: color, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        incident['address'] ?? incident['reference_point'] ?? 'Localização no mapa',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color == const Color(0xFFF5B0AC) ? Colors.white70 : null,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  incident['description'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color == const Color(0xFFF5B0AC) ? Colors.white : null,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF54E4B4), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${incident['confirmations_count'] ?? 12}',
                      style: const TextStyle(color: Color(0xFF54E4B4), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 24),
                    const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white54),
                    const SizedBox(width: 6),
                    const Text(
                      '5',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      'DETALHES >',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if ((incident['comments_count'] ?? 0) >= 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        _CommentPreview(
                          author: 'Anônimo',
                          content: 'ESSA ÁREA COSTUMA SER MUITO PERIG...',
                        ),
                        SizedBox(height: 8),
                        _CommentPreview(
                          author: 'Anônimo',
                          content: 'É MELHOR EVITAR AS 10:00',
                          isBlue: true,
                        ),
                      ],
                    ),
                  ),
                ],
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

  String _statusLabel(String criticality) {
    if (criticality == 'HIGH') return 'Ocorrência Crítica';
    if (criticality == 'MEDIUM') return 'Atenção';
    return 'Relato';
  }
}

class _CommentPreview extends StatelessWidget {
  final String author;
  final String content;
  final bool isBlue;

  const _CommentPreview({
    required this.author,
    required this.content,
    this.isBlue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isBlue ? Colors.blue.withOpacity(0.3) : Colors.white10,
          child: Icon(
            Icons.person,
            size: 16,
            color: isBlue ? Colors.blue : Colors.white24,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              Text(
                content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
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
