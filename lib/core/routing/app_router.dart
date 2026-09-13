import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/attendance/presentation/pages/record_attendance_page.dart';
import '../../features/attendance/presentation/pages/scan_attendance_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/excel/presentation/pages/excel_page.dart';
import '../../features/face_recognition/presentation/pages/face_attendance_page.dart';
import '../../features/parent/presentation/pages/parent_dashboard_page.dart';
import '../../features/pickup/presentation/pages/pickup_requests_page.dart';
import '../../features/students/presentation/pages/students_page.dart';
import '../../features/user_management/presentation/pages/users_page.dart';
import '../../features/workers/presentation/pages/workers_page.dart';
import '../enums/user_role.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';
import 'go_router_refresh_stream.dart';

/// Central router. Redirects are a convenience only — Firebase Security Rules
/// remain the authoritative access control.
class AppRouter {
  AppRouter(AuthCubit authCubit) : router = _build(authCubit);

  final GoRouter router;

  static const _securityDestinations = [
    ShellDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    ShellDestination(
      label: 'Students',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    ShellDestination(
      label: 'Workers',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
    ),
  ];

  static const _managerDestinations = [
    ShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    ShellDestination(
      label: 'Students',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    ShellDestination(
      label: 'Workers',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
    ),
    ShellDestination(
      label: 'Users',
      icon: Icons.manage_accounts_outlined,
      selectedIcon: Icons.manage_accounts,
    ),
    ShellDestination(
      label: 'Excel',
      icon: Icons.table_chart_outlined,
      selectedIcon: Icons.table_chart,
    ),
  ];

  static const _supervisorDestinations = [
    ShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    ShellDestination(
      label: 'Students',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    ShellDestination(
      label: 'Workers',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
    ),
  ];

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
            final role = auth.user!.role;
            final root = _rootFor(role);
            final home = _homeFor(role);
            // Bounce away from splash/login, and keep each role inside its
            // own subtree.
            if (loc == AppRoutes.splash ||
                loc == AppRoutes.login ||
                !loc.startsWith(root)) {
              return home;
            }
            return null;
        }
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (_, __) => const SplashPage(),
        ),
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
        // Full-screen security flows, kept outside the shell so the sidebar
        // doesn't crowd the camera view or these focused tasks.
        GoRoute(
          path: AppRoutes.securityScan,
          builder: (_, __) => const ScanAttendancePage(),
        ),
        GoRoute(
          path: AppRoutes.securityPickup,
          builder: (_, __) => const PickupRequestsPage(),
        ),
        GoRoute(
          path: AppRoutes.securityFace,
          builder: (_, __) => const FaceAttendancePage(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShell(
            navigationShell: navigationShell,
            destinations: _securityDestinations,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.securityHome,
                  builder: (_, __) => const RecordAttendancePage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.securityStudents,
                  builder: (_, __) => const StudentsPage(readOnly: true),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.securityWorkers,
                  builder: (_, __) => const WorkersPage(readOnly: true),
                ),
              ],
            ),
          ],
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShell(
            navigationShell: navigationShell,
            destinations: _managerDestinations,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.managerDashboard,
                  builder: (_, __) => const DashboardPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.managerStudents,
                  builder: (_, __) => const StudentsPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.managerWorkers,
                  builder: (_, __) => const WorkersPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.managerUsers,
                  builder: (_, __) => const UsersPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.managerExcel,
                  builder: (_, __) => const ExcelPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShell(
            navigationShell: navigationShell,
            destinations: _supervisorDestinations,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.supervisorDashboard,
                  builder: (_, __) => const DashboardPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.supervisorStudents,
                  builder: (_, __) => const StudentsPage(readOnly: true),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.supervisorWorkers,
                  builder: (_, __) => const WorkersPage(readOnly: true),
                ),
              ],
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

  /// Prefix used to decide whether the current location already belongs to
  /// this role's subtree (redirect containment check).
  static String _rootFor(UserRole role) => switch (role) {
    UserRole.security => AppRoutes.securityHome,
    UserRole.manager => AppRoutes.managerHome,
    UserRole.supervisor => AppRoutes.supervisorHome,
    UserRole.parent => AppRoutes.parentHome,
  };

  /// Landing location when entering this role's subtree fresh.
  static String _homeFor(UserRole role) => switch (role) {
    UserRole.security => AppRoutes.securityHome,
    UserRole.manager => AppRoutes.managerDashboard,
    UserRole.supervisor => AppRoutes.supervisorDashboard,
    UserRole.parent => AppRoutes.parentHome,
  };
}
