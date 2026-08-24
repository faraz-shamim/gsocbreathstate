// SPDX-License-Identifier: AGPL-3.0-only
enum CsvExportStatus { shared, dismissed, unavailable }

String sanitizedExportName(String displayName) {
  final sanitized = displayName
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return sanitized.isEmpty ? 'breathstate_data' : sanitized;
}
