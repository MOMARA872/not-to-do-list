package com.nottodo.not_to_do_list

import android.content.Intent
import android.provider.Settings
import com.nottodo.not_to_do_list.platform.AccessibilityApi
import com.nottodo.not_to_do_list.platform.AppPickerApi
import com.nottodo.not_to_do_list.platform.AppPickerHostImpl
import com.nottodo.not_to_do_list.platform.NotificationApi
import com.nottodo.not_to_do_list.platform.PermissionStatusApi
import com.nottodo.not_to_do_list.platform.PermissionStatusApiImpl
import com.nottodo.not_to_do_list.platform.UsageApi
import com.nottodo.not_to_do_list.platform.UsageApiImpl
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Phase 2 wires AppPickerApi + PermissionStatusApi; Phase 3 wires UsageApi
        // (DASH-01); Phase 4 will wire AccessibilityApi (PAUS-*); Phase 5 wires
        // NotificationApi (NOTF-*).

        UsageApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            UsageApiImpl(applicationContext),
        )

        AppPickerApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            AppPickerHostImpl(applicationContext),
        )

        PermissionStatusApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            PermissionStatusApiImpl(applicationContext),
        )

        AccessibilityApi.setUp(flutterEngine.dartExecutor.binaryMessenger, object : AccessibilityApi {
            override fun isServiceEnabled(callback: (Result<Boolean>) -> Unit) {
                // Safe stub: report "off" until Phase 4 wires the real check.
                callback(Result.success(false))
            }

            override fun openAccessibilitySettings() {
                // Phase 2: real launch with resolveActivity guard (T-2-02 mitigation).
                val pm = applicationContext.packageManager
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (intent.resolveActivity(pm) != null) {
                    applicationContext.startActivity(intent)
                }
                // If not resolved, the screen-level OEM fallback (Plan 02-08) shows guidance.
            }
        })

        NotificationApi.setUp(flutterEngine.dartExecutor.binaryMessenger, object : NotificationApi {
            override fun scheduleDailyReminder(
                hour: Long,
                minute: Long,
                callback: (Result<Unit>) -> Unit
            ) {
                callback(Result.failure(NotImplementedError("NotificationApi: implemented in Phase 5")))
            }

            override fun cancelDailyReminder(callback: (Result<Unit>) -> Unit) {
                callback(Result.success(Unit))
            }
        })
    }
}
