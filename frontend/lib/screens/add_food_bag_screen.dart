import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../models/food_product.dart';

class AddFoodBagScreen extends StatefulWidget {
  final FoodProduct product;
  const AddFoodBagScreen({super.key, required this.product});

  @override
  State<AddFoodBagScreen> createState() => _AddFoodBagScreenState();
}

class _AddFoodBagScreenState extends State<AddFoodBagScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final today = DateTime.now();
    final dateString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final error = await _apiService.createFoodBag(
      productId: widget.product.id,
      purchaseDate: dateString,
      quantityTotal: double.parse(_quantityController.text),
      pricePaid: _priceController.text.trim().isEmpty
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
      appBar: AppBar(title: Text('Add Bag — ${widget.product.name}')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity (e.g. kg bought)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a quantity';
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
                    labelText: 'Price paid (optional)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Purchase date: ${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}',
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Change date'),
                    ),
                  ],
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
