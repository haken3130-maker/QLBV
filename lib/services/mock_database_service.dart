import 'dart:async';
import 'database_service.dart';
import '../models/app_user.dart';
import '../models/employee.dart';
import '../models/product.dart';
import '../models/job.dart';
import '../models/salary_entry.dart';
import '../models/salary_payment.dart';
import '../models/audit_log.dart';

class MockDatabaseService implements IDatabaseService {
  @override
  String get name => 'Mock';

  // Sample data in memory
  static final List<Employee> _employees = [
    Employee(
      id: 'emp001',
      name: 'Nguyễn Văn A',
      phone: '0901234561',
      joinDate: DateTime(2026, 1, 15),
      status: 'active',
    ),
    Employee(
      id: 'emp002',
      name: 'Trần Văn B',
      phone: '0901234562',
      joinDate: DateTime(2026, 2, 20),
      status: 'active',
    ),
    Employee(
      id: 'emp003',
      name: 'Lê Hoàng C',
      phone: '0901234563',
      joinDate: DateTime(2026, 3, 10),
      status: 'active',
    ),
    Employee(
      id: 'emp004',
      name: 'Phạm Minh D',
      phone: '0901234564',
      joinDate: DateTime(2026, 3, 12),
      status: 'active',
    ),
    Employee(
      id: 'emp005',
      name: 'Đỗ Quốc E',
      phone: '0901234565',
      joinDate: DateTime(2026, 4, 1),
      status: 'active',
    ),
    Employee(
      id: 'emp006',
      name: 'Vũ Tiến F',
      phone: '0901234566',
      joinDate: DateTime(2026, 4, 5),
      status: 'active',
    ),
    Employee(
      id: 'emp007',
      name: 'Nguyễn Văn G',
      phone: '0901234567',
      joinDate: DateTime(2026, 4, 18),
      status: 'inactive',
    ), // Resigned
    Employee(
      id: 'emp008',
      name: 'Trần Minh H',
      phone: '0901234568',
      joinDate: DateTime(2026, 5, 1),
      status: 'active',
    ),
  ];

  static final List<Product> _products = [
    Product(
      id: 'prod001',
      name: 'Giấy cuộn',
      unit: 'Tấn',
      defaultPrice: 900000,
      active: true,
    ),
    Product(
      id: 'prod002',
      name: 'Nhựa dẻo',
      unit: 'Tấn',
      defaultPrice: 800000,
      active: true,
    ),
    Product(
      id: 'prod003',
      name: 'Bao xi măng',
      unit: 'Bao',
      defaultPrice: 15000,
      active: true,
    ),
    Product(
      id: 'prod004',
      name: 'Tôn tấm',
      unit: 'Tấn',
      defaultPrice: 700000,
      active: true,
    ),
  ];

  static final List<Job> _jobs = [
    Job(
      id: 'job001',
      date: DateTime(2026, 5, 28),
      productId: 'prod001',
      productName: 'Giấy cuộn',
      quantity: 10.0,
      unitPrice: 900000,
      totalAmount: 9000000,
      participants: ['emp001', 'emp002', 'emp003', 'emp004', 'emp005'],
      createdBy: 'admin@qlbv.com',
      createdAt: DateTime(2026, 5, 28, 17, 0),
    ),
    Job(
      id: 'job002',
      date: DateTime(2026, 5, 29),
      productId: 'prod002',
      productName: 'Nhựa dẻo',
      quantity: 5.0,
      unitPrice: 800000,
      totalAmount: 4000000,
      participants: ['emp001', 'emp002', 'emp006'],
      createdBy: 'admin@qlbv.com',
      createdAt: DateTime(2026, 5, 29, 17, 30),
    ),
    Job(
      id: 'job003',
      date: DateTime(2026, 5, 30),
      productId: 'prod003',
      productName: 'Bao xi măng',
      quantity: 200.0,
      unitPrice: 15000,
      totalAmount: 3000000,
      participants: ['emp002', 'emp003', 'emp004', 'emp008'],
      createdBy: 'leader@qlbv.com',
      createdAt: DateTime(2026, 5, 30, 16, 0),
    ),
  ];

