import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/enums/person_type.dart';
import '../../../../core/enums/person_type_display.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/person_id.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/locale_toggle_button.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/sign_out_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pickup/presentation/cubit/pickup_alert_cubit.dart';
import '../../domain/attendance_rules.dart';
import '../attendance_status_display.dart';
import '../cubit/record_attendance_cubit.dart';

/// Security screen for recording attendance. QR scanning (Phase 6) will feed
/// the same [RecordAttendanceCubit.submit]; this manual form is the fallback.
class RecordAttendancePage extends StatelessWidget {
  const RecordAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RecordAttendanceCubit>(),
      child: const _RecordAttendanceView(),
    );
  }
}

class _RecordAttendanceView extends StatefulWidget {
  const _RecordAttendanceView();

  @override
  State<_RecordAttendanceView> createState() => _RecordAttendanceViewState();
}

class _RecordAttendanceViewState extends State<_RecordAttendanceView> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  PersonType _type = PersonType.student;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _submit({AttendanceAction? action}) {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final number = int.parse(_idController.text.trim());
    context.read<RecordAttendanceCubit>().submit(
      personId: PersonId.format(_type, number),
      action: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PickupAlertCubit, PickupAlertState>(
      listenWhen: (a, b) =>
          b.lastNewRequest != null && a.lastNewRequest != b.lastNewRequest,
      listener: (context, state) {
        final req = state.lastNewRequest!;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.newPickupRequestSnackbar(req.studentName)),
              action: SnackBarAction(
                label: l10n.commonView,
                onPressed: () => context.push(AppRoutes.securityPickup),
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        context.read<PickupAlertCubit>().acknowledgeSeen();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: PageHeader(
          title: l10n.recordAttendanceTitle,
          subtitle: l10n.recordAttendanceSubtitle,
        ),
        actions: [
          if (AppConfig.pickupEnabled)
            BlocBuilder<PickupAlertCubit, PickupAlertState>(
              builder: (context, alert) => IconButton(
                tooltip: l10n.pickupRequestsTitle,
                icon: Badge(
                  isLabelVisible: alert.pendingCount > 0,
                  label: Text('${alert.pendingCount}'),
                  child: const Icon(Icons.directions_car_outlined),
                ),
                onPressed: () => context.push(AppRoutes.securityPickup),
              ),
            ),
          if (context.isMobile) ...[
            const ThemeToggleButton(),
            const LocaleToggleButton(),
            const SignOutButton(),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => context.push(AppRoutes.securityScan),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l10n.scanQrCodeButton),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.enterIdManually,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<PersonType>(
              segments: [
                ButtonSegment(
                  value: PersonType.student,
                  label: Text(l10n.personTypeStudent),
                  icon: const Icon(Icons.school_outlined),
                ),
                ButtonSegment(
                  value: PersonType.worker,
                  label: Text(l10n.personTypeWorker),
                  icon: const Icon(Icons.badge_outlined),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _idController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: InputDecoration(
                  labelText: 'XXXXX',
                  prefixText: '${_type.qrPrefix}_',
                  prefixIcon: const Icon(Icons.tag),
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return l10n.validatorEnterId;
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return l10n.validatorIdFormat(_type.qrPrefix);
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocConsumer<RecordAttendanceCubit, RecordAttendanceState>(
              listener: (context, state) {
                if (state.status == RecordStatus.success) {
                  _idController.clear();
                }
              },
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrimaryButton(
                      label: l10n.scanRecordButton,
                      isLoading: state.isSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () =>
                                      _submit(action: AttendanceAction.checkIn),
                            child: Text(l10n.forceCheckInButton),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => _submit(
                                    action: AttendanceAction.checkOut,
                                  ),
                            child: Text(l10n.forceCheckOutButton),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ResultCard(state: state),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.state});

  final RecordAttendanceState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    switch (state.status) {
      case RecordStatus.idle:
      case RecordStatus.submitting:
        return const SizedBox.shrink();
      case RecordStatus.failure:
        return Card(
          color: scheme.errorContainer,
          child: ListTile(
            leading: Icon(Icons.error_outline, color: scheme.onErrorContainer),
            title: Text(
              state.message ?? l10n.couldNotRecordAttendance,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        );
      case RecordStatus.success:
        final r = state.record!;
        final person = state.person;
        final recordedBy = state.recordedByName;
        final isIn = state.action == AttendanceAction.checkIn;
        return Card(
          color: scheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isIn ? Icons.login : Icons.logout,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isIn ? l10n.checkedInTitle : l10n.checkedOutTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (person != null)
                  Text(
                    person.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                Text(
                  l10n.personIdTypeLabel(
                    r.personId,
                    r.personType.label(context),
                  ),
                ),
                if (person?.subtitle != null) Text(person!.subtitle!),
                Text(l10n.attendanceCheckInAt(TimeFormat.time(r.checkIn))),
                Text(l10n.attendanceCheckOutAt(TimeFormat.time(r.checkOut))),
                Text(l10n.attendanceStatusLabel(r.state.label(context))),
                if (recordedBy != null)
                  Text(l10n.attendanceRecordedBy(recordedBy)),
              ],
            ),
          ),
        );
    }
  }
}
