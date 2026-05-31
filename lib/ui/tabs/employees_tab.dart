import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/salary_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/employee.dart';
import '../employee_detail_screen.dart';

class EmployeesTab extends StatefulWidget {
  const EmployeesTab({super.key});

  @override
  State<EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<EmployeesTab> {
  int _activeFilterIdx = 1; // 0: All, 1: Active, 2: Inactive (Resigned)

  List<Employee> _filterEmployees(List<Employee> allEmployees) {
    if (_activeFilterIdx == 0) return allEmployees;
    if (_activeFilterIdx == 1)
      return allEmployees.where((e) => e.status == 'active').toList();
    return allEmployees.where((e) => e.status == 'inactive').toList();
  }

  void _openAddEmployeeDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddEmployeeDialog());
  }

  void _openEditEmployeeDialog(BuildContext context, Employee emp) {
    showDialog(
      context: context,
      builder: (_) => EmployeeEditDialog(employee: emp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final filtered = _filterEmployees(salaryProv.employees);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSegmentChip('Tất cả', 0),
                _buildSegmentChip('Đang làm việc', 1),
                _buildSegmentChip('Đã nghỉ việc', 2),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có nhân viên nào phù hợp',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final emp = filtered[index];
                      final isActive = emp.status == 'active';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? Colors.purple.shade50
                                : Colors.grey.shade200,
                            foregroundColor: isActive
                                ? Colors.purple.shade800
                                : Colors.grey.shade600,
                            child: Text(
                              emp.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                emp.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(emp.status),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'SĐT: ${emp.phone}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ngày vào làm: ${DateFormat('dd/MM/yyyy').format(emp.joinDate)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              if (emp.notes != null && emp.notes!.isNotEmpty)
                                Text(
                                  'Ghi chú: ${emp.notes}',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade400,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          trailing: authProv.isAdmin
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      tooltip: 'Sửa',
                                      onPressed: () =>
                                          _openEditEmployeeDialog(context, emp),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isActive
                                            ? Icons.toggle_on
                                            : Icons.toggle_off,
                                        color: isActive
                                            ? Colors.purple
                                            : Colors.grey,
                                        size: 28,
                                      ),
                                      onPressed: () =>
                                          _confirmToggleStatus(context, emp),
                                    ),
                                  ],
                                )
                              : null,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: salaryProv,
                                  child: EmployeeDetailScreen(employee: emp),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: authProv.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openAddEmployeeDialog(context),
              label: const Text('Thêm nhân viên'),
              icon: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Widget _buildSegmentChip(String text, int index) {
    final isActive = _activeFilterIdx == index;
    return ChoiceChip(
      label: Text(text),
      selected: isActive,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _activeFilterIdx = index;
          });
        }
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade400,
        ),
      ),
      child: Text(
        isActive ? 'Đang làm' : 'Nghỉ việc',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green.shade800 : Colors.grey.shade800,
        ),
      ),
    );
  }

  void _confirmToggleStatus(BuildContext context, Employee employee) {
    final targetActive = employee.status != 'active';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thay đổi trạng thái'),
        content: Text(
          targetActive
              ? 'Xác nhận chuyển nhân viên "${employee.name}" hoạt động trở lại?'
              : 'Xác nhận đổi trạng thái của nhân viên "${employee.name}" thành: Đã nghỉ việc? (Không xóa dữ liệu lịch sử)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SalaryProvider>(
                context,
                listen: false,
              ).toggleResignation(employee);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã cập nhật trạng thái của ${employee.name}.'),
                ),
              );
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }
}

class AddEmployeeDialog extends StatefulWidget {
  const AddEmployeeDialog();

  @override
  State<AddEmployeeDialog> createState() => AddEmployeeDialogState();
}

class AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final salaryProv = Provider.of<SalaryProvider>(context, listen: false);
      await salaryProv.addEmployee(
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm nhân viên thành công!'),
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
      title: const Text('Thêm Nhân Viên Mới'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Họ và tên',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'VD: Nguyễn Văn A'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Vui lòng nhập họ tên' : null,
            ),
            const SizedBox(height: 12),
            const Text(
              'Số điện thoại',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'VD: 0901234567'),
              validator: (val) => val == null || val.isEmpty
                  ? 'Vui lòng nhập số điện thoại'
                  : null,
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
          style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Thêm'),
        ),
      ],
    );
  }
}
