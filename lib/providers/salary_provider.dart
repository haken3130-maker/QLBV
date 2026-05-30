import 'dart:async';
import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../models/product.dart';
import '../models/job.dart';
import '../models/salary_entry.dart';
import '../models/salary_payment.dart';
import '../models/audit_log.dart';
import '../repositories/salary_repository.dart';

class SalaryProvider extends ChangeNotifier {
  final SalaryRepository _repository = SalaryRepository();

  List<Employee> _employees = [];
  List<Product> _products = [];
  List<Job> _jobs = [];
  List<SalaryEntry> _salaryEntries = [];
  List<SalaryPayment> _salaryPayments = [];
  List<AuditLog> _auditLogs = [];

  StreamSubscription? _employeeSub;
  StreamSubscription? _productSub;
  StreamSubscription? _jobSub;
  StreamSubscription? _entrySub;
  StreamSubscription? _paymentSub;
  StreamSubscription? _auditLogSub;

  List<Employee> get employees => _employees;
  List<Product> get products => _products;
  List<Job> get jobs => _jobs;
  List<SalaryEntry> get salaryEntries => _salaryEntries;
  List<SalaryPayment> get salaryPayments => _salaryPayments;
  List<AuditLog> get auditLogs => _auditLogs;

  SalaryProvider() {
    initStreams();
  }

