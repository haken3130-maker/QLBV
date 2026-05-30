class SalaryEntry {
  final String id;
  final String employeeId;
  final String employeeName;
  final String jobId;
  final String productName;
  final int amount; // in VND
  final DateTime date;

  SalaryEntry({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.jobId,
    required this.productName,
    required this.amount,
    required this.date,
  });

  factory SalaryEntry.fromMap(Map<String, dynamic> map, String id) {
    return SalaryEntry(
      id: id,
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      jobId: map['jobId'] ?? '',
      productName: map['productName'] ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toInt() : 0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'jobId': jobId,
      'productName': productName,
      'amount': amount,
      'date': date.toIso8601String().substring(0, 10),
    };
  }
}
