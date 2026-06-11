import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../providers/salary_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tab_notifier.dart';
import 'jobs_tab.dart';
import 'employees_tab.dart';
import 'salary_tab.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final now = DateTime.now();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final user = authProv.currentUser;

    // Data calculations
    final activeWorkers = salaryProv.employees.where((e) => e.status == 'active').toList();
    final jobsToday = salaryProv.jobs.where((j) =>
        j.date.year == now.year && j.date.month == now.month && j.date.day == now.day).toList();
    final jobsThisMonth = salaryProv.jobs.where((j) =>
        j.date.year == now.year && j.date.month == now.month).toList();

    final totalVolumeToday = jobsToday.fold<double>(0.0, (s, j) => s + j.quantity);
    final totalRevenueToday = jobsToday.fold<int>(0, (s, j) => s + j.totalAmount);
    final totalParticipantsToday = jobsToday.fold<int>(0, (s, j) => s + j.participants.length);

    final totalRevenueMonth = jobsThisMonth.fold<int>(0, (s, j) => s + j.totalAmount);

    final monthlyEntries = salaryProv.salaryEntries.where((se) =>
        se.date.year == now.year && se.date.month == now.month).toList();
    final totalMonthlySalary = monthlyEntries.fold<int>(0, (s, e) => s + e.amount);

    final monthlyPayments = salaryProv.salaryPayments.where((sp) =>
        sp.paymentDate.year == now.year && sp.paymentDate.month == now.month).toList();
    final totalMonthlyPaid = monthlyPayments.fold<int>(0, (s, p) => s + p.amount);

    final totalOwed = totalMonthlySalary - totalMonthlyPaid;
    final paidPercentage = totalMonthlySalary > 0 ? (totalMonthlyPaid / totalMonthlySalary) : 0.0;

    // Top employees by earnings this month
    final Map<String, int> empEarnings = {};
    final Map<String, String> empNames = {};
    for (final entry in monthlyEntries) {
      empEarnings[entry.employeeId] = (empEarnings[entry.employeeId] ?? 0) + entry.amount;
      empNames[entry.employeeId] = entry.employeeName;
    }
    final topEmployees = empEarnings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final greeting = _getGreeting(now);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () async {
          salaryProv.initStreams();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Hero greeting header ───
              _buildHeroHeader(greeting, user?.name ?? 'Điều Hành Viên', now),
              const SizedBox(height: 20),

              // ─── Today's KPI stats ───
              _buildSectionTitle('📊  HOẠT ĐỘNG HÔM NAY'),
              const SizedBox(height: 12),
              _buildTodayKpiRow(
                context,
                jobsCount: jobsToday.length,
                volume: totalVolumeToday,
                revenue: totalRevenueToday,
                participants: totalParticipantsToday,
                currencyFormat: currencyFormat,
              ),
              const SizedBox(height: 24),

              // ─── Monthly salary fund ───
              _buildSectionTitle('💰  QUỸ LƯƠNG THÁNG ${now.month}/${now.year}'),
              const SizedBox(height: 12),
              _buildSalaryFundCard(
                context,
                totalSalary: totalMonthlySalary,
                totalPaid: totalMonthlyPaid,
                totalOwed: totalOwed,
                paidPercentage: paidPercentage,
                currencyFormat: currencyFormat,
              ),
              const SizedBox(height: 24),

              // ─── Monthly summary cards ───
              _buildSectionTitle('📈  TỔNG QUAN THÁNG'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildGradientStatCard(
                      icon: Icons.work_history,
                      label: 'Tổng công việc',
                      value: '${jobsThisMonth.length}',
                      gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGradientStatCard(
                      icon: Icons.trending_up,
                      label: 'Doanh thu tháng',
                      value: currencyFormat.format(totalRevenueMonth),
                      gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildGradientStatCard(
                      icon: Icons.groups,
                      label: 'Nhân viên hoạt động',
                      value: '${activeWorkers.length}',
                      gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGradientStatCard(
                      icon: Icons.inventory_2,
                      label: 'Tổng sản phẩm',
                      value: '${salaryProv.products.where((p) => p.active).length}',
                      gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Top employees ───
              if (topEmployees.isNotEmpty) ...[
                _buildSectionTitle('🏆  TOP NHÂN VIÊN THÁNG NÀY'),
                const SizedBox(height: 12),
                _buildTopEmployeesCard(context, topEmployees, empNames, currencyFormat),
                const SizedBox(height: 24),
              ],

              // ─── Quick Actions ───
              _buildSectionTitle('⚡  THAO TÁC NHANH'),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting(DateTime now) {
    if (now.hour < 12) return 'Chào buổi sáng';
    if (now.hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  // ─── Hero Header ───
  Widget _buildHeroHeader(String greeting, String userName, DateTime now) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6200EE), Color(0xFF9C27B0), Color(0xFFE040FB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6200EE).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting! 👋',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, dd/MM/yyyy', 'vi').format(now),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Title ───
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF3D3D3D),
        letterSpacing: 0.3,
      ),
    );
  }

  // ─── Today KPI Row ───
  Widget _buildTodayKpiRow(
    BuildContext context, {
    required int jobsCount,
    required double volume,
    required int revenue,
    required int participants,
    required NumberFormat currencyFormat,
  }) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildKpiChip(
            icon: Icons.assignment_turned_in,
            label: 'Công việc',
            value: '$jobsCount',
            bgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 10),
          _buildKpiChip(
            icon: Icons.scale,
            label: 'Sản lượng',
            value: volume.toStringAsFixed(1),
            bgColor: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1565C0),
          ),
          const SizedBox(width: 10),
          _buildKpiChip(
            icon: Icons.attach_money,
            label: 'Doanh thu',
            value: _formatShortCurrency(revenue),
            bgColor: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFF57F17),
          ),
          const SizedBox(width: 10),
          _buildKpiChip(
            icon: Icons.people,
            label: 'Người tham gia',
            value: '$participants',
            bgColor: const Color(0xFFFCE4EC),
            iconColor: const Color(0xFFC62828),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiChip({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: iconColor.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Salary Fund Card ───
  Widget _buildSalaryFundCard(
    BuildContext context, {
    required int totalSalary,
    required int totalPaid,
    required int totalOwed,
    required double paidPercentage,
    required NumberFormat currencyFormat,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Animated circular progress
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return SizedBox(
                    width: 80,
                    height: 80,
                    child: CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: paidPercentage * _progressController.value,
                        progressColor: const Color(0xFF4CAF50),
                        bgColor: Colors.grey.shade200,
                        strokeWidth: 8,
                      ),
                      child: Center(
                        child: Text(
                          '${(paidPercentage * 100 * _progressController.value).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng quỹ lương',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(totalSalary),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6200EE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: paidPercentage * _progressController.value,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(
                    paidPercentage >= 0.8
                        ? const Color(0xFF4CAF50)
                        : paidPercentage >= 0.5
                            ? const Color(0xFFFFC107)
                            : const Color(0xFFFF5722),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Paid / Owed
          Row(
            children: [
              Expanded(
                child: _buildSalaryInfoTile(
                  icon: Icons.check_circle,
                  iconColor: const Color(0xFF4CAF50),
                  label: 'Đã phát/ứng',
                  value: currencyFormat.format(totalPaid),
                  valueColor: const Color(0xFF4CAF50),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: _buildSalaryInfoTile(
                  icon: Icons.pending,
                  iconColor: const Color(0xFFFF5722),
                  label: 'Còn phải trả',
                  value: currencyFormat.format(totalOwed),
                  valueColor: const Color(0xFFFF5722),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Gradient Stat Card ───
  Widget _buildGradientStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Icon(Icons.arrow_upward, color: Colors.white.withOpacity(0.6), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top Employees ───
  Widget _buildTopEmployeesCard(
    BuildContext context,
    List<MapEntry<String, int>> topEmployees,
    Map<String, String> empNames,
    NumberFormat currencyFormat,
  ) {
    final topItems = topEmployees.take(5).toList();
    final medals = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'];
    final avatarColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
      const Color(0xFF667eea),
      const Color(0xFF764ba2),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: topItems.asMap().entries.map((mapEntry) {
          final idx = mapEntry.key;
          final entry = mapEntry.value;
          final name = empNames[entry.key] ?? 'Nhân viên';
          final isFirst = idx == 0;

          return Padding(
            padding: EdgeInsets.only(bottom: idx < topItems.length - 1 ? 12 : 0),
            child: Row(
              children: [
                Text(medals[idx], style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: isFirst ? 22 : 18,
                  backgroundColor: avatarColors[idx].withOpacity(0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: isFirst ? 18 : 14,
                      fontWeight: FontWeight.w800,
                      color: avatarColors[idx],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600,
                          fontSize: isFirst ? 15 : 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // mini progress bar relative to the max
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxVal = topEmployees.first.value;
                          final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 4,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation(avatarColors[idx]),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatShortCurrency(entry.value),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isFirst ? 15 : 13,
                    color: const Color(0xFF6200EE),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Quick Actions ───
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'Tạo việc',
            color: const Color(0xFF4CAF50),
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const CreateJobDialog(),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            icon: Icons.person_add_alt_1,
            label: 'Thêm NV',
            color: const Color(0xFF2196F3),
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const AddEmployeeDialog(),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            icon: Icons.payments,
            label: 'Phát lương',
            color: const Color(0xFFFF9800),
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const RecordPaymentDialog(),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            icon: Icons.assessment,
            label: 'Báo cáo',
            color: const Color(0xFF9C27B0),
            onTap: () {
              Provider.of<TabNotifier>(context, listen: false).navigateTo(5);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
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

// ─── Custom Circular Progress Painter ───
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color bgColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [progressColor.withOpacity(0.6), progressColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
