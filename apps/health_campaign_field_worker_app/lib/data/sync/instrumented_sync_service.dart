import 'dart:async';

import 'package:digit_data_model/data_model.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sync_service/data/sync_service.dart';
import 'package:sync_service/models/bandwidth/bandwidth_model.dart';

import '../../exceptions/sync_diagnostic_exception.dart';
import '../../utils/environment_config.dart';
import '../../utils/sync_failure_reporter.dart';

/// Wraps [SyncService.performSync] to record failures for the sync-failed UI and logcat.
///
/// **Compile-time:** `--dart-define=FORCE_SYNC_DIAGNOSTIC=true` — synthetic failure before sync.
///
/// **`.env` QA toggles** (after [envConfig.initialize]):
/// - `SYNC_DIAGNOSTIC_FAIL=true` — synthetic app [SyncDiagnosticException] (dialog only).
/// - `SYNC_PACKAGE_TYPED_EXCEPTIONS=true` — enables [SyncService.throwDiagnosticExceptionOnSyncFailure]
///   for each root sync so sync-up failures throw [SyncServiceDiagnosticException] from the package.
///
/// **One-shot:** [SyncFailureReporter.simulateFailureOnNextSync] = `true` then sync once.
class InstrumentedSyncService extends SyncService {
  static const bool _forceDiagnostic = bool.fromEnvironment(
    'FORCE_SYNC_DIAGNOSTIC',
    defaultValue: false,
  );

  /// Nesting depth for recursive [SyncService.performSync] calls.
  static int _performSyncDepth = 0;

  static Future<(int, int)> _pendingUpDownCounts({
    required List<LocalRepository> localRepositories,
    required String userId,
  }) async {
    final downFutures = await Future.wait(
      localRepositories.map((e) => e.getItemsToBeSyncedDown(userId)),
    );
    final upFutures = await Future.wait(
      localRepositories.map((e) => e.getItemsToBeSyncedUp(userId)),
    );
    final down = downFutures.expand((e) => e).length;
    final up = upFutures.expand((e) => e).length;
    return (down, up);
  }

  static bool _readEnvDiagnosticFail() {
    try {
      return envConfig.variables.syncDiagnosticFail;
    } catch (_) {
      return false;
    }
  }

  static bool _readPackageTypedExceptionsEnv() {
    try {
      return envConfig.variables.syncPackageTypedExceptions;
    } catch (_) {
      return false;
    }
  }

  @override
  FutureOr<bool> performSync({
    required List<LocalRepository> localRepositories,
    required List<RemoteRepository> remoteRepositories,
    required BandwidthModel bandwidthModel,
    ServiceInstance? service,
  }) async {
    final isRoot = _performSyncDepth == 0;
    _performSyncDepth++;
    var restorePackageTypedExceptions = false;
    try {
      if (isRoot) {
        final (down, up) = await _pendingUpDownCounts(
          localRepositories: localRepositories,
          userId: bandwidthModel.userId,
        );
        SyncFailureReporter.instance.rootSyncHadPendingWork = down > 0 || up > 0;
        restorePackageTypedExceptions = _readPackageTypedExceptionsEnv();
        if (restorePackageTypedExceptions) {
          SyncService.throwDiagnosticExceptionOnSyncFailure = true;
        }
      }

      if (_forceDiagnostic && isRoot) {
        final err = SyncDiagnosticException(
          'FORCE_SYNC_DIAGNOSTIC is enabled (dart-define). '
          'Remove for production builds.',
        );
        SyncFailureReporter.instance.record(
          err,
          StackTrace.current,
          const {'kind': 'synthetic', 'reason': 'FORCE_SYNC_DIAGNOSTIC'},
        );
        throw err;
      }
      if (SyncFailureReporter.simulateFailureOnNextSync && isRoot) {
        SyncFailureReporter.simulateFailureOnNextSync = false;
        final err = SyncDiagnosticException(
          'Simulated failure (SyncFailureReporter.simulateFailureOnNextSync).',
        );
        SyncFailureReporter.instance.record(
          err,
          StackTrace.current,
          const {'kind': 'synthetic', 'reason': 'simulateFailureOnNextSync'},
        );
        throw err;
      }
      if (_readEnvDiagnosticFail() && isRoot) {
        final err = SyncDiagnosticException(
          'SYNC_DIAGNOSTIC_FAIL=true in .env (remove for production).',
        );
        SyncFailureReporter.instance.record(
          err,
          StackTrace.current,
          const {'kind': 'synthetic', 'reason': 'SYNC_DIAGNOSTIC_FAIL_env'},
        );
        throw err;
      }

      try {
        return await super.performSync(
          localRepositories: localRepositories,
          remoteRepositories: remoteRepositories,
          bandwidthModel: bandwidthModel,
          service: service,
        );
      } catch (e, st) {
        SyncFailureReporter.instance.record(
          e,
          st,
          {
            'kind': 'real_sync_failure',
            'sync_layer': 'InstrumentedSyncService',
            'performSync_root': '$isRoot',
            'phase': 'after_package_performSync',
          },
        );
        rethrow;
      }
    } finally {
      if (isRoot && restorePackageTypedExceptions) {
        SyncService.throwDiagnosticExceptionOnSyncFailure = false;
      }
      _performSyncDepth--;
    }
  }
}
