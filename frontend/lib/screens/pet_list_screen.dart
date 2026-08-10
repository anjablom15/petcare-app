import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'add_pet_screen.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  final ApiService _apiService = ApiService();
  List<Pet> _pets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pets = await _apiService.getPets();
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load your pets. Refresh to try again';
        _isLoading = false;
      });
    }
  }

  IconData _iconForSpecies(String species) {
    switch (species) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Pets',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(onRefresh: _loadPets, child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddPetScreen()));
          if (result == true) {
            _loadPets();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Pet', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.textDark.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6)),
          ),
        ],
      );
    }

    if (_pets.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.pets,
            size: 72,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No pets yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Pet" to create your first pet profile',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6)),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _pets.length,
      itemBuilder: (context, index) {
        final pet = _pets[index];
        return _PetCard(pet: pet, iconForSpecies: _iconForSpecies);
      },
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  final IconData Function(String) iconForSpecies;

  const _PetCard({required this.pet, required this.iconForSpecies});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: pet.photoUrl != null
                    ? NetworkImage(pet.photoUrl!)
                    : null,
                child: pet.photoUrl == null
                    ? Icon(
                        iconForSpecies(pet.species),
                        size: 36,
                        color: AppColors.primary,
                      )
                    : null,
              ),

              const SizedBox(height: 12),
              Text(
                pet.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),

              if (pet.breed.isNotEmpty)
                Text(
                  pet.breed,
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

              if (pet.age != null)
                Text(
                  '${pet.age} year${pet.age == 1 ? '' : 's'} old',
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
