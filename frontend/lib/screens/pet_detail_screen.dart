import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/species_style.dart';
import 'add_pet_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isDeleting = false;

  Color get _accentColor => SpeciesStyle.colorFor(widget.pet.species);

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete pet?'),
        content: Text(
          'This will permanently remove ${widget.pet.name}\'s profile and all related records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    final success = await _apiService.deletePet(widget.pet.id);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete pet. Please try again')),
      );
    }
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddPetScreen(pet: widget.pet)));
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;

    if (_isDeleting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  child: SizedBox(
                    height: 400,
                    width: double.infinity,
                    child: pet.photoUrl != null
                        ? Image.network(
                            pet.photoUrl!,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          )
                        : Container(
                            color: _accentColor.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.pets,
                              size: 72,
                              color: _accentColor,
                            ),
                          ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CircleIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        _CircleIconButton(
                          icon: Icons.edit_outlined,
                          onTap: _handleEdit,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatChip(
                        icon: Icons.category_outlined,
                        label: pet.breed.isNotEmpty ? pet.breed : pet.species,
                        color: _accentColor,
                      ),
                      if (pet.age != null)
                        _StatChip(
                          icon: Icons.cake_outlined,
                          label:
                              '${pet.age} year${pet.age == 1 ? '' : 's'} old',
                          color: _accentColor,
                        ),
                      if (pet.birthday != null)
                        _StatChip(
                          icon: Icons.calendar_today_outlined,
                          label: DateFormat(
                            'MMM d, yyyy',
                          ).format(DateTime.parse(pet.birthday!)),
                          color: _accentColor,
                        ),
                      if (pet.gotchaDate != null)
                        _StatChip(
                          icon: Icons.home_outlined,
                          label: DateFormat(
                            'MMM d, yyyy',
                          ).format(DateTime.parse(pet.gotchaDate!)),
                          color: _accentColor,
                        ),
                    ],
                  ),
                  if (pet.allergies.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _InfoCard(title: 'Allergies', content: pet.allergies),
                  ],
                  if (pet.existingConditions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Existing Conditions',
                      content: pet.existingConditions,
                    ),
                  ],
                  const SizedBox(height: 28),
                  Center(
                    child: TextButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Delete Pet',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.textDark),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;

  const _InfoCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                color: AppColors.textDark.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
