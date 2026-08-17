import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';
import '../widgets/pet_care_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Pet> _pets = [];
  bool _isLoading = true;

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
    _loadPets();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PetCareAppBar(title: 'Home'),
      body: RefreshIndicator(
        onRefresh: _loadPets,
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
            const _DashboardSection(
              title: 'Food Tracker',
              icon: Icons.restaurant_outlined,
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

class _DashboardSection extends StatelessWidget {
  final String title;
  final IconData icon;

  const _DashboardSection({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
}
