import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'id_card_pdf_builder.dart';

/// Renders Arabic text lines to transparent PNGs using Flutter's text engine,
/// which shapes and joins Arabic correctly (the `pdf` package cannot).
///
/// Lines are drawn at [_scale] pixels per PDF point (~720 dpi) so they stay
/// crisp when printed.
class ArabicTextRenderer {
  ArabicTextRenderer({
    required Uint8List regularFont,
    required Uint8List boldFont,
  }) : _regularFont = regularFont,
       _boldFont = boldFont;

  static const double _scale = 10;
  static const String _regularFamily = 'CardNotoSansArabic';
  static const String _boldFamily = 'CardNotoSansArabicBold';

  final Uint8List _regularFont;
  final Uint8List _boldFont;
  Future<void>? _fontsLoaded;

  Future<void> _loadFonts() => _fontsLoaded ??= () async {
    Future<void> load(String family, Uint8List bytes) {
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      return loader.load();
    }

    await load(_regularFamily, _regularFont);
    await load(_boldFamily, _boldFont);
  }();

  Future<CardTextImage> render(CardTextSpec spec) async {
    await _loadFonts();
    final painter = TextPainter(
      text: TextSpan(
        text: spec.text,
        style: TextStyle(
          fontFamily: spec.bold ? _boldFamily : _regularFamily,
          fontSize: spec.size * _scale,
          color: ui.Color(spec.color),
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      maxLines: spec.maxLines,
      ellipsis: '…',
    )..layout(maxWidth: spec.maxWidthPt * _scale);

    final width = painter.width.ceil();
    final height = painter.height.ceil();
    final recorder = ui.PictureRecorder();
    painter.paint(ui.Canvas(recorder), ui.Offset.zero);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return CardTextImage(
        png: data!.buffer.asUint8List(),
        widthPt: width / _scale,
        heightPt: height / _scale,
      );
    } finally {
      image.dispose();
      picture.dispose();
      painter.dispose();
    }
  }
}
