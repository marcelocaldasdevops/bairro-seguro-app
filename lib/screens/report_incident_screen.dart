import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ReportIncidentScreen extends StatefulWidget {
  final ApiService apiService;
  final bool showAppBar;
  final VoidCallback? onIncidentCreated;

  const ReportIncidentScreen({
    super.key,
    required this.apiService,
    this.showAppBar = true,
    this.onIncidentCreated,
  });

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _referenceController = TextEditingController();
  final MapController _mapController = MapController();
  final ImagePicker _imagePicker = ImagePicker();
  int _step = 0;
  String _category = 'ASSALTO';
  String _severity = 'LOW';
  LatLng _selectedLocation = const LatLng(-23.550520, -46.633308);
  bool _isLoading = false;
  File? _selectedImage;

  static const _quickLocations = [
    ('Minha rua', 'Rua Petrópolis'),
    ('Novo local', 'Definir manualmente'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLocation;
      });
      _mapController.move(newLocation, 15);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível obter sua localização.')),
      );
    }
  }

  void _submit() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite uma descrição.')),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um título para a ocorrência.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Primeiro, verifica se o perfil está completo
      final profile = await widget.apiService.getProfile();
      if (!mounted) return;
      final isProfileComplete = profile['name'] != null && 
                                 profile['name'] != '' &&
                                 profile['cpf'] != null && 
                                 profile['cpf'] != '' &&
                                 profile['bairro'] != null && 
                                 profile['bairro'] != '';
      
      if (!isProfileComplete) {
        setState(() => _isLoading = false);
        final shouldGoToProfile = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Perfil Incompleto'),
            content: const Text('Para criar um incidente, você precisa completar seu perfil com Nome, CPF e Bairro.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ir para Perfil'),
              ),
            ],
          ),
        );

        if (!mounted) return;
        if (shouldGoToProfile == true) {
          if (widget.showAppBar) {
            Navigator.pop(context);
          } else {
            Navigator.pushNamed(context, '/profile');
          }
        }
        return;
      }
      
      // Se o perfil está completo, cria o incidente
      // Arredonda para 6 casas decimais para evitar erro de max_digits no backend
      final latitude = double.parse(_selectedLocation.latitude.toStringAsFixed(6));
      final longitude = double.parse(_selectedLocation.longitude.toStringAsFixed(6));
      
      final incident = await widget.apiService.createIncident({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text,
        'category': _category,
        'severity_level': _severity,
        'criticality': _severity,
        'status': 'OPEN',
        'is_emergency': _severity == 'HIGH',
        'bairro': profile['bairro'] ?? '',
        'address': _addressController.text.trim(),
        'reference_point': _referenceController.text.trim(),
        'radius_km': '1.0',
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        }
      });
      if (!mounted) return;
      if (_selectedImage != null && incident['id'] is int) {
        await widget.apiService.uploadIncidentAttachment(
          incidentId: incident['id'] as int,
          file: _selectedImage!,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidente relatado com sucesso!')),
      );
      widget.onIncidentCreated?.call();
      if (widget.showAppBar) {
        Navigator.pop(context, true);
      } else {
        _titleController.clear();
        _descriptionController.clear();
        _addressController.clear();
        _referenceController.clear();
        setState(() {
          _category = 'ASSALTO';
          _severity = 'LOW';
          _selectedImage = null;
          _step = 0;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourcePicker();
    if (!mounted) return;
    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      setState(() => _selectedImage = File(pickedFile.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível selecionar a imagem.')),
      );
    }
  }

  Future<ImageSource?> _showImageSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Usar câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remover foto'),
                onTap: () {
                  setState(() => _selectedImage = null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _canAdvanceFromCurrentStep() {
    switch (_step) {
      case 0:
        return _titleController.text.trim().isNotEmpty;
      case 1:
        return _addressController.text.trim().isNotEmpty;
      case 2:
        return _descriptionController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_canAdvanceFromCurrentStep()) {
      final message = switch (_step) {
        0 => 'Selecione o tipo e informe um título.',
        1 => 'Informe o endereço do incidente.',
        _ => 'Descreva o ocorrido antes de continuar.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_step > 0) {
      setState(() => _step -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _buildStepContent(),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 18,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          child: const Text('Voltar'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                    child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                _nextStep();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _step == 2
                                    ? const Color(0xFFB50014)
                                    : Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              child: Text(
                                _step == 2 ? 'Confirmar e alertar vizinhos' : 'Continuar',
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Este alerta será enviado para moradores em um raio de 1km',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatar Incidente'),
        elevation: 0,
      ),
      body: content,
    );
  }

  Widget _buildStepHeader() {
    return Row(
      children: [
        Expanded(child: _StepBadge(number: '1', label: 'Tipo', isActive: _step == 0, isDone: _step > 0)),
        const SizedBox(width: 8),
        Expanded(child: _StepBadge(number: '2', label: 'Local', isActive: _step == 1, isDone: _step > 1)),
        const SizedBox(width: 8),
        Expanded(child: _StepBadge(number: '3', label: 'Detalhes', isActive: _step == 2)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildTypeStep();
      case 1:
        return _buildLocationStep();
      default:
        return _buildDetailsStep();
    }
  }

  Widget _buildTypeStep() {
    return Column(
      key: const ValueKey('step_type'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('O que está acontecendo?'),
        const SizedBox(height: 16),
        _buildCategoryGrid(),
        const SizedBox(height: 24),
        TextField(
          controller: _titleController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Título da ocorrência',
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _severity,
          decoration: const InputDecoration(
            labelText: 'Criticidade',
            prefixIcon: Icon(Icons.priority_high_rounded),
          ),
          items: const [
            DropdownMenuItem(value: 'LOW', child: Text('Baixa')),
            DropdownMenuItem(value: 'MEDIUM', child: Text('Média')),
            DropdownMenuItem(value: 'HIGH', child: Text('Crítica')),
          ],
          onChanged: (value) => setState(() => _severity = value!),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      key: const ValueKey('step_location'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Onde ocorreu'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gps_fixed, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  const Text('Endereço detectado', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Endereço detectado ou informado',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Ponto de referência',
                  prefixIcon: Icon(Icons.near_me_outlined),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _determinePosition,
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('Ajustar localização manualmente'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: _quickLocations.map((item) {
            final isManual = item.$1 == 'Novo local';
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isManual ? 0 : 12),
                child: GestureDetector(
                  onTap: () {
                    if (!isManual) {
                      setState(() {
                        _addressController.text = item.$2;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isManual ? Icons.add_circle_outline : Icons.groups_2_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 14),
                        Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(item.$2, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 15,
                    onTap: (_, latlng) => setState(() => _selectedLocation = latlng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'br.com.bairroseguro.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 48,
                          height: 48,
                          child: const Icon(Icons.location_on, color: Colors.indigo, size: 48),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        'Toque no mapa para ajustar a localização manualmente',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      key: const ValueKey('step_details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Evidências e descrição'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 104,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_outlined),
                      SizedBox(height: 10),
                      Text('Foto'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 104,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  image: _selectedImage == null
                      ? null
                      : DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: _selectedImage == null
                    ? const Center(
                        child: Icon(Icons.image_outlined, size: 32),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _descriptionController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Descrição do ocorrido',
            hintText: 'Descreva o que está acontecendo... (ex: modelo do carro, número de pessoas)',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 90),
              child: Icon(Icons.description_outlined),
            ),
            suffixIcon: Padding(
              padding: EdgeInsets.only(top: 78),
              child: Icon(Icons.mic_none_outlined),
            ),
          ),
          maxLines: 6,
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    const categories = [
      ('ASSALTO', 'Assalto', Icons.local_police_outlined),
      ('ACIDENTE', 'Acidente', Icons.car_crash_outlined),
      ('SUSPEITO', 'Suspeito', Icons.visibility_outlined),
      ('OUTRO', 'Outro', Icons.more_horiz),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((item) {
        final isSelected = _category == item.$1;
        return GestureDetector(
          onTap: () => setState(() => _category = item.$1),
          child: Container(
            width: (MediaQuery.of(context).size.width - 52) / 2,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.16)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                Icon(item.$3, size: 32),
                const SizedBox(height: 16),
                Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final String number;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepBadge({
    required this.number,
    required this.label,
    this.isActive = false,
    this.isDone = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive || isDone
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.primary.withOpacity(0.12);

    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color,
          foregroundColor: isActive || isDone
              ? Colors.white
              : Theme.of(context).colorScheme.primary,
          child: Text(isDone ? '✓' : number),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
