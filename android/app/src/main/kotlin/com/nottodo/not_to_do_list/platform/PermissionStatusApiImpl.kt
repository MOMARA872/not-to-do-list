package com.nottodo.not_to_do_list.platform

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Activity
import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.os.SystemClock
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import androidx.core.content.ContextCompat
import com.nottodo.not_to_do_list.service.NotToDoAccessibilityService
import java.lang.ref.WeakReference

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

    override fun isPostNotificationsGranted(callback: (Result<Boolean>) -> Unit) {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                callback(Result.success(true)); return
            }
            val granted = ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
            callback(Result.success(granted))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }

    override fun postNotificationsRationaleState(callback: (Result<String>) -> Unit) {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                // Pre-Android 13: permission auto-granted, no rationale needed.
                callback(Result.success("grantable")); return
            }
            val prefs = getPostNotificationsPrefs()
            val requestedAtLeastOnce = prefs.getBoolean(KEY_POST_NOTIFICATIONS_REQUESTED, false)
            val granted = ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED

            val state = when {
                granted -> "grantable"
                !requestedAtLeastOnce -> "grantable"
                else -> {
                    // Read the rationale-visible flag written after each requestPostNotifications call.
                    val rationaleVisible = prefs.getBoolean(KEY_POST_NOTIFICATIONS_RATIONALE_VISIBLE, false)
                    if (rationaleVisible) "rationale" else "permanently_denied"
                }
            }
            callback(Result.success(state))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }

    /**
     * SEMANTIC NOTE — non-blocking return:
     *
     * This method returns the PRE-dialog granted state, NOT the post-dialog state. The Android runtime
     * permission dialog dispatches its result to MainActivity.onRequestPermissionsResult asynchronously;
     * blocking the Pigeon callback on that result would hold the Flutter engine thread for the duration
     * of the user's interaction with the system dialog, which is not acceptable.
     *
     * Caller contract:
     *   1. Dart side calls requestPostNotifications() — system dialog appears for the user
     *   2. Kotlin returns the PRE-dialog granted state immediately (the dialog has not closed yet)
     *   3. Dart side MUST re-poll isPostNotificationsGranted() on AppLifecycleState.resumed to observe
     *      the post-dialog grant outcome
     *
     * The Plan 05-08 PostNotificationsEarnedStep ConsumerStatefulWidget implements this re-poll via
     * WidgetsBindingObserver.didChangeAppLifecycleState — when the user returns from the system dialog
     * the app is resumed and the widget re-checks the permission, advancing onboarding accordingly.
     *
     * See T-05-16 in 05-04-PLAN.md threat register for the full lifecycle contract.
     */
    override fun requestPostNotifications(callback: (Result<Boolean>) -> Unit) {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                // Pre-Android 13: auto-granted, no dialog needed.
                callback(Result.success(true)); return
            }
            val prefs = getPostNotificationsPrefs()
            // Capture pre-dialog granted state — returned immediately (non-blocking).
            val preDialogGranted = ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED

            // Write the requested-at-least-once flag and capture shouldShowRationale
            // BEFORE launching the dialog so postNotificationsRationaleState reads fresh state.
            val activity = weakRef?.get()
            val rationaleVisible = activity?.shouldShowRequestPermissionRationale(
                android.Manifest.permission.POST_NOTIFICATIONS,
            ) ?: false

            prefs.edit()
                .putBoolean(KEY_POST_NOTIFICATIONS_REQUESTED, true)
                .putBoolean(KEY_POST_NOTIFICATIONS_RATIONALE_VISIBLE, rationaleVisible)
                .apply()

            // Launch the system dialog via the Activity if available.
            activity?.requestPermissions(
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_CODE_POST_NOTIFICATIONS,
            )

            // Return PRE-dialog state immediately. Caller re-polls on AppLifecycleState.resumed.
            callback(Result.success(preDialogGranted))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }

    override fun bootMonotonicNanos(callback: (Result<Long>) -> Unit) {
        try {
            callback(Result.success(SystemClock.elapsedRealtimeNanos()))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }

    override fun openAppNotificationSettings(callback: (Result<Unit>) -> Unit) {
        launchSettingsOrFallback(
            primary = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName),
            fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.parse("package:${context.packageName}")),
            callback = callback,
        )
    }

    private fun getPostNotificationsPrefs(): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

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

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_POST_NOTIFICATIONS_REQUESTED =
            "flutter.post_notifications_requested_at_least_once"
        private const val KEY_POST_NOTIFICATIONS_RATIONALE_VISIBLE =
            "flutter.post_notifications_rationale_visible"
        private const val REQUEST_CODE_POST_NOTIFICATIONS = 1001

        /**
         * Weak reference to the host Activity.
         * Plan 05-05 populates this in MainActivity.configureFlutterEngine so that
         * [requestPostNotifications] can launch the runtime permission dialog.
         * Null-safe: if no Activity is bound, requestPostNotifications returns the
         * current PRE-dialog granted state without launching a dialog.
         */
        var weakRef: WeakReference<Activity>? = null
    }
}
