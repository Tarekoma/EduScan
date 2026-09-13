import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../cubit/record_attendance_cubit.dart';

/// Security QR scan flow. Each detected code is resolved to a person and
/// recorded via the shared [RecordAttendanceCubit].
class ScanAttendancePage extends StatelessWidget {
  const ScanAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RecordAttendanceCubit>(),
      child: const _ScanView(),
    );
  }
}

class _ScanView extends StatefulWidget {
  const _ScanView();

  @override
  State<_ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<_ScanView> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;
    context.read<RecordAttendanceCubit>().submitScanned(
      raw,
      scanKey: raw.trim().toUpperCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: BlocConsumer<RecordAttendanceCubit, RecordAttendanceState>(
        listener: (context, state) {
          if (state.status == RecordStatus.success) {
            HapticFeedback.mediumImpact();
          } else if (state.status == RecordStatus.failure) {
            HapticFeedback.vibrate();
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(controller: _controller, onDetect: _onDetect),
                    if (state.isSubmitting)
                      const ColoredBox(
                        color: Colors.black45,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
              _ResultBar(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.state});

  final RecordAttendanceState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, String text) = switch (state.status) {
      RecordStatus.idle => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        'Point the camera at a student or worker QR code.',
      ),
      RecordStatus.submitting => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        'Recording…',
      ),
      RecordStatus.failure => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        state.message ?? 'Could not record attendance.',
      ),
      RecordStatus.success => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        () {
          final r = state.record!;
          final verb = r.checkOut != null ? 'Checked out' : 'Checked in';
          final time = TimeFormat.time(r.checkOut ?? r.checkIn);
          return '$verb • ${r.personId} • $time';
        }(),
      ),
    };
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(color: fg)),
          ),
          if (state.status == RecordStatus.success ||
              state.status == RecordStatus.failure)
            TextButton(
              onPressed: () => context.read<RecordAttendanceCubit>().reset(),
              child: const Text('Next'),
            ),
        ],
      ),
    );
  }
}
