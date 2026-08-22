import 'package:flutter/material.dart';
import 'package:frontend/models/feeding_slot.dart';
import '../models/food_product.dart';
import '../models/food_bag.dart';
import '../models/pet.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'add_food_bag_screen.dart';
import 'add_feeding_slot_screen.dart';

class FoodProductDetailScreen extends StatefulWidget {
  final FoodProduct product;

  const FoodProductDetailScreen({super.key, required this.product});

  @override
  State<FoodProductDetailScreen> createState() =>
      _FoodProductDetailScreenState();
}

class _FoodProductDetailScreenState extends State<FoodProductDetailScreen> {
  final ApiService _apiService = ApiService();
  late FoodProduct _product;
  List<FoodBag> _bags = [];
  List<FeedingSlot> _feedingSlots = [];
  List<Pet> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _apiService.getFoodProduct(widget.product.id),
        _apiService.getFoodBags(productId: widget.product.id),
        _apiService.getFeedingSlots(productId: widget.product.id),
        _apiService.getPets(),
      ]);
      setState(() {
        _product = results[0] as FoodProduct;
        _bags = results[1] as List<FoodBag>;
        _feedingSlots = results[2] as List<FeedingSlot>;
        _pets = results[3] as List<Pet>;
        _isLoading = false;
      });
    } catch (e) {
      print('LOAD DATA ERROR: $e');
      setState(() {
        _isLoading = false;
      });
      print(
        'LOADED ${_feedingSlots.length} FEEDING SLOTS FOR PRODUCT ${widget.product.id}',
      );
    }
  }

  String _petName(int petId) {
    final match = _pets.where((pet) => pet.id == petId);
    return match.isEmpty ? 'Unknown pet' : match.first.name;
  }

  String _formatPortion(double portionAmount) {
    if (_product.unitType == 'weight') {
      final grams = portionAmount * 1000;
      return '${grams.toStringAsFixed(0)} g';
    }
    return '${portionAmount.toStringAsFixed(0)} items';
  }

  Future<void> _markFinished(FoodBag bag) async {
    final today = DateTime.now();
    final dateString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final error = await _apiService.markBagFinished(
      bagId: bag.id,
      finishedDate: dateString,
    );

    if (!mounted) return;

    if (error == null) {
      _loadData();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _confirmDeleteFeedingSlot(FeedingSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete feeding schedule?'),
        content: Text(
          'This will remove the ${slot.label.isNotEmpty ? slot.label : 'feeding'} schedule for ${_petName(slot.pet)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _apiService.deleteFeedingSlot(slot.id);
      _loadData();
    }
  }

  Future<void> _logMissedMeal(FeedingSlot slot) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    final dateString =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    final error = await _apiService.createMissedMeal(
      feedingSlotId: slot.id,
      date: dateString,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Missed meal logged")));
      _loadData();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_product.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.product.brand.isNotEmpty)
                        Text(widget.product.brand),
                      const SizedBox(height: 8),
                      Text(
                        '${_product.remainingQuantity.toStringAsFixed(1)} / ${_product.activeBagTotal.toStringAsFixed(1)} kg remaining',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.estimatedFinishDate == null
                            ? 'No active feeding schedule'
                            : 'Finishes ~${widget.product.estimatedFinishDate!.day}/${widget.product.estimatedFinishDate!.month}/${widget.product.estimatedFinishDate!.year}',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Bag history",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),

                      for (final bag in _bags)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              '${bag.quantityTotal.toStringAsFixed(1)} kg — bought ${bag.purchaseDate.day}/${bag.purchaseDate.month}/${bag.purchaseDate.year}',
                            ),
                            subtitle: bag.finishedEarlyDate != null
                                ? Text(
                                    'Finished on ${bag.finishedEarlyDate!.day}/${bag.finishedEarlyDate!.month}/${bag.finishedEarlyDate!.year}',
                                  )
                                : null,
                            trailing: bag.finishedEarlyDate == null
                                ? TextButton(
                                    onPressed: () => _markFinished(bag),
                                    child: const Text('Mark finished'),
                                  )
                                : const Icon(
                                    Icons.check_circle,
                                    color: AppColors.secondary,
                                  ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Feeding Schedule',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: AppColors.primary,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddFeedingSlotScreen(
                                    product: _product,
                                    pets: _pets,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadData();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_feedingSlots.isEmpty)
                        const Text('No feeding schedules set up yet.')
                      else
                        for (final slot in _feedingSlots)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                '${_petName(slot.pet)} — ${_formatPortion(slot.portionAmount)}${slot.label.isNotEmpty ? ' (${slot.label})' : ''}',
                              ),
                              subtitle: Text(slot.daysOfWeek.join(', ')),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.event_busy,
                                      color: AppColors.primary,
                                    ),
                                    tooltip: 'Log missed meal',
                                    onPressed: () => _logMissedMeal(slot),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.secondary,
                                    ),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddFeedingSlotScreen(
                                                product: _product,
                                                pets: _pets,
                                                existingSlot: slot,
                                              ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadData();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _confirmDeleteFeedingSlot(slot),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFoodBagScreen(product: widget.product),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
