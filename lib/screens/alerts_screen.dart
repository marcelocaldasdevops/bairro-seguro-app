import 'package:flutter/material.dart';

import '../services/alert_center_service.dart';
import '../services/api_service.dart';
import '../widgets/alert_cards.dart';
import '../widgets/app_states.dart';
import '../widgets/section_title.dart';
import 'incident_details_screen.dart';

class AlertsScreen extends StatefulWidget {
  final ApiService apiService;
  final AlertCenterService alertCenterService;
  final VoidCallback? onAlertsUpdated;
  final VoidCallback? onIncidentChanged;

  const AlertsScreen({
    super.key,
    required this.apiService,
    required this.alertCenterService,
    this.onAlertsUpdated,
    this.onIncidentChanged,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  Map<String, dynamic>? _summary;
  Set<int> _seenAlertIds = const {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        widget.apiService.getDashboardSummary(),
        widget.alertCenterService.getSeenAlertIds(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _seenAlertIds = results[1] as Set<int>;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível carregar os alertas.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final criticalAlerts = _criticalAlerts();
    final ids = criticalAlerts
        .map((item) => item['id'])
        .whereType<int>()
        .toList();
    if (ids.isEmpty) return;

    await widget.alertCenterService.markAlertsAsSeen(ids);
    widget.onAlertsUpdated?.call();
    if (!mounted) return;
    setState(() {
      _seenAlertIds = {..._seenAlertIds, ...ids};
    });
  }

  Future<void> _openIncident(Map<String, dynamic> incident) async {
    final incidentId = incident['id'];
    if (incidentId is! int) return;

    await widget.alertCenterService.markAlertsAsSeen([incidentId]);
    widget.onAlertsUpdated?.call();
    if (mounted) {
      setState(() {
        _seenAlertIds = {..._seenAlertIds, incidentId};
      });
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentDetailsScreen(
          apiService: widget.apiService,
          incidentId: incidentId,
          onIncidentChanged: widget.onIncidentChanged,
        ),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  List<Map<String, dynamic>> _criticalAlerts() {
    final alerts = _summary?['critical_alerts'] as List<dynamic>? ?? [];
    return alerts.whereType<Map<String, dynamic>>().toList();
  }

  int _unreadCount(List<Map<String, dynamic>> alerts) {
    return alerts
        .map((item) => item['id'])
        .whereType<int>()
        .where((id) => !_seenAlertIds.contains(id))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final criticalAlerts = _criticalAlerts();
    final attentionZones =
        _summary?['attention_zones'] as List<dynamic>? ?? const [];
    final unreadCount = _unreadCount(criticalAlerts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Alertas'),
        actions: [
          if (criticalAlerts.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Marcar tudo'),
            ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingState()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.notifications_active_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$unreadCount alerta(s) não lido(s)',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Acompanhe ocorrências críticas e zonas com maior risco.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Ocorrências críticas',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (criticalAlerts.isEmpty)
                    const AppEmptyCard(
                      label: 'Nenhum alerta crítico ativo neste momento.',
                    )
                  else
                    ...criticalAlerts.map(
                      (incident) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AlertListTile(
                          incident: incident,
                          isRead: _seenAlertIds.contains(incident['id']),
                          onTap: () => _openIncident(incident),
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  const SectionTitle(title: 'Zonas monitoradas'),
                  const SizedBox(height: 12),
                  if (attentionZones.isEmpty)
                    const AppEmptyCard(
                      label: 'Nenhuma zona de atenção ativa no momento.',
                    )
                  else
                    ...attentionZones.map(
                      (zone) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ZoneRiskTile(zone: zone as Map<String, dynamic>),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
