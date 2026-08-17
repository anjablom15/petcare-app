import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'crop_photo_screen.dart';

class AddPetScreen extends StatefulWidget {
  final Pet? pet;
  const AddPetScreen({super.key, this.pet});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _existingConditionsController;

  String? _species;
  DateTime? _birthday;
  DateTime? _gotchaDate;

  Uint8List? _photoBytes;
  String? _photoFilename;

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.pet != null;

  final List<Map<String, String>> _speciesOptions = const [
    {'value': 'dog', 'label': 'Dog'},
    {'value': 'cat', 'label': 'Cat'},
    {'value': 'bird', 'label': 'Bird'},
    {'value': 'fish', 'label': 'Fish'},
    {'value': 'reptile', 'label': 'Reptile'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;

    _nameController = TextEditingController(text: pet?.name ?? '');
    _breedController = TextEditingController(text: pet?.breed ?? '');
    _allergiesController = TextEditingController(text: pet?.allergies ?? '');
    _existingConditionsController = TextEditingController(
      text: pet?.existingConditions ?? '',
    );

    _species = pet?.species;
    _birthday = pet?.birthday != null ? DateTime.parse(pet!.birthday!) : null;
    _gotchaDate = pet?.gotchaDate != null
        ? DateTime.parse(pet!.gotchaDate!)
        : null;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    final croppedBytes = await Navigator.of(context).push<Uint8List?>(
      MaterialPageRoute(builder: (_) => CropPhotoScreen(imageBytes: bytes)),
    );

    if (croppedBytes != null) {
      setState(() {
        _photoBytes = croppedBytes;
        _photoFilename = pickedFile.name;
      });
    }
  }

  Future<void> _pickDate({required bool isBirthday}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 1),
      firstDate: DateTime(1990),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        if (isBirthday) {
          _birthday = picked;
        } else {
          _gotchaDate = picked;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_species == null) {
      setState(() => _errorMessage = 'Please choose a species');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String? error;
    if (_isEditing) {
      error = await _apiService.updatePet(
        id: widget.pet!.id,
        name: _nameController.text.trim(),
        species: _species!,
        breed: _breedController.text.trim(),
        birthday: _birthday != null
            ? DateFormat('yyyy-MM-dd').format(_birthday!)
            : null,
        gotchaDate: _gotchaDate != null
            ? DateFormat('yyyy-MM-dd').format(_gotchaDate!)
            : null,
        allergies: _allergiesController.text.trim(),
        existingConditions: _existingConditionsController.text.trim(),
        photoBytes: _photoBytes,
        photoFilename: _photoFilename,
      );
    } else {
      error = await _apiService.createPet(
        name: _nameController.text.trim(),
        species: _species!,
        breed: _breedController.text.trim(),
        birthday: _birthday != null
            ? DateFormat('yyyy-MM-dd').format(_birthday!)
            : null,
        gotchaDate: _gotchaDate != null
            ? DateFormat('yyyy-MM-dd').format(_gotchaDate!)
            : null,
        allergies: _allergiesController.text.trim(),
        existingConditions: _existingConditionsController.text.trim(),
        photoBytes: _photoBytes,
        photoFilename: _photoFilename,
      );
    }

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _allergiesController.dispose();
    _existingConditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Pet' : 'Add Pet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundImage: _photoBytes != null
                        ? MemoryImage(_photoBytes!)
                        : (widget.pet?.photoUrl != null
                                  ? NetworkImage(widget.pet!.photoUrl!)
                                  : null)
                              as ImageProvider?,
                    child: (_photoBytes == null && widget.pet?.photoUrl == null)
                        ? const Icon(
                            Icons.add_a_photo_outlined,
                            size: 32,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickPhoto,
                  child: Text(
                    (_photoBytes == null && widget.pet?.photoUrl == null)
                        ? 'Add a photo'
                        : 'Change photo',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _FormSection(
                title: 'Basic Info',
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter a name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _species,
                    decoration: const InputDecoration(
                      labelText: 'Species',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _speciesOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option['value'],
                            child: Text(option['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _species = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _breedController,
                    decoration: const InputDecoration(
                      labelText: 'Breed (optional)',
                      prefixIcon: Icon(Icons.pets_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: 'Important Dates',
                children: [
                  _DateField(
                    label: 'Birthday (optional)',
                    value: _birthday,
                    onTap: () => _pickDate(isBirthday: true),
                  ),
                  const SizedBox(height: 16),
                  _DateField(
                    label: 'Gotcha day (optional)',
                    value: _gotchaDate,
                    onTap: () => _pickDate(isBirthday: false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: 'Health Info',
                children: [
                  TextFormField(
                    controller: _allergiesController,
                    decoration: const InputDecoration(
                      labelText: 'Allergies (optional)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _existingConditionsController,
                    decoration: const InputDecoration(
                      labelText: 'Existing conditions (optional)',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Save Pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value != null
              ? DateFormat('MMM d, yyyy').format(value!)
              : 'Select a date',
          style: TextStyle(
            color: value != null
                ? AppColors.textDark
                : AppColors.textDark.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
