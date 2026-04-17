import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final ApiService apiService;
  RegisterScreen({required this.apiService});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _bairroController = TextEditingController();

  bool _isLoading = false;
  bool _showOptionalFields = false;

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Register base user
      await widget.apiService.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      // 2. Login to get token
      await widget.apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      // 3. Update profile if optional fields are filled
      if (_nameController.text.isNotEmpty ||
          _cpfController.text.isNotEmpty ||
          _bairroController.text.isNotEmpty) {
        await widget.apiService.updateProfile({
          if (_nameController.text.isNotEmpty) 'name': _nameController.text,
          if (_cpfController.text.isNotEmpty) 'cpf': _cpfController.text,
          if (_bairroController.text.isNotEmpty)
            'bairro': _bairroController.text,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cadastro realizado com sucesso!')),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                SizedBox(height: 32),
                _buildBaseFields(),
                SizedBox(height: 24),
                _buildOptionalToggle(),
                if (_showOptionalFields) ...[
                  SizedBox(height: 16),
                  _buildOptionalFields(),
                ],
                SizedBox(height: 48),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.person_add_outlined,
            size: 64, color: theme.colorScheme.primary),
        SizedBox(height: 16),
        Text(
          'Junte-se ao Bairro Seguro',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Sua segurança começa com a colaboração.',
          style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBaseFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _usernameController,
          label: 'Nome de Usuário',
          icon: Icons.person_outline,
          validator: (val) => val!.isEmpty ? 'Campo obrigatório' : null,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'E-mail',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (val) =>
              val!.isEmpty || !val.contains('@') ? 'E-mail inválido' : null,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Senha',
          icon: Icons.lock_outline,
          obscureText: true,
          helperText: 'Mínimo 8 caracteres, com letras e números',
          validator: (val) => val!.length < 8 ? 'Senha muito curta' : null,
        ),
      ],
    );
  }

  Widget _buildOptionalToggle() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _showOptionalFields = !_showOptionalFields);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _showOptionalFields
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 12),
            Text(
              'Configurar perfil agora (opcional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Nome Completo',
          icon: Icons.badge_outlined,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _cpfController,
          label: 'CPF',
          icon: Icons.credit_card_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [cpfMask],
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _bairroController,
          label: 'Bairro',
          icon: Icons.location_city_outlined,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<dynamic>? inputFormatters,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters?.cast(),
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        helperText: helperText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton() {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _register();
            },
            child: Text('Criar minha conta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          );
  }
}