  static final List<SalaryEntry> _salaryEntries = [
    SalaryEntry(
      id: 'se001',
      employeeId: 'emp001',
      employeeName: 'Nguyễn Văn A',
      jobId: 'job001',
      productName: 'Giấy cuộn',
      amount: 1800000,
      date: DateTime(2026, 5, 28),
    ),
    SalaryEntry(
      id: 'se002',
      employeeId: 'emp002',
      employeeName: 'Trần Văn B',
      jobId: 'job001',
      productName: 'Giấy cuộn',
      amount: 1800000,
      date: DateTime(2026, 5, 28),
    ),
    SalaryEntry(
      id: 'se003',
      employeeId: 'emp003',
      employeeName: 'Lê Hoàng C',
      jobId: 'job001',
      productName: 'Giấy cuộn',
      amount: 1800000,
      date: DateTime(2026, 5, 28),
    ),
    SalaryEntry(
      id: 'se004',
      employeeId: 'emp004',
      employeeName: 'Phạm Minh D',
      jobId: 'job001',
      productName: 'Giấy cuộn',
      amount: 1800000,
      date: DateTime(2026, 5, 28),
    ),
    SalaryEntry(
      id: 'se005',
      employeeId: 'emp005',
      employeeName: 'Đỗ Quốc E',
      jobId: 'job001',
      productName: 'Giấy cuộn',
      amount: 1800000,
      date: DateTime(2026, 5, 28),
    ),

    SalaryEntry(
      id: 'se006',
      employeeId: 'emp001',
      employeeName: 'Nguyễn Văn A',
      jobId: 'job002',
      productName: 'Nhựa dẻo',
      amount: 1333333,
      date: DateTime(2026, 5, 29),
    ),
    SalaryEntry(
      id: 'se007',
      employeeId: 'emp002',
      employeeName: 'Trần Văn B',
      jobId: 'job002',
      productName: 'Nhựa dẻo',
      amount: 1333333,
      date: DateTime(2026, 5, 29),
    ),
    SalaryEntry(
      id: 'se008',
      employeeId: 'emp006',
      employeeName: 'Vũ Tiến F',
      jobId: 'job002',
      productName: 'Nhựa dẻo',
      amount: 1333334,
      date: DateTime(2026, 5, 29),
    ),

    SalaryEntry(
      id: 'se009',
      employeeId: 'emp002',
      employeeName: 'Trần Văn B',
      jobId: 'job003',
      productName: 'Bao xi măng',
      amount: 750000,
      date: DateTime(2026, 5, 30),
    ),
    SalaryEntry(
      id: 'se010',
      employeeId: 'emp003',
      employeeName: 'Lê Hoàng C',
      jobId: 'job003',
      productName: 'Bao xi măng',
      amount: 750000,
      date: DateTime(2026, 5, 30),
    ),
    SalaryEntry(
      id: 'se011',
      employeeId: 'emp004',
      employeeName: 'Phạm Minh D',
      jobId: 'job003',
      productName: 'Bao xi măng',
      amount: 750000,
      date: DateTime(2026, 5, 30),
    ),
    SalaryEntry(
      id: 'se012',
      employeeId: 'emp008',
      employeeName: 'Trần Minh H',
      jobId: 'job003',
      productName: 'Bao xi măng',
      amount: 750000,
      date: DateTime(2026, 5, 30),
    ),
  ];

  static final List<SalaryPayment> _salaryPayments = [
    SalaryPayment(
      id: 'sp001',
      employeeId: 'emp001',
      employeeName: 'Nguyễn Văn A',
      amount: 2000000,
      paymentDate: DateTime(2026, 5, 29),
      notes: 'Phát lương tuần',
      createdBy: 'admin@qlbv.com',
      createdAt: DateTime(2026, 5, 29, 18, 0),
    ),
    SalaryPayment(
      id: 'sp002',
      employeeId: 'emp002',
      employeeName: 'Trần Văn B',
      amount: 3000000,
      paymentDate: DateTime(2026, 5, 30),
      notes: 'Ứng lương',
      createdBy: 'admin@qlbv.com',
      createdAt: DateTime(2026, 5, 30, 18, 30),
    ),
  ];

  static final List<AuditLog> _auditLogs = [
    AuditLog(
      id: 'al001',
      action: 'CREATE_JOB',
      targetType: 'JOB',
      targetId: 'job001',
      description: 'Đã tạo công việc Giấy cuộn (10.0 Tấn)',
      performedBy: 'admin@qlbv.com',
      performedAt: DateTime(2026, 5, 28, 17, 0),
    ),
    AuditLog(
      id: 'al002',
      action: 'CREATE_PAYMENT',
      targetType: 'SALARY_PAYMENT',
      targetId: 'sp001',
      description: 'Đã phát lương cho Nguyễn Văn A số tiền 2,000,000đ',
      performedBy: 'admin@qlbv.com',
      performedAt: DateTime(2026, 5, 29, 18, 0),
    ),
  ];

