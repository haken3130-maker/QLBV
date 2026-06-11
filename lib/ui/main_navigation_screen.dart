import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tab_notifier.dart';
import 'auth/login_screen.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/jobs_tab.dart';
import 'tabs/employees_tab.dart';
import 'tabs/salary_tab.dart';
import 'tabs/products_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/audit_log_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  void initState() {
    super.initState();
    final tabProv = context.read<TabNotifier>();
    tabProv.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    context.read<TabNotifier>().removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 700;
    final authProv = Provider.of<AuthProvider>(context);
    final tabProv = Provider.of<TabNotifier>(context);
    final user = authProv.currentUser;

    if (user == null) {
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> tabs = [
      const DashboardTab(),
      const JobsTab(),
      const EmployeesTab(),
      const ProductsTab(),
      const SalaryTab(),
      const ReportsTab(),
      if (user.role == 'admin') const AuditLogTab(),
    ];

    int selectedIndex = tabProv.index;
    if (selectedIndex >= tabs.length) {
      selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.local_shipping, size: 24),
            const SizedBox(width: 8),
            Text(isTablet ? 'HỆ THỐNG QUẢN LÝ LƯƠNG ĐỘI BỐC VÁC' : 'QL Bốc Vác'),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)),
            ),
            child: Text(
              user.role == 'admin' ? 'QTV' : 'Tổ trưởng',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            tooltip: 'Đăng xuất',
            onPressed: () => authProv.logout(),
          ),
        ],
      ),
      body: isTablet
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => tabProv.navigateTo(index),
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Trang chủ'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(Icons.assignment),
                      label: Text('Công việc'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Nhân viên'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Sản phẩm'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.monetization_on_outlined),
                      selectedIcon: Icon(Icons.monetization_on),
                      label: Text('Lương'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text('Báo cáo'),
                    ),
                    if (user.role == 'admin')
                      const NavigationRailDestination(
                        icon: Icon(Icons.history_outlined),
                        selectedIcon: Icon(Icons.history),
                        label: Text('Nhật ký'),
                      ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: tabs[selectedIndex]),
              ],
            )
          : tabs[selectedIndex],
      bottomNavigationBar: isTablet
          ? null
          : BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => tabProv.navigateTo(index),
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 10,
              unselectedFontSize: 9,
              iconSize: 22,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Trang chủ',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  activeIcon: Icon(Icons.assignment),
                  label: 'Công việc',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Nhân viên',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'Sản phẩm',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.monetization_on_outlined),
                  activeIcon: Icon(Icons.monetization_on),
                  label: 'Lương',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart),
                  label: 'Báo cáo',
                ),
                if (user.role == 'admin')
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.history_outlined),
                    activeIcon: Icon(Icons.history),
                    label: 'Nhật ký',
                  ),
              ],
            ),
    );
  }
}
