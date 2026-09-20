import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.scanQrTitle),
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
    final l10n = AppLocalizations.of(context)!;
    final (Color bg, Color fg, String text) = switch (state.status) {
      RecordStatus.idle => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        l10n.scanPointCamera,
      ),
      RecordStatus.submitting => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        l10n.scanRecording,
      ),
      RecordStatus.failure => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        state.message ?? l10n.couldNotRecordAttendance,
      ),
      RecordStatus.success => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        () {
          final r = state.record!;
          final verb = r.checkOut != null
              ? l10n.checkedOutTitle
              : l10n.checkedInTitle;
          final time = TimeFormat.time(r.checkOut ?? r.checkIn);
          final name = state.person?.displayName;
          final recordedBy = state.recordedByName;
          return [
            if (name != null)
              l10n.personNameIdLabel(name, r.personId)
            else
              r.personId,
            l10n.scanResultLine(verb, time),
            if (recordedBy != null) l10n.attendanceRecordedBy(recordedBy),
          ].join('\n');
        }(),
      ),
    };
    return ColoredBox(
      color: bg,
      // Only the bottom inset needs protecting here — the AppBar above
      // already keeps this page clear of the top status bar.
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: TextStyle(color: fg)),
              ),
              if (state.status == RecordStatus.success ||
                  state.status == RecordStatus.failure)
                TextButton(
                  onPressed: () =>
                      context.read<RecordAttendanceCubit>().reset(),
                  child: Text(l10n.commonNext),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
