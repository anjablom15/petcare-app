import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AddFoodProductScreen extends StatefulWidget {
  const AddFoodProductScreen({super.key});

  @override
  State<AddFoodProductScreen> createState() => _AddFoodProductScreenState();
}

class _AddFoodProductScreenState extends State<AddFoodProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _packageSizeController = TextEditingController();
  final _priceController = TextEditingController();

  String _unitType = 'weight';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _packageSizeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final error = await _apiService.createFoodProduct(
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      unitType: _unitType,
      typicalPackageSize: double.parse(_packageSizeController.text),
      typicalPrice: _priceController.text.trim().isEmpty
          ? null
          : double.parse(_priceController.text),
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Food Product')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand (optional)',
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("Weight (kg)"),
                      selected: _unitType == 'weight',
                      onSelected: (_) {
                        setState(() {
                          _unitType = 'weight';
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    ChoiceChip(
                      label: const Text("Count (items)"),
                      selected: _unitType == 'count',
                      onSelected: (_) {
                        setState(() {
                          _unitType = 'count';
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _packageSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Typical package size',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a package size';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Typical price (optional)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
