import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _existingConditionsController = TextEditingController();

  String? _species;
  DateTime? _birthday;
  DateTime? _gotchaDate;

  Uint8List? _photoBytes;
  String? _photoFilename;

  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _speciesOptions = const [
    {'value': 'dog', 'label': 'Dog'},
    {'value': 'cat', 'label': 'Cat'},
    {'value': 'bird', 'label': 'Bird'},
    {'value': 'fish', 'label': 'Fish'},
    {'value': 'reptile', 'label': 'Reptile'},
    {'value': 'other', 'label': 'Other'},
  ];

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _photoBytes = bytes;
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

    final error = await _apiService.createPet(
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
      appBar: AppBar(title: const Text('Add Pet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                        : null,
                    child: _photoBytes == null
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
                    _photoBytes == null ? 'Add a photo' : 'Change photo',
                  ),
                ),
              ),

              const SizedBox(height: 16),
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

              const SizedBox(height: 16),
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

              const SizedBox(height: 16),
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
                  labelText: 'Existing Conditions (optional)',
                ),
                maxLines: 3,
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
                    : const Text('Save Pet'),
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
