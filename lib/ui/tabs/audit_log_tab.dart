import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/salary_provider.dart';
import '../../models/audit_log.dart';

class AuditLogTab extends StatefulWidget {
  const AuditLogTab({super.key});

  @override
  State<AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<AuditLogTab>
    with TickerProviderStateMixin {
  String _activeFilter = 'ALL';
  late AnimationController _listController;

  final Map<String, String> _filterLabels = {
    'ALL': 'Tất cả',
    'JOB': 'Công việc',
    'SALARY_PAYMENT': 'Phát lương',
    'EMPLOYEE': 'Nhân viên',
    'PRODUCT': 'Sản phẩm',
  };

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

  List<AuditLog> _filterLogs(List<AuditLog> allLogs) {
    if (_activeFilter == 'ALL') return allLogs;
    return allLogs.where((log) => log.targetType == _activeFilter).toList();
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'CREATE_JOB':
        return Icons.add_task_rounded;
      case 'UPDATE_JOB':
        return Icons.edit_note_rounded;
      case 'DELETE_JOB':
        return Icons.delete_sweep_rounded;
      case 'CREATE_PAYMENT':
        return Icons.payments_rounded;
      case 'DELETE_PAYMENT':
        return Icons.money_off_rounded;
      case 'UPDATE_EMPLOYEE':
        return Icons.person_outline_rounded;
      case 'UPDATE_PRODUCT':
        return Icons.inventory_2_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getActionColor(String action) {
    if (action.startsWith('CREATE')) return Colors.green;
    if (action.startsWith('DELETE')) return Colors.red;
    if (action.startsWith('UPDATE')) return Colors.orange;
    return Colors.blue;
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'CREATE_JOB':
        return 'TẠO VIỆC';
      case 'UPDATE_JOB':
        return 'SỬA VIỆC';
      case 'DELETE_JOB':
        return 'XÓA VIỆC';
      case 'CREATE_PAYMENT':
        return 'PHÁT LƯƠNG';
      case 'DELETE_PAYMENT':
        return 'XÓA LƯƠNG';
      case 'UPDATE_EMPLOYEE':
        return 'CẬP NHẬT NV';
      case 'UPDATE_PRODUCT':
        return 'CẬP NHẬT SP';
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final filteredLogs = _filterLogs(salaryProv.auditLogs);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Aggregate statistics
    final totalCount = filteredLogs.length;
    final createCount = filteredLogs
        .where((l) => l.action.startsWith('CREATE'))
        .length;
    final deleteCount = filteredLogs
        .where((l) => l.action.startsWith('DELETE'))
        .length;

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
                    children: _filterLabels.entries.map((entry) {
                      final isActive = _activeFilter == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeFilter = entry.key;
                              _listController.reset();
                              _listController.forward();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF6200EE)
                                  : const Color(0xFFF0F1F5),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF6200EE,
                                        ).withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF5A5A5A),
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats summary bar
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMiniTile(
                        icon: Icons.history_rounded,
                        color: const Color(0xFF6200EE),
                        label: 'Bản ghi',
                        value: '$totalCount',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryMiniTile(
                        icon: Icons.add_circle_outline_rounded,
                        color: Colors.green,
                        label: 'Tạo mới',
                        value: '$createCount',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryMiniTile(
                        icon: Icons.remove_circle_outline_rounded,
                        color: Colors.red,
                        label: 'Xóa',
                        value: '$deleteCount',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ─── Audit Log List ───
          Expanded(
            child: filteredLogs.isEmpty
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
                          child: Icon(
                            Icons.history_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có nhật ký hoạt động',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mọi hoạt động sửa/xóa sẽ được lưu tại đây.',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final actionColor = _getActionColor(log.action);
                      final actionIcon = _getActionIcon(log.action);
                      final actionLabel = _getActionLabel(log.action);

                      // Staggered list animations
                      final animationDelay = (index * 40).clamp(0, 300);

                      return AnimatedBuilder(
                        animation: _listController,
                        builder: (context, child) {
                          final double slideProgress = Curves.easeOutCubic
                              .transform(
                                (_listController.value - (animationDelay / 600))
                                    .clamp(0.0, 1.0),
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
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Action icon column
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: actionColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    actionIcon,
                                    color: actionColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Description & metadata column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: actionColor.withOpacity(
                                                0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              actionLabel,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: actionColor,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              log.performedBy,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        log.description,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 12,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            dateFormat.format(log.performedAt),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade400,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
            child: Icon(icon, color: color, size: 15),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
