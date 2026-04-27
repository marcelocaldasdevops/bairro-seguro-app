import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CriticalAlertCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  final VoidCallback onTap;

  const CriticalAlertCard({
    super.key,
    required this.incident,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF3A1219),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5B0AC),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'URGENTE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              (incident['title'] ?? 'Ocorrência crítica').toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              _incidentAddress(incident),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _dateLabel(incident['datetime']?.toString()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
            const Spacer(),
            SizedBox(
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _getIncidentLatLng(incident),
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'br.com.bairroseguro.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _getIncidentLatLng(incident),
                          width: 30,
                          height: 30,
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFF5B0AC),
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

LatLng _getIncidentLatLng(Map<String, dynamic> incident) {
  final location = incident['location'] as Map<String, dynamic>?;
  final latitude = double.tryParse(location?['latitude']?.toString() ?? '') ?? -3.10;
  final longitude = double.tryParse(location?['longitude']?.toString() ?? '') ?? -59.97;
  return LatLng(latitude, longitude);
}

class AlertListTile extends StatelessWidget {
  final Map<String, dynamic> incident;
  final bool isRead;
  final VoidCallback onTap;

  const AlertListTile({
    super.key,
    required this.incident,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _accentForCriticality(
      (incident['criticality'] ?? incident['severity_level'])?.toString(),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isRead ? Colors.transparent : color.withOpacity(0.4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: isRead ? Colors.transparent : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _categoryLabel(incident['category']?.toString()),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isRead ? 'Lido' : 'Novo',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (incident['title'] ?? 'Ocorrência crítica').toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _incidentAddress(incident),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: color),
                        const SizedBox(width: 6),
                        Text(
                          '${incident['confirmations_count'] ?? 0} confirmações',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${incident['comments_count'] ?? 0} comentários',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ZoneRiskTile extends StatelessWidget {
  final Map<String, dynamic> zone;
  final bool compact;
  final bool showChevron;

  const ZoneRiskTile({
    super.key,
    required this.zone,
    this.compact = false,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final risk = (zone['risk'] ?? 'Médio').toString();
    final color = switch (risk) {
      'Alto' => const Color(0xFFEE6C5E),
      'Baixo' => const Color(0xFF54E4B4),
      _ => const Color(0xFFFFC928),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(compact ? 24 : 22),
      ),
      child: Row(
        children: [
          compact
              ? CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(Icons.place_outlined, color: color),
                )
              : Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.place_outlined, color: color),
                ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (zone['label'] ?? 'Zona monitorada').toString(),
                  style: compact
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                ),
                const SizedBox(height: 4),
                Text(
                  compact
                      ? '${zone['incidents_count'] ?? 0} incidentes · Risco $risk'
                      : '${zone['incidents_count'] ?? 0} ocorrência(s) recentes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          showChevron
              ? const Icon(Icons.chevron_right)
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    risk,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

Color _accentForCriticality(String? criticality) {
  switch (criticality) {
    case 'HIGH':
      return const Color(0xFFEE6C5E);
    case 'MEDIUM':
      return const Color(0xFFFFC928);
    default:
      return const Color(0xFF54E4B4);
  }
}

String _categoryLabel(String? category) {
  switch (category) {
    case 'ASSALTO':
      return 'Assalto';
    case 'ACIDENTE':
      return 'Acidente';
    case 'SUSPEITO':
      return 'Suspeito';
    case 'INFRAESTRUTURA':
      return 'Infraestrutura';
    default:
      return 'Outro';
  }
}

String _incidentAddress(Map<String, dynamic> incident) {
  return (incident['address'] ??
          incident['reference_point'] ??
          'Localização no mapa')
      .toString();
}

String _dateLabel(String? rawDate) {
  final raw = (rawDate ?? '').replaceFirst('T', ' ');
  if (raw.isEmpty) return '';
  return raw.length > 16 ? raw.substring(0, 16) : raw;
}
