import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../models/app_user.dart';
import '../models/employee.dart';
import '../models/product.dart';
import '../models/job.dart';
import '../models/salary_entry.dart';
import '../models/salary_payment.dart';
import '../models/audit_log.dart';

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
    receiveTimeout: const Duration(seconds: 180),
    // increase send timeout as some endpoints may be slow
    sendTimeout: const Duration(seconds: 60),
  ));

  static String? _token;
  static String? _refreshToken;
  static AppUser? _cachedUser;
  static Completer<void>? _refreshCompleter;

  static String? get token => _token;
  static String? get refreshToken => _refreshToken;

  static void restoreSession(String token, String? refreshToken, AppUser user) {
    _token = token;
    _refreshToken = refreshToken;
    _cachedUser = user;
    final service = SpringBootDatabaseService();
    service._refreshEmployees();
    service._refreshProducts();
    service._refreshJobs();
    service._refreshSalaries();
    service._refreshAuditLogs();
  }

  // StreamControllers to publish reactive updates
  final _employeeStreamController = StreamController<List<Employee>>.broadcast();
  final _productStreamController = StreamController<List<Product>>.broadcast();
  final _jobStreamController = StreamController<List<Job>>.broadcast();
  final _salaryEntryStreamController = StreamController<List<SalaryEntry>>.broadcast();
  final _salaryPaymentStreamController = StreamController<List<SalaryPayment>>.broadcast();
  final _auditLogStreamController = StreamController<List<AuditLog>>.broadcast();

  SpringBootDatabaseService() {
    // Helpful debug: print effective base URL when service constructed
    debugPrint('SpringBootDatabaseService baseUrl=$_baseUrl');
    if (!_baseUrl.startsWith('https://')) {
      throw StateError('SpringBootDatabaseService requires HTTPS base URL.');
    }
    // Add Interceptor to automatically append JWT bearer token to requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Log outgoing requests in debug builds
        final path = '${options.baseUrl}${options.path}';
        debugPrint('[onRequest] ===== OUTGOING REQUEST =====');
        debugPrint('[onRequest] ${options.method} $path');
        debugPrint('[onRequest] skipAuth flag: ${options.extra['skipAuth']}');
        debugPrint('[onRequest] Current token: ${_token != null ? 'Bearer ${_token!.substring(0, 10)}...' : 'NULL'}');
        
        if (options.data != null) {
          try {
            debugPrint('[onRequest] Request body: ${options.data}');
          } catch (_) {}
        }
        
        // Allow certain calls (e.g. token refresh) to opt-out of automatic
        // Authorization header injection by setting `options.extra['skipAuth'] = true`.
        if (options.extra['skipAuth'] != true && _token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
          debugPrint('[onRequest] Authorization header INJECTED');
        } else if (options.extra['skipAuth'] == true) {
          debugPrint('[onRequest] Authorization header SKIPPED (skipAuth=true)');
        } else if (_token == null) {
          debugPrint('[onRequest] Authorization header SKIPPED (token is null)');
        }
        
        final authHeader = options.headers['Authorization'];
        debugPrint('[onRequest] Authorization header present: ${authHeader != null}');
        if (authHeader != null) {
          debugPrint('[onRequest] Authorization header: Bearer ****');
        }
        debugPrint('[onRequest] ===========================');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Log responses for easier remote debugging
        try {
          debugPrint('API Response: ${response.statusCode} ${response.requestOptions.path} -> ${response.data}');
        } catch (_) {}
        return handler.next(response);
      },
      onError: (e, handler) async {
        try {
          final opts = e.requestOptions;
          debugPrint('SpringBootDatabaseService API Error: ${e.response?.statusCode} - ${e.message} - ${opts.method} ${opts.path} (receiveTimeout=${opts.receiveTimeout ?? 'default'}, connectTimeout=${opts.connectTimeout ?? 'default'})');
          if (e.response?.data != null) {
            debugPrint('Error response body: ${e.response?.data}');
          }

          if (e.response?.statusCode == 401 &&
              opts.path != '/api/auth/login' &&
              opts.path != '/api/auth/refresh' &&
              opts.extra['retried'] != true) {
            try {
              await _refreshAccessToken();
              opts.extra['retried'] = true;
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (refreshError) {
              debugPrint('Refresh token failed: $refreshError');
              // If refresh fails, log out user since tokens are invalid
              _token = null;
              _refreshToken = null;
              _cachedUser = null;
            }
          }
        } catch (_) {
          debugPrint('SpringBootDatabaseService API Error: ${e.response?.statusCode} - ${e.message}');
        }
        return handler.next(e);
      }
    ));
  }

  // Simple GET with retry/backoff to handle slow server responses during startup sync.
  Future<Response> _getWithRetry(String path, {int attempts = 3}) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
          final resp = await _dio.get(path, options: Options(receiveTimeout: const Duration(seconds: 180)));
        return resp;
      } on DioException catch (e) {
        if (attempt >= attempts) rethrow;
        // Only retry on timeout or connection related errors
        if (e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.unknown) {
          final backoff = Duration(seconds: 1 << (attempt)); // 2,4,8...
          debugPrint('Retry $_getWithRetry: attempt $attempt for $path after $backoff due to ${e.type}');
          await Future.delayed(backoff);
          continue;
        }
        rethrow;
      }
    }
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

  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('Không có refresh token để làm mới phiên.');
    }

    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<void>();
    try {
      // Ensure we do NOT send the current (possibly expired) access token
      // when calling the refresh endpoint by using the `skipAuth` flag.
      final response = await _dio.post(
        '/api/auth/refresh',
        data: {
          'refreshToken': _refreshToken,
        },
        options: Options(extra: {'skipAuth': true}),
      );

      if (response.statusCode == 200 && response.data != null) {
        _token = response.data['token'] as String?;
        _refreshToken = response.data['refreshToken'] as String?;

        final prefs = await SharedPreferences.getInstance();
        if (_token != null) {
          await prefs.setString('auth_token', _token!);
        }
        if (_refreshToken != null) {
          await prefs.setString('auth_refresh_token', _refreshToken!);
        }

        _refreshCompleter!.complete();
        return;
      }

      throw Exception('Không thể làm mới token.');
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Exception _buildApiException(DioException e, [String fallbackMessage = 'Yêu cầu thất bại']) {
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      if (statusCode == 401) {
        return Exception('Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.');
      }
      if (statusCode == 403) {
        return Exception('Bạn không có quyền thực hiện thao tác này.');
      }
      if (e.response?.data is Map) {
        final responseData = e.response?.data as Map;
        final errorMessage = responseData['error'] ?? responseData['message'] ?? responseData['detail'];
        if (errorMessage is String && errorMessage.isNotEmpty) {
          return Exception(errorMessage);
        }
      }
      return Exception('Lỗi máy chủ: $statusCode');
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Không thể kết nối đến máy chủ Spring Boot. Vui lòng thử lại.');
    }

    return Exception(fallbackMessage);
  }

  // --- Auth operations ---

  @override
  Future<AppUser?> signIn(String email, String password) async {
    try {
      debugPrint('Signing in with email=$email');
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      debugPrint('SignIn response status=${response.statusCode} body=${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['token'];
        _refreshToken = data['refreshToken'];
        
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
    _refreshToken = null;
    _cachedUser = null;
  }

  @override
  Future<AppUser?> getCurrentUser(String uid) async {
    return _cachedUser;
  }

  // --- Employee operations ---

  Future<void> _refreshEmployees() async {
    try {
      final response = await _getWithRetry('/api/employees');
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((item) => Employee.fromMap(item, item['id']?.toString() ?? ''))
            .toList();
        _employeeStreamController.add(list);
        return;
      }
    } catch (e) {
      debugPrint('Error fetching employees: $e');
    }
    if (!_employeeStreamController.isClosed) {
      _employeeStreamController.add([]);
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

  @override
  Future<void> deleteEmployee(String employeeId) async {
    try {
      await _dio.delete('/api/employees/$employeeId');
    } on DioException catch (e) {
      throw _buildApiException(e, 'Xóa nhân viên thất bại.');
    }

    await _refreshEmployees();
    await _refreshSalaries();
    _refreshJobs();
    _refreshAuditLogs();
  }

  // --- Product operations ---

  Future<void> _refreshProducts() async {
    try {
      final response = await _getWithRetry('/api/products');
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((item) => Product.fromMap(item, item['id']))
            .toList();
        _productStreamController.add(list);
        return;
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
    if (!_productStreamController.isClosed) {
      _productStreamController.add([]);
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

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _dio.delete('/api/products/$productId');
    } on DioException catch (e) {
      throw _buildApiException(e, 'Xóa sản phẩm thất bại.');
    }

    await _refreshProducts();
  }

  // --- Job operations ---

  Future<void> _refreshJobs() async {
    try {
      final response = await _getWithRetry('/api/jobs');
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((item) => Job.fromMap(item, item['id']))
            .toList();
        _jobStreamController.add(list);
        return;
      }
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
    }
    if (!_jobStreamController.isClosed) {
      _jobStreamController.add([]);
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
    var entriesEmitted = false;
    try {
      final responseEntries = await _getWithRetry('/api/salaries/entries');
      if (responseEntries.statusCode == 200) {
        final list = (responseEntries.data as List)
            .map((item) => SalaryEntry.fromMap(item, item['id']))
            .toList();
        _salaryEntryStreamController.add(list);
        entriesEmitted = true;
      }
    } catch (e) {
      debugPrint('Error fetching salary entries: $e');
    }
    if (!entriesEmitted && !_salaryEntryStreamController.isClosed) {
      _salaryEntryStreamController.add([]);
    }

    var paymentsEmitted = false;
    try {
      final responsePayments = await _getWithRetry('/api/salaries/payments');
      if (responsePayments.statusCode == 200) {
        final list = (responsePayments.data as List)
            .map((item) => SalaryPayment.fromMap(item, item['id']))
            .toList();
        _salaryPaymentStreamController.add(list);
        paymentsEmitted = true;
      }
    } catch (e) {
      debugPrint('Error fetching salary payments: $e');
    }
    if (!paymentsEmitted && !_salaryPaymentStreamController.isClosed) {
      _salaryPaymentStreamController.add([]);
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
      final response = await _getWithRetry('/api/audit-logs');
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((item) => AuditLog.fromMap(item, item['id']))
            .toList();
        _auditLogStreamController.add(list);
        return;
      }
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
    }
    if (!_auditLogStreamController.isClosed) {
      _auditLogStreamController.add([]);
    }
  }

  @override
  Stream<List<AuditLog>> streamAuditLogs() {
    _refreshAuditLogs();
    return _auditLogStreamController.stream;
  }
}
