package com.nottodo.not_to_do_list.receiver

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.nottodo.not_to_do_list.platform.NotificationApiImpl

/**
 * BroadcastReceiver that re-arms the daily reminder after device reboot (NOTF-05).
 *
 * AlarmManager alarms are cleared on reboot. This receiver re-reads the stored
 * reminder time from FlutterSharedPreferences and reschedules the exact alarm.
 *
 * android:exported="true" with an intent-filter for ACTION_BOOT_COMPLETED and
 * ACTION_LOCKED_BOOT_COMPLETED is required so the OS can deliver the broadcast.
 * RECEIVE_BOOT_COMPLETED permission is declared in AndroidManifest.xml.
 *
 * Security: ACTION_BOOT_COMPLETED can only be sent by the system (T-05-17). The
 * action guard below provides defence-in-depth per V5 input-validation (PATTERNS.md).
 *
 * PLAY-02 invariant: this class MUST NOT invoke any autonomous AccessibilityService
 * actions. The forbidden API tokens are intentionally absent from this file so
 * absence-greps in play_invariants_test.dart stay exact.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // V5 input-validation guard — reject anything that is not a boot action.
        // OS-sent BOOT_COMPLETED is trusted; this guards defence-in-depth.
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.LOCKED_BOOT_COMPLETED"
        ) {
            return
        }

        // Read flutter.reminder_hour_minute from FlutterSharedPreferences.
        // Cross-process key contract: Dart writes 'reminder_hour_minute';
        // Kotlin reads 'flutter.reminder_hour_minute' (T-05-22 mitigation,
        // RESEARCH §10 R-9). Default: 21:00 (9 PM) if never set.
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val hm = prefs.getLong("flutter.reminder_hour_minute", 21 * 60).toInt()
        val h = hm / 60
        val m = hm % 60

        val triggerMs = NotificationApiImpl.computeNextOccurrenceMs(h, m)
        val pi = NotificationApiImpl.buildPendingIntent(context)
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // Same exact-or-inexact branch as ReminderAlarmReceiver.onReceive
        // (RESEARCH §10 R-2: canScheduleExactAlarms revoke mid-flight, T-05-20 mitigation).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms()) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pi)
        } else {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pi)
        }
    }
}
