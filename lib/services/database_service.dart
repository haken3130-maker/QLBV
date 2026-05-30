import '../models/app_user.dart';
import '../models/employee.dart';
import '../models/product.dart';
import '../models/job.dart';
import '../models/salary_entry.dart';
import '../models/salary_payment.dart';
import '../models/audit_log.dart';

abstract class IDatabaseService {
  String get name;

  // Auth
  Future<AppUser?> signIn(String email, String password);
  Future<void> signOut();
  Future<AppUser?> getCurrentUser(String uid);

  // Employees
  Stream<List<Employee>> streamEmployees();
  Future<void> addEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);

  // Products
  Stream<List<Product>> streamProducts();
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);

  // Jobs
  Stream<List<Job>> streamJobs();
  Future<void> createJob(Job job, List<SalaryEntry> salaryEntries);
  Future<void> updateJob(Job job, List<SalaryEntry> salaryEntries);
  Future<void> deleteJob(String jobId);

  // Salary Entries
  Stream<List<SalaryEntry>> streamSalaryEntries();

  // Salary Payments
  Stream<List<SalaryPayment>> streamSalaryPayments();
  Future<void> addSalaryPayment(SalaryPayment payment);
  Future<void> deleteSalaryPayment(String paymentId);

  // Audit Logs
  Stream<List<AuditLog>> streamAuditLogs();
}
