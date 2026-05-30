import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';
import '../models/employee.dart';
import '../models/salary_entry.dart';
import '../models/salary_payment.dart';

class ExcelReportService {
  static Future<void> exportAndSharePeriodReport({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required List<Employee> employees,
    required List<Job> jobs,
    required List<SalaryEntry> salaryEntries,
    required List<SalaryPayment> payments,
  }) async {
    final excel = Excel.createExcel();
    
    final String defaultSheet = excel.getDefaultSheet()!;
    excel.rename(defaultSheet, 'Tong_hop');

    // 1. TỔNG HỢP SHEET
    final Sheet sheet1 = excel['Tong_hop'];
    sheet1.appendRow([TextCellValue('BAO CAO LUONG NHAN VIEN')]);
    sheet1.appendRow([TextCellValue('Ky bao cao: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}')]);
    sheet1.appendRow([]);
    
    sheet1.appendRow([
      TextCellValue('Ma NV'),
      TextCellValue('Ten Nhan Vien'),
      TextCellValue('So dien thoai'),
      TextCellValue('So cong viec'),
      TextCellValue('Tong thu nhap (VND)'),
      TextCellValue('Da ung/phat (VND)'),
      TextCellValue('Con no (VND)'),
    ]);

    for (var employee in employees) {
      final empEntries = salaryEntries.where((e) => e.employeeId == employee.id).toList();
      final empPayments = payments.where((p) => p.employeeId == employee.id).toList();

      final totalSalary = empEntries.fold<int>(0, (sum, item) => sum + item.amount);
      final totalPaid = empPayments.fold<int>(0, (sum, item) => sum + item.amount);
      final remaining = totalSalary - totalPaid;

      sheet1.appendRow([
        TextCellValue(employee.id),
        TextCellValue(employee.name),
        TextCellValue(employee.phone),
        IntCellValue(empEntries.length),
        IntCellValue(totalSalary),
        IntCellValue(totalPaid),
        IntCellValue(remaining),
      ]);
    }

    // 2. CHI TIẾT CÔNG VIỆC SHEET
    final Sheet sheet2 = excel['Chi_tiet_cong_viec'];
    sheet2.appendRow([TextCellValue('DANH SACH CHI TIET CONG VIEC')]);
    sheet2.appendRow([]);
    sheet2.appendRow([
      TextCellValue('Ngay'),
      TextCellValue('San pham'),
      TextCellValue('So luong'),
      TextCellValue('Don gia (VND)'),
      TextCellValue('Tong tien (VND)'),
      TextCellValue('So nguoi lam'),
      TextCellValue('Tien chia (VND)'),
      TextCellValue('Nguoi tham gia'),
    ]);

    for (var job in jobs) {
      final jobEntries = salaryEntries.where((e) => e.jobId == job.id).toList();
      final shareAmount = jobEntries.isNotEmpty ? jobEntries.first.amount : 0;
      final names = jobEntries.map((e) => e.employeeName).join(', ');

      sheet2.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy').format(job.date)),
        TextCellValue(job.productName),
        DoubleCellValue(job.quantity),
        IntCellValue(job.unitPrice),
        IntCellValue(job.totalAmount),
        IntCellValue(job.participants.length),
        IntCellValue(shareAmount),
        TextCellValue(names),
      ]);
    }

    // 3. PHÁT LƯƠNG SHEET
    final Sheet sheet3 = excel['Phat_luong'];
    sheet3.appendRow([TextCellValue('LICH SU PHAT UNG LUONG')]);
    sheet3.appendRow([]);
    sheet3.appendRow([
      TextCellValue('Ma GD'),
      TextCellValue('Ngay'),
      TextCellValue('Nhan vien'),
      TextCellValue('So tien (VND)'),
      TextCellValue('Ghi chu'),
      TextCellValue('Nguoi lap'),
    ]);

    for (var p in payments) {
      sheet3.appendRow([
        TextCellValue(p.id),
        TextCellValue(DateFormat('dd/MM/yyyy').format(p.paymentDate)),
        TextCellValue(p.employeeName),
        IntCellValue(p.amount),
        TextCellValue(p.notes ?? ''),
        TextCellValue(p.createdBy),
      ]);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final tempDir = await getTemporaryDirectory();
      final formattedTitle = title.replaceAll(RegExp(r'[^\w\-_]'), '_');
      final file = await File('${tempDir.path}/$formattedTitle.xlsx').create();
      await file.writeAsBytes(bytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Bao cao Excel $title',
      );
    }
  }
}
