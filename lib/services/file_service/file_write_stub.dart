// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:share_plus/share_plus.dart';

import 'export_result.dart';

class FileWriterService {
  Future<void> writeStringToFile(String data, String fileName) async {
    developer.log('[Web] File write skipped for $fileName');
  }

  Future<void> shareFile(String fileName) async {
    developer.log('[Web] Raw file sharing not available for $fileName');
  }

  Future<CsvExportStatus> exportCsv(String csv, String displayName) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(csv),
            mimeType: 'text/csv',
            name: '${sanitizedExportName(displayName)}_export.csv',
          ),
        ],
        text: 'BreathState data: ${sanitizedExportName(displayName)}',
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => CsvExportStatus.shared,
      ShareResultStatus.dismissed => CsvExportStatus.dismissed,
      ShareResultStatus.unavailable => CsvExportStatus.unavailable,
    };
  }

  Future<String> getFilePath(String fileName) async => '';
}
