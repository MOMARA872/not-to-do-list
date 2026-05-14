package com.nottodo.not_to_do_list

import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

/**
 * Phase-1 stub for the Pause / reflection screen activity.
 *
 * This class exists in Phase 1 only so that the manifest entry
 * (`<activity android:name=".PauseActivity">`) points to a real compilable class.
 * The body is intentionally empty.
 *
 * Phase 4 will implement:
 *   - setShowWhenLocked(true) and setTurnScreenOn(true) (PAUS-08)
 *   - reading the blocked-package Intent extra
 *   - routing the Flutter engine to the /pause route with the package name
 *   - cooldown-timer state handoff between the AccessibilityService and Flutter
 */
class PauseActivity : FlutterActivity() {

    private var entryId: Long = -1L
    private var blockedPackage: String = ""
    private var blockMode: String = ""
    private var triggeredAtMs: Long = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        // PAUS-08 / D-15: lock-screen flags MUST be set before super.onCreate
        // because the window attaches there.
        setShowWhenLocked(true)
        setTurnScreenOn(true)

        // T-02 fail-closed: read + validate extras BEFORE super.onCreate.
        // If anything is malformed, finish() silently — no engine bind, no
        // route navigation, no pause_events row.
        entryId = intent.getLongExtra("extra_entry_id", -1L)
        blockedPackage = intent.getStringExtra("extra_blocked_package") ?: ""
        blockMode = intent.getStringExtra("extra_block_mode") ?: ""
        triggeredAtMs = intent.getLongExtra("extra_triggered_at_ms", 0L)

        if (entryId == -1L ||
            blockedPackage.isEmpty() ||
            (blockMode != "soft" && blockMode != "hard") ||
            triggeredAtMs <= 0L
        ) {
            // WR-02: Malformed Intent — silent dismissal without binding the
            // FlutterEngine. Calling super.onCreate on a FlutterActivity triggers
            // provideFlutterEngine(), consuming or allocating the cached engine
            // before finish() is reached. Skipping super.onCreate is legal: the
            // system creates the Activity in CREATED state; finish() transitions
            // it to DESTROYED without engine lifecycle. T-02.
            finish()
            return
        }

        super.onCreate(savedInstanceState)
    }

    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? {
        // D-14: bind to MainActivity-pre-warmed engine for sub-300ms cold-start
        // (PAUS-07). Fall back to super (fresh engine) if the cache is empty —
        // functionally correct but slower; should be rare in practice because
        // the service is only enabled after MainActivity has run at least once.
        return FlutterEngineCache.getInstance().get("pause_engine")
            ?: super.provideFlutterEngine(context)
    }

    override fun getInitialRoute(): String {
        // Plan 04-07's GoRouter handles /pause/:entryId. The query params are
        // belt-and-suspenders — Plan 04-07's PauseScreen reads them via
        // state.uri.queryParameters instead of round-tripping Intent extras.
        return "/pause/$entryId?package=" +
            Uri.encode(blockedPackage) +
            "&mode=$blockMode" +
            "&triggeredAt=$triggeredAtMs"
    }
}