  // StreamControllers to publish updates
  final _employeeStreamController =
      StreamController<List<Employee>>.broadcast();
  final _productStreamController = StreamController<List<Product>>.broadcast();
  final _jobStreamController = StreamController<List<Job>>.broadcast();
  final _salaryEntryStreamController =
      StreamController<List<SalaryEntry>>.broadcast();
  final _salaryPaymentStreamController =
      StreamController<List<SalaryPayment>>.broadcast();
  final _auditLogStreamController =
      StreamController<List<AuditLog>>.broadcast();

  MockDatabaseService() {
    _emitAll();
  }

  void _emitAll() {
    _employeeStreamController.add(List.from(_employees));
    _productStreamController.add(List.from(_products));
    _jobStreamController.add(List.from(_jobs));
    _salaryEntryStreamController.add(List.from(_salaryEntries));
    _salaryPaymentStreamController.add(List.from(_salaryPayments));
    _auditLogStreamController.add(List.from(_auditLogs));
  }

  @override
  Future<AppUser?> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (email == 'admin@qlbv.com' && password == 'admin123') {
      return AppUser(
        uid: 'admin_uid',
        email: email,
        name: 'Quản Lý Admin',
        role: 'admin',
      );
    } else if (email == 'leader@qlbv.com' && password == 'leader123') {
      return AppUser(
        uid: 'leader_uid',
        email: email,
        name: 'Tổ Trưởng Vương',
        role: 'leader',
      );
    }
    throw Exception('Tài khoản hoặc mật khẩu không chính xác!');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<AppUser?> getCurrentUser(String uid) async {
    if (uid == 'admin_uid') {
      return AppUser(
        uid: 'admin_uid',
        email: 'admin@qlbv.com',
        name: 'Quản Lý Admin',
        role: 'admin',
      );
    } else if (uid == 'leader_uid') {
      return AppUser(
        uid: 'leader_uid',
        email: 'leader@qlbv.com',
        name: 'Tổ Trưởng Vương',
        role: 'leader',
      );
    }
    return null;
  }

  @override
  Stream<List<Employee>> streamEmployees() {
    _employeeStreamController.add(List.from(_employees));
    return _employeeStreamController.stream;
  }

