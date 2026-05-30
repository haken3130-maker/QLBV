import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 700;
    final authProv = Provider.of<AuthProvider>(context);
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

    // Ensure _selectedIndex doesn't exceed valid tab range
    if (_selectedIndex >= tabs.length) {
      _selectedIndex = 0;
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.shade100),
            ),
            child: Text(
              user.role == 'admin' ? 'QTV' : 'Tổ trưởng',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: () {
              authProv.logout();
            },
          ),
        ],
      ),
      body: isTablet
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
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
                Expanded(
                  child: tabs[_selectedIndex],
                ),
              ],
            )
          : tabs[_selectedIndex],
      bottomNavigationBar: isTablet
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
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
