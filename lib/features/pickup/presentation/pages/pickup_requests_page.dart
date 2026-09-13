import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../cubit/pickup_alert_cubit.dart';
import '../cubit/security_pickup_cubit.dart';
import '../widgets/pickup_request_card.dart';

/// Security screen: the live queue of active pickup requests.
class PickupRequestsPage extends StatelessWidget {
  const PickupRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SecurityPickupCubit>()..start(),
      child: const _PickupRequestsView(),
    );
  }
}

class _PickupRequestsView extends StatefulWidget {
  const _PickupRequestsView();

  @override
  State<_PickupRequestsView> createState() => _PickupRequestsViewState();
}

class _PickupRequestsViewState extends State<_PickupRequestsView> {
  @override
  void initState() {
    super.initState();
    // Opening the queue counts as the security user seeing the alerts.
    context.read<PickupAlertCubit>().acknowledgeSeen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup requests')),
      body: BlocConsumer<SecurityPickupCubit, SecurityPickupState>(
        listenWhen: (a, b) =>
            a.actionError != b.actionError && b.actionError != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.actionError!)));
        },
        builder: (context, state) {
          switch (state.status) {
            case PickupQueueStatus.initial:
            case PickupQueueStatus.loading:
              return const LoadingView();
            case PickupQueueStatus.error:
              return ErrorView(
                message:
                    state.errorMessage ?? 'Could not load pickup requests.',
                onRetry: () => context.read<SecurityPickupCubit>().start(),
              );
            case PickupQueueStatus.ready:
              if (state.requests.isEmpty) {
                return const EmptyView(
                  message: 'No active pickup requests.',
                  icon: Icons.directions_car_outlined,
                );
              }
              final cubit = context.read<SecurityPickupCubit>();
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: state.requests.length,
                itemBuilder: (context, i) {
                  final r = state.requests[i];
                  return PickupRequestCard(
                    request: r,
                    busy: state.isMutating,
                    highlight: i == 0,
                    onAcknowledge: () => cubit.acknowledge(r.requestId),
                    onComplete: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: 'Complete pickup',
                        message:
                            'Confirm ${r.studentName} has been collected by ${r.parentName}?',
                        confirmLabel: 'Complete',
                      );
                      if (ok) cubit.complete(r.requestId);
                    },
                    onCancel: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: 'Cancel request',
                        message:
                            'Cancel the pickup request for ${r.studentName}?',
                        confirmLabel: 'Cancel request',
                        destructive: true,
                      );
                      if (ok) cubit.cancel(r.requestId);
                    },
                  );
                },
              );
          }
        },
      ),
    );
  }
}
