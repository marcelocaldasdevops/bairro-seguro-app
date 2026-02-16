import 'package:flutter/material.dart';
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
        _usernameController.text,
        _passwordController.text,
      );

      // 3. Update profile if optional fields are filled
      if (_nameController.text.isNotEmpty || 
          _cpfController.text.isNotEmpty || 
          _bairroController.text.isNotEmpty) {
        await widget.apiService.updateProfile({
          if (_nameController.text.isNotEmpty) 'name': _nameController.text,
          if (_cpfController.text.isNotEmpty) 'cpf': _cpfController.text,
          if (_bairroController.text.isNotEmpty) 'bairro': _bairroController.text,
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Criar Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[50]!],
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
    return Column(
      children: [
        Icon(Icons.person_add_outlined, size: 64, color: Theme.of(context).primaryColor),
        SizedBox(height: 16),
        Text(
          'Junte-se ao Bairro Seguro',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Sua segurança começa com a colaboração.',
          style: TextStyle(color: Colors.grey[600]),
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
          validator: (val) => val!.isEmpty || !val.contains('@') ? 'E-mail inválido' : null,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Senha',
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (val) => val!.length < 6 ? 'Mínimo 6 caracteres' : null,
        ),
      ],
    );
  }

  Widget _buildOptionalToggle() {
    return InkWell(
      onTap: () => setState(() => _showOptionalFields = !_showOptionalFields),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _showOptionalFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: 12),
            Text(
              'Configurar perfil agora (opcional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters?.cast(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton() {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _register,
            child: Text('Criar minha conta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          );
  }
}
