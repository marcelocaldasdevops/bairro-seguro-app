import 'package:flutter/material.dart';

import '../services/alert_center_service.dart';
import '../services/api_service.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'report_incident_screen.dart';
import 'roteiro_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;

  const HomeScreen({super.key, required this.apiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlertCenterService _alertCenterService = AlertCenterService();
  int _currentIndex = 0;
  int _refreshToken = 0;
  Map<String, dynamic>? _profile;
  int _unreadAlerts = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUnreadAlerts();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.apiService.getProfile();
      if (mounted) {
        setState(() => _profile = profile);
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    await widget.apiService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _openReportTab() {
    setState(() => _currentIndex = 2);
  }

  void _refreshDataAndGoToRoteiro() {
    setState(() {
      _refreshToken += 1;
      _currentIndex = 1;
    });
    _loadUnreadAlerts();
  }

  Future<void> _loadUnreadAlerts() async {
    try {
      final summary = await widget.apiService.getDashboardSummary();
      final criticalAlerts = summary['critical_alerts'] as List<dynamic>? ?? [];
      final unreadCount =
          await _alertCenterService.getUnreadCount(criticalAlerts);
      if (!mounted) return;
      setState(() => _unreadAlerts = unreadCount);
    } catch (_) {}
  }

  Future<void> _openAlerts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlertsScreen(
          apiService: widget.apiService,
          alertCenterService: _alertCenterService,
          onAlertsUpdated: _loadUnreadAlerts,
          onIncidentChanged: _refreshDataAndGoToRoteiro,
        ),
      ),
    );
    if (!mounted) return;
    await _loadUnreadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        apiService: widget.apiService,
        refreshToken: _refreshToken,
      ),
      RoteiroScreen(
        apiService: widget.apiService,
        onCreateIncident: _openReportTab,
        onIncidentChanged: _refreshDataAndGoToRoteiro,
        refreshToken: _refreshToken,
      ),
      ReportIncidentScreen(
        apiService: widget.apiService,
        showAppBar: false,
        onIncidentCreated: _refreshDataAndGoToRoteiro,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manaus · AM'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _openAlerts,
              icon: _AlertBell(unreadCount: _unreadAlerts),
              tooltip: 'Alertas',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                child: Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Text(_initialForProfile()),
                ),
                title: Text(_profile?['name'] ?? 'Usuário'),
                subtitle: Text(_profile?['email'] ?? ''),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Meu perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(apiService: widget.apiService),
                    ),
                  ).then((_) => _loadProfile());
                },
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Locais'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.alt_route_outlined),
                title: const Text('Roteiro'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                  _loadUnreadAlerts();
                },
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Vigília'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Central de alertas'),
                trailing: _unreadAlerts > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '$_unreadAlerts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _openAlerts();
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair', style: TextStyle(color: Colors.red)),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        height: 82,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Locais',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route),
            label: 'Roteiro',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Vigília',
          ),
        ],
      ),
    );
  }

  String _initialForProfile() {
    final value = (_profile?['name'] ?? _profile?['username'] ?? 'U').toString().trim();
    if (value.isEmpty) {
      return 'U';
    }
    return value.substring(0, 1).toUpperCase();
  }
}

class _AlertBell extends StatelessWidget {
  final int unreadCount;

  const _AlertBell({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_none_rounded),
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEE6C5E),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
