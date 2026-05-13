package com.nottodo.not_to_do_list.platform

import android.content.Context
import android.content.Intent
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import org.json.JSONArray
import org.json.JSONObject

/**
 * Phase 4 Plan 04-04: D-10 LocalBroadcast emitter.
 *
 * Translates the Pigeon publishBlockList(snapshot) call into a LOCAL broadcast
 * with action ACTION_BLOCKLIST_UPDATED carrying the snapshot serialized as a
 * JSON-string extra.
 *
 * Receiver: NotToDoAccessibilityService (Plan 04-05) registers a runtime
 * BroadcastReceiver with Context.RECEIVER_NOT_EXPORTED (API 33+) for this
 * action. Service NEVER reads SQLite (Pattern 1) — this is the SOLE refresh
 * path for its in-memory Map<String, ScheduleSlice>.
 *
 * The action string is qualified (package-prefixed) so collisions with any
 * other app are impossible. setPackage() on the Intent further restricts
 * delivery to this app's process. T-01 mitigation: external apps cannot
 * inject ACTION_BLOCKLIST_UPDATED into our service — the receiver is
 * registered NOT_EXPORTED and the action is not declared in AndroidManifest.
 *
 * PLAY-02: this file does not call any AccessibilityService API. Forbidden
 * tokens (performAction, performGlobalAction, dispatchGesture) are absent.
 */
class BlocklistBroadcastApiImpl(private val context: Context) : BlocklistBroadcastApi {

    companion object {
        const val ACTION_BLOCKLIST_UPDATED =
            "com.nottodo.not_to_do_list.ACTION_BLOCKLIST_UPDATED"
        const val EXTRA_BLOCKLIST_SNAPSHOT_JSON =
            "extra_blocklist_snapshot_json"
    }

    override fun publishBlockList(entries: List<BlockListEntrySnapshot>) {
        val arr = JSONArray()
        for (e in entries) {
            arr.put(
                JSONObject().apply {
                    put("entryId", e.entryId)
                    put("packageName", e.packageName)
                    put("blockMode", e.blockMode)
                    putOpt("scheduleStartMinutes", e.scheduleStartMinutes)
                    putOpt("scheduleEndMinutes", e.scheduleEndMinutes)
                    putOpt("scheduleWeekdayMask", e.scheduleWeekdayMask)
                },
            )
        }
        val intent = Intent(ACTION_BLOCKLIST_UPDATED)
            .setPackage(context.packageName)
            .putExtra(EXTRA_BLOCKLIST_SNAPSHOT_JSON, arr.toString())
        LocalBroadcastManager.getInstance(context).sendBroadcast(intent)
    }
}
