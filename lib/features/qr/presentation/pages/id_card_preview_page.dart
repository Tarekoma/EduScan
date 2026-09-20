import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/file_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/id_card_pdf_builder.dart';
import '../../data/id_card_pdf_service.dart';
import '../../domain/entities/id_card_data.dart';
import 'add_cards_page.dart';

/// The generated landscape A4 sheet of QR cards. The bottom bar offers print,
/// save, share, and "add more people" — which regenerates the sheet with the
/// extra cards.
class IdCardPreviewPage extends StatefulWidget {
  const IdCardPreviewPage({super.key, required this.cards});

  final List<IdCardData> cards;

  @override
  State<IdCardPreviewPage> createState() => _IdCardPreviewPageState();
}

class _IdCardPreviewPageState extends State<IdCardPreviewPage> {
  late List<IdCardData> _cards = List.of(widget.cards);
  late Future<Uint8List> _pdf = _generate();

  /// Rendering progress (0..1) while preparing the sheet; null = indeterminate.
  final ValueNotifier<double?> _progress = ValueNotifier(null);

  /// True while saving / sharing, to show a blocking spinner.
  bool _busy = false;

  Future<Uint8List> _generate() {
    _progress.value = null;
    return sl<IdCardPdfService>().generate(
      _cards,
      onProgress: (done, total) =>
          _progress.value = done >= total ? null : done / total,
    );
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _whileBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _retry() => setState(() => _pdf = _generate());

  Future<void> _addPeople() async {
    final added = await Navigator.of(context).push<List<IdCardData>>(
      MaterialPageRoute(
        builder: (_) =>
            AddCardsPage(excluded: {for (final c in _cards) c.qrValue}),
      ),
    );
    if (!mounted || added == null || added.isEmpty) return;
    setState(() {
      _cards = [..._cards, ...added];
      _pdf = _generate();
    });
  }

  Future<void> _save(Uint8List bytes) => _whileBusy(() => _doSave(bytes));

  Future<void> _share(Uint8List bytes) => _whileBusy(() => _doShare(bytes));

  Future<void> _doSave(Uint8List bytes) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final saved = await sl<FileService>().savePdf(
        bytes,
        IdCardPdfService.fileName(_cards),
      );
      if (saved) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.printQrSaved)));
      }
    } catch (_) {
      _showFailed(messenger, l10n);
    }
  }

  Future<void> _doShare(Uint8List bytes) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await sl<FileService>().shareBytes(
        bytes,
        IdCardPdfService.fileName(_cards),
      );
    } catch (_) {
      _showFailed(messenger, l10n);
    }
  }

  void _showFailed(ScaffoldMessengerState messenger, AppLocalizations l10n) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.printQrFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.printQrPreviewTitle,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBody(l10n)),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreparing(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<double?>(
            valueListenable: _progress,
            builder: (_, value, __) => SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(value: value),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.printQrPreparing(_cards.length)),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return FutureBuilder<Uint8List>(
      future: _pdf,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorView(message: l10n.printQrFailed, onRetry: _retry);
        }
        final bytes = snapshot.data;
        if (bytes == null) return _buildPreparing(l10n);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Column(
                children: [
                  Text(
                    l10n.printQrCardsCount(_cards.length),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    l10n.printQrSizeHint,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                key: ValueKey(bytes),
                build: (_) => bytes,
                initialPageFormat: IdCardPdfBuilder.pageFormat,
                pdfFileName: IdCardPdfService.fileName(_cards),
                allowPrinting: true,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                maxPageWidth: 900,
                actions: [
                  PdfPreviewAction(
                    icon: const Icon(Icons.download),
                    onPressed: (_, __, ___) => _save(bytes),
                  ),
                  PdfPreviewAction(
                    icon: const Icon(Icons.share),
                    onPressed: (_, __, ___) => _share(bytes),
                  ),
                  PdfPreviewAction(
                    icon: const Icon(Icons.person_add_alt_1),
                    onPressed: (_, __, ___) => _addPeople(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