  void initStreams() {
    _employeeSub?.cancel();
    _productSub?.cancel();
    _jobSub?.cancel();
    _entrySub?.cancel();
    _paymentSub?.cancel();
    _auditLogSub?.cancel();

    _employeeSub = _repository.streamEmployees().listen((list) {
      _employees = list;
      notifyListeners();
    });

    _productSub = _repository.streamProducts().listen((list) {
      _products = list;
      notifyListeners();
    });

    _jobSub = _repository.streamJobs().listen((list) {
      _jobs = list;
      notifyListeners();
    });

    _entrySub = _repository.streamSalaryEntries().listen((list) {
      _salaryEntries = list;
      notifyListeners();
    });

    _paymentSub = _repository.streamSalaryPayments().listen((list) {
      _salaryPayments = list;
      notifyListeners();
    });

    _auditLogSub = _repository.streamAuditLogs().listen((list) {
      _auditLogs = list;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _employeeSub?.cancel();
    _productSub?.cancel();
    _jobSub?.cancel();
    _entrySub?.cancel();
    _paymentSub?.cancel();
    _auditLogSub?.cancel();
    super.dispose();
  }

  // --- Actions ---

  Future<void> addEmployee(String name, String phone) async {
    final id = 'emp_${DateTime.now().millisecondsSinceEpoch}';
    final employee = Employee(
      id: id,
      name: name,
      phone: phone,
      joinDate: DateTime.now(),
      status: 'active',
    );
    await _repository.addEmployee(employee);
  }

  Future<void> updateEmployee(
    String id,
    String name,
    String phone,
    String? notes,
  ) async {
    final emp = _employees.firstWhere((e) => e.id == id);
    final updated = emp.copyWith(name: name, phone: phone, notes: notes);
    await _repository.updateEmployee(updated);
  }

  Future<void> toggleResignation(Employee employee) async {
    final updated = employee.copyWith(
      status: employee.status == 'active' ? 'inactive' : 'active',
    );
    await _repository.updateEmployee(updated);
  }

  Future<void> addProduct(String name, String unit, int defaultPrice) async {
    final id = 'prod_${DateTime.now().millisecondsSinceEpoch}';
    final product = Product(
      id: id,
      name: name,
      unit: unit,
      defaultPrice: defaultPrice,
      active: true,
    );
    await _repository.addProduct(product);
  }

  Future<void> toggleProductActive(Product product) async {
    final updated = product.copyWith(active: !product.active);
    await _repository.updateProduct(updated);
  }

  Future<void> updateProductPrice(Product product, int newPrice) async {
    final updated = product.copyWith(defaultPrice: newPrice);
    await _repository.updateProduct(updated);
  }

  Future<void> createJob({
    required DateTime date,
    required Product product,
    required double quantity,
    required int unitPrice,
    required List<String> participantIds,
    required String createdBy,
  }) async {
    final jobId = 'job_${DateTime.now().millisecondsSinceEpoch}';
    final totalAmount = (quantity * unitPrice).round();
    final numParticipants = participantIds.length;

    if (numParticipants == 0)
      throw Exception('Phải chọn ít nhất 1 người tham gia.');

    final baseSplit = totalAmount ~/ numParticipants;
    final remainder = totalAmount % numParticipants;

    final List<SalaryEntry> entries = [];
    for (int i = 0; i < numParticipants; i++) {
      final empId = participantIds[i];
      final empIdStr = empId.toString();
      Employee? matchedEmp;
      for (final e in _employees) {
        if (e.id == empIdStr || e.id == empId) {
          matchedEmp = e;
          break;
        }
      }
      final empName = matchedEmp?.name ?? 'Nhân viên';
      final amount = baseSplit + (i < remainder ? 1 : 0);

      entries.add(
        SalaryEntry(
          id: 'se_${jobId}_$i',
          employeeId: empIdStr,
          employeeName: empName,
          jobId: jobId,
          productName: product.name,
          amount: amount,
          date: date,
        ),
      );
    }

    final job = Job(
      id: jobId,
      date: date,
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      unitPrice: unitPrice,
      totalAmount: totalAmount,
      participants: participantIds,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    await _repository.createJob(job, entries);
  }

  Future<void> updateJob({
    required String jobId,
    required DateTime date,
    required Product product,
    required double quantity,
    required int unitPrice,
    required List<String> participantIds,
    required String updatedBy,
  }) async {
    final totalAmount = (quantity * unitPrice).round();
    final numParticipants = participantIds.length;
    if (numParticipants == 0)
      throw Exception('Phải chọn ít nhất 1 người tham gia.');

    final baseSplit = totalAmount ~/ numParticipants;
    final remainder = totalAmount % numParticipants;

    final List<SalaryEntry> entries = [];
    for (int i = 0; i < numParticipants; i++) {
      final empId = participantIds[i];
      String empName = 'Nhân viên';
      for (final e in _employees) {
        if (e.id == empId) {
          empName = e.name;
          break;
        }
      }
      final amount = baseSplit + (i < remainder ? 1 : 0);
      entries.add(
        SalaryEntry(
          id: 'se_${jobId}_$i',
          employeeId: empId,
          employeeName: empName,
          jobId: jobId,
          productName: product.name,
          amount: amount,
          date: date,
        ),
      );
    }

    final existingJob = _jobs.firstWhere((j) => j.id == jobId);
    final job = existingJob.copyWith(
      date: date,
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      unitPrice: unitPrice,
      totalAmount: totalAmount,
      participants: participantIds,
      updatedBy: updatedBy,
      updatedAt: DateTime.now(),
    );

    await _repository.updateJob(job, entries);
  }

  Future<void> cancelJob(String jobId, String updatedBy) async {
    final existing = _jobs.firstWhere((j) => j.id == jobId);
    final updated = existing.copyWith(
      status: 'cancelled',
      updatedBy: updatedBy,
      updatedAt: DateTime.now(),
    );
    await _repository.updateJob(updated, []);
  }

  Future<void> deleteJob(String jobId) async {
    await _repository.deleteJob(jobId);
  }

  Future<void> recordPayment({
    required String employeeId,
    required int amount,
    required DateTime date,
    String? notes,
    required String createdBy,
  }) async {
    final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    Employee? matchedEmp;
    for (final e in _employees) {
      if (e.id == employeeId || e.id == employeeId.toString()) {
        matchedEmp = e;
        break;
      }
    }
    final empName = matchedEmp?.name ?? 'Nhân viên';

    final payment = SalaryPayment(
      id: paymentId,
      employeeId: employeeId,
      employeeName: empName,
      amount: amount,
      paymentDate: date,
      notes: notes,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    await _repository.addSalaryPayment(payment);
  }

  Future<void> deletePayment(String paymentId) async {
    await _repository.deleteSalaryPayment(paymentId);
  }
}
