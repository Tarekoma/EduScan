import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Thin wrapper over the platform file pick / share plugins so features depend
/// on an interface, not the plugins directly.
abstract interface class FileService {
  /// Lets the user pick a spreadsheet; returns its bytes, or null if cancelled.
  Future<Uint8List?> pickSpreadsheet();

  /// Hands the user a generated file to save / send.
  Future<void> shareBytes(Uint8List bytes, String filename);

  /// Lets the user choose where to save a generated PDF. Returns false if the
  /// user cancelled.
  Future<bool> savePdf(Uint8List bytes, String filename);
}

class PlatformFileService implements FileService {
  const PlatformFileService();

  @override
  Future<Uint8List?> pickSpreadsheet() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    return result?.files.single.bytes;
  }

  @override
  Future<void> shareBytes(Uint8List bytes, String filename) async {
    // share_plus has no real share target on desktop, so let the user pick a
    // save location there instead of silently sending just the filename.
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final extension = filename.contains('.') ? filename.split('.').last : null;
      final path = await FilePicker.platform.saveFile(
        dialogTitle: filename,
        fileName: filename,
        type: extension == null ? FileType.any : FileType.custom,
        allowedExtensions: extension == null ? null : [extension],
        bytes: bytes,
      );
      if (path != null) {
        await File(path).writeAsBytes(bytes, flush: true);
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], subject: filename);
  }

  @override
  Future<bool> savePdf(Uint8List bytes, String filename) async {
    // Mobile/web plugins write [bytes] themselves; on desktop the picker only
    // returns the chosen path, so the file must be written here.
    final path = await FilePicker.platform.saveFile(
      dialogTitle: filename,
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );
    if (path == null) return false;
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return true;
  }
}
