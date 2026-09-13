import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/attendance_state.dart';
import '../../../../core/enums/pickup_status.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../students/domain/entities/student.dart';
import '../../domain/entities/pickup_request.dart';
import '../cubit/parent_pickup_cubit.dart';

/// Parent-facing pickup control for one child. Provides its own cubit so it can
/// be keyed by student id and rebuilt cleanly on child switch.
class ParentPickupCard extends StatelessWidget {
  const ParentPickupCard({super.key, required this.child});

  final Student child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('pickup-${child.studentId}'),
      create: (_) => sl<ParentPickupCubit>()..watch(child.studentId),
      child: _CardBody(child: child),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.child});

  final Student child;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ParentPickupCubit, ParentPickupState>(
      listenWhen: (a, b) =>
          a.errorMessage != b.errorMessage && b.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        final cubit = context.read<ParentPickupCubit>();
        final request = state.active;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pickup', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                if (state.status == ParentPickupStatus.loading)
                  const Center(child: CircularProgressIndicator())
                else if (request == null)
                  state.childState == AttendanceState.inside
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Tap when you have arrived to collect your child.",
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            PrimaryButton(
                              label: "I'm here to pick up my child",
                              icon: Icons.directions_car,
                              isLoading: state.isSubmitting,
                              onPressed: () => cubit.request(
                                studentId: child.studentId,
                                studentName: child.fullName,
                                className: child.className,
                              ),
                            ),
                          ],
                        )
                      : _NotEligibleNotice(childState: state.childState)
                else
                  _ActiveRequest(
                    request: request,
                    isSubmitting: state.isSubmitting,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shown instead of the request button when the child isn't currently
/// checked in — there is nothing to pick up yet, or they've already left.
class _NotEligibleNotice extends StatelessWidget {
  const _NotEligibleNotice({required this.childState});

  final AttendanceState childState;

  @override
  Widget build(BuildContext context) {
    final message = switch (childState) {
      AttendanceState.absent => "Your child hasn't checked in yet today.",
      AttendanceState.left =>
        'Your child has already checked out for today.',
      AttendanceState.inside => '',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
      ],
    );
  }
}

class _ActiveRequest extends StatelessWidget {
  const _ActiveRequest({required this.request, required this.isSubmitting});

  final PickupRequest request;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ParentPickupCubit>();
    final status = request.status;
    final message = switch (status) {
      PickupStatus.pending => 'Request sent — waiting for security.',
      PickupStatus.acknowledged => 'Security has received your request.',
      PickupStatus.completed => 'Pickup completed.',
      PickupStatus.cancelled => 'Request cancelled.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              status == PickupStatus.completed
                  ? Icons.check_circle
                  : Icons.hourglass_top,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Requested ${TimeFormat.time(request.requestedAt)}'),
        if (status.isActive) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isSubmitting ? null : cubit.cancel,
              child: const Text('Cancel request'),
            ),
          ),
        ],
      ],
    );
  }
}
