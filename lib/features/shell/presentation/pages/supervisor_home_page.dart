import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/nav_grid.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class SupervisorHomePage extends StatelessWidget {
  const SupervisorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor'),
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
            route: AppRoutes.supervisorDashboard,
          ),
          NavDestination(
            label: 'Students',
            subtitle: 'View only',
            icon: Icons.school_outlined,
            route: AppRoutes.supervisorStudents,
          ),
          NavDestination(
            label: 'Workers',
            subtitle: 'View only',
            icon: Icons.badge_outlined,
            route: AppRoutes.supervisorWorkers,
          ),
        ],
      ),
    );
  }
}
