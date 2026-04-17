import 'package:flutter/material.dart';
import '../helpers/utils.dart';

class IncidentListItem extends StatelessWidget {
  final dynamic incident;
  final VoidCallback onTap;

  const IncidentListItem({
    super.key,
    required this.incident,
    required this.onTap,
  });

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getSeverityText(String severity) {
    switch (severity) {
      case 'HIGH':
        return 'Alto Risco';
      case 'MEDIUM':
        return 'Risco Médio';
      case 'LOW':
        return 'Risco Baixo';
      default:
        return severity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = incident['severity_level'];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: _getSeverityColor(severity),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                _getSeverityColor(severity).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getSeverityText(severity),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getSeverityColor(severity),
                            ),
                          ),
                        ),
                        Text(
                          Utils.formatDateTime(incident['datetime'])
                              .split(' ')[0],
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      incident['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Localização no mapa',
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18, color: colorScheme.onSurfaceVariant),
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
