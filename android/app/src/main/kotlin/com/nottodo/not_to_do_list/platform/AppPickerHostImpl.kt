package com.nottodo.not_to_do_list.platform

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Process
import androidx.core.graphics.drawable.toBitmap
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * Phase 2 Plan 02-03 implementation of AppPickerApi.
 *
 * All work runs on a private background Executor — never the UI thread
 * (T-2-06 mitigation: PackageManager + UsageStatsManager calls are I/O-bound
 * and would ANR if invoked on the main thread).
 *
 * Visibility scope: relies on the AndroidManifest.xml <queries> + LAUNCHER
 * intent filter declared in Phase 1. No broad-package-query permission is
 * requested (PLAY-04 invariant — the forbidden token is kept out of this
 * file so the V5 absence-grep stays exact).
 *
 * PLAY-02 invariant: this class MUST NEVER call any autonomous-action API
 * (performAction / performGlobalAction / dispatchGesture). The forbidden
 * tokens are deliberately kept out of this file so absence-greps stay exact.
 */
class AppPickerHostImpl(private val context: Context) : AppPickerApi {
    private val executor = Executors.newSingleThreadExecutor()

    override fun listInstalledApps(callback: (Result<List<InstalledApp>>) -> Unit) {
        executor.execute {
            try {
                val pm = context.packageManager
                val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                val launchablePackages = pm
                    .queryIntentActivities(launcherIntent, 0)
                    .map { it.activityInfo.packageName }
                    .toSet()
                val all = pm.getInstalledApplications(PackageManager.MATCH_DEFAULT_ONLY)
                    .map { ai ->
                        InstalledApp(
                            packageName = ai.packageName,
                            displayName = pm.getApplicationLabel(ai).toString(),
                            isSystemApp = (ai.flags and ApplicationInfo.FLAG_SYSTEM) != 0,
                            hasLauncherIntent = ai.packageName in launchablePackages,
                        )
                    }
                    .sortedBy { it.displayName.lowercase() }
                callback(Result.success(all))
            } catch (e: Throwable) {
                callback(Result.failure(e))
            }
        }
    }

    override fun recentlyUsedApps(daysBack: Long, callback: (Result<List<RecentApp>>) -> Unit) {
        executor.execute {
            try {
                // Gate on Usage Access — return emptyList() (NOT throw) when not granted
                // (RESEARCH §App Picker, Pitfall A). Caller's UI inline-prompts to grant.
                val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                val mode = appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName,
                )
                if (mode != AppOpsManager.MODE_ALLOWED) {
                    callback(Result.success(emptyList()))
                    return@execute
                }
                val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val now = System.currentTimeMillis()
                val start = now - (daysBack * 24L * 3600L * 1000L)
                val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, start, now) ?: emptyList()
                val recents = stats
                    .filter { it.totalTimeInForeground > 0L }
                    .sortedByDescending { it.totalTimeInForeground }
                    .take(20)
                    .map { RecentApp(packageName = it.packageName, totalForegroundSeconds = (it.totalTimeInForeground / 1000L)) }
                callback(Result.success(recents))
            } catch (e: Throwable) {
                callback(Result.failure(e))
            }
        }
    }

    override fun getApplicationIconPng(packageName: String, callback: (Result<ByteArray?>) -> Unit) {
        executor.execute {
            try {
                val drawable = context.packageManager.getApplicationIcon(packageName)
                val bitmap = drawable.toBitmap(96, 96)
                val bytes = ByteArrayOutputStream().apply {
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, this)
                }.toByteArray()
                callback(Result.success(bytes))
            } catch (e: PackageManager.NameNotFoundException) {
                callback(Result.success(null))
            } catch (e: Throwable) {
                callback(Result.failure(e))
            }
        }
    }
}
