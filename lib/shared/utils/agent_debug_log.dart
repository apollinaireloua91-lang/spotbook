import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Logs de debug session (NDJSON). Ne pas logger de secrets ni PII.
// #region agent log
const String _agentDebugSessionId = '4a1921';
const String _agentDebugNdjsonPath =
    '/Users/louq/Desktop/spotbook/.cursor/debug-4a1921.log';

void agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?> data = const {},
  String runId = 'pre-fix',
}) {
  final payload = <String, Object?>{
    'sessionId': _agentDebugSessionId,
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final line = '${jsonEncode(payload)}\n';
  if (kDebugMode) {
    debugPrint('[SPOTBOOK_DEBUG_NDJSON]$line'.trimRight());
  }
  if (!kIsWeb) {
    try {
      File(_agentDebugNdjsonPath).writeAsStringSync(
        line,
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }
  Future<void>.microtask(() async {
    try {
      await http.post(
        Uri.parse(
          'http://127.0.0.1:7396/ingest/82466da8-88b3-44c5-8b69-fd3998f0dd8f',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': _agentDebugSessionId,
        },
        body: jsonEncode(payload),
      );
    } catch (_) {}
  });
}
// #endregion
