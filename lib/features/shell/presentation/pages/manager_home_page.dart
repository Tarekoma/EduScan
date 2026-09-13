import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/nav_grid.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class ManagerHomePage extends StatelessWidget {
  const ManagerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      body: const NavGrid(
        destinations: [
          NavDestination(
            label: 'Dashboard',
            subtitle: 'Stats & activity',
            icon: Icons.dashboard_outlined,
            route: AppRoutes.managerDashboard,
          ),
          NavDestination(
            label: 'Students',
            subtitle: 'Add, edit, QR',
            icon: Icons.school_outlined,
            route: AppRoutes.managerStudents,
          ),
          NavDestination(
            label: 'Workers',
            subtitle: 'Add, edit, QR',
            icon: Icons.badge_outlined,
            route: AppRoutes.managerWorkers,
          ),
          NavDestination(
            label: 'Users',
            subtitle: 'Parents & staff',
            icon: Icons.manage_accounts_outlined,
            route: AppRoutes.managerUsers,
          ),
          NavDestination(
            label: 'Excel',
            subtitle: 'Import & export',
            icon: Icons.table_chart_outlined,
            route: AppRoutes.managerExcel,
          ),
        ],
      ),
    );
  }
}
