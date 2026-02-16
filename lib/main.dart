import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart'; // Added
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/report_incident_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bairro Seguro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter', // Note: User needs to add font or it falls back to default
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(apiService: apiService),
        '/register': (context) => RegisterScreen(apiService: apiService),
        '/home': (context) => HomeScreen(apiService: apiService),
        '/profile': (context) => ProfileScreen(apiService: apiService),
        '/report': (context) => ReportIncidentScreen(apiService: apiService),
      },
    );
  }
}
