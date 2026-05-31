import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import '../models/app_user.dart';
import '../models/employee.dart';
import '../models/product.dart';
import '../models/job.dart';
import '../models/salary_entry.dart';
import '../models/salary_payment.dart';
import '../models/audit_log.dart';

import 'dart:io' show Platform;

class SpringBootDatabaseService implements IDatabaseService {
  @override
  String get name => 'Spring Boot';

  static String get _baseUrl {
    const defineUrl = String.fromEnvironment('API_BASE_URL');
    if (defineUrl.isNotEmpty) {
      return defineUrl;
    }
    return 'https://qlbv-9542.onrender.com';
  }

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ));

  static String? _token;
  static AppUser? _cachedUser;

  // StreamControllers to publish reactive updates
  final _employeeStreamController = StreamController<List<Employee>>.broadcast();
  final _productStreamController = StreamController<List<Product>>.broadcast();
  final _jobStreamController = StreamController<List<Job>>.broadcast();
  final _salaryEntryStreamController = StreamController<List<SalaryEntry>>.broadcast();
  final _salaryPaymentStreamController = StreamController<List<SalaryPayment>>.broadcast();
  final _auditLogStreamController = StreamController<List<AuditLog>>.broadcast();

  SpringBootDatabaseService() {
    // Add Interceptor to automatically append JWT bearer token to requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        debugPrint('SpringBootDatabaseService API Error: ${e.response?.statusCode} - ${e.message}');
        return handler.next(e);
      }
    ));
  }

  /// Format DateTime to 'yyyy-MM-ddTHH:mm:ss' without milliseconds or timezone
  /// to be compatible with Java's LocalDateTime parsing.
  static String _formatDateTime(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}T'
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  // --- Auth operations ---

  @override
  Future<AppUser?> signIn(String email, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['token'];
        
        final user = AppUser(
          uid: data['uid'] ?? '',
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          role: data['role'] ?? 'leader',
        );

        _cachedUser = user;
        
        // Trigger initial data pre-fetches
        _refreshEmployees();
        _refreshProducts();
        _refreshJobs();
        _refreshSalaries();
        _refreshAuditLogs();

        return user;
      }
    } on DioException catch (e) {
      String msg = 'Đăng nhập thất bại!';
      if (e.response?.statusCode == 401) {
        msg = 'Tài khoản hoặc mật khẩu không chính xác!';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        msg = 'Không thể kết nối đến máy chủ Spring Boot!';
      }
      throw Exception(msg);
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    _token = null;
    _cachedUser = null;
  }

  @override
  Future<AppUser?> getCurrentUser(String uid) async {
    return _cachedUser;
  }

  // --- Employee operations ---

  Future<void> _refreshEmployees() async {
    try {
      final response = await _dio.get('/api/employees');
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((item) => Employee.fromMap(item, item['id']?.toString() ?? ''))
            .toList();
        _employeeStreamController.add(list);
      }
    } catch (e) {
      debugPrint('Error fetching employees: $e');
    }
  }

  @override
  Stream<List<Employee>> streamEmployees() {
    _refreshEmployees();
    return _employeeStreamController.stream;
  }

  @override
  Future<void> addEmployee(Employee employee) async {
    await _dio.post('/api/employees', data: {
      'id': employee.id,
      ...employee.toMap(),
    });
    await _refreshEmployees();
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await _dio.put('/api/employees/${employee.id}', data: employee.toMap());
    await _refreshEmployees();
  }

  // --- Product operations ---

  Future<void> _refreshProducts() async {
    try {
      final response = await _dio.get('/api/products');
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((item) => Product.fromMap(item, item['id']))
            .toList();
        _productStreamController.add(list);
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  @override
  Stream<List<Product>> streamProducts() {
    _refreshProducts();
    return _productStreamController.stream;
  }

  @override
  Future<void> addProduct(Product product) async {
    await _dio.post('/api/products', data: {
      'id': product.id,
      ...product.toMap(),
    });
    await _refreshProducts();
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _dio.put('/api/products/${product.id}', data: product.toMap());
    await _refreshProducts();
  }

  // --- Job operations ---

  Future<void> _refreshJobs() async {
    try {
      final response = await _dio.get('/api/jobs');
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((item) => Job.fromMap(item, item['id']))
            .toList();
        _jobStreamController.add(list);
      }
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
    }
  }

  @override
  Stream<List<Job>> streamJobs() {
    _refreshJobs();
    return _jobStreamController.stream;
  }

  @override
  Future<void> createJob(Job job, List<SalaryEntry> salaryEntries) async {
    // Note: The Spring Boot backend recalculates splits internally.
    // We send the full Job object (which includes date, quantity, total price, and participant list).
    final payload = {
      'id': job.id,
      'date': _formatDateTime(job.date),
      'productId': job.productId,
      'productName': job.productName,
      'quantity': job.quantity,
      'unitPrice': job.unitPrice,
      'totalAmount': job.totalAmount,
      'participants': job.participants.map((p) => p.toString()).toList(),
      'createdBy': job.createdBy,
      'createdAt': _formatDateTime(job.createdAt),
    };
    debugPrint('SpringBootDatabaseService.createJob payload: $payload');
    try {
      final response = await _dio.post('/api/jobs', data: payload);
      debugPrint('SpringBootDatabaseService.createJob response: ${response.statusCode} - ${response.data}');
      
      if (response.statusCode != 200) {
        final errorMsg = response.data is Map ? response.data['error'] : 'Lỗi không xác định';
        throw Exception(errorMsg ?? 'Tạo công việc thất bại');
      }
    } on DioException catch (e) {
      debugPrint('SpringBootDatabaseService.createJob DioException: ${e.response?.statusCode} - ${e.response?.data} - ${e.message}');
      String msg = 'Tạo công việc thất bại!';
      if (e.response?.data is Map && e.response?.data['error'] != null) {
        msg = e.response!.data['error'];
      } else if (e.response?.data is Map && e.response?.data['message'] != null) {
        msg = e.response!.data['message'];
      } else if (e.response?.statusCode == 400) {
        msg = 'Dữ liệu không hợp lệ!';
      } else if (e.response?.statusCode == 401) {
        msg = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại!';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        msg = 'Không thể kết nối đến máy chủ!';
      }
      throw Exception(msg);
    }
    await _refreshJobs();
    await _refreshSalaries();
    _refreshAuditLogs();
  }

  @override
  Future<void> updateJob(Job job, List<SalaryEntry> salaryEntries) async {
    final payload = {
      'id': job.id,
      'date': _formatDateTime(job.date),
      'productId': job.productId,
      'productName': job.productName,
      'quantity': job.quantity,
      'unitPrice': job.unitPrice,
      'totalAmount': job.totalAmount,
      'participants': job.participants.map((p) => p.toString()).toList(),
      'updatedBy': job.updatedBy ?? '',
      'updatedAt': _formatDateTime(job.updatedAt ?? DateTime.now()),
      if (job.status != 'active') 'status': job.status,
    };
    try {
      await _dio.put('/api/jobs/${job.id}', data: payload);
    } on DioException catch (e) {
      debugPrint('SpringBootDatabaseService.updateJob error: $e');
      throw Exception('Cập nhật công việc thất bại!');
    }
    await _refreshJobs();
    await _refreshSalaries();
    _refreshAuditLogs();
  }

  @override
  Future<void> deleteJob(String jobId) async {
    await _dio.delete('/api/jobs/$jobId');
    await _refreshJobs();
    await _refreshSalaries();
    _refreshAuditLogs();
  }

  // --- Salary operations ---

  Future<void> _refreshSalaries() async {
    try {
      // 1. Fetch entries
      final responseEntries = await _dio.get('/api/salaries/entries');
      if (responseEntries.statusCode == 200) {
        final list = (responseEntries.data as List)
            .map((item) => SalaryEntry.fromMap(item, item['id']))
            .toList();
        _salaryEntryStreamController.add(list);
      }

      // 2. Fetch payments
      final responsePayments = await _dio.get('/api/salaries/payments');
      if (responsePayments.statusCode == 200) {
        final list = (responsePayments.data as List)
            .map((item) => SalaryPayment.fromMap(item, item['id']))
            .toList();
        _salaryPaymentStreamController.add(list);
      }
    } catch (e) {
      debugPrint('Error fetching salary details: $e');
    }
  }

  @override
  Stream<List<SalaryEntry>> streamSalaryEntries() {
    _refreshSalaries();
    return _salaryEntryStreamController.stream;
  }

  // --- Salary Payment operations ---

  @override
  Stream<List<SalaryPayment>> streamSalaryPayments() {
    _refreshSalaries();
    return _salaryPaymentStreamController.stream;
  }

  @override
  Future<void> addSalaryPayment(SalaryPayment payment) async {
    await _dio.post('/api/salaries/payments', data: {
      'id': payment.id,
      'employeeId': payment.employeeId,
      'employeeName': payment.employeeName,
      'amount': payment.amount,
      'paymentDate': _formatDateTime(payment.paymentDate),
      'notes': payment.notes,
      'createdBy': payment.createdBy,
      'createdAt': _formatDateTime(payment.createdAt),
    });
    await _refreshSalaries();
    _refreshAuditLogs();
  }

  @override
  Future<void> deleteSalaryPayment(String paymentId) async {
    await _dio.delete('/api/salaries/payments/$paymentId');
    await _refreshSalaries();
    _refreshAuditLogs();
  }

  Future<void> _refreshAuditLogs() async {
    if (_cachedUser?.role != 'admin') return;
    try {
      final response = await _dio.get('/api/audit-logs');
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((item) => AuditLog.fromMap(item, item['id']))
            .toList();
        _auditLogStreamController.add(list);
      }
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
    }
  }

  @override
  Stream<List<AuditLog>> streamAuditLogs() {
    _refreshAuditLogs();
    return _auditLogStreamController.stream;
  }
}
