import 'package:flutter/material.dart';
import '../models/food_product.dart';
import '../models/pet.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../models/feeding_slot.dart';

class AddFeedingSlotScreen extends StatefulWidget {
  final FoodProduct product;
  final List<Pet> pets;
  final FeedingSlot? existingSlot;

  const AddFeedingSlotScreen({
    super.key,
    required this.product,
    required this.pets,
    this.existingSlot,
  });

  @override
  State<AddFeedingSlotScreen> createState() => _AddFeedingSlotScreenState();
}

class _AddFeedingSlotScreenState extends State<AddFeedingSlotScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _labelController = TextEditingController();
  final _portionController = TextEditingController();

  final Set<int> _selectedPetIds = {};
  final Set<String> _selectedDays = {};
  DateTime _startDate = DateTime.now();

  bool _isSaving = false;
  String? _errorMessage;

  static const List<Map<String, String>> _dayOptions = [
    {'value': 'mon', 'label': 'Mon'},
    {'value': 'tue', 'label': 'Tue'},
    {'value': 'wed', 'label': 'Wed'},
    {'value': 'thu', 'label': 'Thu'},
    {'value': 'fri', 'label': 'Fri'},
    {'value': 'sat', 'label': 'Sat'},
    {'value': 'sun', 'label': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSlot;
    if (existing != null) {
      _selectedPetIds.add(existing.pet);
      _labelController.text = existing.label;
      final portionValue = widget.product.unitType == 'weight'
          ? existing.portionAmount * 1000
          : existing.portionAmount;
      _portionController.text = portionValue.toStringAsFixed(0);
      _selectedDays.addAll(existing.daysOfWeek);
      _startDate = existing.startDate;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _portionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPetIds.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one pet';
      });
      return;
    }
    if (_selectedDays.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one feeding day';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final dateString =
        '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
    final enteredPortion = double.parse(_portionController.text);
    final portionInKg = widget.product.unitType == 'weight'
        ? enteredPortion / 1000
        : enteredPortion;

    String? error;

    if (widget.existingSlot != null) {
      error = await _apiService.updateFeedingSlot(
        id: widget.existingSlot!.id,
        petId: _selectedPetIds.first,
        productId: widget.product.id,
        label: _labelController.text,
        portionAmount: portionInKg,
        daysOfWeek: _selectedDays.toList(),
        startDate: dateString,
      );
    } else {
      for (final petId in _selectedPetIds) {
        error = await _apiService.createFeedingSlot(
          petId: petId,
          productId: widget.product.id,
          label: _labelController.text,
          portionAmount: portionInKg,
          daysOfWeek: _selectedDays.toList(),
          startDate: dateString,
        );
        if (error != null) break;
      }
    }

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
      appBar: AppBar(
        title: Text(
          widget.existingSlot == null
              ? 'Feeding Shedule - ${widget.product.name}'
              : 'Edit Feeding Schedule',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pet', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final pet in widget.pets)
                      FilterChip(
                        label: Text(pet.name),
                        selected: _selectedPetIds.contains(pet.id),
                        onSelected: (isSelected) {
                          setState(() {
                            if (widget.existingSlot != null) {
                              _selectedPetIds
                                ..clear()
                                ..add(pet.id);
                            } else if (isSelected) {
                              _selectedPetIds.add(pet.id);
                            } else {
                              _selectedPetIds.remove(pet.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label (e.g. Breakfast, optional)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _portionController,
                  decoration: InputDecoration(
                    labelText: widget.product.unitType == 'weight'
                        ? 'Portion amount per feeding (grams)'
                        : 'Portion amount per feeding (items)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a portion amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Eats more than once a day? Add a separate schedule for each feeding — e.g. "Breakfast" and "Dinner" — so missed meals only affect that one feeding.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Feeding Days',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedDays.length == _dayOptions.length) {
                            _selectedDays.clear();
                          } else {
                            _selectedDays
                              ..clear()
                              ..addAll(_dayOptions.map((d) => d['value']!));
                          }
                        });
                      },
                      child: Text(
                        _selectedDays.length == _dayOptions.length
                            ? 'Clear all'
                            : 'Select all',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  children: [
                    for (final day in _dayOptions)
                      FilterChip(
                        label: Text(day['label']!),
                        selected: _selectedDays.contains(day['value']),
                        onSelected: (isSelected) {
                          setState(() {
                            if (isSelected) {
                              _selectedDays.add(day['value']!);
                            } else {
                              _selectedDays.remove(day['value']!);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Start date: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    ),
                    TextButton(
                      onPressed: _pickStartDate,
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
