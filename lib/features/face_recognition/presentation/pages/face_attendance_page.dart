import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../cubit/face_attendance_cubit.dart';

/// Security fallback: record attendance by face when a person has no QR code.
///
/// The live camera + on-device model are added together (see
/// `features/face_recognition/README.md`). Until then this screen surfaces the
/// unavailable state clearly rather than pretending to work.
class FaceAttendancePage extends StatelessWidget {
  const FaceAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FaceAttendanceCubit>(),
      child: const _FaceAttendanceView(),
    );
  }
}

class _FaceAttendanceView extends StatelessWidget {
  const _FaceAttendanceView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face recognition')),
      body: BlocBuilder<FaceAttendanceCubit, FaceAttendanceState>(
        builder: (context, state) {
          switch (state.status) {
            case FaceStatus.unavailable:
              return const _UnavailableBody();
            case FaceStatus.processing:
              return const Center(child: CircularProgressIndicator());
            case FaceStatus.success:
              final r = state.result!;
              return _MessageBody(
                icon: Icons.check_circle,
                title: r.action.name == 'checkIn'
                    ? 'Checked in'
                    : 'Checked out',
                detail:
                    '${r.match.personId}  •  '
                    '${(r.match.confidence * 100).toStringAsFixed(0)}% match\n'
                    'In ${TimeFormat.time(r.record.checkIn)}  •  '
                    'Out ${TimeFormat.time(r.record.checkOut)}',
                onReset: () => context.read<FaceAttendanceCubit>().reset(),
              );
            case FaceStatus.failure:
              return _MessageBody(
                icon: Icons.error_outline,
                title: 'Not recorded',
                detail: state.message ?? 'Try again or use the QR code.',
                onReset: () => context.read<FaceAttendanceCubit>().reset(),
              );
            case FaceStatus.idle:
              return const _IdleBody();
          }
        },
      ),
    );
  }
}

class _UnavailableBody extends StatelessWidget {
  const _UnavailableBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.face_retouching_off,
              size: 56,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Face recognition is not enabled on this build.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Attendance continues to work with QR codes. A recognition model '
              'can be added without changing the attendance flow.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleBody extends StatelessWidget {
  const _IdleBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Point the camera at the person to identify them, then confirm.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onReset,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(detail, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onReset, child: const Text('Next')),
          ],
        ),
      ),
    );
  }
}
