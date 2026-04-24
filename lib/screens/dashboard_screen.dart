import 'package:flutter/material.dart';

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
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

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
      final data = await widget.apiService.getDashboardSummary();
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _SectionHeader(
            title: summary['location_label'] ?? 'Manaus · AM',
            subtitle: 'Visão geral da sua área',
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF172134), Color(0xFF101827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22111824),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary['bairro'] ?? 'Área monitorada',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Status da área',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        summary['status'] ?? 'Moderado',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFC928), width: 6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${summary['safety_percentage'] ?? 0}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.menu,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.14),
          child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
        ),
      ],
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
