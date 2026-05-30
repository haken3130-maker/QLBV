class AuditLog {
  final String id;
  final String action;
  final String targetType;
  final String? targetId;
  final String description;
  final String performedBy;
  final DateTime performedAt;
  final String? details;

  AuditLog({
    required this.id,
    required this.action,
    required this.targetType,
    this.targetId,
    required this.description,
    required this.performedBy,
    required this.performedAt,
    this.details,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map, String id) {
    return AuditLog(
      id: id,
      action: map['action'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'],
      description: map['description'] ?? '',
      performedBy: map['performedBy'] ?? '',
      performedAt: map['performedAt'] != null
          ? DateTime.parse(map['performedAt'])
          : DateTime.now(),
      details: map['details'],
    );
  }
}
