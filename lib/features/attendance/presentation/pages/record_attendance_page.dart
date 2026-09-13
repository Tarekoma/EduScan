import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/enums/attendance_state.dart';
import '../../../../core/enums/person_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/person_id.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../pickup/presentation/cubit/pickup_alert_cubit.dart';
import '../../domain/attendance_rules.dart';
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
    context.read<RecordAttendanceCubit>().submit(
      personId: _idController.text.trim().toUpperCase(),
      personType: _type,
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('New pickup request: ${req.studentName}'),
              action: SnackBarAction(
                label: 'View',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record attendance'),
        actions: [
          if (AppConfig.pickupEnabled)
            BlocBuilder<PickupAlertCubit, PickupAlertState>(
              builder: (context, alert) => IconButton(
                tooltip: 'Pickup requests',
                icon: Badge(
                  isLabelVisible: alert.pendingCount > 0,
                  label: Text('${alert.pendingCount}'),
                  child: const Icon(Icons.directions_car_outlined),
                ),
                onPressed: () => context.push(AppRoutes.securityPickup),
              ),
            ),
          IconButton(
            tooltip: 'Contact staff',
            icon: const Icon(Icons.contact_phone_outlined),
            onPressed: () => context.push(AppRoutes.securityWorkers),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
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
              label: const Text('Scan QR code'),
            ),
            if (AppConfig.faceRecognitionEnabled) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.securityFace),
                icon: const Icon(Icons.face),
                label: const Text('Use face recognition'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Or enter an ID manually',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<PersonType>(
              segments: const [
                ButtonSegment(
                  value: PersonType.student,
                  label: Text('Student'),
                  icon: Icon(Icons.school_outlined),
                ),
                ButtonSegment(
                  value: PersonType.worker,
                  label: Text('Worker'),
                  icon: Icon(Icons.badge_outlined),
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
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: '${_type.qrPrefix}_XXXXX',
                  prefixIcon: const Icon(Icons.tag),
                ),
                validator: (v) {
                  final value = (v ?? '').trim().toUpperCase();
                  if (value.isEmpty) return 'Enter an ID.';
                  if (!PersonId.isValid(value, _type)) {
                    return 'ID must look like ${_type.qrPrefix}_00125.';
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
                      label: 'Scan / record',
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
                            child: const Text('Force check-in'),
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
                            child: const Text('Force check-out'),
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
              state.message ?? 'Could not record attendance.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        );
      case RecordStatus.success:
        final r = state.record!;
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
                      isIn ? 'Checked in' : 'Checked out',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('${r.personId} • ${r.personType.value}'),
                Text('Check-in: ${TimeFormat.time(r.checkIn)}'),
                Text('Check-out: ${TimeFormat.time(r.checkOut)}'),
                Text('Status: ${_stateLabel(r.state)}'),
              ],
            ),
          ),
        );
    }
  }

  String _stateLabel(AttendanceState s) => switch (s) {
    AttendanceState.absent => 'Absent',
    AttendanceState.inside => 'Inside',
    AttendanceState.left => 'Left',
  };
}
