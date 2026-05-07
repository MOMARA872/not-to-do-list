package com.nottodo.not_to_do_list.platform

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import com.nottodo.not_to_do_list.service.NotToDoAccessibilityService

/**
 * Phase 2 Plan 02-03 implementation of PermissionStatusApi.
 *
 * Status checks are I/O-light (single system-service lookups) — they run on
 * the Pigeon dispatcher thread without explicit Executor. Settings deep-link
 * launches use a `resolveActivity(pm) != null` guard before `startActivity`
 * (T-2-02 mitigation: no implicit-intent spoofing — Android intent resolver
 * is the trust boundary, and we only ever fire Settings.ACTION_* actions).
 *
 * PLAY-02 invariant: this class MUST NEVER call any autonomous-action API.
 * The forbidden tokens are kept out of this file so absence-greps stay exact.
 */
class PermissionStatusApiImpl(private val context: Context) : PermissionStatusApi {
    override fun isUsageAccessGranted(callback: (Result<Boolean>) -> Unit) {
        try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
            callback(Result.success(mode == AppOpsManager.MODE_ALLOWED))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }

    override fun isAccessibilityServiceEnabled(callback: (Result<Boolean>) -> Unit) {
        try {
            val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
            val target = ComponentName(context, NotToDoAccessibilityService::class.java).flattenToString()
            val enabled = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK).any {
                val si = it.resolveInfo.serviceInfo
                it.id == target ||
                    ComponentName(si.packageName, si.name).flattenToString() == target
            }
            callback(Result.success(enabled))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }

    override fun isIgnoringBatteryOptimizations(callback: (Result<Boolean>) -> Unit) {
        try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            callback(Result.success(pm.isIgnoringBatteryOptimizations(context.packageName)))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }

    override fun currentBuildFingerprint(callback: (Result<String>) -> Unit) {
        callback(Result.success(Build.FINGERPRINT))
    }

    override fun currentManufacturer(callback: (Result<String>) -> Unit) {
        callback(Result.success(Build.MANUFACTURER.lowercase()))
    }

    override fun openUsageAccessSettings(callback: (Result<Unit>) -> Unit) {
        launchSettingsOrFallback(
            primary = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS),
            fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.parse("package:${context.packageName}")),
            callback = callback,
        )
    }

    override fun openAccessibilitySettings(callback: (Result<Unit>) -> Unit) {
        launchSettingsOrFallback(
            primary = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS),
            fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.parse("package:${context.packageName}")),
            callback = callback,
        )
    }

    override fun openBatteryOptSettings(callback: (Result<Unit>) -> Unit) {
        // Preferred: ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS — opens a system dialog
        // that grants the exemption directly. Requires `package:` data Uri per docs.
        launchSettingsOrFallback(
            primary = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                .setData(Uri.parse("package:${context.packageName}")),
            fallback = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
            callback = callback,
        )
    }

    private fun launchSettingsOrFallback(
        primary: Intent,
        fallback: Intent,
        callback: (Result<Unit>) -> Unit,
    ) {
        val pm = context.packageManager
        val withFlag = primary.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (withFlag.resolveActivity(pm) != null) {
            try {
                context.startActivity(withFlag)
                callback(Result.success(Unit)); return
            } catch (e: Throwable) {
                // fall through to fallback
            }
        }
        val fb = fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (fb.resolveActivity(pm) != null) {
            try {
                context.startActivity(fb)
                callback(Result.success(Unit)); return
            } catch (e: Throwable) {
                callback(Result.failure(e)); return
            }
        }
        callback(Result.failure(Exception("No Settings activity resolves on this device")))
    }
}
