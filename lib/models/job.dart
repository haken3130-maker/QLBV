class Job {
  final String id;
  final DateTime date;
  final String productId;
  final String productName;
  final double quantity;
  final int unitPrice;
  final int totalAmount;
  final List<String> participants; // Employee IDs
  final String createdBy;
  final DateTime createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final String status; // 'active' or 'cancelled'

  Job({
    required this.id,
    required this.date,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.status = 'active',
  });

  factory Job.fromMap(Map<String, dynamic> map, String id) {
    return Job(
      id: id,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] is num)
          ? (map['quantity'] as num).toDouble()
          : 0.0,
      unitPrice: (map['unitPrice'] is num)
          ? (map['unitPrice'] as num).toInt()
          : 0,
      totalAmount: (map['totalAmount'] is num)
          ? (map['totalAmount'] as num).toInt()
          : 0,
      participants: List<String>.from(map['participants'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedBy: map['updatedBy'],
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().substring(0, 10),
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'participants': participants,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'status': status,
    };
  }

  Job copyWith({
    DateTime? date,
    String? productId,
    String? productName,
    double? quantity,
    int? unitPrice,
    int? totalAmount,
    List<String>? participants,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    String? status,
  }) {
    return Job(
      id: id,
      date: date ?? this.date,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  bool get isCancelled => status == 'cancelled';
  bool get isActive => status == 'active';
}
