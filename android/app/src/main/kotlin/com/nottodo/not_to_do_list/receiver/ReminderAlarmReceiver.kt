package com.nottodo.not_to_do_list.receiver

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.nottodo.not_to_do_list.MainActivity
import com.nottodo.not_to_do_list.R
import com.nottodo.not_to_do_list.platform.NotificationApiImpl

/**
 * BroadcastReceiver that fires the daily check-in notification and self-re-arms
 * for the next day. AlarmManager.setExactAndAllowWhileIdle is a one-shot API —
 * re-arming at the end of onReceive satisfies NOTF-04 (alarm persists across Doze).
 *
 * android:exported="false" in manifest prevents external triggers (T-05-16 mitigation).
 *
 * PLAY-02 invariant: this class MUST NOT invoke any autonomous AccessibilityService
 * actions. The forbidden API tokens are intentionally absent from this file so
 * absence-greps in play_invariants_test.dart stay exact.
 */
class ReminderAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // 1. Fire the daily check-in notification.
        showCheckinNotification(context)

        // 2. CRITICAL: re-arm for the NEXT day. setExactAndAllowWhileIdle is one-shot.
        // Read flutter.reminder_hour_minute from FlutterSharedPreferences
        // (RESEARCH §10 R-9 cross-process key — Kotlin reads with "flutter." prefix).
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val hm = prefs.getLong("flutter.reminder_hour_minute", 21 * 60).toInt()
        val h = hm / 60
        val m = hm % 60

        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = NotificationApiImpl.buildPendingIntent(context)
        val triggerMs = NotificationApiImpl.computeNextOccurrenceMs(h, m)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms()) {
            // User revoked exact-alarm permission since last schedule (RESEARCH §10 R-2).
            // Fall back to inexact to avoid SecurityException crash (T-05-20 mitigation).
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pi)
        } else {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pi)
        }
    }

    private fun showCheckinNotification(ctx: Context) {
        val nm = ctx.getSystemService(NotificationManager::class.java)

        // Create the notification channel — idempotent (createNotificationChannel is no-op
        // if the channel already exists).
        val channel = NotificationChannel(
            CHANNEL_ID,
            ctx.getString(R.string.notification_channel_daily_checkin),
            NotificationManager.IMPORTANCE_DEFAULT,
        )
        nm.createNotificationChannel(channel)

        // PendingIntent to open MainActivity with extra triggering /checkin deep-link.
        // NOTF-03: MainActivity.onNewIntent validates deep_link_to against allow-list
        // {"/checkin"} and writes pending_deep_link to FlutterSharedPreferences.
        val deepLinkIntent = Intent(ctx, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("deep_link_to", "/checkin")
        }
        val pi = PendingIntent.getActivity(
            ctx,
            0,
            deepLinkIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        // D-10 privacy lock: title and body are EXACT static literals from strings.xml.
        // No entry names, app names, or dynamic user data in the notification body.
        val notification = NotificationCompat.Builder(ctx, CHANNEL_ID)
            .setContentTitle(ctx.getString(R.string.notification_channel_daily_checkin))
            .setContentText(ctx.getString(R.string.notification_body_daily_checkin))
            .setSmallIcon(R.mipmap.ic_launcher) // re-use launcher icon; Phase 6 polish upgrades
            .setContentIntent(pi)
            .setAutoCancel(true)
            .build()

        nm.notify(REMINDER_NOTIFICATION_ID, notification)
    }

    companion object {
        const val CHANNEL_ID = "daily_checkin"
        const val REMINDER_NOTIFICATION_ID = 5001
    }
}
