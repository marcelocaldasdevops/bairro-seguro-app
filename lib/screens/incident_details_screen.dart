import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../widgets/app_states.dart';
import '../widgets/status_tokens.dart';

class IncidentDetailsScreen extends StatefulWidget {
  final ApiService apiService;
  final int incidentId;
  final VoidCallback? onIncidentChanged;

  const IncidentDetailsScreen({
    super.key,
    required this.apiService,
    required this.incidentId,
    this.onIncidentChanged,
  });

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();

  Map<String, dynamic>? _incident;
  List<dynamic> _comments = const [];
  bool _isLoading = true;
  bool _isSubmittingComment = false;
  bool _isConfirming = false;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final incident =
          await widget.apiService.getIncidentDetails(widget.incidentId);
      final comments =
          await widget.apiService.getIncidentComments(widget.incidentId);
      if (!mounted) return;
      setState(() {
        _incident = incident;
        _comments = comments;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar esta ocorrência.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleConfirmation() async {
    final isConfirmed = (_incident?['confirmed_by_me'] as bool?) ?? false;
    setState(() => _isConfirming = true);
    try {
      if (isConfirmed) {
        await widget.apiService.unconfirmIncident(widget.incidentId);
      } else {
        await widget.apiService.confirmIncident(widget.incidentId);
      }
      await _load();
      _markIncidentChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConfirmed ? 'Confirmação removida.' : 'Ocorrência confirmada.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar a confirmação.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    try {
      await widget.apiService.createComment(widget.incidentId, content);
      _commentController.clear();
      await _load();
      _markIncidentChanged();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível enviar o comentário.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  void _markIncidentChanged() {
    _hasChanged = true;
    widget.onIncidentChanged?.call();
  }

  Color _riskColor(String? criticality) {
    switch (criticality) {
      case 'HIGH':
        return const Color(0xFFF5B0AC);
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

  String _statusLabel(String? status) {
    switch (status) {
      case 'UNDER_REVIEW':
        return 'Em análise';
      case 'RESOLVED':
        return 'Resolvido';
      case 'DISMISSED':
        return 'Descartado';
      default:
        return 'Aberto';
    }
  }

  String _criticalityLabel(String? criticality) {
    switch (criticality) {
      case 'HIGH':
        return 'Alta';
      case 'MEDIUM':
        return 'Média';
      default:
        return 'Baixa';
    }
  }

  String _formatDateTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Agora há pouco';
    final date = DateTime.tryParse(rawDate)?.toLocal();
    if (date == null) return 'Agora há pouco';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month às $hour:$minute';
  }

  String _relativeTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Recente';
    final date = DateTime.tryParse(rawDate)?.toLocal();
    if (date == null) return 'Recente';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours} h atrás';
    return '${diff.inDays} d atrás';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: AppLoadingState(),
      );
    }

    final incident = _incident ?? <String, dynamic>{};
    final criticality =
        (incident['criticality'] ?? incident['severity_level'])?.toString();
    final color = _riskColor(criticality);
    final attachments = incident['attachments'] as List<dynamic>? ?? [];
    final location = incident['location'] as Map<String, dynamic>?;
    final latitude = double.tryParse(location?['latitude']?.toString() ?? '');
    final longitude = double.tryParse(location?['longitude']?.toString() ?? '');
    final hasMapLocation = latitude != null && longitude != null;
    final isConfirmedByMe = (incident['confirmed_by_me'] as bool?) ?? false;
    final isReportedByMe = (incident['reported_by_me'] as bool?) ?? false;
    final createdAt = incident['datetime']?.toString();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {
        if (_hasChanged) {
          widget.onIncidentChanged?.call();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalhes da Ocorrência')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _categoryLabel(incident['category']?.toString()),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        MetaPill(
                          icon: Icons.flag_outlined,
                          label: _statusLabel(incident['status']?.toString()),
                        ),
                        MetaPill(
                          icon: Icons.schedule_outlined,
                          label: _relativeTime(createdAt),
                        ),
                        if (incident['is_emergency'] == true)
                          const MetaPill(
                            icon: Icons.warning_amber_rounded,
                            label: 'Emergência',
                          ),
                        if (isReportedByMe)
                          const MetaPill(
                            icon: Icons.person_outline,
                            label: 'Relatado por você',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      incident['title'] ?? 'Ocorrência',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      incident['address'] ??
                          incident['reference_point'] ??
                          'Localização no mapa',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(incident['description'] ?? ''),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        DetailMetricChip(
                          title: 'Criticidade',
                          value: _criticalityLabel(criticality),
                          color: color,
                        ),
                        DetailMetricChip(
                          title: 'Bairro',
                          value:
                              (incident['bairro']?.toString().isNotEmpty ??
                                      false)
                                  ? incident['bairro'].toString()
                                  : 'Área monitorada',
                          color: Colors.blueGrey,
                        ),
                        DetailMetricChip(
                          title: 'Raio',
                          value: '${incident['radius_km'] ?? '1.0'} km',
                          color: Colors.indigo,
                        ),
                        DetailMetricChip(
                          title: 'Autor',
                          value:
                              (incident['user_name']?.toString().isNotEmpty ??
                                      false)
                                  ? incident['user_name'].toString()
                                  : (incident['user_username']?.toString() ??
                                      'Morador'),
                          color: Colors.teal,
                        ),
                      ],
                    ),
                    if (hasMapLocation) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 180,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(latitude, longitude),
                                  initialZoom: 15,
                                  interactionOptions:
                                      const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'br.com.bairroseguro.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(latitude, longitude),
                                        width: 48,
                                        height: 48,
                                        child: Icon(
                                          Icons.location_on,
                                          color: color,
                                          size: 42,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    incident['address'] ??
                                        incident['reference_point'] ??
                                        'Localização informada no mapa',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (attachments.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Evidências (${attachments.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: attachments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final attachment =
                                attachments[index] as Map<String, dynamic>;
                            return _AttachmentPreview(attachment: attachment);
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        InfoBadge(
                          icon: Icons.shield_outlined,
                          label:
                              '${incident['confirmations_count'] ?? 0} confirmações',
                          color: color,
                        ),
                        const SizedBox(width: 10),
                        InfoBadge(
                          icon: Icons.chat_bubble_outline,
                          label:
                              '${incident['comments_count'] ?? 0} comentários',
                          color: Colors.blueGrey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _isConfirming
                        ? const Center(child: CircularProgressIndicator())
                        : FilledButton.tonalIcon(
                            onPressed: _toggleConfirmation,
                            icon: Icon(
                              isConfirmedByMe
                                  ? Icons.verified_user
                                  : Icons.verified_user_outlined,
                            ),
                            label: Text(
                              isConfirmedByMe
                                  ? 'Remover minha confirmação'
                                  : 'Confirmar ocorrência',
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Comentários',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Adicione contexto para outros moradores',
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isSubmittingComment
                        ? const Center(child: CircularProgressIndicator())
                        : Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: _sendComment,
                              child: const Text('Enviar comentário'),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_comments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Ainda não há comentários para esta ocorrência.',
                  ),
                ),
              ..._comments.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CommentTile(comment: item as Map<String, dynamic>),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final Map<String, dynamic> attachment;

  const _AttachmentPreview({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (attachment['file_url'] ?? '').toString();
    return GestureDetector(
      onTap: imageUrl.isEmpty ? null : () => _openPreview(context, imageUrl),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          image: imageUrl.isEmpty
              ? null
              : DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
        ),
        child: imageUrl.isEmpty
            ? const Center(child: Icon(Icons.attachment_outlined))
            : Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.open_in_full,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  void _openPreview(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AttachmentViewer(imageUrl: imageUrl),
      ),
    );
  }
}

class _AttachmentViewer extends StatelessWidget {
  final String imageUrl;

  const _AttachmentViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Evidência'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _CommentTile({required this.comment});

  String _relativeTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Recente';
    final date = DateTime.tryParse(rawDate)?.toLocal();
    if (date == null) return 'Recente';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours} h atrás';
    return '${diff.inDays} d atrás';
  }

  @override
  Widget build(BuildContext context) {
    final author =
        (comment['user_name'] ?? comment['user_username'] ?? 'Anônimo')
            .toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: Text(
              author.isNotEmpty ? author.substring(0, 1).toUpperCase() : 'A',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        author,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      _relativeTime(comment['created_at']?.toString()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(comment['content'] ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
