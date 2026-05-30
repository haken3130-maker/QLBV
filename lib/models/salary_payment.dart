class SalaryPayment {
  final String id;
  final String employeeId;
  final String employeeName;
  final int amount; // in VND
  final DateTime paymentDate;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;

  SalaryPayment({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.paymentDate,
    this.notes,
    required this.createdBy,
    required this.createdAt,
  });

  factory SalaryPayment.fromMap(Map<String, dynamic> map, String id) {
    return SalaryPayment(
      id: id,
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toInt() : 0,
      paymentDate: map['paymentDate'] != null ? DateTime.parse(map['paymentDate']) : DateTime.now(),
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String().substring(0, 10),
      if (notes != null) 'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
