import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart'; // Added
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/report_incident_screen.dart';
import 'services/api_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Erro ao carregar .env: $e");
    // Se falhar o carregamento (ex: em produção sem arquivo), o app não deve crashar
    // mas o baseUrl terá que ser tratado no ApiService
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ApiService apiService = ApiService();

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Color(0xFF7986FB) : Colors.indigo;
    final backgroundColor = isDark ? Color(0xFF121212) : Colors.grey[50];
    final surfaceColor = isDark ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.grey[900];
    final textSecondary = isDark ? Colors.grey[400] : Colors.grey[600];

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: brightness,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.indigo[900],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side:
              BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 56),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: textColor, fontSize: 14),
        titleLarge: TextStyle(
            color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(
            color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
                color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return TextStyle(color: textSecondary, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 26);
          }
          return IconThemeData(color: textSecondary, size: 26);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[900],
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bairro Seguro',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
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
