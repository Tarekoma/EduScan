import 'package:flutter/services.dart';

import '../domain/entities/id_card_data.dart';
import 'arabic_text_renderer.dart';
import 'id_card_pdf_builder.dart';

/// Produces print-ready ID-card PDFs. Loads the bundled fonts once; the
/// fonts cover Latin and Arabic so names print correctly in either language.
class IdCardPdfService {
  IdCardPdfService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Future<IdCardPdfAssets>? _assets;
  ArabicTextRenderer? _renderer;

  /// [onProgress] reports `(done, total)` while Arabic text is being rendered,
  /// the slow part for big batches; the final PDF assembly has no steps.
  Future<Uint8List> generate(
    List<IdCardData> cards, {
    void Function(int done, int total)? onProgress,
  }) async {
    final assets = await (_assets ??= _loadAssets());
    final renderer = _renderer ??= ArabicTextRenderer(
      regularFont: assets.arabicRegular,
      boldFont: assets.arabicBold,
    );

    // Each distinct Arabic line is rendered once, however many cards use it.
    final specs = {
      for (final card in cards)
        for (final spec in IdCardPdfBuilder.arabicSpecs(card)) spec.key: spec,
    };
    final images = <String, CardTextImage>{};
    for (final entry in specs.entries) {
      images[entry.key] = await renderer.render(entry.value);
      onProgress?.call(images.length, specs.length);
      // Let the UI draw a frame so the progress indicator keeps moving.
      await Future<void>.delayed(Duration.zero);
    }
    return IdCardPdfBuilder.build(cards, assets, textImages: images);
  }

  Future<IdCardPdfAssets> _loadAssets() async {
    try {
      Future<Uint8List> load(String path) async =>
          (await _bundle.load(path)).buffer.asUint8List();
      final results = await Future.wait([
        load('assets/fonts/NotoSans-Regular.ttf'),
        load('assets/fonts/NotoSans-Bold.ttf'),
        load('assets/fonts/NotoSansArabic-Regular.ttf'),
        load('assets/fonts/NotoSansArabic-Bold.ttf'),
        load('assets/images/madrasty_logo2.jpeg'),
      ]);
      return IdCardPdfAssets(
        regular: results[0],
        bold: results[1],
        arabicRegular: results[2],
        arabicBold: results[3],
        logo: results[4],
      );
    } catch (_) {
      _assets = null; // allow a retry instead of caching the failure
      rethrow;
    }
  }

  /// File name for a generated PDF — one person or a batch.
  static String fileName(List<IdCardData> cards, {DateTime? now}) {
    if (cards.length == 1) {
      final safe = cards.single.personId.replaceAll(
        RegExp(r'[^A-Za-z0-9_\-]'),
        '_',
      );
      return 'qr_card_$safe.pdf';
    }
    final d = now ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'qr_cards_${d.year}${two(d.month)}${two(d.day)}.pdf';
  }
}
