import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final ApiService apiService;
  LoginScreen({required this.apiService});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      await widget.apiService.login(
        _emailController.text,
        _passwordController.text,
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Color(0xFF1E1E1E), Color(0xFF121212)]
                : [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('assets/images/logo.png'),
                  ),
                ),
                SizedBox(height: 24),
                Text('Bairro Seguro',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      color: theme.colorScheme.primary,
                    )),
                SizedBox(height: 8),
                Text('Sua vizinhança mais conectada',
                    style: TextStyle(
                        color: theme.colorScheme.primary.withOpacity(0.7),
                        fontSize: 16)),
                SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    labelStyle:
                        TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.email_outlined,
                        color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    labelStyle:
                        TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.lock_outline,
                        color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 32),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _login();
                        },
                        child: Text('Entrar',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text('Não tem uma conta? Cadastre-se agora',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
