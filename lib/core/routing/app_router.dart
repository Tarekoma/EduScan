import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/attendance/presentation/pages/record_attendance_page.dart';
import '../../features/attendance/presentation/pages/scan_attendance_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/excel/presentation/pages/excel_page.dart';
import '../../features/face_recognition/presentation/pages/face_attendance_page.dart';
import '../../features/parent/presentation/pages/parent_dashboard_page.dart';
import '../../features/pickup/presentation/pages/pickup_requests_page.dart';
import '../../features/shell/presentation/pages/manager_home_page.dart';
import '../../features/shell/presentation/pages/supervisor_home_page.dart';
import '../../features/students/presentation/pages/students_page.dart';
import '../../features/user_management/presentation/pages/users_page.dart';
import '../../features/workers/presentation/pages/workers_page.dart';
import '../enums/user_role.dart';
import 'app_routes.dart';
import 'go_router_refresh_stream.dart';

/// Central router. Redirects are a convenience only — Firebase Security Rules
/// remain the authoritative access control.
class AppRouter {
  AppRouter(AuthCubit authCubit) : router = _build(authCubit);

  final GoRouter router;

  static GoRouter _build(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final auth = authCubit.state;
        final loc = state.matchedLocation;

        switch (auth.status) {
          case AuthStatus.unknown:
            return loc == AppRoutes.splash ? null : AppRoutes.splash;
          case AuthStatus.unauthenticated:
            return loc == AppRoutes.login ? null : AppRoutes.login;
          case AuthStatus.authenticated:
            final home = _homeFor(auth.user!.role);
            // Bounce away from splash/login, and keep each role inside its
            // own subtree.
            if (loc == AppRoutes.splash ||
                loc == AppRoutes.login ||
                !loc.startsWith(home)) {
              return home;
            }
            return null;
        }
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (_, __) => const _SplashScreen(),
        ),
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
        GoRoute(
          path: AppRoutes.securityHome,
          builder: (_, __) => const RecordAttendancePage(),
          routes: [
            GoRoute(
              path: 'scan',
              builder: (_, __) => const ScanAttendancePage(),
            ),
            GoRoute(
              path: 'pickup',
              builder: (_, __) => const PickupRequestsPage(),
            ),
            GoRoute(
              path: 'face',
              builder: (_, __) => const FaceAttendancePage(),
            ),
            GoRoute(
              path: 'workers',
              builder: (_, __) => const WorkersPage(readOnly: true),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.managerHome,
          builder: (_, __) => const ManagerHomePage(),
          routes: [
            GoRoute(
              path: 'dashboard',
              builder: (_, __) => const DashboardPage(),
            ),
            GoRoute(path: 'students', builder: (_, __) => const StudentsPage()),
            GoRoute(path: 'workers', builder: (_, __) => const WorkersPage()),
            GoRoute(path: 'users', builder: (_, __) => const UsersPage()),
            GoRoute(path: 'excel', builder: (_, __) => const ExcelPage()),
          ],
        ),
        GoRoute(
          path: AppRoutes.supervisorHome,
          builder: (_, __) => const SupervisorHomePage(),
          routes: [
            GoRoute(
              path: 'dashboard',
              builder: (_, __) => const DashboardPage(),
            ),
            GoRoute(
              path: 'students',
              builder: (_, __) => const StudentsPage(readOnly: true),
            ),
            GoRoute(
              path: 'workers',
              builder: (_, __) => const WorkersPage(readOnly: true),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.parentHome,
          builder: (_, __) => const ParentDashboardPage(),
        ),
      ],
    );
  }

  static String _homeFor(UserRole role) => switch (role) {
    UserRole.security => AppRoutes.securityHome,
    UserRole.manager => AppRoutes.managerHome,
    UserRole.supervisor => AppRoutes.supervisorHome,
    UserRole.parent => AppRoutes.parentHome,
  };
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
