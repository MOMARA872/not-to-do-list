package com.nottodo.not_to_do_list

import com.nottodo.not_to_do_list.platform.AccessibilityApi
import com.nottodo.not_to_do_list.platform.AppPickerApi
import com.nottodo.not_to_do_list.platform.AppPickerHostImpl
import com.nottodo.not_to_do_list.platform.NotificationApi
import com.nottodo.not_to_do_list.platform.UsageApi
import com.nottodo.not_to_do_list.platform.UsagePackageStat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Phase 2 wires AppPickerApi + PermissionStatusApi as real impls;
        // Phase 3/4/5 will replace UsageApi/NotificationApi.

        UsageApi.setUp(flutterEngine.dartExecutor.binaryMessenger, object : UsageApi {
            override fun queryRange(
                startEpochMs: Long,
                endEpochMs: Long,
                callback: (Result<List<UsagePackageStat>>) -> Unit
            ) {
                callback(Result.failure(NotImplementedError("UsageApi: implemented in Phase 3")))
            }
        })

        AppPickerApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            AppPickerHostImpl(applicationContext),
        )

        AccessibilityApi.setUp(flutterEngine.dartExecutor.binaryMessenger, object : AccessibilityApi {
            override fun isServiceEnabled(callback: (Result<Boolean>) -> Unit) {
                // Safe stub: report "off" until Phase 4 wires the real check.
                callback(Result.success(false))
            }

            override fun openAccessibilitySettings() {
                // No-op stub; Phase 2 deep-links to system settings.
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
