// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;
import 'package:share_plus/share_plus.dart';

import 'export_result.dart';

class FileWriterService {
  Future<void> writeStringToFile(String data, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.txt');
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      await file.writeAsString('$data\n', mode: FileMode.append);
      developer.log('String data appended to file: ${file.path}');
    } catch (e) {
      developer.log('Error writing string to file: $e');
    }
  }

  Future<void> shareFile(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.txt';
      final file = File(filePath);
      if (await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(filePath)], text: 'Data file: $fileName'),
        );
      } else {
        developer.log('File not found: $filePath');
      }
    } catch (e) {
      developer.log('Error sharing file: $e');
    }
  }

  Future<CsvExportStatus> exportCsv(String csv, String displayName) async {
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/${sanitizedExportName(displayName)}_export.csv',
    );
    try {
      await file.writeAsString(csv, flush: true);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'BreathState data: ${sanitizedExportName(displayName)}',
        ),
      );
      return switch (result.status) {
        ShareResultStatus.success => CsvExportStatus.shared,
        ShareResultStatus.dismissed => CsvExportStatus.dismissed,
        ShareResultStatus.unavailable => CsvExportStatus.unavailable,
      };
    } catch (e) {
      developer.log('Error exporting CSV: $e');
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {
      }
      rethrow;
    }
  }

  Future<String> getFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName.txt';
  }
}
