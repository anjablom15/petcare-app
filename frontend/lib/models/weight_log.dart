class WeightLog {
  final int id;
  final int pet;
  final double weightKg;
  final String date;
  final String notes;

  WeightLog({
    required this.id,
    required this.pet,
    required this.weightKg,
    required this.date,
    required this.notes,
  });

  factory WeightLog.fromJson(Map<String, dynamic> json) {
    return WeightLog(
      id: json['id'],
      pet: json['pet'],
      weightKg: double.parse(json['weight_kg'].toString()),
      date: json['date'],
      notes: json['notes'] ?? '',
    );
  }
}
