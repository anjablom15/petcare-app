class FeedingSlot {
  final int id;
  final int pet;
  final int product;
  final String label;
  final double portionAmount;
  final List<String> daysOfWeek;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  FeedingSlot({
    required this.id,
    required this.pet,
    required this.product,
    required this.label,
    required this.portionAmount,
    required this.daysOfWeek,
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory FeedingSlot.fromJson(Map<String, dynamic> json) {
    return FeedingSlot(
      id: json['id'],
      pet: json['pet'],
      product: json['product'],
      label: json['label'] ?? '',
      portionAmount: double.parse(json['portion_amount'].toString()),
      daysOfWeek: List<String>.from(json['days_of_week']),
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
