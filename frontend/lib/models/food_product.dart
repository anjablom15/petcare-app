class FoodProduct {
  final int id;
  final int household;
  final String name;
  final String brand;
  final String unitType;
  final double typicalPackageSize;
  final double? typicalPrice;
  final DateTime createdAt;
  final double remainingQuantity;
  final DateTime? estimatedFinishDate;
  final double activeBagTotal;

  FoodProduct({
    required this.id,
    required this.household,
    required this.name,
    required this.brand,
    required this.unitType,
    required this.typicalPackageSize,
    this.typicalPrice,
    required this.createdAt,
    required this.remainingQuantity,
    this.estimatedFinishDate,
    required this.activeBagTotal,
  });

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    return FoodProduct(
      id: json['id'],
      household: json['household'],
      name: json['name'],
      brand: json['brand'] ?? '',
      unitType: json['unit_type'],
      typicalPackageSize: double.parse(json['typical_package_size'].toString()),
      typicalPrice: json['typical_price'] != null
          ? double.parse(json['typical_price'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at']),
      remainingQuantity: (json['remaining_quantity'] as num).toDouble(),
      estimatedFinishDate: json['estimated_finish_date'] != null
          ? DateTime.parse(json['estimated_finish_date'])
          : null,
      activeBagTotal: (json['active_bag_total'] as num).toDouble(),
    );
  }
}
