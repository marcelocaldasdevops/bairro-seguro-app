import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
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
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: CardTheme(
          color: const Color(0xFF1E293B).withOpacity(0.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F172A).withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(apiService: apiService),
        '/home': (context) => HomeScreen(apiService: apiService),
        '/profile': (context) => ProfileScreen(apiService: apiService),
        '/report': (context) => ReportIncidentScreen(apiService: apiService),
      },
    );
  }
}
