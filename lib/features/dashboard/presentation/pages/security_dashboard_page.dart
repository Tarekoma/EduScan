import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/locale_toggle_button.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/sign_out_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/dashboard_cubit.dart';
import 'dashboard_page.dart' show TodaySnapshotSection;

/// Read-only "today" view for the security role: the same live snapshot
/// and activity feed managers/supervisors see on [DashboardPage], without
/// the historical reports section (rate-over-time, per-class comparison,
/// detailed table) that's out of scope for this role.
class SecurityDashboardPage extends StatelessWidget {
  const SecurityDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardCubit>()..start(),
      child: const _SecurityDashboardView(),
    );
  }
}

class _SecurityDashboardView extends StatelessWidget {
  const _SecurityDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading ||
            state.status == DashboardStatus.initial) {
          return const LoadingView();
        }
        if (state.status == DashboardStatus.error) {
          return ErrorView(
            message: state.errorMessage ??
                AppLocalizations.of(context)!.dashboardCouldNotLoad,
            onRetry: () => context.read<DashboardCubit>().start(),
          );
        }
        final l10n = AppLocalizations.of(context)!;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PageHeader(
                    title: l10n.dashboardTitle,
                    subtitle: l10n.dashboardSubtitle,
                  ),
                ),
                if (context.isMobile) ...[
                  const ThemeToggleButton(),
                  const LocaleToggleButton(),
                  const SignOutButton(),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TodaySnapshotSection(state: state),
          ],
        );
      },
    );
  }
}
