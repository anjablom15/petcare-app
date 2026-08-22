class FoodBag {
  final int id;
  final int product;
  final DateTime purchaseDate;
  final double quantityTotal;
  final double? pricePaid;
  final DateTime? finishedEarlyDate;
  final DateTime createdAt;

  FoodBag({
    required this.id,
    required this.product,
    required this.purchaseDate,
    required this.quantityTotal,
    this.pricePaid,
    this.finishedEarlyDate,
    required this.createdAt,
  });

  factory FoodBag.fromJson(Map<String, dynamic> json) {
    return FoodBag(
      id: json['id'],
      product: json['product'],
      purchaseDate: DateTime.parse(json['purchase_date']),
      quantityTotal: double.parse(json['quantity_total'].toString()),
      pricePaid: json['price_paid'] != null
          ? double.parse(json['price_paid'].toString())
          : null,
      finishedEarlyDate: json['finished_early_date'] != null
          ? DateTime.parse(json['finished_early_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
