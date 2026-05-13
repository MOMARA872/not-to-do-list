package com.nottodo.not_to_do_list.service

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.nottodo.not_to_do_list.PauseActivity
import com.nottodo.not_to_do_list.platform.BlocklistBroadcastApiImpl
import org.json.JSONArray
/**
 * Phase-1 stub for the Not-To-Do AccessibilityService.
 *
 * This class exists in Phase 1 only so that the manifest entry points to a
 * real compilable class. The body is intentionally empty.
 *
 * Phase 4 will implement:
 *   - the TYPE_WINDOW_STATE_CHANGED filter
 *   - the 800ms debounce window (per ARCHITECTURE.md)
 *   - the in-memory match against the user's Not-To-Do list
 *   - launching the pause activity for matched packages
 *
 * PLAY-02 contract: this service MUST NEVER call any autonomous-action API on
 * AccessibilityService (see docs/play-declaration.md section 2 for the canonical
 * forbidden-call list). The forbidden API names are deliberately kept out of
 * this file so that the V12/PLAY-02 absence-greps stay exact.
 *
 * RESEARCH section-13 anti-pattern lockdown: this service MUST NEVER access an
 * on-device database from the event thread. Database technology names are kept
 * out of this file so that the no-DB-imports absence-grep stays exact.
 */
class NotToDoAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "NotToDoA11yService"
        private const val DEBOUNCE_MS = 800L
    }

    /** In-memory block list keyed by packageName. Replaced atomically by [BlockListReceiver]. */
    @Volatile
    private var blockMap: Map<String, ScheduleSlice> = emptyMap()

    /** Per-package last-fired timestamp for 800ms debounce. Accessed only on the event thread. */
    private val lastFiredAtMs = mutableMapOf<String, Long>()

    private val receiver = BlockListReceiver()

    override fun onServiceConnected() {
        super.onServiceConnected()
        LocalBroadcastManager.getInstance(this).registerReceiver(
            receiver,
            IntentFilter(BlocklistBroadcastApiImpl.ACTION_BLOCKLIST_UPDATED),
        )
        Log.d(TAG, "service connected")
    }

    override fun onDestroy() {
        LocalBroadcastManager.getInstance(this).unregisterReceiver(receiver)
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // (1) Null guard
        event ?: return
        // (2) Event type filter — observe TYPE_WINDOW_STATE_CHANGED only (D-09)
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        // (3) Package name guard
        val pkg = event.packageName?.toString() ?: return
        // (4) Block-list membership check
        val slice = blockMap[pkg] ?: return
        // (5) 800ms per-package debounce (D-09)
        val now = System.currentTimeMillis()
        val last = lastFiredAtMs[pkg] ?: 0L
        if (now - last < DEBOUNCE_MS) return
        // (6) Schedule gate (PAUS-10): skip if outside the configured window
        val hasSchedule = slice.startMinutes != null &&
            slice.endMinutes != null &&
            slice.weekdayMask != null
        if (hasSchedule && !isInScheduleWindow(
                now,
                slice.startMinutes!!,
                slice.endMinutes!!,
                slice.weekdayMask!!,
            )
        ) return
        // (7) Update debounce timestamp
        lastFiredAtMs[pkg] = now
        // (8) Launch PauseActivity with 4 lowercase_snake extras (D-11)
        val intent = Intent(this, PauseActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .putExtra("extra_blocked_package", pkg)
            .putExtra("extra_entry_id", slice.entryId)
            .putExtra("extra_block_mode", slice.blockMode)
            .putExtra("extra_triggered_at_ms", now)
        startActivity(intent)
    }

    override fun onInterrupt() {
        // Phase-1 stub. No interruptible feedback to cancel.
    }

    /** Immutable snapshot of a single block-list entry for in-memory matching. */
    private data class ScheduleSlice(
        val entryId: Long,
        val blockMode: String,
        val startMinutes: Int?,
        val endMinutes: Int?,
        val weekdayMask: Int?,
    )

    /**
     * Receives ACTION_BLOCKLIST_UPDATED and atomically replaces [blockMap].
     * JSON parsing failures keep the previous map intact (T-4-05-07 fail-safe).
     */
    private inner class BlockListReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val json = intent?.getStringExtra(
                BlocklistBroadcastApiImpl.EXTRA_BLOCKLIST_SNAPSHOT_JSON,
            ) ?: return
            try {
                val arr = JSONArray(json)
                val map = mutableMapOf<String, ScheduleSlice>()
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    val packageName = o.optString("packageName")
                    if (packageName.isEmpty()) continue
                    map[packageName] = ScheduleSlice(
                        entryId = o.getLong("entryId"),
                        blockMode = o.getString("blockMode"),
                        startMinutes = if (o.has("scheduleStartMinutes")) o.getInt("scheduleStartMinutes") else null,
                        endMinutes = if (o.has("scheduleEndMinutes")) o.getInt("scheduleEndMinutes") else null,
                        weekdayMask = if (o.has("scheduleWeekdayMask")) o.getInt("scheduleWeekdayMask") else null,
                    )
                }
                blockMap = map
            } catch (e: Throwable) {
                // Malformed snapshot — keep previous map intact (T-4-05-07).
                // No logging of the JSON payload (T-4-05-04 / T-04 discipline).
            }
        }
    }
}
