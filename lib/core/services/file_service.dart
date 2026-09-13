import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Thin wrapper over the platform file pick / share plugins so features depend
/// on an interface, not the plugins directly.
abstract interface class FileService {
  /// Lets the user pick a spreadsheet; returns its bytes, or null if cancelled.
  Future<Uint8List?> pickSpreadsheet();

  /// Hands the user a generated file to save / send.
  Future<void> shareBytes(Uint8List bytes, String filename);
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
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], subject: filename);
  }
}
