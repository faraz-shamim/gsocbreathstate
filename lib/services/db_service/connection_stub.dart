// SPDX-License-Identifier: AGPL-3.0-only
import 'package:drift/drift.dart';

QueryExecutor connectDatabase() {
  throw UnsupportedError(
    'No suitable database implementation for this platform.',
  );
}