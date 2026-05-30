import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/salary_provider.dart';
import '../../services/zalo_report_service.dart';
import '../../services/excel_report_service.dart';
import '../../services/pdf_report_service.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTime _dailyReportDate = DateTime.now();
  
  int _selectedPeriodMonth = DateTime.now().month;
  int _selectedPeriodYear = DateTime.now().year;
  bool _isFirstPeriod = true;

  int _selectedMonthlyMonth = DateTime.now().month;
  int _selectedMonthlyYear = DateTime.now().year;

  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Color(0xFF6200EE),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF6200EE),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(icon: Icon(Icons.today_rounded, size: 18), text: 'Báo cáo Ngày'),
                Tab(icon: Icon(Icons.date_range_rounded, size: 18), text: 'Báo cáo Kỳ'),
                Tab(icon: Icon(Icons.calendar_month_rounded, size: 18), text: 'Báo cáo Tháng'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildDailyReportTab(context),
            _buildPeriodReportTab(context),
            _buildMonthlyReportTab(context),
          ],
        ),
      ),
    );
  }

  // ─── DAILY REPORT VIEW (ZALO TEXT TEMPLATES) ───
  Widget _buildDailyReportTab(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    
    final jobsToday = salaryProv.jobs.where((j) =>
        j.date.year == _dailyReportDate.year &&
        j.date.month == _dailyReportDate.month &&
        j.date.day == _dailyReportDate.day).toList();

    final entriesToday = salaryProv.salaryEntries.where((se) =>
        se.date.year == _dailyReportDate.year &&
        se.date.month == _dailyReportDate.month &&
        se.date.day == _dailyReportDate.day).toList();

    final totalJobs = jobsToday.length;
    final totalVolume = jobsToday.fold<double>(0.0, (sum, item) => sum + item.quantity);
    final totalAmount = jobsToday.fold<int>(0, (sum, item) => sum + item.totalAmount);

    final Map<String, int> workerEarnings = {};
    for (var entry in entriesToday) {
      workerEarnings[entry.employeeName] = (workerEarnings[entry.employeeName] ?? 0) + entry.amount;
    }

    final summaryText = ZaloReportService.buildSummaryChunk(_dailyReportDate, totalJobs, totalVolume, totalAmount);
    final jobChunks = ZaloReportService.buildJobsDetailChunks(jobsToday, entriesToday);
    final earningsText = ZaloReportService.buildWorkerEarningsChunk(_dailyReportDate, workerEarnings);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SelectionArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date picker container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF6200EE)),
                        const SizedBox(width: 8),
                        Text(
                          'Ngày xem báo cáo: ${DateFormat('dd/MM/yyyy').format(_dailyReportDate)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50)),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dailyReportDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _dailyReportDate = picked);
                        }
                      },
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF6200EE)),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                      label: const Text('Chọn ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              if (totalJobs == 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'Không có hoạt động trong ngày này',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Vui lòng chọn ngày khác để xem mẫu báo cáo.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildTemplateCard(
                  title: 'Phần 1: Tổng hợp chung',
                  content: summaryText,
                  icon: Icons.analytics_outlined,
                ),
                
                ...List.generate(jobChunks.length, (idx) {
                  return _buildTemplateCard(
                    title: 'Phần 2.${idx + 1}: Chi tiết công việc #${idx + 1}',
                    content: jobChunks[idx],
                    icon: Icons.inventory_2_outlined,
                  );
                }),
                
                _buildTemplateCard(
                  title: 'Phần 3: Thu nhập nhân viên',
                  content: earningsText,
                  icon: Icons.groups_outlined,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTemplateCard({required String title, required String content, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF6200EE)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50)),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF6200EE)),
                      tooltip: 'Sao chép',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép vào bộ nhớ tạm!'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, size: 15, color: Colors.blue),
                      tooltip: 'Gửi Zalo',
                      onPressed: () => ZaloReportService.shareChunk(content),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontFamily: 'monospace', 
                fontSize: 12, 
                height: 1.4,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PERIOD REPORT VIEW (EXCEL EXPORTS) ───
  Widget _buildPeriodReportTab(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);

    final startDate = DateTime(_selectedPeriodYear, _selectedPeriodMonth, _isFirstPeriod ? 1 : 11);
    final endDate = _isFirstPeriod
        ? DateTime(_selectedPeriodYear, _selectedPeriodMonth, 10, 23, 59, 59)
        : DateTime(_selectedPeriodYear, _selectedPeriodMonth + 1, 1).subtract(const Duration(seconds: 1));

    final periodJobs = salaryProv.jobs.where((j) =>
        j.date.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
        j.date.isBefore(endDate.add(const Duration(milliseconds: 1)))).toList();

    final periodEntries = salaryProv.salaryEntries.where((se) =>
        se.date.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
        se.date.isBefore(endDate.add(const Duration(milliseconds: 1)))).toList();

    final periodPayments = salaryProv.salaryPayments.where((sp) =>
        sp.paymentDate.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
        sp.paymentDate.isBefore(endDate.add(const Duration(milliseconds: 1)))).toList();

    final totalJobs = periodJobs.length;
    final totalVolume = periodJobs.fold<double>(0.0, (sum, item) => sum + item.quantity);
    final totalAmount = periodJobs.fold<int>(0, (sum, item) => sum + item.totalAmount);
    final totalSalary = periodEntries.fold<int>(0, (sum, item) => sum + item.amount);
    final totalPaid = periodPayments.fold<int>(0, (sum, item) => sum + item.amount);
    final totalOwed = totalSalary - totalPaid;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Picker Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Color(0xFF6200EE), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Cấu Hình Báo Cáo Kỳ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedPeriodMonth,
                        decoration: InputDecoration(
                          labelText: 'Tháng',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text('Tháng ${index + 1}'),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPeriodMonth = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedPeriodYear,
                        decoration: InputDecoration(
                          labelText: 'Năm',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [2025, 2026, 2027, 2028].map((y) {
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPeriodYear = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Kỳ selection (ChoiceChips)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isFirstPeriod = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isFirstPeriod ? const Color(0xFF6200EE) : const Color(0xFFF0F1F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Kỳ 1 (Ngày 1 - 10)',
                              style: TextStyle(
                                color: _isFirstPeriod ? Colors.white : const Color(0xFF5A5A5A),
                                fontWeight: _isFirstPeriod ? FontWeight.bold : FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isFirstPeriod = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isFirstPeriod ? const Color(0xFF6200EE) : const Color(0xFFF0F1F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Kỳ 2 (Ngày 11 - Hết)',
                              style: TextStyle(
                                color: !_isFirstPeriod ? Colors.white : const Color(0xFF5A5A5A),
                                fontWeight: !_isFirstPeriod ? FontWeight.bold : FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Overview metrics cards grid
          const Text(
            'KẾT QUẢ KỲ BÁO CÁO',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6200EE), fontSize: 12, letterSpacing: 0.3),
          ),
          const SizedBox(height: 10),

          // Custom Grid for Stats (Better than raw Tables)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildStatGridCard('Tổng việc', '$totalJobs', Icons.assignment_outlined, const Color(0xFF6200EE)),
              _buildStatGridCard('Tổng sản lượng', '${totalVolume.toStringAsFixed(1)} T/B', Icons.scale_outlined, const Color(0xFF1565C0)),
              _buildStatGridCard('Tổng tiền hàng', currencyFormat.format(totalAmount), Icons.monetization_on_outlined, const Color(0xFF2E7D32)),
              _buildStatGridCard('Tổng quỹ lương', currencyFormat.format(totalSalary), Icons.account_balance_wallet_outlined, Colors.purple),
              _buildStatGridCard('Đã phát/tạm ứng', currencyFormat.format(totalPaid), Icons.check_circle_outlined, Colors.green),
              _buildStatGridCard('Còn nợ lại', currencyFormat.format(totalOwed), Icons.pending_outlined, const Color(0xFFFF5722)),
            ],
          ),
          const SizedBox(height: 24),

          // Export button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final termStr = _isFirstPeriod ? 'Ky_1_10' : 'Ky_11_Cuoi';
                ExcelReportService.exportAndSharePeriodReport(
                  title: 'Bao_cao_ky_${termStr}_thang_${_selectedPeriodMonth}_$_selectedPeriodYear',
                  startDate: startDate,
                  endDate: endDate,
                  employees: salaryProv.employees,
                  jobs: periodJobs,
                  salaryEntries: periodEntries,
                  payments: periodPayments,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
              icon: const Icon(Icons.file_download_rounded, size: 20),
              label: const Text(
                'XUẤT BÁO CÁO EXCEL KỲ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGridCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── MONTHLY REPORT VIEW (EXCEL & PDF EXPORTS) ───
  Widget _buildMonthlyReportTab(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);

    final startDate = DateTime(_selectedMonthlyYear, _selectedMonthlyMonth, 1);
    final endDate = DateTime(_selectedMonthlyYear, _selectedMonthlyMonth + 1, 1).subtract(const Duration(seconds: 1));

    final monthJobs = salaryProv.jobs.where((j) =>
        j.date.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
        j.date.isBefore(endDate.add(const Duration(milliseconds: 1)))).toList();

    final monthEntries = salaryProv.salaryEntries.where((se) =>
        se.date.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
        se.date.isBefore(endDate.add(const Duration(milliseconds: 1)))).toList();

    final monthPayments = salaryProv.salaryPayments.where((sp) =>
        sp.paymentDate.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
        sp.paymentDate.isBefore(endDate.add(const Duration(milliseconds: 1)))).toList();

    final totalJobs = monthJobs.length;
    final totalVolume = monthJobs.fold<double>(0.0, (sum, item) => sum + item.quantity);
    final totalAmount = monthJobs.fold<int>(0, (sum, item) => sum + item.totalAmount);
    final totalSalary = monthEntries.fold<int>(0, (sum, item) => sum + item.amount);
    final totalPaid = monthPayments.fold<int>(0, (sum, item) => sum + item.amount);
    final totalOwed = totalSalary - totalPaid;

    final rankings = salaryProv.employees.map((emp) {
      final empEntries = monthEntries.where((e) => e.employeeId == emp.id).toList();
      final income = empEntries.fold<int>(0, (sum, item) => sum + item.amount);
      return _EmpRank(name: emp.name, jobs: empEntries.length, income: income);
    }).toList();
    rankings.sort((a, b) => b.income.compareTo(a.income));
    final medals = ['🥇', '🥈', '🥉'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: Column(
        children: [
          // Select Year/Month card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonthlyMonth,
                      decoration: InputDecoration(
                        labelText: 'Tháng',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(value: index + 1, child: Text('Tháng ${index + 1}'));
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonthlyMonth = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonthlyYear,
                      decoration: InputDecoration(
                        labelText: 'Năm',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [2025, 2026, 2027, 2028].map((y) {
                        return DropdownMenuItem(value: y, child: Text('$y'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonthlyYear = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Statistics
                  const Text(
                    'TỔNG QUAN THÁNG BÁO CÁO', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6200EE), fontSize: 12, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 10),
                  
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildStatGridCard('Tổng việc', '$totalJobs', Icons.assignment_outlined, const Color(0xFF6200EE)),
                      _buildStatGridCard('Tổng sản lượng', '${totalVolume.toStringAsFixed(1)} T/B', Icons.scale_outlined, const Color(0xFF1565C0)),
                      _buildStatGridCard('Doanh thu đội', currencyFormat.format(totalAmount), Icons.monetization_on_outlined, const Color(0xFF2E7D32)),
                      _buildStatGridCard('Tổng quỹ lương', currencyFormat.format(totalSalary), Icons.account_balance_wallet_outlined, Colors.purple),
                      _buildStatGridCard('Đã chi trả', currencyFormat.format(totalPaid), Icons.check_circle_outlined, Colors.green),
                      _buildStatGridCard('Chưa giải ngân', currencyFormat.format(totalOwed), Icons.pending_outlined, const Color(0xFFFF5722)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Actions row (Excel and PDF)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ExcelReportService.exportAndSharePeriodReport(
                              title: 'Bao_cao_Excel_thang_${_selectedMonthlyMonth}_$_selectedMonthlyYear',
                              startDate: startDate,
                              endDate: endDate,
                              employees: salaryProv.employees,
                              jobs: monthJobs,
                              salaryEntries: monthEntries,
                              payments: monthPayments,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.table_view_rounded, color: Color(0xFF2E7D32), size: 18),
                          label: const Text('EXCEL THÁNG', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            PdfReportService.exportAndShareMonthlyPdf(
                              monthStr: '$_selectedMonthlyMonth/$_selectedMonthlyYear',
                              employees: salaryProv.employees,
                              jobs: monthJobs,
                              salaryEntries: monthEntries,
                              payments: monthPayments,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 18),
                          label: const Text('PDF THÁNG', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Employee Listing Table
                  const Text(
                    'BẢNG DOANH THU NHÂN VIÊN', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6200EE), fontSize: 12, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // Custom premium header row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text('Hạng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2C3E50)), textAlign: TextAlign.center),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text('Nhân viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2C3E50))),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Số công', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2C3E50))),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('Thu nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2C3E50))),
                              ),
                            ],
                          ),
                        ),
                        ...rankings.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final rank = entry.value;
                          final medal = idx < 3 ? medals[idx] : '${idx + 1}';

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    medal,
                                    style: const TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    rank.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${rank.jobs} công',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    currencyFormat.format(rank.income),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900, 
                                      fontSize: 12,
                                      color: Color(0xFF6200EE),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmpRank {
  final String name;
  final int jobs;
  final int income;
  _EmpRank({required this.name, required this.jobs, required this.income});
}
