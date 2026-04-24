import 'package:shared_preferences/shared_preferences.dart';

class AlertCenterService {
  static const _seenAlertIdsKey = 'bairro_seguro_seen_alert_ids';

  Future<Set<int>> getSeenAlertIds() async {
    final prefs = await SharedPreferences.getInstance();
    final rawIds = prefs.getStringList(_seenAlertIdsKey) ?? const [];
    return rawIds.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> markAlertsAsSeen(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getSeenAlertIds();
    current.addAll(ids);
    await prefs.setStringList(
      _seenAlertIdsKey,
      current.map((id) => id.toString()).toList(),
    );
  }

  Future<int> getUnreadCount(List<dynamic> alerts) async {
    final seenIds = await getSeenAlertIds();
    final alertIds = alerts
        .map((item) => item is Map<String, dynamic> ? item['id'] : null)
        .whereType<int>();
    return alertIds.where((id) => !seenIds.contains(id)).length;
  }
}
