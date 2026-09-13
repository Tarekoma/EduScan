import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_config.dart';
import '../theme/app_theme.dart';
import '../theme/theme_cubit.dart';
import '../utils/responsive.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

/// Persistent navigation frame for the manager/supervisor role trees: a dark
/// sidebar on tablet/desktop, a bottom nav bar on mobile. Wraps a
/// [StatefulNavigationShell] branch so each destination keeps its own
/// navigation stack (e.g. pushing a form) while the frame stays put.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.destinations,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;

  void _onSelect(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Scaffold(
        body: SafeArea(child: navigationShell),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onSelect,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon ?? d.icon),
                label: d.label,
              ),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            destinations: destinations,
            selectedIndex: navigationShell.currentIndex,
            onSelect: _onSelect,
            expanded: context.isDesktop,
          ),
          Expanded(child: SafeArea(child: navigationShell)),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.expanded,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    return Container(
      width: expanded ? 240 : 80,
      color: AppColors.sidebarBackground,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  if (expanded) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        AppConfig.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    _SidebarItem(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      expanded: expanded,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: _ThemeToggle(expanded: expanded),
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: _UserFooter(name: user.name, role: user.role.value, expanded: expanded),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      selected ? (destination.selectedIcon ?? destination.icon) : destination.icon,
      color: selected ? Colors.white : AppColors.sidebarForegroundMuted,
      size: 22,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? AppColors.sidebarBackgroundActive : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: expanded
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          destination.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.sidebarForeground,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(child: icon),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformBrightness == Brightness.dark);
    final icon = Icon(
      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      color: AppColors.sidebarForegroundMuted,
      size: 20,
    );
    final tooltip = isDark ? 'Switch to light mode' : 'Switch to dark mode';
    void onTap() => context.read<ThemeCubit>().toggle(platformBrightness);

    if (!expanded) {
      return IconButton(tooltip: tooltip, icon: icon, onPressed: onTap);
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isDark ? 'Dark mode' : 'Light mode',
                  style: const TextStyle(
                    color: AppColors.sidebarForeground,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter({required this.name, required this.role, required this.expanded});

  final String name;
  final String role;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final roleLabel = role.isEmpty ? '' : '${role[0].toUpperCase()}${role.substring(1)}';
    final avatar = CircleAvatar(
      backgroundColor: AppColors.sidebarBackgroundActive,
      foregroundColor: Colors.white,
      child: Text(initial),
    );
    if (!expanded) {
      return Column(
        children: [
          avatar,
          const SizedBox(height: AppSpacing.xs),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: AppColors.sidebarForegroundMuted, size: 20),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      );
    }
    return Row(
      children: [
        avatar,
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Text(
                roleLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.sidebarForegroundMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout, color: AppColors.sidebarForegroundMuted, size: 20),
          onPressed: () => context.read<AuthCubit>().signOut(),
        ),
      ],
    );
  }
}
