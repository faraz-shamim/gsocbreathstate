import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor connectDatabase() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'breathstate_v2',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}