import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/entities/id_card_data.dart';

/// Font / image bytes the PDF needs. Kept as plain bytes so the whole build
/// can run in a background isolate.
class IdCardPdfAssets {
  const IdCardPdfAssets({
    required this.regular,
    required this.bold,
    required this.arabicRegular,
    required this.arabicBold,
    required this.logo,
  });

  final Uint8List regular;
  final Uint8List bold;
  final Uint8List arabicRegular;
  final Uint8List arabicBold;
  final Uint8List logo;
}

/// A line of text to be drawn by the PDF, described independently of how it is
/// rendered.
class CardTextSpec {
  const CardTextSpec({
    required this.text,
    required this.size,
    required this.color,
    this.bold = false,
    this.maxLines = 1,
    this.maxWidthPt = IdCardPdfBuilder.textWidthPt,
  });

  final String text;
  final double size;
  final int color; // ARGB
  final bool bold;
  final int maxLines;
  final double maxWidthPt;

  String get key => '$size|$bold|$color|$maxLines|$text';
}

/// Pre-rendered image of a text line (see `ArabicTextRenderer`), sized in PDF
/// points.
class CardTextImage {
  const CardTextImage({
    required this.png,
    required this.widthPt,
    required this.heightPt,
  });

  final Uint8List png;
  final double widthPt;
  final double heightPt;
}

/// Lays ID cards out on landscape A4 sheets (4 x 2 = 8 cards) for printing and
/// cutting.
///
/// The QR is drawn as vector graphics (not a bitmap), so it stays perfectly
/// sharp at any print resolution. Its payload is exactly
/// [IdCardData.qrValue] with the same error-correction level (M) as the
/// on-screen QR.
abstract final class IdCardPdfBuilder {
  // Physical sizes, in millimetres.
  static const double cardWidthMm = 54;
  static const double cardHeightMm = 86;
  static const double gapMm = 6;
  static const double pageMarginMm = 10;
  static const double _headerHeightMm = 10;
  static const double _qrBoxMm = 38;
  static const double _qrQuietZoneMm = 2.5;

  /// Width available for text inside a card.
  static const double textWidthPt = (cardWidthMm - 6) * PdfPageFormat.mm;

  static final PdfPageFormat pageFormat = PdfPageFormat.a4.landscape;

  static const int _brandArgb = 0xFF0B3B6F;
  static const int _mutedArgb = 0xFF4B5563;
  static const PdfColor _brand = PdfColor.fromInt(_brandArgb);
  static const PdfColor _outline = PdfColor.fromInt(0xFF9CA3AF);

  /// Cards that fit across the printable width.
  static int get columns => _fit(pageFormat.width, cardWidthMm);

  /// Cards that fit down the printable height.
  static int get rows => _fit(pageFormat.height, cardHeightMm);

  static int get cardsPerPage => columns * rows;

  static int _fit(double pageLengthPt, double cardMm) {
    final usable = pageLengthPt / PdfPageFormat.mm - 2 * pageMarginMm;
    return ((usable + gapMm) / (cardMm + gapMm)).floor();
  }

  static final RegExp _arabic = RegExp(r'[֐-ࣿ]');

  static bool needsImage(String text) => _arabic.hasMatch(text);

  static CardTextSpec _typeSpec(IdCardData card) => CardTextSpec(
    text: card.typeLabel,
    size: 10,
    color: 0xFFFFFFFF,
    bold: true,
    maxWidthPt: 30 * PdfPageFormat.mm,
  );

  static CardTextSpec _nameSpec(IdCardData card) => CardTextSpec(
    text: card.fullName,
    size: _nameSize(card.fullName),
    color: 0xFF000000,
    bold: true,
    maxLines: 2,
  );

  static CardTextSpec _detailSpec(String detail) =>
      CardTextSpec(text: detail, size: 9, color: _mutedArgb);

  /// Text lines on [card] that contain Arabic. The PDF library reorders
  /// right-to-left text but cannot join Arabic letters, so these lines are
  /// rendered to images by Flutter's text engine instead.
  static List<CardTextSpec> arabicSpecs(IdCardData card) {
    final detail = card.detail?.trim() ?? '';
    return [
      if (needsImage(card.typeLabel)) _typeSpec(card),
      if (needsImage(card.fullName)) _nameSpec(card),
      if (needsImage(detail)) _detailSpec(detail),
    ];
  }

  /// Builds the PDF off the UI thread. [textImages] maps
  /// [CardTextSpec.key] to its rendered image.
  static Future<Uint8List> build(
    List<IdCardData> cards,
    IdCardPdfAssets assets, {
    Map<String, CardTextImage> textImages = const {},
  }) {
    if (cards.isEmpty) {
      throw ArgumentError.value(cards, 'cards', 'must not be empty');
    }
    return compute(_buildSync, (
      cards: cards,
      assets: assets,
      textImages: textImages,
    ));
  }

