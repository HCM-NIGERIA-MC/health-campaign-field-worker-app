/// Thrown when [SyncFailureReporter.simulateFailureOnNextSync] is used or when
/// built with `--dart-define=FORCE_SYNC_DIAGNOSTIC=true` (see [InstrumentedSyncService]).
class SyncDiagnosticException implements Exception {
  SyncDiagnosticException([this.message = 'Synthetic sync diagnostic failure.']);

  final String message;

  @override
  String toString() => 'SyncDiagnosticException: $message';
}
