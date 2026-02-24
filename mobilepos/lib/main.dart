import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/hive_service.dart';
import 'ui/auth/login_screen.dart';
import 'ui/pos_screen.dart';
import 'ui/checkout/checkout_screen.dart';
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/history/history_screen.dart';
import 'ui/members/members_screen.dart';
import 'ui/shifts/shift_history_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/menu/menu_screen.dart';
import 'ui/inventory/inventory_screen.dart';
import 'core/services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await HiveService.init();
  await NotificationService.init();
  runApp(const ProviderScope(child: PosApp()));
}

// Auth status notifier for router refresh
class AuthNotifierForRouter extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  void update(bool value) {
    if (_isAuthenticated != value) {
      _isAuthenticated = value;
      notifyListeners();
    }
  }
}

final authNotifierForRouter = AuthNotifierForRouter();

// Create router once, only refresh on actual auth changes
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: authNotifierForRouter,
  redirect: (context, state) {
    final isLoggedIn = authNotifierForRouter.isAuthenticated;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginRoute) {
      return '/login';
    }

    if (isLoggedIn && isLoginRoute) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(path: '/', builder: (context, state) => const PosScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/members',
      builder: (context, state) => const MembersScreen(),
    ),
    GoRoute(
      path: '/shifts',
      builder: (context, state) => const ShiftHistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(path: '/menu', builder: (context, state) => const MenuScreen()),
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryScreen(),
    ),
  ],
);

class PosApp extends ConsumerWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only listen for isAuthenticated changes to update router
    final isAuthenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );

    // Update router notifier when auth status changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authNotifierForRouter.update(isAuthenticated);
    });

    return MaterialApp.router(
      title: 'POS Ruang Bincang Coffee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5a6c37),
          primary: const Color(0xFF5a6c37),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      routerConfig: appRouter,
    );
  }
}
