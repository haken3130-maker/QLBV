class Product {
  final String id;
  final String name;
  final String unit;
  final int defaultPrice; // in VND
  final bool active;

  Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.defaultPrice,
    required this.active,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      unit: map['unit'] ?? '',
      defaultPrice: map['defaultPrice'] is num ? (map['defaultPrice'] as num).toInt() : 0,
      active: map['active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'defaultPrice': defaultPrice,
      'active': active,
    };
  }

  Product copyWith({
    String? name,
    String? unit,
    int? defaultPrice,
    bool? active,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      active: active ?? this.active,
    );
  }
}
