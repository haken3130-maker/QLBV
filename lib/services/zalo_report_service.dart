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

  static List<String> buildJobsDetailChunks(List<Job> jobs, List<SalaryEntry> allEntries) {
    final List<String> chunks = [];
    
    for (int i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      final jobEntries = allEntries.where((e) => e.jobId == job.id).toList();
      final shareAmount = jobEntries.isNotEmpty ? jobEntries.first.amount : 0;
      final names = jobEntries.map((e) => e.employeeName).join(', ');

      final text = '''📦 CHI TIẾT CÔNG VIỆC #${i + 1}

• Sản phẩm: ${job.productName}
• Số lượng: ${job.quantity}
• Đơn giá: ${_currencyFormat.format(job.unitPrice)}
• Tổng cộng: ${_currencyFormat.format(job.totalAmount)}

👥 Nhân viên tham gia (${job.participants.length} người):
$names

💵 Chia đều: ${_currencyFormat.format(shareAmount)}/người''';
      chunks.add(text);
    }
    
    return chunks;
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

  static Future<void> shareChunk(String text) async {
    await Share.share(text);
  }
}
