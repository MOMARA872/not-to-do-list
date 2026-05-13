package com.nottodo.not_to_do_list.platform

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.accessibility.AccessibilityManager

/**
 * Phase 4 Plan 04-03 implementation of AccessibilityApi.
 *
 * Replaces the Phase 2 hardcoded-false anonymous-object stub in MainActivity.kt.
 * As a side effect, permissionHealthProvider.accessibilityServiceGranted becomes
 * truth-bearing for the first time — the Phase 2 HealthCheckBanner starts firing
 * accurately.
 *
 * Both methods are cheap system-service reads (no I/O, microseconds) — no
 * background Executor is needed (contrast with AppPickerHostImpl.kt which does
 * PackageManager + UsageStatsManager I/O). This follows the PermissionStatusApiImpl.kt
 * precedent for simple reads.
 *
 * Settings deep-link uses a resolveActivity guard before startActivity
 * (T-2-02 mitigation pattern preserved from Phase 2 MainActivity.kt:46-54).
 *
 * PLAY-02 invariant: this class MUST NEVER call any autonomous-action API
 * (performAction / performGlobalAction / dispatchGesture). The forbidden
 * tokens are deliberately kept out of this file so absence-greps stay exact.
 */
class AccessibilityApiImpl(private val context: Context) : AccessibilityApi {
    override fun isServiceEnabled(callback: (Result<Boolean>) -> Unit) {
        try {
            val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
            val enabled = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            val expectedId = "${context.packageName}/com.nottodo.not_to_do_list.service.NotToDoAccessibilityService"
            callback(Result.success(enabled.any { it.id == expectedId }))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }

    override fun openAccessibilitySettings() {
        val pm = context.packageManager
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (intent.resolveActivity(pm) != null) {
            context.startActivity(intent)
        }
        // If not resolved, the screen-level OEM fallback (Plan 02-08) shows guidance.
    }
}
