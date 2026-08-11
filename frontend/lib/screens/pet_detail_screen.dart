import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isDeleting = false;

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

    setState(() {
      _isDeleting = true;
    });

    final success = await _apiService.deletePet(widget.pet.id);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete pet. Please try again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;

    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),

      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      backgroundImage: pet.photoUrl != null
                          ? NetworkImage(pet.photoUrl!)
                          : null,
                      child: pet.photoUrl == null
                          ? const Icon(
                              Icons.pets,
                              size: 40,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _InfoCard(
                    children: [
                      _InfoRow(label: 'Species', value: pet.species),
                      if (pet.breed.isNotEmpty)
                        _InfoRow(label: 'Breed', value: pet.breed),
                      if (pet.age != null)
                        _InfoRow(label: 'Age', value: '${pet.age} years old'),
                      if (pet.birthday != null)
                        _InfoRow(label: 'Birthday', value: pet.birthday!),
                      if (pet.gotchaDate != null)
                        _InfoRow(label: 'Gotcha day', value: pet.gotchaDate!),
                    ],
                  ),

                  if (pet.allergies.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Allergies',
                      children: [Text(pet.allergies)],
                    ),
                  ],
                  if (pet.existingConditions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Existing Conditions',
                      children: [Text(pet.existingConditions)],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _InfoCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5)),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
