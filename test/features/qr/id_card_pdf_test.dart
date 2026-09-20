import 'dart:io';

import 'package:attendance_management/features/qr/data/id_card_pdf_builder.dart';
import 'package:attendance_management/features/qr/data/id_card_pdf_service.dart';
import 'package:attendance_management/features/qr/domain/entities/id_card_data.dart';
import 'package:flutter_test/flutter_test.dart';

IdCardData _card(int i, {String? name, String? detail, String? type}) =>
    IdCardData(
      personId: 'STU_${i.toString().padLeft(5, '0')}',
      fullName: name ?? 'Student Number $i',
      qrValue: 'qr-token-$i',
      typeLabel: type ?? 'STUDENT',
      detail: detail ?? 'Class 5A',
    );

int _pageCount(List<int> bytes) =>
    RegExp(r'/Type\s*/Page\b').allMatches(String.fromCharCodes(bytes)).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('landscape A4 fits 4 x 2 = 8 cards of 54 x 86 mm', () {
    expect(
      IdCardPdfBuilder.pageFormat.width > IdCardPdfBuilder.pageFormat.height,
      isTrue,
    );
    expect(IdCardPdfBuilder.columns, 4);
    expect(IdCardPdfBuilder.rows, 2);
    expect(IdCardPdfBuilder.cardsPerPage, 8);
  });

  test('paginates eight cards per sheet and supports Arabic', () async {
    final service = IdCardPdfService();
    final cards = [
      for (var i = 1; i <= 8; i++) _card(i),
      _card(9, name: 'ادم خالد عبدالرازق', detail: 'الفصل ٥أ', type: 'طالب'),
    ];
    final bytes = await service.generate(cards);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(_pageCount(bytes), 2);
    final out = Platform.environment['CARD_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });

  test('eight cards fit exactly one sheet', () async {
    final bytes = await IdCardPdfService().generate([
      for (var i = 1; i <= 8; i++) _card(i),
    ]);
    expect(_pageCount(bytes), 1);
  });

  test('single card yields one page; empty list is rejected', () async {
    final service = IdCardPdfService();
    expect(_pageCount(await service.generate([_card(1)])), 1);
    expect(() => service.generate(const []), throwsArgumentError);
  });

  test('file names are safe and descriptive', () {
    expect(IdCardPdfService.fileName([_card(144)]), 'qr_card_STU_00144.pdf');
    expect(
      IdCardPdfService.fileName([
        _card(1),
        _card(2),
      ], now: DateTime(2026, 9, 5)),
      'qr_cards_20260905.pdf',
    );
  });

  test('reports progress while rendering Arabic text', () async {
    final steps = <(int, int)>[];
    await IdCardPdfService().generate([
      _card(1, name: 'ادم خالد', detail: 'الفصل أ', type: 'طالب'),
      _card(2, name: 'سارة علي', detail: 'الفصل أ', type: 'طالب'),
    ], onProgress: (done, total) => steps.add((done, total)));
    expect(steps, isNotEmpty);
    expect(steps.last.$1, steps.last.$2);
    expect(
      steps.map((s) => s.$1),
      orderedEquals(List.generate(steps.length, (i) => i + 1)),
    );
  });
}
