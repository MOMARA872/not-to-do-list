package com.nottodo.not_to_do_list.platform

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Process
import java.util.concurrent.Executors

/**
 * Phase 3 implementation of UsageApi (DASH-01).
 *
 * Runs on a private background Executor — never the UI thread (D-02;
 * PITFALLS.md anti-pattern #3: queryUsageStats drops frames if called
 * on the main thread).
 *
 * AppOps gate (D-03): on MODE_ALLOWED != mode, returns USAGE_ACCESS_DENIED
 * via UsageApiError so Dart routes to the no-permission fallback (D-13).
 *
 * Locked-device handling (D-04): Android R+ queryUsageStats can return null
 * silently when the device is locked, or surface SecurityException past the
 * AppOps gate. Both paths return an empty list — the dashboard shows the
 * cached snapshot rather than crashing.
 *
 * INTERVAL_DAILY produces day-bucketed totals; multiple buckets per package
 * are summed and grouped. launchCount is filled with 0 (research A5: the
 * INTERVAL_DAILY UsageStats API does not surface a meaningful launch count;
 * Phase 5 will switch to queryEvents if STRK needs accurate counts).
 *
 * PLAY-02 invariant: this class MUST NEVER call any autonomous-action API.
 * The forbidden tokens are deliberately kept out of this file body so the
 * absence-greps in test/policy/play_invariants_test.dart stay exact.
 */
class UsageApiImpl(private val context: Context) : UsageApi {
    private val executor = Executors.newSingleThreadExecutor()

    override fun queryRange(
        startEpochMs: Long,
        endEpochMs: Long,
        callback: (Result<List<UsagePackageStat>>) -> Unit,
    ) {
        executor.execute {
            try {
                // AppOps gate (D-03). Same idiom as PermissionStatusApiImpl.kt
                // lines 32-36 + AppPickerHostImpl.kt lines 65-74.
                val appOps = context.getSystemService(Context.APP_OPS_SERVICE)
                    as AppOpsManager
                val mode = appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName,
                )
                if (mode != AppOpsManager.MODE_ALLOWED) {
                    callback(
                        Result.failure(
                            UsageApiError(
                                code = "USAGE_ACCESS_DENIED",
                                message = "PACKAGE_USAGE_STATS not granted",
                            ),
                        ),
                    )
                    return@execute
                }

                val usm = context.getSystemService(Context.USAGE_STATS_SERVICE)
                    as UsageStatsManager

                // INTERVAL_DAILY = day-bucketed aggregates. queryUsageStats
                // returns null on Android R+ when the device is locked
                // (PITFALLS.md L313). Treat null as empty list (D-04).
                val raw = usm.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    startEpochMs,
                    endEpochMs,
                ) ?: emptyList()

                // Sum totalTimeInForeground (ms) -> seconds, group by package.
                // Multiple buckets can return for the same package across day
                // boundaries within the requested window — coalesce them.
                val grouped = raw
                    .filter { it.totalTimeInForeground > 0L }
                    .groupBy { it.packageName }
                    .map { (pkg, list) ->
                        UsagePackageStat(
                            packageName = pkg,
                            foregroundSeconds = list.sumOf {
                                it.totalTimeInForeground
                            } / 1000L,
                            // INTERVAL_DAILY UsageStats lacks a meaningful
                            // launchCount; fill with 0 (research A5).
                            launchCount = 0L,
                        )
                    }
                callback(Result.success(grouped))
            } catch (e: SecurityException) {
                // Android R+ locked-device occasionally surfaces
                // SecurityException even past the AppOps gate. Treat as
                // transient (D-04).
                callback(Result.success(emptyList()))
            } catch (e: Throwable) {
                callback(Result.failure(e))
            }
        }
    }
}
