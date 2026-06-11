import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/salary_provider.dart';
import '../providers/auth_provider.dart';
import '../models/job.dart';
import '../models/product.dart';
import '../models/employee.dart';
import '../utils/number_formatters.dart';

class JobDetailScreen extends StatelessWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final count = job.participants.length;
    final splitAmount = count > 0 ? (job.totalAmount / count).round() : 0;

    final jobEntries = salaryProv.salaryEntries
        .where((se) => se.jobId == job.id)
        .toList();
    final isCancelled = job.status == 'cancelled';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${job.productName} - ${DateFormat('dd/MM/yyyy').format(job.date)}',
        ),
        actions: authProv.isAdmin
            ? [
                if (!isCancelled)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Sửa công việc',
                    onPressed: () => _openEditDialog(context, job),
                  ),
                if (!isCancelled)
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Hủy công việc',
                    onPressed: () => _confirmCancel(context, job),
                  ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCancelled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    const Text(
                      'Công việc đã bị hủy',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            if (isCancelled) const SizedBox(height: 16),
            _buildInfoCard(job, currencyFormat),
            const SizedBox(height: 16),
            _buildParticipantsCard(
              job,
              salaryProv.employees,
              jobEntries,
              currencyFormat,
              splitAmount,
            ),
            if (job.updatedBy != null) ...[
              const SizedBox(height: 16),
              _buildEditHistoryCard(job),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Job job, NumberFormat fmt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'THÔNG TIN CÔNG VIỆC',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(job.date),
                    style: TextStyle(
                      color: Colors.purple.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Sản phẩm', job.productName),
            _buildInfoRow('Số lượng', '${job.quantity}'),
            _buildInfoRow('Đơn giá', fmt.format(job.unitPrice)),
            _buildInfoRow(
              'Tổng tiền',
              fmt.format(job.totalAmount),
              valueColor: const Color(0xFF6200EE),
            ),
            _buildInfoRow('Người tham gia', '${job.participants.length} người'),
            const Divider(height: 16),
            _buildInfoRow('Người tạo', job.createdBy),
            _buildInfoRow(
              'Ngày tạo',
              DateFormat('dd/MM/yyyy HH:mm').format(job.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard(
    Job job,
    List<Employee> employees,
    List list,
    NumberFormat fmt,
    int splitAmount,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NGƯỜI THAM GIA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Chia đều: ${fmt.format(splitAmount)}/người',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(height: 20),
            ...job.participants.map((pId) {
              final emp = employees.firstWhere(
                (e) => e.id == pId,
                orElse: () => Employee(
                  id: '',
                  name: 'Không xác định',
                  phone: '',
                  joinDate: DateTime.now(),
                  status: '',
                ),
              );
              final matches = list.where((se) => se.employeeId == pId).toList();
              final amount = matches.isNotEmpty
                  ? matches.first.amount
                  : splitAmount;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade100,
                      child: Text(
                        emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        emp.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      fmt.format(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEditHistoryCard(Job job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LỊCH SỬ CHỈNH SỬA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Divider(height: 16),
            Row(
              children: [
                Icon(Icons.edit_note, color: Colors.orange.shade400, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sửa bởi: ${job.updatedBy}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(job.updatedAt!)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditDialog(BuildContext context, Job job) {
    showDialog(
      context: context,
      builder: (_) => JobEditDialog(job: job),
    );
  }

  void _confirmCancel(BuildContext context, Job job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy công việc'),
        content: Text(
          'Hủy công việc "${job.productName}" ngày ${DateFormat('dd/MM/yyyy').format(job.date)}? (Sẽ xóa bản ghi chia lương tương ứng)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              final authProv = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              Provider.of<SalaryProvider>(
                context,
                listen: false,
              ).cancelJob(job.id, authProv.currentUser?.email ?? 'Unknown');
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã hủy công việc.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy công việc'),
          ),
        ],
      ),
    );
  }
}

class JobEditDialog extends StatefulWidget {
  final Job job;
  const JobEditDialog({super.key, required this.job});

  @override
  State<JobEditDialog> createState() => _JobEditDialogState();
}

class _JobEditDialogState extends State<JobEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  Product? _selectedProduct;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late List<String> _selectedParticipants;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.job.date;
    _quantityController = TextEditingController(
      text: widget.job.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: formatCurrency(widget.job.unitPrice),
    );
    _selectedParticipants = List.from(widget.job.participants);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  int get _calculatedTotal {
    final qty = double.tryParse(_quantityController.text) ?? 0.0;
    final price = parseCurrencyInt(_priceController.text);
    return (qty * price).round();
  }

  int get _calculatedSplit {
    final count = _selectedParticipants.length;
    return count > 0 ? (_calculatedTotal / count).round() : 0;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn sản phẩm'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 người tham gia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      final salaryProv = Provider.of<SalaryProvider>(context, listen: false);
      await salaryProv.updateJob(
        jobId: widget.job.id,
        date: _selectedDate,
        product: _selectedProduct!,
        quantity: double.parse(_quantityController.text),
        unitPrice: parseCurrencyInt(_priceController.text),
        participantIds: _selectedParticipants,
        updatedBy: authProv.currentUser?.email ?? 'Unknown',
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật công việc!'),
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
    final salaryProv = Provider.of<SalaryProvider>(context);
    final activeProducts = salaryProv.products.where((p) => p.active).toList();
    final activeEmployees = salaryProv.employees
        .where((e) => e.status == 'active')
        .toList();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Pre-select current product
    _selectedProduct ??= activeProducts.cast<Product?>().firstWhere(
        (p) => p?.id == widget.job.productId,
        orElse: () => null,
      );

    return AlertDialog(
      title: const Text('Sửa công việc'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width > 600 ? 500 : double.infinity,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text(
                        'Đổi ngày',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Product>(
                  initialValue: _selectedProduct,
                  decoration: const InputDecoration(labelText: 'Sản phẩm'),
                  items: activeProducts
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProduct = val;
                      if (val != null) {
                        _priceController.text = val.defaultPrice.toString();
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Số lượng',
                    suffixText: _selectedProduct?.unit ?? '',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Nhập số lượng';
                    if (double.tryParse(v) == null) return 'Số không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  decoration: const InputDecoration(labelText: 'Đơn giá (đ)'),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Nhập đơn giá';
                    if (v.replaceAll(RegExp(r'[^0-9]'), '').isEmpty) return 'Đơn giá phải là số';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng: ${currencyFormat.format(_calculatedTotal)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        'Chia: ${currencyFormat.format(_calculatedSplit)}/ng',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chọn người tham gia:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: activeEmployees.map((emp) {
                      final checked = _selectedParticipants.contains(emp.id);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(
                          emp.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                        value: checked,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedParticipants.add(emp.id);
                            } else {
                              _selectedParticipants.remove(emp.id);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
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
              : const Text('Lưu thay đổi'),
        ),
      ],
    );
  }
}
