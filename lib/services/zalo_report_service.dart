import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/job.dart';
import '../models/salary_entry.dart';

class ZaloReportService {
  static final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  static String buildSummaryChunk(DateTime date, int jobsCount, double totalQuantity, int totalAmount) {
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    return '''📋 BÁO CÁO TỔNG HỢP NGÀY $dateStr

• Số công việc: $jobsCount
• Tổng sản lượng: ${totalQuantity.toStringAsFixed(1)}
• Tổng doanh thu: ${_currencyFormat.format(totalAmount)}''';
  }

  static String buildJobsDetailText(List<Job> jobs, List<SalaryEntry> allEntries) {
    if (jobs.isEmpty) {
      return 'Không có chi tiết công việc trong ngày.';
    }

    final buffer = StringBuffer();
    for (int i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      final jobEntries = allEntries.where((e) => e.jobId == job.id).toList();
      final validParticipants = job.participants.isNotEmpty ? job.participants.length : 1;
      final shareAmount = job.totalAmount ~/ validParticipants;
      final names = jobEntries.map((e) => e.employeeName).toSet().join(', ');

      buffer.writeln('📦 CHI TIẾT CÔNG VIỆC #${i + 1}');
      buffer.writeln();
      buffer.writeln('• Sản phẩm: ${job.productName}');
      buffer.writeln('• Số lượng: ${job.quantity}');
      buffer.writeln('• Đơn giá: ${_currencyFormat.format(job.unitPrice)}');
      buffer.writeln('• Tổng cộng: ${_currencyFormat.format(job.totalAmount)}');
      buffer.writeln();
      buffer.writeln('👥 Nhân viên tham gia (${job.participants.length} người):');
      buffer.writeln(names.isNotEmpty ? names : 'Không có nhân viên');
      buffer.writeln();
      buffer.writeln('💵 Chia đều: ${_currencyFormat.format(shareAmount)}/người');

      if (i < jobs.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  static String buildWorkerEarningsChunk(DateTime date, Map<String, int> workerEarnings) {
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    final buffer = StringBuffer('💰 THU NHẬP NHÂN VIÊN NGÀY $dateStr\n\n');
    
    if (workerEarnings.isEmpty) {
      buffer.write('Không có thu nhập phát sinh trong ngày.');
    } else {
      var sortedEntries = workerEarnings.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (var entry in sortedEntries) {
        buffer.write('• ${entry.key}: ${_currencyFormat.format(entry.value)}\n');
      }
    }
    
    return buffer.toString();
  }

  static String buildFullDailyReport(DateTime date, List<Job> jobs, List<SalaryEntry> allEntries, Map<String, int> workerEarnings) {
    final summaryText = buildSummaryChunk(
      date,
      jobs.length,
      jobs.fold<double>(0.0, (sum, item) => sum + item.quantity),
      jobs.fold<int>(0, (sum, item) => sum + item.totalAmount),
    );

    final detailsText = buildJobsDetailText(jobs, allEntries);
    final earningsText = buildWorkerEarningsChunk(date, workerEarnings);

    return '''$summaryText

$detailsText

$earningsText''';
  }

  static Future<void> shareChunk(String text) async {
    await Share.share(text);
  }
}
