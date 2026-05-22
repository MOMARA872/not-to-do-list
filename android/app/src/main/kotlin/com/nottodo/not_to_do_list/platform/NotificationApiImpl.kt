package com.nottodo.not_to_do_list.platform

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.nottodo.not_to_do_list.receiver.ReminderAlarmReceiver
import java.util.Calendar

/**
 * Phase 5 NotificationApi implementation (Plan 05-05).
 *
 * Schedules a daily reminder via AlarmManager.setExactAndAllowWhileIdle
 * (NOTF-02 / NOTF-04). Persists reminder_hour_minute to FlutterSharedPreferences
 * for BootReceiver cross-process re-arm (NOTF-05, RESEARCH §10 R-9).
 *
 * Android 12+ canScheduleExactAlarms() guard: returns Result.failure("EXACT_ALARM_DENIED")
 * when exact-alarm permission is absent — Dart side surfaces NOTF-07 banner.
 *
 * PLAY-02 invariant: this class MUST NOT invoke any autonomous AccessibilityService
 * actions. The forbidden API tokens are intentionally absent from this file so
 * absence-greps in play_invariants_test.dart stay exact.
 */
class NotificationApiImpl(private val context: Context) : NotificationApi {

    override fun scheduleDailyReminder(hour: Long, minute: Long, callback: (Result<Unit>) -> Unit) {
        try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = buildPendingIntent(context)
            val triggerAtMs = computeNextOccurrenceMs(hour.toInt(), minute.toInt())

            // Android 12+ requires canScheduleExactAlarms() check.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (!am.canScheduleExactAlarms()) {
                    // Surface as a Pigeon error; Dart side falls back to setAndAllowWhileIdle
                    // (inexact) and shows the NOTF-07 banner with a deeper sub-message.
                    callback(Result.failure(NotificationApiError("EXACT_ALARM_DENIED")))
                    return
                }
            }

            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)

            // Persist hour/minute for BootReceiver re-arm (RESEARCH §10 R-9 cross-process key).
            // Key format: "flutter.<key>" per shared_preferences plugin convention.
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putLong("flutter.reminder_hour_minute", hour * 60 + minute)
                .apply()

            callback(Result.success(Unit))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }

    override fun cancelDailyReminder(callback: (Result<Unit>) -> Unit) {
        try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(buildPendingIntent(context))
            callback(Result.success(Unit))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }

    companion object {
        /**
         * Builds a reusable PendingIntent targeting ReminderAlarmReceiver.
         * Shared by ReminderAlarmReceiver (self-re-arm) and BootReceiver (reboot re-arm).
         * FLAG_IMMUTABLE | FLAG_UPDATE_CURRENT required since Android 12 (T-05-21 mitigation).
         */
        fun buildPendingIntent(ctx: Context): PendingIntent {
            val intent = Intent(ctx, ReminderAlarmReceiver::class.java).apply {
                `package` = ctx.packageName // explicit, defence-in-depth (T-05-16 mitigation)
            }
            return PendingIntent.getBroadcast(
                ctx,
                REMINDER_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }

        /**
         * Computes the next wall-clock occurrence of [h]:[m]:00.
         * Returns today's instance if still in the future; adds one day otherwise.
         */
        fun computeNextOccurrenceMs(h: Int, m: Int): Long {
            val now = Calendar.getInstance()
            val target = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, h)
                set(Calendar.MINUTE, m)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            if (!target.after(now)) target.add(Calendar.DAY_OF_YEAR, 1)
            return target.timeInMillis
        }

        const val REMINDER_REQUEST_CODE = 5001 // Phase 5 — arbitrary, but stable
    }
}
