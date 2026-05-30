import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/salary_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/employee.dart';

class SalaryTab extends StatefulWidget {
  const SalaryTab({super.key});

  @override
  State<SalaryTab> createState() => _SalaryTabState();
}

class _SalaryTabState extends State<SalaryTab> with TickerProviderStateMixin {
  late AnimationController _animationController;

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
    _animationController.dispose();
    super.dispose();
  }

  void _openPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RecordPaymentDialog(),
    );
  }

  void _openDetailsDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => _WorkerSalaryDetailsDialog(employee: employee),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Calculate aggregated salary data for summary panel
    int totalEarnedAll = 0;
    int totalPaidAll = 0;
    int totalOwedAll = 0;

    for (final emp in salaryProv.employees) {
      final empEntries = salaryProv.salaryEntries.where((se) => se.employeeId == emp.id);
      final empPayments = salaryProv.salaryPayments.where((sp) => sp.employeeId == emp.id);
      
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
      body: salaryProv.employees.isEmpty
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
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          icon: Icons.account_balance_wallet_outlined,
                          color: const Color(0xFF6200EE),
                          label: 'Tổng thu nhập',
                          value: _formatShortCurrency(totalEarnedAll),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryItem(
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF2E7D32),
                          label: 'Tổng đã phát',
                          value: _formatShortCurrency(totalPaidAll),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                ),

                // ─── Employee Salary List ───
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    physics: const BouncingScrollPhysics(),
                    itemCount: salaryProv.employees.length,
                    itemBuilder: (context, index) {
                      final emp = salaryProv.employees[index];
                      final empEntries = salaryProv.salaryEntries.where((se) => se.employeeId == emp.id).toList();
                      final empPayments = salaryProv.salaryPayments.where((sp) => sp.employeeId == emp.id).toList();

                      final totalEarned = empEntries.fold<int>(0, (sum, item) => sum + item.amount);
                      final totalPaid = empPayments.fold<int>(0, (sum, item) => sum + item.amount);
                      final balance = totalEarned - totalPaid;

                      final isInactive = emp.status != 'active';

                      // Staggered list animations
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
                                    // Employee Header Row
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
                                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                                      ],
                                    ),
                                    const Divider(height: 24, thickness: 0.8),
                                    
                                    // Financial Grid
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
                                            label: 'Đã nhận/ứng',
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
                  ),
                ),
              ],
            ),
      floatingActionButton: authProv.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openPaymentDialog(context),
              backgroundColor: const Color(0xFF6200EE),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.payments_outlined),
              label: const Text(
                'Phát / Ứng lương',
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

class _RecordPaymentDialog extends StatefulWidget {
  const _RecordPaymentDialog();

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  Employee? _selectedEmployee;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();

  bool _isSaving = false;

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
                        'Ghi Nhận Phát / Ứng Lương',
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
                  onChanged: (val) => setState(() => _selectedEmployee = val),
                  validator: (val) => val == null ? 'Vui lòng chọn nhân viên' : null,
                ),
                const SizedBox(height: 16),

                const Text('Số tiền phát/ứng (VNĐ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'VD: 5000000',
                    prefixIcon: const Icon(Icons.monetization_on_outlined),
                    suffixText: 'đ',
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
                    hintText: 'VD: Ứng lương đợt 1 tháng 6',
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
  const _WorkerSalaryDetailsDialog({required this.employee});

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final empEntries = salaryProv.salaryEntries.where((se) => se.employeeId == employee.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final empPayments = salaryProv.salaryPayments.where((sp) => sp.employeeId == employee.id).toList()
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
                        const Text('Đã ứng/phát', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
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
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  title: Text(entry.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
                                  subtitle: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 10, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(DateFormat('dd/MM/yyyy').format(entry.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                          ? const Center(child: Text('Chưa có lịch sử nhận/ứng lương.', style: TextStyle(color: Colors.grey, fontSize: 13)))
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
