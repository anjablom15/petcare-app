import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';
import '../utils/species_style.dart';
import '../widgets/pet_care_app_bar.dart';

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
      appBar: const PetCareAppBar(title: 'My Pets'),
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
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: _pets.length,
      itemBuilder: (context, index) {
        final pet = _pets[index];
        return _PetCard(
          pet: pet,
          iconForSpecies: _iconForSpecies,
          onChanged: _loadPets,
        );
      },
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  final IconData Function(String) iconForSpecies;
  final VoidCallback onChanged;

  const _PetCard({
    required this.pet,
    required this.iconForSpecies,
    required this.onChanged,
  });

  Color get _accentColor => SpeciesStyle.colorFor(pet.species);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      elevation: 2,
      shadowColor: _accentColor.withValues(alpha: 0.25),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () async {
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)));
          if (result == true) {
            onChanged();
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: pet.photoUrl != null
                        ? Image.network(pet.photoUrl!, fit: BoxFit.cover)
                        : Container(
                            color: _accentColor.withValues(alpha: 0.15),
                            child: Icon(
                              iconForSpecies(pet.species),
                              size: 40,
                              color: _accentColor,
                            ),
                          ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 44,
                    color: _accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        pet.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 10,
                bottom: 8,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 15,
                    color: _accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
