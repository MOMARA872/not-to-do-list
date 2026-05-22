package com.nottodo.not_to_do_list

import android.content.Intent
import android.os.Bundle
import com.nottodo.not_to_do_list.platform.AccessibilityApi
import com.nottodo.not_to_do_list.platform.AccessibilityApiImpl
import com.nottodo.not_to_do_list.platform.AppPickerApi
import com.nottodo.not_to_do_list.platform.BlocklistBroadcastApi
import com.nottodo.not_to_do_list.platform.BlocklistBroadcastApiImpl
import com.nottodo.not_to_do_list.platform.AppPickerHostImpl
import com.nottodo.not_to_do_list.platform.NotificationApi
import com.nottodo.not_to_do_list.platform.NotificationApiImpl
import com.nottodo.not_to_do_list.platform.PermissionStatusApi
import com.nottodo.not_to_do_list.platform.PermissionStatusApiImpl
import com.nottodo.not_to_do_list.platform.UsageApi
import com.nottodo.not_to_do_list.platform.UsageApiImpl
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import java.lang.ref.WeakReference

class MainActivity : FlutterActivity() {

    companion object {
        /**
         * Weak reference to the host Activity, populated in onCreate and cleared in onDestroy.
         * Used by PermissionStatusApiImpl.requestPostNotifications to launch the system dialog
         * via ActivityCompat.requestPermissions (Plan 05-04 prerequisite — Plan 05-05 wires it).
         */
        @JvmStatic
        var weakInstance: WeakReference<MainActivity>? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Wire the Activity weak-ref for PermissionStatusApiImpl permission dialog (Plan 05-04).
        weakInstance = WeakReference(this)
        // Also set PermissionStatusApiImpl.weakRef so requestPostNotifications can launch dialog.
        PermissionStatusApiImpl.weakRef = WeakReference(this)

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

        // Handle cold-launch from notification tap: extract deep_link_to from launch intent.
        // Same logic as onNewIntent — both paths must check the extra (NOTF-03).
        handleDeepLinkIntent(intent)
    }

    override fun onDestroy() {
        weakInstance?.clear()
        weakInstance = null
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle warm-launch (singleTop re-delivery) from notification tap (NOTF-03).
        handleDeepLinkIntent(intent)
    }

    /**
     * Validates the `deep_link_to` extra against an allow-list {"/checkin"} (T-05-18 mitigation).
     * On match, writes `flutter.pending_deep_link = "/checkin"` to FlutterSharedPreferences.
     * HomeScreen.initState (Plan 05-07) reads and clears this key to navigate to /checkin.
     * All other values are silently rejected — V5 input-validation lock.
     */
    private fun handleDeepLinkIntent(intent: Intent?) {
        val deepLink = intent?.getStringExtra("deep_link_to") ?: return
        // Allow-list: ONLY "/checkin" is accepted. Any other value is a no-op.
        if (deepLink != "/checkin") return
        applicationContext.getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
            .edit()
            .putString("flutter.pending_deep_link", "/checkin")
            .apply()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Phase 2 wires AppPickerApi + PermissionStatusApi; Phase 3 wires UsageApi
        // (DASH-01); Phase 4 wires AccessibilityApi (PAUS-*); Phase 5 wires
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

        // Phase 5 (Plan 05-05): wire NotificationApi with the real Kotlin body.
        NotificationApi.setUp(flutterEngine.dartExecutor.binaryMessenger, NotificationApiImpl(applicationContext))
    }
}