  static Future<Uint8List> _buildSync(
    ({
      List<IdCardData> cards,
      IdCardPdfAssets assets,
      Map<String, CardTextImage> textImages,
    })
    request,
  ) {
    final assets = request.assets;
    final arabicRegular = pw.Font.ttf(
      ByteData.sublistView(assets.arabicRegular),
    );
    final arabicBold = pw.Font.ttf(ByteData.sublistView(assets.arabicBold));
    final theme = pw.ThemeData.withFont(
      base: pw.Font.ttf(ByteData.sublistView(assets.regular)),
      bold: pw.Font.ttf(ByteData.sublistView(assets.bold)),
      fontFallback: [arabicRegular],
    );
    final fonts = _Fonts(
      logo: pw.MemoryImage(assets.logo),
      regularFallback: [arabicRegular],
      boldFallback: [arabicBold],
      textImages: {
        for (final e in request.textImages.entries)
          e.key: (
            pw.MemoryImage(e.value.png),
            e.value.widthPt,
            e.value.heightPt,
          ),
      },
    );

    final doc = pw.Document(
      title: 'QR ID cards',
      creator: 'Madrasty',
      theme: theme,
    );

    final perPage = cardsPerPage;
    for (var start = 0; start < request.cards.length; start += perPage) {
      final pageCards = request.cards.skip(start).take(perPage).toList();
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(pageMarginMm * PdfPageFormat.mm),
          build: (_) => pw.Align(
            alignment: pw.Alignment.topCenter,
            child: _grid(pageCards, fonts),
          ),
        ),
      );
    }
    return doc.save();
  }

  static pw.Widget _grid(List<IdCardData> cards, _Fonts fonts) {
    const gap = gapMm * PdfPageFormat.mm;
    final rowWidgets = <pw.Widget>[];
    for (var i = 0; i < cards.length; i += columns) {
      final children = <pw.Widget>[];
      for (var c = 0; c < columns; c++) {
        if (c > 0) children.add(pw.SizedBox(width: gap));
        children.add(
          i + c < cards.length
              ? _card(cards[i + c], fonts)
              : pw.SizedBox(
                  width: cardWidthMm * PdfPageFormat.mm,
                  height: cardHeightMm * PdfPageFormat.mm,
                ),
        );
      }
      if (rowWidgets.isNotEmpty) rowWidgets.add(pw.SizedBox(height: gap));
      rowWidgets.add(
        pw.Row(mainAxisSize: pw.MainAxisSize.min, children: children),
      );
    }
    return pw.Column(mainAxisSize: pw.MainAxisSize.min, children: rowWidgets);
  }

  static pw.Widget _card(IdCardData card, _Fonts fonts) {
    const mm = PdfPageFormat.mm;
    final detail = card.detail?.trim();
    return pw.Container(
      width: cardWidthMm * mm,
      height: cardHeightMm * mm,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _outline, width: 0.5),
        borderRadius: pw.BorderRadius.circular(3 * mm),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 3 * mm,
        verticalRadius: 3 * mm,
        child: pw.Column(
          children: [
            pw.Container(
              height: _headerHeightMm * mm,
              color: _brand,
              child: pw.Center(
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Image(fonts.logo, width: 6.5 * mm, height: 6.5 * mm),
                    pw.SizedBox(width: 2 * mm),
                    fonts.imageFor(_typeSpec(card)) ??
                        pw.Text(
                          card.typeLabel,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            fontFallback: fonts.boldFallback,
                            letterSpacing: 1,
                          ),
                        ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 4 * mm),
            // White quiet zone around the QR keeps it scannable on any stock.
            pw.Container(
              width: _qrBoxMm * mm,
              height: _qrBoxMm * mm,
              color: PdfColors.white,
              padding: const pw.EdgeInsets.all(_qrQuietZoneMm * mm),
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(
                  errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
                ),
                data: card.qrValue,
                drawText: false,
                color: PdfColors.black,
              ),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 3 * mm),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _text(_nameSpec(card), fonts),
                    pw.SizedBox(height: 1.5 * mm),
                    _text(
                      CardTextSpec(
                        text: card.personId,
                        size: 10,
                        color: _brandArgb,
                        bold: true,
                      ),
                      fonts,
                    ),
                    if (detail != null && detail.isNotEmpty) ...[
                      pw.SizedBox(height: 1 * mm),
                      _text(_detailSpec(detail), fonts),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _nameSize(String name) {
    final n = name.length;
    if (n <= 24) return 12;
    if (n <= 36) return 10.5;
    return 9;
  }

  static pw.Widget _text(CardTextSpec spec, _Fonts fonts) {
    return fonts.imageFor(spec) ??
        pw.Text(
          spec.text,
          textAlign: pw.TextAlign.center,
          maxLines: spec.maxLines,
          style: pw.TextStyle(
            fontSize: spec.size,
            color: PdfColor.fromInt(spec.color),
            fontWeight: spec.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontFallback: spec.bold
                ? fonts.boldFallback
                : fonts.regularFallback,
          ),
        );
  }
}

/// Per-document resources shared by every card.
class _Fonts {
  const _Fonts({
    required this.logo,
    required this.regularFallback,
    required this.boldFallback,
    required this.textImages,
  });

  final pw.ImageProvider logo;
  final List<pw.Font> regularFallback;
  final List<pw.Font> boldFallback;
  final Map<String, (pw.ImageProvider, double, double)> textImages;

  /// The pre-rendered image for [spec], if one was supplied.
  pw.Widget? imageFor(CardTextSpec spec) {
    if (!IdCardPdfBuilder.needsImage(spec.text)) return null;
    final entry = textImages[spec.key];
    if (entry == null) return null;
    return pw.Image(entry.$1, width: entry.$2, height: entry.$3);
  }
}
