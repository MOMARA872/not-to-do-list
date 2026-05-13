package com.nottodo.not_to_do_list

import android.os.Bundle
import com.nottodo.not_to_do_list.platform.AccessibilityApi
import com.nottodo.not_to_do_list.platform.AccessibilityApiImpl
import com.nottodo.not_to_do_list.platform.AppPickerApi
import com.nottodo.not_to_do_list.platform.BlocklistBroadcastApi
import com.nottodo.not_to_do_list.platform.BlocklistBroadcastApiImpl
import com.nottodo.not_to_do_list.platform.AppPickerHostImpl
import com.nottodo.not_to_do_list.platform.NotificationApi
import com.nottodo.not_to_do_list.platform.PermissionStatusApi
import com.nottodo.not_to_do_list.platform.PermissionStatusApiImpl
import com.nottodo.not_to_do_list.platform.UsageApi
import com.nottodo.not_to_do_list.platform.UsageApiImpl
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // D-14 / PAUS-07: pre-warm a FlutterEngine for PauseActivity so cold-start
        // is paid here at app launch, not on the first blocked-app trigger.
        // Cache key "pause_engine" is consumed by PauseActivity (Plan 04-06)
        // via FlutterActivity.withCachedEngine("pause_engine").
        if (FlutterEngineCache.getInstance().get("pause_engine") == null) {
            val pauseEngine = io.flutter.embedding.engine.FlutterEngine(applicationContext)
            pauseEngine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault(),
            )
            FlutterEngineCache.getInstance().put("pause_engine", pauseEngine)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Phase 2 wires AppPickerApi + PermissionStatusApi; Phase 3 wires UsageApi
        // (DASH-01); Phase 4 wires AccessibilityApi (PAUS-*); Phase 5 will wire
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

        AccessibilityApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            AccessibilityApiImpl(applicationContext),
        )

        BlocklistBroadcastApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            BlocklistBroadcastApiImpl(applicationContext),
        )

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