  @override
  Future<void> addEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _employees.add(employee);
    _employeeStreamController.add(List.from(_employees));
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      final oldName = _employees[index].name;
      _employees[index] = employee;
      _employeeStreamController.add(List.from(_employees));
      _auditLogs.insert(
        0,
        AuditLog(
          id: 'al_${DateTime.now().millisecondsSinceEpoch}',
          action: 'UPDATE_EMPLOYEE',
          targetType: 'EMPLOYEE',
          targetId: employee.id,
          description: 'Đã cập nhật thông tin nhân viên $oldName',
          performedBy: 'admin@qlbv.com',
          performedAt: DateTime.now(),
        ),
      );
      _auditLogStreamController.add(List.from(_auditLogs));
    }
  }

  @override
  Stream<List<Product>> streamProducts() {
    _productStreamController.add(List.from(_products));
    return _productStreamController.stream;
  }

  @override
  Future<void> addProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _products.add(product);
    _productStreamController.add(List.from(_products));
  }

  @override
  Future<void> updateProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      final oldName = _products[index].name;
      _products[index] = product;
      _productStreamController.add(List.from(_products));
      _auditLogs.insert(
        0,
        AuditLog(
          id: 'al_${DateTime.now().millisecondsSinceEpoch}',
          action: 'UPDATE_PRODUCT',
          targetType: 'PRODUCT',
          targetId: product.id,
          description:
              'Đã cập nhật sản phẩm $oldName (giá: ${product.defaultPrice}đ)',
          performedBy: 'admin@qlbv.com',
          performedAt: DateTime.now(),
        ),
      );
      _auditLogStreamController.add(List.from(_auditLogs));
    }
  }

  @override
  Stream<List<Job>> streamJobs() {
    _jobStreamController.add(List.from(_jobs));
    return _jobStreamController.stream;
  }

  @override
  Future<void> createJob(Job job, List<SalaryEntry> salaryEntries) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _jobs.add(job);
    _salaryEntries.addAll(salaryEntries);

    _auditLogs.insert(
      0,
      AuditLog(
        id: 'al_${DateTime.now().millisecondsSinceEpoch}',
        action: 'CREATE_JOB',
        targetType: 'JOB',
        targetId: job.id,
        description:
            'Đã tạo công việc ${job.productName} (${job.quantity} ${job.quantity > 50 ? 'Bao' : 'Tấn'})',
        performedBy: job.createdBy,
        performedAt: DateTime.now(),
      ),
    );

    _jobStreamController.add(List.from(_jobs));
    _salaryEntryStreamController.add(List.from(_salaryEntries));
    _auditLogStreamController.add(List.from(_auditLogs));
  }

  @override
  Future<void> updateJob(Job job, List<SalaryEntry> salaryEntries) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _jobs.indexWhere((j) => j.id == job.id);
    if (index != -1) {
      _salaryEntries.removeWhere((se) => se.jobId == job.id);
      _jobs[index] = job;
      _salaryEntries.addAll(salaryEntries);
      _auditLogs.insert(
        0,
        AuditLog(
          id: 'al_${DateTime.now().millisecondsSinceEpoch}',
          action: 'UPDATE_JOB',
          targetType: 'JOB',
          targetId: job.id,
          description:
              'Đã cập nhật công việc ${job.productName} (${job.quantity} ${job.quantity > 50 ? 'Bao' : 'Tấn'})',
          performedBy: job.updatedBy ?? 'admin@qlbv.com',
          performedAt: DateTime.now(),
        ),
      );
      _jobStreamController.add(List.from(_jobs));
      _salaryEntryStreamController.add(List.from(_salaryEntries));
      _auditLogStreamController.add(List.from(_auditLogs));
    }
  }

  @override
  Future<void> deleteJob(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      final job = _jobs[index];
      _auditLogs.insert(
        0,
        AuditLog(
          id: 'al_${DateTime.now().millisecondsSinceEpoch}',
          action: 'DELETE_JOB',
          targetType: 'JOB',
          targetId: jobId,
          description:
              'Đã xóa công việc ${job.productName} (${job.quantity} ${job.quantity > 50 ? 'Bao' : 'Tấn'})',
          performedBy: 'admin@qlbv.com',
          performedAt: DateTime.now(),
        ),
      );
    }
    _jobs.removeWhere((j) => j.id == jobId);
    _salaryEntries.removeWhere((se) => se.jobId == jobId);

    _jobStreamController.add(List.from(_jobs));
    _salaryEntryStreamController.add(List.from(_salaryEntries));
    _auditLogStreamController.add(List.from(_auditLogs));
  }

  @override
  Stream<List<SalaryEntry>> streamSalaryEntries() {
    _salaryEntryStreamController.add(List.from(_salaryEntries));
    return _salaryEntryStreamController.stream;
  }

  @override
  Stream<List<SalaryPayment>> streamSalaryPayments() {
    _salaryPaymentStreamController.add(List.from(_salaryPayments));
    return _salaryPaymentStreamController.stream;
  }

  @override
  Future<void> addSalaryPayment(SalaryPayment payment) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _salaryPayments.add(payment);

    _auditLogs.insert(
      0,
      AuditLog(
        id: 'al_${DateTime.now().millisecondsSinceEpoch}',
        action: 'CREATE_PAYMENT',
        targetType: 'SALARY_PAYMENT',
        targetId: payment.id,
        description:
            'Đã phát lương cho ${payment.employeeName} số tiền ${payment.amount}đ',
        performedBy: payment.createdBy,
        performedAt: DateTime.now(),
      ),
    );

    _salaryPaymentStreamController.add(List.from(_salaryPayments));
    _auditLogStreamController.add(List.from(_auditLogs));
  }

  @override
  Future<void> deleteSalaryPayment(String paymentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _salaryPayments.indexWhere((p) => p.id == paymentId);
    if (index != -1) {
      final payment = _salaryPayments[index];
      _auditLogs.insert(
        0,
        AuditLog(
          id: 'al_${DateTime.now().millisecondsSinceEpoch}',
          action: 'DELETE_PAYMENT',
          targetType: 'SALARY_PAYMENT',
          targetId: paymentId,
          description:
              'Đã xóa phát lương cho ${payment.employeeName} số tiền ${payment.amount}đ',
          performedBy: 'admin@qlbv.com',
          performedAt: DateTime.now(),
        ),
      );
    }
    _salaryPayments.removeWhere((sp) => sp.id == paymentId);
    _salaryPaymentStreamController.add(List.from(_salaryPayments));
    _auditLogStreamController.add(List.from(_auditLogs));
  }

  @override
  Stream<List<AuditLog>> streamAuditLogs() {
    _auditLogStreamController.add(List.from(_auditLogs));
    return _auditLogStreamController.stream;
  }
}
