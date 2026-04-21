import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:sync_service/data/sync_service.dart';

/// Holds the last sync error so the UI can show it when [SyncBloc] reports failure.
class SyncFailureReporter {
  SyncFailureReporter._();

  static final SyncFailureReporter instance = SyncFailureReporter._();

  static final _log = Logger(
    printer:
        PrettyPrinter(methodCount: 0, errorMethodCount: 8, lineLength: 120),
  );

  /// When set to `true`, the next root [InstrumentedSyncService.performSync] throws
  /// [SyncDiagnosticException] once (then resets to `false`) to verify the failure dialog.
  static bool simulateFailureOnNextSync = false;

  Object? lastError;
  StackTrace? lastStackTrace;
  DateTime? lastRecordedAt;

  /// Optional key/values from the app when [record] runs (e.g. where in app code).
  Map<String, String>? lastClientContext;

  /// Set only for the **root** [InstrumentedSyncService.performSync] call: whether
  /// any pending up/down rows existed before sync ran. Used to avoid showing
  /// "data synced" when there was nothing to sync.
  bool? rootSyncHadPendingWork;

  static const int _maxResponseBodyChars = 4000;

  /// Stack lines matching these substrings are shown first under "Your app code".
  /// Add feature packages you own (e.g. internal plugins) if needed.
  static const List<String> _appCodePackageHints = [
    'package:health_campaign_field_worker_app/',
  ];

  static const int _maxOtherStackFrames = 28;

  /// Records a failure. [clientContext] should be field-safe (no secrets): e.g. where in app sync ran.
  void record(
    Object error, [
    StackTrace? stackTrace,
    Map<String, String>? clientContext,
  ]) {
    lastError = error;
    lastStackTrace = stackTrace;
    lastRecordedAt = DateTime.now();
    lastClientContext = clientContext;
    _log.e(
      'Sync failure captured',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _truncate(String s, int maxChars) {
    if (s.length <= maxChars) return s;
    return '${s.substring(0, maxChars)}…\n[truncated, ${s.length - maxChars} more chars]';
  }

  static String _stringifyForSupport(Object? data) {
    if (data == null) return '(null)';
    if (data is String) return data;
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (_) {}
    return data.toString();
  }

  /// Hides absolute dev-machine paths; keeps `package:...` lines intact (what you need on client devices).
  static String _sanitizeStackLine(String line) {
    var s = line.trimRight();
    s = s.replaceAllMapped(
      RegExp(r'file:///[^\s\)\]]+'),
      (_) => '<file>',
    );
    s = s.replaceAllMapped(
      RegExp(r'\(/?(?:Users|home|Android|data)/[^)]{4,300}\)'),
      (_) => '(<path>)',
    );
    return s;
  }

  static bool _isAppCodeFrame(String line) {
    final l = line.trim();
    return _appCodePackageHints.any((h) => l.contains(h));
  }

  /// Puts frames that reference [health_campaign_field_worker_app] first so support
  /// knows which **your** source file to open — not pub-cache / third-party noise.
  static String _formatStackTraceForClientDiagnosis(StackTrace st) {
    final raw = st.toString();
    final lines = raw.split('\n').map(_sanitizeStackLine).where((l) => l.trim().isNotEmpty).toList();
    final appFrames = <String>[];
    final otherFrames = <String>[];
    for (final line in lines) {
      if (_isAppCodeFrame(line)) {
        appFrames.add(line.trim());
      } else {
        otherFrames.add(line.trim());
      }
    }
    final out = StringBuffer();
    if (appFrames.isNotEmpty) {
      out.writeln('--- your app code (open these in the repo first) ---');
      for (final f in appFrames) {
        out.writeln(f);
      }
      out.writeln('');
    } else {
      out.writeln(
        '(no frames from package:health_campaign_field_worker_app in this trace — failure may originate in a plugin or native code)',
      );
      out.writeln('');
    }
    out.writeln('--- other frames (Flutter / packages / engine) ---');
    final show = otherFrames.length > _maxOtherStackFrames
        ? otherFrames.take(_maxOtherStackFrames).toList()
        : otherFrames;
    for (final f in show) {
      out.writeln(f);
    }
    if (otherFrames.length > _maxOtherStackFrames) {
      out.writeln(
        '… ${otherFrames.length - _maxOtherStackFrames} more lines omitted',
      );
    }
    return out.toString();
  }

  static void _appendDioException(StringBuffer buf, DioException e) {
    buf.writeln('DioException [${e.type.name}]');
    buf.writeln('Message: ${e.message ?? '(none)'}');
    final req = e.requestOptions;
    buf.writeln('HTTP: ${req.method} ${req.uri}');
    final hdrs = req.headers;
    if (hdrs.isNotEmpty) {
      final safeHeaders = Map<String, dynamic>.from(hdrs);
      for (final k in List<String>.from(safeHeaders.keys)) {
        if (k.toLowerCase() == 'authorization' && safeHeaders[k] != null) {
          safeHeaders[k] = '[redacted]';
        }
      }
      buf.writeln('Request headers: $safeHeaders');
    }
    final res = e.response;
    if (res != null) {
      buf.writeln('HTTP status: ${res.statusCode}');
      buf.writeln(
        'Response body:\n${_truncate(_stringifyForSupport(res.data), _maxResponseBodyChars)}',
      );
    } else {
      buf.writeln('(no HTTP response — network / timeout / cancel)');
    }
    final c = e.error;
    if (c != null && c is! DioException) {
      buf.writeln('Wrapped error: $c');
    }
  }

  static String _syncErrorTitle(SyncError o) {
    if (o is SyncUpError) {
      return 'SyncUpError (data could not be uploaded to the server)';
    }
    if (o is SyncDownError) {
      return 'SyncDownError (data could not be downloaded from the server)';
    }
    return o.runtimeType.toString();
  }

  static void _appendErrorDetails(StringBuffer buf, Object o) {
    if (o is DioException) {
      _appendDioException(buf, o);
      return;
    }
    if (o is SyncServiceDiagnosticException) {
      buf.writeln(o.message);
      buf.writeln('--- wrapped sync error ---');
      _appendErrorDetails(buf, o.cause);
      return;
    }
    if (o is SyncError) {
      buf.writeln(_syncErrorTitle(o));
      final inner = o.error;
      if (inner != null) {
        buf.writeln('');
        buf.writeln('Root cause:');
        _appendErrorDetails(buf, inner as Object);
      }
      return;
    }
    buf.writeln(o.toString());
  }

  void clear() {
    lastError = null;
    lastStackTrace = null;
    lastRecordedAt = null;
    lastClientContext = null;
    rootSyncHadPendingWork = null;
  }

  /// Text shown under the user-facing title on the sync failed dialog.
  String get detailText {
    if (lastError == null) {
      return 'No technical details were captured for this attempt. '
          'If the problem continues, share a screen recording or the approximate time '
          'with support.';
    }
    final buf = StringBuffer();
    if (lastRecordedAt != null) {
      buf.writeln('Time: ${lastRecordedAt!.toIso8601String()}');
      buf.writeln();
    }
    final ctx = lastClientContext;
    if (ctx != null && ctx.isNotEmpty) {
      buf.writeln('--- app sync context (field / client) ---');
      ctx.forEach((k, v) {
        buf.writeln('$k: $v');
      });
      buf.writeln();
    }
    _appendErrorDetails(buf, lastError!);
    if (lastStackTrace != null) {
      buf.writeln();
      buf.writeln(_formatStackTraceForClientDiagnosis(lastStackTrace!));
    }
    return buf.toString();
  }
}
