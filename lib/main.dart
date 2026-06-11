import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/salary_provider.dart';
import 'providers/tab_notifier.dart';
import 'services/springboot_database_service.dart';
import 'models/app_user.dart';
import 'ui/theme.dart';
import 'ui/auth/login_screen.dart';
import 'ui/main_navigation_screen.dart';

Future<void> _initializeAuth() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final refreshToken = prefs.getString('auth_refresh_token');
  final uid = prefs.getString('auth_user_uid');
  final email = prefs.getString('auth_user_email');
  final name = prefs.getString('auth_user_name');
  final role = prefs.getString('auth_user_role');

  print('[_initializeAuth] token: ${token != null ? token.substring(0, 20) + '...' : 'NULL'}');
  print('[_initializeAuth] refreshToken: ${refreshToken != null ? refreshToken.substring(0, 20) + '...' : 'NULL'}');
  print('[_initializeAuth] uid: $uid, email: $email');

  if (token != null && 
      token.isNotEmpty && 
      refreshToken != null && 
      refreshToken.isNotEmpty && 
      uid != null && 
      uid.isNotEmpty && 
      email != null && 
      name != null && 
      role != null) {
    // Restore session BEFORE any repositories are created
    final user = AppUser(uid: uid, email: email, name: name, role: role);
    print('[_initializeAuth] Restoring session for user: $email');
    SpringBootDatabaseService.restoreSession(token, refreshToken, user);
  } else {
    print('[_initializeAuth] No saved session found or incomplete data');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null);
  await _initializeAuth(); // Restore session before creating app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..loadSavedSession(),
        ),
        ChangeNotifierProvider(create: (_) => SalaryProvider()),
        ChangeNotifierProvider(create: (_) => TabNotifier()),
      ],
      child: MaterialApp(
        title: 'Quản Lý Lương',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate>
    with SingleTickerProviderStateMixin {
  bool _streamsStarted = false;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final salaryProv = Provider.of<SalaryProvider>(context);

    if (authProv.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProv.currentUser != null) {
      if (!_streamsStarted) {
        _streamsStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          salaryProv.syncData();
        });
      }

      if (salaryProv.isSyncing || !salaryProv.isSynced) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: salaryProv.isSyncing
                              ? salaryProv.syncStep / salaryProv.syncTotal
                              : null,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF4F46E5),
                          ),
                        ),
                        RotationTransition(
                          turns: Tween<double>(
                            begin: 0,
                            end: 1,
                          ).animate(_rotationController),
                          child: const Icon(
                            Icons.sync_rounded,
                            size: 46,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    salaryProv.syncMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: salaryProv.isSyncing
                        ? salaryProv.syncStep / salaryProv.syncTotal
                        : null,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4F46E5)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${salaryProv.syncStep}/${salaryProv.syncTotal}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  if (!salaryProv.isSyncing && !salaryProv.isSynced) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        salaryProv.syncData();
                      },
                      child: const Text('Thử lại đồng bộ'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }

      return const MainNavigationScreen();
    }

    return const LoginScreen();
  }
}
