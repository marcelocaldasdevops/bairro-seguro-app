import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final ApiService apiService;
  ProfileScreen({required this.apiService});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _bairroController = TextEditingController();
  bool _isLoading = false;

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##', 
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    try {
      final profile = await widget.apiService.getProfile();
      setState(() {
        _nameController.text = profile['name'] ?? '';
        _cpfController.text = profile['cpf'] ?? '';
        _bairroController.text = profile['bairro'] ?? '';
      });
    } catch (e) {
      print(e);
    }
  }

  void _save() async {
    setState(() => _isLoading = true);
    try {
      await widget.apiService.updateProfile({
        'name': _nameController.text,
        'cpf': _cpfController.text,
        'bairro': _bairroController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
      Navigator.pop(context);
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
        title: Text('Meu Perfil'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              SizedBox(height: 32),
              _buildFields(),
              SizedBox(height: 32),
              _buildSaveButton(),
              SizedBox(height: 16),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: () {
        widget.apiService.logout();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      },
      icon: Icon(Icons.logout, color: Colors.red),
      label: Text('Sair da Conta', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.red.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.person_outline, size: 50, color: Theme.of(context).colorScheme.primary),
        ),
        SizedBox(height: 16),
        Text(
          'Informações Pessoais',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Mantenha seus dados atualizados para relatar incidentes.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildFields() {
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
    TextInputType? keyboardType,
    List<dynamic>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters?.cast(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }

  Widget _buildSaveButton() {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _save,
            child: Text('Salvar Alterações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
  }
}
