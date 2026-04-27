import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../widgets/alert_cards.dart';
import '../widgets/app_states.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_title.dart';
import 'incident_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ApiService apiService;
  final int refreshToken;

  const DashboardScreen({
    super.key,
    required this.apiService,
    this.refreshToken = 0,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // Obter localização real
      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition();
          setState(() => _currentPosition = position);
        }
      } catch (e) {
        debugPrint('Erro ao obter localização: $e');
      }

      final data = await widget.apiService.getDashboardSummary(
        latitude: position?.latitude,
        longitude: position?.longitude,
        radiusKm: 2.0,
      );
      setState(() => _summary = data);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar o dashboard.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _summary ?? {};
    final criticalAlerts = summary['critical_alerts'] as List<dynamic>? ?? [];
    final attentionZones = summary['attention_zones'] as List<dynamic>? ?? [];

    if (_isLoading) {
      return const AppLoadingState();
    }

    final center = _currentPosition != null 
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-3.10194, -59.97416); // Fallback para Manaus se não houver posição

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 380,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13.5,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'br.com.bairroseguro.app',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: center,
                          radius: 2000, // Raio de 2km
                          useRadiusInMeter: true,
                          color: Colors.blue.withOpacity(0.1),
                          borderColor: Colors.blue.withOpacity(0.3),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC928).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFC928),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFFFC928),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Gradient overlay for better text readability at the bottom of the map
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        theme.scaffoldBackgroundColor.withOpacity(0.8),
                        theme.scaffoldBackgroundColor,
                      ],
                      stops: const [0.6, 0.9, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 40,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _StatusIndicator(percentage: summary['safety_percentage'] ?? 85),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'STATUS DA ÁREA',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white54,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              summary['status'] ?? 'Moderado',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(color: Colors.white10, indent: 8, endIndent: 8),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'RAIO',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white54,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${summary['radius_km'] ?? 1.0}km',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 110,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.fullscreen, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Últimas 24h',
                        value: '${summary['incidents_last_24h'] ?? 0}',
                        suffix: 'relatos',
                        accent: const Color(0xFFA9B8FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'Atividade',
                        value: '${summary['active_watchers'] ?? 0}',
                        suffix: 'vigilantes',
                        accent: const Color(0xFF54E4B4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: SectionTitle(
                        title: 'Alertas críticos',
                        uppercase: true,
                      ),
                    ),
                    Text('Arraste para ver', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 12),
                if (criticalAlerts.isEmpty)
                  const AppEmptyCard(
                    height: 180,
                    label: 'Nenhum alerta crítico ativo no momento.',
                  )
                else
                  SizedBox(
                    height: 214,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: criticalAlerts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final incident = criticalAlerts[index] as Map<String, dynamic>;
                        return CriticalAlertCard(
                          incident: incident,
                          onTap: () => _openIncidentDetails(incident),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: _ActionCard(
                        title: 'EMERGÊNCIA',
                        subtitle: 'Acesso rápido',
                        color: Color(0xFFBF0A18),
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        title: 'MEU GRUPO',
                        subtitle: (summary['bairro'] ?? 'Vizinhos próximos').toString(),
                        color: const Color(0xFF202B43),
                        icon: Icons.groups_2_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const SectionTitle(title: 'Zonas de atenção', uppercase: true),
                const SizedBox(height: 12),
                if (attentionZones.isEmpty)
                  const AppEmptyCard(
                    height: 88,
                    label: 'Nenhuma zona de atenção mapeada ainda.',
                  )
                else
                  ...attentionZones.map(
                    (zone) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ZoneRiskTile(
                        zone: zone as Map<String, dynamic>,
                        compact: true,
                        showChevron: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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
    if (!mounted) return;
    await _load();
  }
}

class _StatusIndicator extends StatelessWidget {
  final int percentage;

  const _StatusIndicator({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFC928).withOpacity(0.2),
          width: 3,
        ),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 3,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC928)),
            ),
          ),
          Text(
            '$percentage%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
