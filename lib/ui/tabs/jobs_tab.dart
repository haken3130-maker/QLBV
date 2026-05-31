import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/salary_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/job.dart';
import '../../models/product.dart';
import '../../models/employee.dart';
import '../job_detail_screen.dart';

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> with TickerProviderStateMixin {
  DateFilter _activeFilter = DateFilter.today;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  List<Job> _filterJobs(List<Job> allJobs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    
    return allJobs.where((job) {
      final jobDate = DateTime(job.date.year, job.date.month, job.date.day);
      switch (_activeFilter) {
        case DateFilter.today:
          return jobDate.isAtSameMomentAs(today);
        case DateFilter.yesterday:
          return jobDate.isAtSameMomentAs(yesterday);
        case DateFilter.last7Days:
          return jobDate.isAfter(sevenDaysAgo.subtract(const Duration(milliseconds: 1)));
        case DateFilter.currentMonth:
          return job.date.year == now.year && job.date.month == now.month;
        case DateFilter.all:
          return true;
      }
    }).toList();
  }

  void _openCreateJobDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateJobDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final filteredJobs = _filterJobs(salaryProv.jobs);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Calculations for the filtered stats summary
    final statsJobCount = filteredJobs.length;
    final statsTotalVolume = filteredJobs.fold<double>(0.0, (s, j) => s + j.quantity);
    final statsTotalRevenue = filteredJobs.fold<int>(0, (s, j) => s + j.totalAmount);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: Column(
        children: [
          // ─── Filter Section with Stats Summary ───
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterButton('Hôm nay', DateFilter.today),
                      const SizedBox(width: 8),
                      _buildFilterButton('Hôm qua', DateFilter.yesterday),
                      const SizedBox(width: 8),
                      _buildFilterButton('7 ngày qua', DateFilter.last7Days),
                      const SizedBox(width: 8),
                      _buildFilterButton('Tháng này', DateFilter.currentMonth),
                      const SizedBox(width: 8),
                      _buildFilterButton('Tất cả', DateFilter.all),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Stats summary panel
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMiniTile(
                        icon: Icons.assignment_outlined,
                        color: const Color(0xFF6200EE),
                        label: 'Số việc',
                        value: '$statsJobCount',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryMiniTile(
                        icon: Icons.scale_outlined,
                        color: const Color(0xFF1565C0),
                        label: 'Sản lượng',
                        value: '${statsTotalVolume.toStringAsFixed(1)}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryMiniTile(
                        icon: Icons.payments_outlined,
                        color: const Color(0xFF2E7D32),
                        label: 'Tổng tiền',
                        value: _formatShortCurrency(statsTotalRevenue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // ─── Jobs List ───
          Expanded(
            child: filteredJobs.isEmpty
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
                          child: Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy công việc nào',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chọn bộ lọc khác hoặc nhấn "Thêm việc" bên dưới.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = filteredJobs[index];
                      final count = job.participants.length;
                      final splitAmount = count > 0 ? (job.totalAmount / count).round() : 0;
                      
                      // Animated entry index
                      final animationDelay = (index * 50).clamp(0, 300);
                      
                      return AnimatedBuilder(
                        animation: _listController,
                        builder: (context, child) {
                          final double slideProgress = Curves.easeOutCubic.transform(
                            (_listController.value - (animationDelay / 600)).clamp(0.0, 1.0),
                          );
                          return Opacity(
                            opacity: slideProgress,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1.0 - slideProgress)),
                              child: child,
                            ),
                          );
                        },
                        child: _buildJobCard(context, job, count, splitAmount, authProv, salaryProv, currencyFormat),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateJobDialog(context),
        backgroundColor: const Color(0xFF6200EE),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Thêm việc',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.2),
        ),
      ),
    );
  }

  Widget _buildSummaryMiniTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, DateFilter filter) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filter;
          _listController.reset();
          _listController.forward();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6200EE) : const Color(0xFFF0F1F5),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF6200EE).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF5A5A5A),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    Job job,
    int count,
    int splitAmount,
    AuthProvider authProv,
    SalaryProvider salaryProv,
    NumberFormat currencyFormat,
  ) {
    final productUnit = salaryProv.products.firstWhere(
      (p) => p.id == job.productId,
      orElse: () => Product(id: '', name: '', unit: 'Tấn', defaultPrice: 0, active: true),
    ).unit;

    final isCancelled = job.status == 'cancelled';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: salaryProv,
              child: JobDetailScreen(job: job),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isCancelled ? Colors.red.shade100 : Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: isCancelled ? Colors.red : const Color(0xFF6200EE), width: 4),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Date & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCancelled ? Colors.grey.shade100 : const Color(0xFF6200EE).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month, size: 12, color: isCancelled ? Colors.grey : const Color(0xFF6200EE)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(job.date),
                            style: TextStyle(
                              color: isCancelled ? Colors.grey : const Color(0xFF6200EE),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (authProv.isAdmin)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                        onSelected: (val) {
                          if (val == 'edit' && !isCancelled) {
                            showDialog(
                              context: context,
                              builder: (_) => JobEditDialog(job: job),
                            );
                          } else if (val == 'cancel' && !isCancelled) {
                            _confirmCancelJob(context, job);
                          } else if (val == 'delete') {
                            _confirmDeleteJob(context, job);
                          }
                        },
                        itemBuilder: (_) => [
                          if (!isCancelled)
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Sửa')])),
                          if (!isCancelled)
                            const PopupMenuItem(value: 'cancel', child: Row(children: [Icon(Icons.cancel, size: 18, color: Colors.orange), SizedBox(width: 8), Text('Hủy việc')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Xóa')])),
                        ],
                      ),
                  ],
                ),
                if (isCancelled) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('ĐÃ HỦY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                ],
                const SizedBox(height: 12),
                
                // Product Name
                Text(
                  job.productName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isCancelled ? Colors.grey : const Color(0xFF2C3E50),
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
              
              // Metrics (Quantity / Unit Price)
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Sản lượng: ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${job.quantity} $productUnit',
                    style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.sell_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Đơn giá: ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    currencyFormat.format(job.unitPrice),
                    style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Split Section (Highlighted Card)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E9F3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng doanh thu',
                            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(job.totalAmount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.green, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Mỗi người ($count người)',
                            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(splitAmount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 14),
              // Participants list title
              Row(
                children: [
                  Icon(Icons.groups_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  const Text(
                    'Thành viên bốc xếp:',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              // Custom chips list for employees
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: job.participants.map((pId) {
                  final emp = salaryProv.employees.firstWhere(
                    (e) => e.id == pId,
                    orElse: () => Employee(id: '', name: 'K.Danh', phone: '', joinDate: DateTime.now(), status: ''),
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 7,
                          backgroundColor: const Color(0xFF6200EE).withOpacity(0.12),
                          child: Text(
                            emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Color(0xFF6200EE)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          emp.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              
              // Creator label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${job.id}',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Người tạo: ${job.createdBy}',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
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

  void _confirmDeleteJob(BuildContext context, Job job) {
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
        content: Text('Bạn có chắc chắn muốn xóa công việc "${job.productName}" và tất cả bản ghi chia lương tương ứng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<SalaryProvider>(context, listen: false).deleteJob(job.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa công việc.'),
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
  }

  void _confirmCancelJob(BuildContext context, Job job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xác nhận hủy'),
          ],
        ),
        content: Text('Hủy công việc "${job.productName}" ngày ${DateFormat('dd/MM/yyyy').format(job.date)}? Các bản ghi chia lương sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () {
              final authProv = Provider.of<AuthProvider>(context, listen: false);
              Provider.of<SalaryProvider>(context, listen: false).cancelJob(
                job.id,
                authProv.currentUser?.email ?? 'Unknown',
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã hủy công việc.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 40),
              elevation: 0,
            ),
            child: const Text('Hủy việc'),
          ),
        ],
      ),
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

class CreateJobDialog extends StatefulWidget {
  const CreateJobDialog();

  @override
  State<CreateJobDialog> createState() => CreateJobDialogState();
}

class CreateJobDialogState extends State<CreateJobDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  Product? _selectedProduct;
  
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final List<String> _selectedParticipants = [];

  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onProductChanged(Product? prod) {
    setState(() {
      _selectedProduct = prod;
      if (prod != null) {
        _priceController.text = prod.defaultPrice.toString();
      }
    });
  }

  int get _calculatedTotal {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final price = int.tryParse(_priceController.text) ?? 0;
    return (quantity * price).round();
  }

  int get _calculatedSplit {
    final total = _calculatedTotal;
    final count = _selectedParticipants.length;
    return count > 0 ? (total / count).round() : 0;
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sản phẩm'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 người tham gia'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      final salaryProv = Provider.of<SalaryProvider>(context, listen: false);

      await salaryProv.createJob(
        date: _selectedDate,
        product: _selectedProduct!,
        quantity: double.parse(_quantityController.text),
        unitPrice: int.parse(_priceController.text),
        participantIds: _selectedParticipants,
        createdBy: authProv.currentUser?.email ?? 'Unknown',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu công việc và chia lương thành công!'),
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
    final activeProducts = salaryProv.products.where((p) => p.active).toList();
    final activeEmployees = salaryProv.employees.where((e) => e.status == 'active').toList();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  const Icon(Icons.add_task_rounded, color: Color(0xFF6200EE)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tạo Công Việc Mới',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date selector container
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
                                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6200EE)),
                                const SizedBox(width: 8),
                                Text(
                                  'Ngày làm: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50)),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => _selectDate(context),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF6200EE),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Thay đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Product Selector
                      const Text(
                        'Loại sản phẩm bốc xếp',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<Product>(
                        value: _selectedProduct,
                        decoration: InputDecoration(
                          hintText: 'Chọn sản phẩm',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: activeProducts.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text('${p.name} (${p.unit})'),
                          );
                        }).toList(),
                        onChanged: _onProductChanged,
                        validator: (val) => val == null ? 'Vui lòng chọn sản phẩm' : null,
                      ),
                      const SizedBox(height: 16),

                      // Quantity
                      const Text(
                        'Sản lượng bốc xếp',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'VD: 10.5',
                          prefixIcon: const Icon(Icons.scale_outlined),
                          suffixText: _selectedProduct?.unit ?? '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Vui lòng nhập số lượng';
                          if (double.tryParse(val) == null) return 'Số lượng phải là số hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Unit Price
                      const Text(
                        'Đơn giá bốc xếp (VNĐ)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'VD: 900000',
                          prefixIcon: const Icon(Icons.sell_outlined),
                          suffixText: 'đ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Vui lòng nhập đơn giá';
                          if (int.tryParse(val) == null) return 'Đơn giá phải là số nguyên';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Dynamic calculations layout
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TỔNG TIỀN BỐC XẾP', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(_calculatedTotal),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 35, color: Colors.green.shade200),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('CHIA MỖI NGƯỜI', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(_calculatedSplit),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Participants Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chọn nhân viên tham gia',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50)),
                          ),
                          Text(
                            'Đã chọn: ${_selectedParticipants.length}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6200EE)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Active employees checklist
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: activeEmployees.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: Text('Không có nhân viên hoạt động')),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: activeEmployees.length,
                                itemBuilder: (context, idx) {
                                  final emp = activeEmployees[idx];
                                  final isChecked = _selectedParticipants.contains(emp.id);
                                  
                                  return CheckboxListTile(
                                    title: Text(
                                      emp.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    subtitle: Text(emp.phone, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    value: isChecked,
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedParticipants.add(emp.id);
                                        } else {
                                          _selectedParticipants.remove(emp.id);
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xFF6200EE),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action buttons
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6200EE),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 44),
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
                        : const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum DateFilter { today, yesterday, last7Days, currentMonth, all }
