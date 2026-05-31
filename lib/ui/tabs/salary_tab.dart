import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/salary_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/employee.dart';
import '../../models/job.dart';

class SalaryTab extends StatefulWidget {
  const SalaryTab({super.key});

  @override
  State<SalaryTab> createState() => _SalaryTabState();
}

class _SalaryTabState extends State<SalaryTab> with TickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _showAllTime = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _openPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecordPaymentDialog(),
    );
  }

  void _openDetailsDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => _WorkerSalaryDetailsDialog(
        employee: employee,
        showAllTime: _showAllTime,
        selectedMonth: _selectedMonth,
        selectedYear: _selectedYear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final filteredSalaryEntries = salaryProv.salaryEntries.where((se) {
      if (_showAllTime) return true;
      return se.date.year == _selectedYear && se.date.month == _selectedMonth;
    }).toList();

    final filteredSalaryPayments = salaryProv.salaryPayments.where((sp) {
      if (_showAllTime) return true;
      return sp.paymentDate.year == _selectedYear && sp.paymentDate.month == _selectedMonth;
    }).toList();

    // Calculate aggregated salary data for summary panel
    int totalEarnedAll = 0;
    int totalPaidAll = 0;
    int totalOwedAll = 0;

    for (final emp in salaryProv.employees) {
      final empEntries = filteredSalaryEntries.where((se) => se.employeeId == emp.id);
      final empPayments = filteredSalaryPayments.where((sp) => sp.employeeId == emp.id);
      
      final earned = empEntries.fold<int>(0, (sum, item) => sum + item.amount);
      final paid = empPayments.fold<int>(0, (sum, item) => sum + item.amount);
      
      totalEarnedAll += earned;
      totalPaidAll += paid;
      if (earned - paid > 0) {
        totalOwedAll += (earned - paid);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 450;
            final double dropdownWidth = isCompact ? (constraints.maxWidth - 32) / 3.0 : 120.0;

            return salaryProv.employees.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.monetization_on_outlined, size: 64, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có nhân viên nào',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                // ─── Aggregated Salary Stats Panel ───
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              icon: Icons.account_balance_wallet_outlined,
                              color: const Color(0xFF6200EE),
                              label: 'Tổng thu nhập',
                              value: _formatShortCurrency(totalEarnedAll),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryItem(
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF2E7D32),
                              label: 'Tổng đã phát',
                              value: _formatShortCurrency(totalPaidAll),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryItem(
                              icon: Icons.pending_outlined,
                              color: const Color(0xFFFF5722),
                              label: 'Tổng còn nợ',
                              value: _formatShortCurrency(totalOwedAll),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Kỳ xem lương',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: dropdownWidth,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value: _selectedMonth,
                                  items: List.generate(12, (index) {
                                    final month = index + 1;
                                    return DropdownMenuItem(
                                      value: month,
                                      child: Text('Tháng $month'),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedMonth = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: dropdownWidth,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value: _selectedYear,
                                  items: List.generate(DateTime.now().year - 2024 + 1, (index) {
                                    final year = 2024 + index;
                                    return DropdownMenuItem(value: year, child: Text('$year'));
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedYear = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isCompact ? dropdownWidth : 120,
                              height: 40,
                              child: OutlinedButton(
                                onPressed: () => setState(() => _showAllTime = !_showAllTime),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(_showAllTime ? 'Tất cả' : 'Theo kỳ'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _showAllTime
                              ? 'Hiển thị: Toàn bộ lịch sử lương'
                              : 'Hiển thị: Tháng $_selectedMonth / $_selectedYear',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF424242)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Employee Salary List ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Tìm nhân viên theo tên, số điện thoại, mã...',
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: () {
                    final query = _searchController.text.trim().toLowerCase();
                    final employeesToShow = salaryProv.employees.where((e) {
                      if (query.isEmpty) return true;
                      return e.name.toLowerCase().contains(query) || e.phone.toLowerCase().contains(query) || e.id.toLowerCase().contains(query);
                    }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      physics: const BouncingScrollPhysics(),
                      itemCount: employeesToShow.length,
                      itemBuilder: (context, index) {
                        final emp = employeesToShow[index];
                        final empEntries = filteredSalaryEntries.where((se) => se.employeeId == emp.id).toList();
                        final empPayments = filteredSalaryPayments.where((sp) => sp.employeeId == emp.id).toList();

                        final totalEarned = empEntries.fold<int>(0, (sum, item) => sum + item.amount);
                        final totalPaid = empPayments.fold<int>(0, (sum, item) => sum + item.amount);
                        final balance = totalEarned - totalPaid;

                        final isInactive = emp.status != 'active';

                        final animationDelay = (index * 50).clamp(0, 300);

                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final double slideProgress = Curves.easeOutCubic.transform(
                              (_animationController.value - (animationDelay / 600)).clamp(0.0, 1.0),
                            );
                            return Opacity(
                              opacity: slideProgress,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1.0 - slideProgress)),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () => _openDetailsDialog(context, emp),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: isInactive ? Colors.grey : const Color(0xFF6200EE),
                                        width: 4,
                                      ),
                                    ),
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
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: (isInactive ? Colors.grey : const Color(0xFF6200EE)).withOpacity(0.1),
                                                child: Text(
                                                  emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: isInactive ? Colors.grey : const Color(0xFF6200EE),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        emp.name,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF2C3E50),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '(' + (emp.id.length > 6 ? emp.id.substring(0, 6) : emp.id) + ')',
                                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                      ),
                                                      if (isInactive) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey.shade100,
                                                            borderRadius: BorderRadius.circular(10),
                                                            border: Border.all(color: Colors.grey.shade300),
                                                          ),
                                                          child: const Text(
                                                            'Đã nghỉ',
                                                            style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'SĐT: ${emp.phone}',
                                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF1D4ED8)),
                                                onPressed: () async {
                                                  final shareText = _buildEmployeeShareText(
                                                    emp,
                                                    salaryProv,
                                                    currencyFormat,
                                                    _showAllTime,
                                                    _selectedMonth,
                                                    _selectedYear,
                                                  );
                                                  await Share.share(shareText, subject: 'Bảng lương ${emp.name}');
                                                },
                                                splashRadius: 20,
                                                tooltip: 'Chia sẻ lương',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.payments, size: 18, color: Color(0xFF2E7D32)),
                                                onPressed: () {
                                                  // open payment dialog pre-filled for this employee
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (_) => RecordPaymentDialog(initialEmployee: emp),
                                                  );
                                                },
                                                splashRadius: 20,
                                                tooltip: 'Ghi nhận phát lương',
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24, thickness: 0.8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: _buildFinancialColumn(
                                              label: 'Thu nhập',
                                              value: currencyFormat.format(totalEarned),
                                              valueColor: const Color(0xFF2C3E50),
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildFinancialColumn(
                                              label: 'Đã nhận',
                                              value: currencyFormat.format(totalPaid),
                                              valueColor: const Color(0xFF2E7D32),
                                              crossAlign: CrossAxisAlignment.center,
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildFinancialColumn(
                                              label: 'Còn nợ',
                                              value: currencyFormat.format(balance),
                                              valueColor: balance > 0 ? const Color(0xFFFF5722) : Colors.grey.shade600,
                                              crossAlign: CrossAxisAlignment.end,
                                              badge: balance > 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }(),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: authProv.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openPaymentDialog(context),
              backgroundColor: const Color(0xFF6200EE),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.payments_outlined),
              label: const Text(
                'Phát lương',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.2),
              ),
            )
          : null,
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialColumn({
    required String label,
    required String value,
    required Color valueColor,
    CrossAxisAlignment crossAlign = CrossAxisAlignment.start,
    bool badge = false,
  }) {
    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        badge
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: valueColor,
                  ),
                ),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
      ],
    );
  }

  String _formatShortCurrency(int amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỷ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '$amount đ';
  }

}

