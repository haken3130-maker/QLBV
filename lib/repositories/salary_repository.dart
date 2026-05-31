import '../services/database_service.dart';
import '../services/springboot_database_service.dart';
import '../models/app_user.dart';
import '../models/employee.dart';
import '../models/product.dart';
import '../models/job.dart';
import '../models/salary_entry.dart';
import '../models/salary_payment.dart';
import '../models/audit_log.dart';

class SalaryRepository implements IDatabaseService {
  static final SalaryRepository _instance = SalaryRepository._internal();
  factory SalaryRepository() => _instance;
  SalaryRepository._internal();

  final IDatabaseService _activeService = SpringBootDatabaseService();

  @override
  String get name => _activeService.name;

  @override
  Future<AppUser?> signIn(String email, String password) =>
      _activeService.signIn(email, password);

  @override
  Future<void> signOut() => _activeService.signOut();

  @override
  Future<AppUser?> getCurrentUser(String uid) =>
      _activeService.getCurrentUser(uid);

  @override
  Stream<List<Employee>> streamEmployees() => _activeService.streamEmployees();

  @override
  Future<void> addEmployee(Employee employee) =>
      _activeService.addEmployee(employee);

  @override
  Future<void> updateEmployee(Employee employee) =>
      _activeService.updateEmployee(employee);

  @override
  Stream<List<Product>> streamProducts() => _activeService.streamProducts();

  @override
  Future<void> addProduct(Product product) =>
      _activeService.addProduct(product);

  @override
  Future<void> updateProduct(Product product) =>
      _activeService.updateProduct(product);

  @override
  Stream<List<Job>> streamJobs() => _activeService.streamJobs();

  @override
  Future<void> createJob(Job job, List<SalaryEntry> salaryEntries) =>
      _activeService.createJob(job, salaryEntries);

  @override
  Future<void> updateJob(Job job, List<SalaryEntry> salaryEntries) =>
      _activeService.updateJob(job, salaryEntries);

  @override
  Future<void> deleteJob(String jobId) => _activeService.deleteJob(jobId);

  @override
  Stream<List<SalaryEntry>> streamSalaryEntries() =>
      _activeService.streamSalaryEntries();

  @override
  Stream<List<SalaryPayment>> streamSalaryPayments() =>
      _activeService.streamSalaryPayments();

  @override
  Future<void> addSalaryPayment(SalaryPayment payment) =>
      _activeService.addSalaryPayment(payment);

  @override
  Future<void> deleteSalaryPayment(String paymentId) =>
      _activeService.deleteSalaryPayment(paymentId);

  @override
  Stream<List<AuditLog>> streamAuditLogs() => _activeService.streamAuditLogs();
}
