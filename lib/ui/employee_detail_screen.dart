import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/salary_provider.dart';
import '../providers/auth_provider.dart';
import '../models/employee.dart';
import '../models/salary_entry.dart';
import '../models/salary_payment.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final Employee employee;
  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final empEntries =
        salaryProv.salaryEntries
            .where((se) => se.employeeId == employee.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final empPayments =
        salaryProv.salaryPayments
            .where((sp) => sp.employeeId == employee.id)
            .toList()
          ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    final totalJobs = empEntries.length;
    final totalEarned = empEntries.fold<int>(0, (s, e) => s + e.amount);
    final totalPaid = empPayments.fold<int>(0, (s, p) => s + p.amount);
    final balance = totalEarned - totalPaid;

    final isActive = employee.status == 'active';

    return Scaffold(
      appBar: AppBar(
        title: Text(employee.name),
        actions: authProv.isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Sửa thông tin',
                  onPressed: () => _openEditDialog(context),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, employee, isActive),
            const SizedBox(height: 20),
            _buildSummaryCard(
              totalJobs,
              totalEarned,
              totalPaid,
              balance,
              currencyFormat,
            ),
            const SizedBox(height: 24),
            _buildHistorySection(empEntries, empPayments, currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Employee emp, bool isActive) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isActive
                  ? Colors.purple.shade50
                  : Colors.grey.shade200,
              foregroundColor: isActive
                  ? Colors.purple.shade800
                  : Colors.grey.shade600,
              child: Text(
                emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        emp.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade50
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Đang làm' : 'Nghỉ việc',
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive
                                ? Colors.green.shade800
                                : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SĐT: ${emp.phone}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Vào làm: ${DateFormat('dd/MM/yyyy').format(emp.joinDate)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (emp.notes != null && emp.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ghi chú: ${emp.notes}',
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    int totalJobs,
    int totalEarned,
    int totalPaid,
    int balance,
    NumberFormat fmt,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                  'Tổng công việc',
                  '$totalJobs',
                  Colors.purple,
                ),
                _buildSummaryStat(
                  'Tổng thu nhập',
                  fmt.format(totalEarned),
                  Colors.blue,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                  'Đã nhận lương',
                  fmt.format(totalPaid),
                  Colors.green,
                ),
                _buildSummaryStat(
                  'Còn lại',
                  fmt.format(balance),
                  balance > 0 ? Colors.orange : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHistorySection(
    List<SalaryEntry> entries,
    List<SalaryPayment> payments,
    NumberFormat fmt,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LỊCH SỬ THAM GIA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const TabBar(
            tabs: [
              Tab(text: 'Công việc'),
              Tab(text: 'Nhận lương'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                entries.isEmpty
                    ? const Center(child: Text('Chưa có lịch sử công việc.'))
                    : ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) {
                          final e = entries[i];
                          return ListTile(
                            title: Text(
                              e.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy').format(e.date),
                            ),
                            trailing: Text(
                              '+${fmt.format(e.amount)}',
                              style: const TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                payments.isEmpty
                    ? const Center(child: Text('Chưa có lịch sử nhận lương.'))
                    : ListView.separated(
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) {
                          final p = payments[i];
                          return ListTile(
                            title: Text(
                              fmt.format(p.amount),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(p.paymentDate),
                                ),
                                if (p.notes != null)
                                  Text(
                                    'Ghi chú: ${p.notes}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => EmployeeEditDialog(employee: employee),
    );
  }
}

class EmployeeEditDialog extends StatefulWidget {
  final Employee employee;
  const EmployeeEditDialog({required this.employee});

  @override
  State<EmployeeEditDialog> createState() => _EmployeeEditDialogState();
}

class _EmployeeEditDialogState extends State<EmployeeEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _phoneController = TextEditingController(text: widget.employee.phone);
    _notesController = TextEditingController(text: widget.employee.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await Provider.of<SalaryProvider>(context, listen: false).updateEmployee(
        widget.employee.id,
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin nhân viên!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sửa thông tin nhân viên'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Họ tên'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Vui lòng nhập SĐT' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
