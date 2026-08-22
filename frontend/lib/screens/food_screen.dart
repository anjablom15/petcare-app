import 'package:flutter/material.dart';
import '../models/food_product.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'add_food_product_screen.dart';
import 'food_product_detail_screen.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final ApiService _apiService = ApiService();
  List<FoodProduct> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _apiService.getFoodProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load food products. Please try again.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
            ? const Center(
                child: Text('No food products yet. Add one to get started!'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FoodProductDetailScreen(
                            product: _products[index],
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadProducts();
                      }
                    },
                    child: _FoodProductCard(product: _products[index]),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddFoodProductScreen(),
            ),
          );
          if (result == true) {
            _loadProducts();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _FoodProductCard extends StatelessWidget {
  final FoodProduct product;

  const _FoodProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final double progress = product.activeBagTotal > 0
        ? (product.remainingQuantity / product.activeBagTotal).clamp(0.0, 1.0)
        : 0.0;

    final String finishDateLabel = product.estimatedFinishDate == null
        ? 'No active feeding schedule'
        : 'Finishes ~ ${product.estimatedFinishDate!.day}/${product.estimatedFinishDate!.month}/${product.estimatedFinishDate!.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: Theme.of(context).textTheme.titleMedium),
            if (product.brand.isNotEmpty)
              Text(product.brand, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${product.remainingQuantity.toStringAsFixed(1)} / ${product.activeBagTotal.toStringAsFixed(1)} kg left',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Flexible(
                  child: Text(
                    finishDateLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
