import 'dart:convert';
import 'dart:developer' as developer;

import 'package:share_plus/share_plus.dart';

class FileWriterService {
  Future<void> writeStringToFile(String data, String fileName) async {
    developer.log('[Web] File write skipped for $fileName');
  }

  Future<void> shareFile(String fileName) async {
    developer.log('[Web] Raw file sharing not available for $fileName');
  }

  Future<void> exportCsv(String csv, String displayName) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(csv),
              mimeType: 'text/csv',
              name: '${displayName}_export.csv',
            ),
          ],
          text: 'BreathState data: $displayName',
        ),
      );
    } catch (e) {
      developer.log('[Web] CSV export error: $e');
    }
  }

  Future<String> getFilePath(String fileName) async => '';
}
