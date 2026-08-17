import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/weight_log.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/species_style.dart';
import '../widgets/pet_care_app_bar.dart';
import 'add_weight_log_screen.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final ApiService _apiService = ApiService();
  List<Pet> _pets = [];
  Pet? _selectedPet;
  List<WeightLog> _logs = [];
  bool _isLoadingPets = true;
  bool _isLoadingLogs = false;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoadingPets = true;
    });

    try {
      final pets = await _apiService.getPets();
      setState(() {
        _pets = pets;
        _selectedPet = pets.isNotEmpty ? pets.first : null;
        _isLoadingPets = false;
      });

      if (_selectedPet != null) {
        _loadLogs();
      }
    } catch (e) {
      setState(() {
        _isLoadingPets = false;
      });
    }
  }

  Future<void> _loadLogs() async {
    if (_selectedPet == null) return;

    setState(() {
      _isLoadingLogs = true;
    });

    try {
      final logs = await _apiService.getWeightLogs(_selectedPet!.id);
      logs.sort((a, b) => a.date.compareTo(b.date));
      setState(() {
        _logs = logs;
        _isLoadingLogs = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLogs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PetCareAppBar(title: 'Weight'),
      body: _isLoadingPets
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
          ? Center(
              child: Text(
                'Add a pet first to start tracking weight',
                style: TextStyle(
                  color: AppColors.textDark.withValues(alpha: 0.6),
                ),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: _pets.map((pet) {
                      final isSelected = _selectedPet?.id == pet.id;
                      final color = SpeciesStyle.colorFor(pet.species);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(pet.name),
                          selected: isSelected,
                          selectedColor: color,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textDark,
                          ),
                          backgroundColor: color.withValues(alpha: 0.1),
                          onSelected: (_) {
                            setState(() => _selectedPet = pet);
                            _loadLogs();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: _isLoadingLogs
                      ? const Center(child: CircularProgressIndicator())
                      : _logs.isEmpty
                      ? Center(
                          child: Text(
                            'No weight logs yet for ${_selectedPet?.name}',
                            style: TextStyle(
                              color: AppColors.textDark.withValues(alpha: 0.6),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            SizedBox(
                              height: 220,
                              child: _WeightChart(
                                logs: _logs,
                                color: SpeciesStyle.colorFor(
                                  _selectedPet!.species,
                                ),
                              ),
                            ),
                            //   _WeightChart, passing _logs and the
                            //   selected pet's species color
                            const SizedBox(height: 24),

                            ..._logs.reversed.map(
                              (log) => _WeightLogTile(
                                log: log,
                                onDelete: () async {
                                  final success = await _apiService
                                      .deleteWeightLog(log.id);
                                  if (success) _loadLogs();
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: _selectedPet == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddWeightLogScreen(petId: _selectedPet!.id),
                  ),
                );

                if (result == true) _loadLogs();
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Log Weight',
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightLog> logs;
  final Color color;

  const _WeightChart({required this.logs, required this.color});

  @override
  Widget build(BuildContext context) {
    final spots = logs
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.weightKg))
        .toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= logs.length)
                  return const SizedBox.shrink();
                final date = DateTime.parse(logs[index].date);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM d').format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightLogTile extends StatelessWidget {
  final WeightLog log;
  final VoidCallback onDelete;

  const _WeightLogTile({required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.monitor_weight_outlined,
          color: AppColors.primary,
        ),
        title: Text('${log.weightKg} kg'),
        subtitle: Text(
          DateFormat('MMM d, yyyy').format(DateTime.parse(log.date)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
