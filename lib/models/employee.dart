class Employee {
  final String id;
  final String name;
  final String phone;
  final DateTime joinDate;
  final String status; // 'active' or 'inactive'
  final String? notes;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.joinDate,
    required this.status,
    this.notes,
  });

  factory Employee.fromMap(Map<String, dynamic> map, String id) {
    return Employee(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      joinDate: map['joinDate'] != null
          ? DateTime.parse(map['joinDate'])
          : DateTime.now(),
      status: map['status'] ?? 'active',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'joinDate': joinDate.toIso8601String().substring(0, 10), // YYYY-MM-DD
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  Employee copyWith({
    String? name,
    String? phone,
    DateTime? joinDate,
    String? status,
    String? notes,
  }) {
    return Employee(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
