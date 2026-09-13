import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.route,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final String route;
  final String? subtitle;
}

/// Responsive grid of navigation cards, shared by the manager and supervisor
/// home screens. Uses `push` so sub-pages get a back button.
class NavGrid extends StatelessWidget {
  const NavGrid({super.key, required this.destinations});

  final List<NavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final columns = responsiveValue(context, mobile: 2, tablet: 3, desktop: 4);
    return GridView.count(
      crossAxisCount: columns,
      padding: const EdgeInsets.all(AppSpacing.md),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.1,
      children: [
        for (final d in destinations)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              onTap: () => context.push(d.route),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(d.icon, size: 36),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      d.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (d.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        d.subtitle!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
