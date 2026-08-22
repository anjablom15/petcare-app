class MissedMeal {
  final int id;
  final int feedingSlot;
  final DateTime date;
  final DateTime createdAt;

  MissedMeal({
    required this.id,
    required this.feedingSlot,
    required this.date,
    required this.createdAt,
  });

  factory MissedMeal.fromJson(Map<String, dynamic> json) {
    return MissedMeal(
      id: json['id'],
      feedingSlot: json['feeding_slot'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
