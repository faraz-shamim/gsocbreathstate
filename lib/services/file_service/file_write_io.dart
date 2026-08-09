import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;
import 'package:share_plus/share_plus.dart';

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

  Future<void> exportCsv(String csv, String displayName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${displayName}_export.csv');
      await file.writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'BreathState data: $displayName',
        ),
      );
    } catch (e) {
      developer.log('Error exporting CSV: $e');
    }
  }

  Future<String> getFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName.txt';
  }
}