String _buildEmployeeShareText(
  Employee employee,
  SalaryProvider salaryProv,
  NumberFormat currencyFormat,
  bool showAllTime,
  int selectedMonth,
  int selectedYear,
) {
  final filteredEntries = salaryProv.salaryEntries.where((se) {
    if (se.employeeId != employee.id) return false;
    if (showAllTime) return true;
    return se.date.year == selectedYear && se.date.month == selectedMonth;
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final filteredPayments = salaryProv.salaryPayments.where((sp) {
    if (sp.employeeId != employee.id) return false;
    if (showAllTime) return true;
    return sp.paymentDate.year == selectedYear && sp.paymentDate.month == selectedMonth;
  }).toList()
    ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

  final totalEarned = filteredEntries.fold<int>(0, (sum, item) => sum + item.amount);
  final totalPaid = filteredPayments.fold<int>(0, (sum, item) => sum + item.amount);
  final balance = totalEarned - totalPaid;

  final periodText = showAllTime
      ? 'Toàn bộ lịch sử'
      : 'Tháng $selectedMonth/${selectedYear.toString().substring(2)}';

  final buffer = StringBuffer();
  buffer.writeln('Bảng lương nhân viên: ${employee.name}');
  buffer.writeln('Số điện thoại: ${employee.phone}');
  buffer.writeln('Kỳ: $periodText');
  buffer.writeln('Tổng thu nhập: ${currencyFormat.format(totalEarned)}');
  buffer.writeln('Tổng đã phát: ${currencyFormat.format(totalPaid)}');
  buffer.writeln('Còn nợ: ${currencyFormat.format(balance)}');
  buffer.writeln('');
  buffer.writeln('Chi tiết công việc:');

  if (filteredEntries.isEmpty) {
    buffer.writeln('- Chưa có lịch sử công');
  } else {
    for (final entry in filteredEntries) {
      final date = DateFormat('dd/MM/yyyy').format(entry.date);
      final relatedJob = salaryProv.jobs.firstWhere(
        (job) => job.id == entry.jobId,
        orElse: () => Job(
          id: '',
          date: entry.date,
          productId: '',
          productName: entry.productName,
          quantity: 0,
          unitPrice: 0,
          totalAmount: entry.amount,
          participants: [],
          createdBy: '',
          createdAt: entry.date,
        ),
      );
      buffer.writeln('- $date | ${entry.productName} | Số lượng: ${relatedJob.quantity} | Lương: ${currencyFormat.format(entry.amount)}');
    }
  }

  if (filteredPayments.isNotEmpty) {
    buffer.writeln('');
    buffer.writeln('Lịch sử phát lương:');
    for (final payment in filteredPayments) {
      buffer.writeln('- ${DateFormat('dd/MM/yyyy').format(payment.paymentDate)} | ${currencyFormat.format(payment.amount)} | Ghi chú: ${payment.notes ?? '-'}');
    }
  }

  buffer.writeln('');
  buffer.writeln('Cập nhật tự động từ hệ thống QLBV.');
  return buffer.toString();
}

class RecordPaymentDialog extends StatefulWidget {
  final Employee? initialEmployee;
  const RecordPaymentDialog({Key? key, this.initialEmployee}) : super(key: key);

  @override
  State<RecordPaymentDialog> createState() => RecordPaymentDialogState();
}

class RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  Employee? _selectedEmployee;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String? _autoFilledEmployeeId;
  String? _amountHelperText;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = widget.initialEmployee;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedEmployee != null && _autoFilledEmployeeId != _selectedEmployee!.id) {
      _updateAmountForSelectedEmployee();
    }
  }

  void _updateAmountForSelectedEmployee() {
    if (_selectedEmployee == null) return;
    final salaryProv = Provider.of<SalaryProvider>(context, listen: false);
    final earned = salaryProv.salaryEntries
        .where((e) => e.employeeId == _selectedEmployee!.id)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final paid = salaryProv.salaryPayments
        .where((p) => p.employeeId == _selectedEmployee!.id)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final balance = earned - paid;

    if (balance > 0) {
      _amountController.text = balance.toString();
      _amountHelperText = 'Tự động điền số tiền còn nợ: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(balance)}';
    } else {
      _amountController.text = '0';
      _amountHelperText = 'Nhân viên hiện không còn nợ lương.';
    }
    _autoFilledEmployeeId = _selectedEmployee!.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhân viên'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      final salaryProv = Provider.of<SalaryProvider>(context, listen: false);

      await salaryProv.recordPayment(
        employeeId: _selectedEmployee!.id,
        amount: int.parse(_amountController.text),
        date: _paymentDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdBy: authProv.currentUser?.email ?? 'Unknown',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ghi nhận phát lương thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final activeEmployees = salaryProv.employees.where((e) => e.status == 'active').toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.payment_rounded, color: Color(0xFF6200EE)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ghi nhận phát lương',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Form fields
                const Text('Nhân viên nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
                const SizedBox(height: 6),
                DropdownButtonFormField<Employee>(
                  value: _selectedEmployee,
                  hint: const Text('Chọn nhân viên'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: activeEmployees.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(e.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedEmployee = val;
                      _updateAmountForSelectedEmployee();
                    });
                  },
                  validator: (val) => val == null ? 'Vui lòng chọn nhân viên' : null,
                ),
                const SizedBox(height: 16),

                const Text('Số tiền phát (VNĐ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'VD: 5000000',
                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                    suffixText: 'đ',
                    helperText: _amountHelperText,
                    helperMaxLines: 2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Vui lòng nhập số tiền';
                    if (int.tryParse(val) == null) return 'Số tiền phải là số nguyên';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Selector
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E9F3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 16, color: Color(0xFF6200EE)),
                          const SizedBox(width: 8),
                          Text(
                            'Ngày phát: ${DateFormat('dd/MM/yyyy').format(_paymentDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50)),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _selectDate(context),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6200EE),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Thay đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Ghi chú giao dịch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'VD: Phát lương đợt 1 tháng 6',
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Lưu giao dịch', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkerSalaryDetailsDialog extends StatelessWidget {
  final Employee employee;
  final bool showAllTime;
  final int selectedMonth;
  final int selectedYear;

  const _WorkerSalaryDetailsDialog({
    required this.employee,
    required this.showAllTime,
    required this.selectedMonth,
    required this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final empEntries = salaryProv.salaryEntries.where((se) {
      if (se.employeeId != employee.id) return false;
      if (showAllTime) return true;
      return se.date.year == selectedYear && se.date.month == selectedMonth;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final empPayments = salaryProv.salaryPayments.where((sp) {
      if (sp.employeeId != employee.id) return false;
      if (showAllTime) return true;
      return sp.paymentDate.year == selectedYear && sp.paymentDate.month == selectedMonth;
    }).toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    final totalEarned = empEntries.fold<int>(0, (sum, item) => sum + item.amount);
    final totalPaid = empPayments.fold<int>(0, (sum, item) => sum + item.amount);
    final balance = totalEarned - totalPaid;

    return DefaultTabController(
      length: 2,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 520,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF6200EE).withOpacity(0.1),
                      child: Text(
                        employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6200EE)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(employee.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                          const SizedBox(height: 2),
                          Text('Số điện thoại: ${employee.phone}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiết lương cá nhân',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final shareText = _buildEmployeeShareText(
                          employee,
                          salaryProv,
                          currencyFormat,
                          showAllTime,
                          selectedMonth,
                          selectedYear,
                        );
                        await Share.share(shareText, subject: 'Bảng lương ${employee.name}');
                      },
                      icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF1D4ED8)),
                      label: const Text('Chia sẻ', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),

              // Aggregated Mini Details Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thu nhập', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(currencyFormat.format(totalEarned), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Đã nhận', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(currencyFormat.format(totalPaid), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Còn nợ', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(balance),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: balance > 0 ? const Color(0xFFFF5722) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // TabBar selector
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: TabBar(
                  labelColor: Color(0xFF6200EE),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF6200EE),
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: 'Lịch sử công'),
                    Tab(text: 'Lịch sử nhận'),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Tab content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBarView(
                    children: [
                      // Tab 1: Work list
                      empEntries.isEmpty
                          ? const Center(child: Text('Chưa có lịch sử bốc xếp.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: empEntries.length,
                              separatorBuilder: (_, __) => Divider(height: 16, color: Colors.grey.shade100),
                              itemBuilder: (context, idx) {
                                final entry = empEntries[idx];
                                final relatedJob = salaryProv.jobs.firstWhere(
                                  (job) => job.id == entry.jobId,
                                  orElse: () => Job(
                                    id: '',
                                    date: entry.date,
                                    productId: '',
                                    productName: entry.productName,
                                    quantity: 0,
                                    unitPrice: 0,
                                    totalAmount: entry.amount,
                                    participants: [],
                                    createdBy: '',
                                    createdAt: entry.date,
                                  ),
                                );
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  title: Text(entry.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 10, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(DateFormat('dd/MM/yyyy').format(entry.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Số lượng: ${relatedJob.quantity} ${relatedJob.productName} · Lương: ${currencyFormat.format(entry.amount)}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    '+${currencyFormat.format(entry.amount)}',
                                    style: const TextStyle(color: Color(0xFF6200EE), fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                  dense: true,
                                );
                              },
                            ),

                      // Tab 2: Payments history
                      empPayments.isEmpty
                          ? const Center(child: Text('Chưa có lịch sử nhận lương.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: empPayments.length,
                              separatorBuilder: (_, __) => Divider(height: 16, color: Colors.grey.shade100),
                              itemBuilder: (context, idx) {
                                final p = empPayments[idx];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  title: Text(
                                    currencyFormat.format(p.amount),
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 10, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(DateFormat('dd/MM/yyyy').format(p.paymentDate), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        ],
                                      ),
                                      if (p.notes != null) ...[
                                        const SizedBox(height: 2),
                                        Text('Ghi chú: ${p.notes}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                                      ],
                                    ],
                                  ),
                                  trailing: authProv.isAdmin
                                      ? IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                title: const Row(
                                                  children: [
                                                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                                                    SizedBox(width: 8),
                                                    Text('Xác nhận xóa'),
                                                  ],
                                                ),
                                                content: const Text('Bạn có chắc chắn muốn xóa giao dịch phát lương này?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      salaryProv.deletePayment(p.id);
                                                      Navigator.of(ctx).pop();
                                                      Navigator.of(context).pop();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Đã xóa giao dịch phát lương.'),
                                                          behavior: SnackBarBehavior.floating,
                                                        ),
                                                      );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.redAccent, 
                                                      foregroundColor: Colors.white, 
                                                      minimumSize: const Size(80, 40),
                                                      elevation: 0,
                                                    ),
                                                    child: const Text('Xóa'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          splashRadius: 18,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        )
                                      : null,
                                  dense: true,
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
