import 'package:flutter/material.dart';
import 'package:frontend/models/food_product.dart';
import '../models/pet.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';
import '../widgets/pet_care_app_bar.dart';
import 'food_screen.dart';
import 'food_product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Pet> _pets = [];
  bool _isLoading = true;
  List<FoodProduct> _foodProducts = [];

  static const Map<String, Color> _speciesColors = {
    'dog': Color(0xFFE8756B),
    'cat': Color(0xFF8FA98C),
    'bird': Color(0xFF6BAED6),
    'fish': Color(0xFF5FB7B0),
    'reptile': Color(0xFFC9A227),
    'other': Color(0xFFB08FA9),
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    try {
      final pets = await _apiService.getPets();
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getPets(),
        _apiService.getFoodProducts(),
      ]);
      setState(() {
        _pets = results[0] as List<Pet>;
        _foodProducts = results[1] as List<FoodProduct>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PetCareAppBar(title: 'Home'),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'My Pets',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 96,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._pets.map(
                          (pet) => _PetAvatar(
                            pet: pet,
                            accentColor:
                                _speciesColors[pet.species] ??
                                AppColors.primary,
                            onTap: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PetDetailScreen(pet: pet),
                                ),
                              );
                              if (result == true) _loadPets();
                            },
                          ),
                        ),
                        _AddPetAvatar(
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddPetScreen(),
                              ),
                            );
                            if (result == true) _loadPets();
                          },
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 28),
            _DashboardSection(
              title: 'Food Tracker',
              icon: Icons.restaurant_outlined,
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const FoodScreen()));
              },
              child: () {
                final activeProducts = _foodProducts
                    .where((product) => product.activeBagTotal > 0)
                    .toList();

                if (activeProducts.isEmpty) {
                  return Text(
                    'No active food bags right now',
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final product in activeProducts)
                      _FoodTrackerRow(
                        product: product,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FoodProductDetailScreen(product: product),
                            ),
                          );
                        },
                      ),
                  ],
                );
              }(),
            ),
            const SizedBox(height: 16),
            const _DashboardSection(
              title: 'Medication / Vaccines',
              icon: Icons.medical_services_outlined,
            ),
            const SizedBox(height: 16),
            const _DashboardSection(
              title: 'Bath Time',
              icon: Icons.bathtub_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  final Pet pet;
  final Color accentColor;
  final VoidCallback onTap;

  const _PetAvatar({
    required this.pet,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              backgroundImage: pet.photoUrl != null
                  ? NetworkImage(pet.photoUrl!)
                  : null,
              child: pet.photoUrl == null
                  ? Icon(Icons.pets, color: accentColor)
                  : null,
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                pet.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPetAvatar extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPetAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.add, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          const SizedBox(
            width: 64,
            child: Text(
              'Add Pet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodTrackerRow extends StatelessWidget {
  final FoodProduct product;
  final VoidCallback onTap;

  const _FoodTrackerRow({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double progress = product.activeBagTotal > 0
        ? (product.remainingQuantity / product.activeBagTotal).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${product.remainingQuantity.toStringAsFixed(1)} / ${product.activeBagTotal.toStringAsFixed(1)} kg left',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textDark.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? child;
  final VoidCallback? onTap;

  const _DashboardSection({
    required this.title,
    required this.icon,
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textDark.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child ??
                  Text(
                    'Nothing to show yet',
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
