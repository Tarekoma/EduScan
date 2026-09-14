import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/enums/user_role_display.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/locale_toggle_button.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/sign_out_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../cubit/user_management_cubit.dart';
import 'create_internal_page.dart';
import 'create_parent_page.dart';
import 'student_multi_select_page.dart';

/// Manager screen for administering accounts, one tab per role.
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          title: PageHeader(
            title: l10n.usersTitle,
            subtitle: l10n.usersSubtitle,
          ),
          actions: [
            if (context.isMobile) ...[
              const ThemeToggleButton(),
              const LocaleToggleButton(),
              const SignOutButton(),
            ],
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabParents),
              Tab(text: l10n.tabSecurity),
              Tab(text: l10n.tabSupervisors),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RoleTab(role: UserRole.parent),
            _RoleTab(role: UserRole.security),
            _RoleTab(role: UserRole.supervisor),
          ],
        ),
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UserManagementCubit>()..start(role),
      child: _RoleTabView(role: role),
    );
  }
}

class _RoleTabView extends StatelessWidget {
  const _RoleTabView({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.addRoleButton(role.label(context))),
      ),
      body: BlocConsumer<UserManagementCubit, UserManagementState>(
        listenWhen: (a, b) =>
            a.actionError != b.actionError && b.actionError != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.actionError!)));
        },
        builder: (context, state) {
          switch (state.status) {
            case UsersStatus.initial:
            case UsersStatus.loading:
              return const LoadingView();
            case UsersStatus.error:
              return ErrorView(
                message: state.errorMessage ?? l10n.usersCouldNotLoad,
                onRetry: () => context.read<UserManagementCubit>().start(role),
              );
            case UsersStatus.ready:
              if (state.users.isEmpty) {
                return EmptyView(message: l10n.noRoleAccountsYet(role.label(context)));
              }
              return ListView.separated(
                itemCount: state.users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) =>
                    _UserTile(user: state.users[i], role: role),
              );
          }
        },
      ),
    );
  }

  Future<void> _create(BuildContext context) {
    final cubit = context.read<UserManagementCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: role == UserRole.parent
              ? const CreateParentPage()
              : CreateInternalPage(role: role),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.role});

  final AppUser user;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UserManagementCubit>();
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(user.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email),
          if (role == UserRole.parent)
            Text(
              user.studentIds.isEmpty
                  ? l10n.userNoChildrenLinked
                  : l10n.userChildrenLinked(user.studentIds.join(', ')),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      isThreeLine: role == UserRole.parent,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: user.isActive,
            onChanged: (v) => cubit.setActive(user.uid, v),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'links') {
                final picked = await Navigator.of(context).push<List<String>>(
                  MaterialPageRoute(
                    builder: (_) =>
                        StudentMultiSelectPage(initial: user.studentIds),
                  ),
                );
                if (picked != null) cubit.updateLinks(user.uid, picked);
              } else if (v == 'delete') {
                final ok = await showConfirmDialog(
                  context,
                  title: l10n.deleteAccountDialogTitle,
                  message: l10n.deleteAccountMessage(user.name),
                  confirmLabel: l10n.commonDelete,
                  destructive: true,
                );
                if (ok) cubit.deleteUser(user.uid, role);
              }
            },
            itemBuilder: (_) => [
              if (role == UserRole.parent)
                PopupMenuItem(
                  value: 'links',
                  child: Text(l10n.editLinkedChildrenMenuItem),
                ),
              PopupMenuItem(value: 'delete', child: Text(l10n.commonDelete)),
            ],
          ),
        ],
      ),
    );
  }
}
