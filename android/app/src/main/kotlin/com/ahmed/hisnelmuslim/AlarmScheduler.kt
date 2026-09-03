package com.ahmed.hisnelmuslim

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Exact-alarm scheduling via AlarmManager, mirroring the reference app's chain:
 * AlarmManager fires -> PrayerAlarmReceiver -> full-screen notification -> activity.
 *
 * - Fajr challenge: [AlarmManager.setAlarmClock] (highest priority, survives
 *   Doze / app standby / battery optimization, and is shown in the system clock UI).
 * - Prayer times: [AlarmManager.setExactAndAllowWhileIdle].
 *
 * All schedule functions return whether an alarm was actually armed, so
 * callers (and the UI) never report phantom successes.
 */
object AlarmScheduler {
    const val REQUEST_CHALLENGE = 9001

    val prayerRequestCodes = mapOf(
        "Fajr" to 9002,
        "Sunrise" to 9003,
        "Dhuhr" to 9004,
        "Asr" to 9005,
        "Maghrib" to 9006,
        "Isha" to 9007,
        "First Third" to 9008,
        "Midnight" to 9009,
        "Last Third" to 9010,
    )

    fun canScheduleExact(context: Context): Boolean {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return Build.VERSION.SDK_INT < 31 || alarmManager.canScheduleExactAlarms()
    }

    private fun pendingIntent(
        context: Context,
        requestCode: Int,
        action: String,
        prayerName: String? = null,
    ): PendingIntent {
        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            this.action = action
            if (prayerName != null) putExtra("prayer_name", prayerName)
        }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun alarmManager(context: Context): AlarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    /** Fajr challenge alarm — highest priority, survives Doze / battery optimization. */
    fun scheduleChallenge(context: Context, triggerAtMillis: Long): Boolean {
        if (triggerAtMillis <= System.currentTimeMillis() + 30_000) return false
        if (!canScheduleExact(context)) return false
        val alarmManager = alarmManager(context)
        cancelChallenge(context)

        val showPendingIntent = PendingIntent.getActivity(
            context, REQUEST_CHALLENGE,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.setAlarmClock(
            AlarmManager.AlarmClockInfo(triggerAtMillis, showPendingIntent),
            pendingIntent(context, REQUEST_CHALLENGE, PrayerAlarmReceiver.ACTION_FAJR_CHALLENGE)
        )
        // Persist immediately so a reboot (or process death before the
        // service saves its extras) can still rebuild this alarm.
        context.getSharedPreferences("prayer_service_prefs", Context.MODE_PRIVATE)
            .edit()
            .putLong("challenge_timestamp", triggerAtMillis)
            .putBoolean("challenge_triggered", false)
            .apply()
        return true
    }

    /** Test the fajr challenge alarm with a near-future trigger time. */
    fun testChallenge(context: Context, delaySeconds: Int = 5): Boolean {
        if (!canScheduleExact(context)) return false
        val triggerAtMillis = System.currentTimeMillis() + (delaySeconds * 1000L)
        val alarmManager = alarmManager(context)
        cancelChallenge(context)

        val showPendingIntent = PendingIntent.getActivity(
            context, REQUEST_CHALLENGE,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.setAlarmClock(
            AlarmManager.AlarmClockInfo(triggerAtMillis, showPendingIntent),
            pendingIntent(context, REQUEST_CHALLENGE, PrayerAlarmReceiver.ACTION_FAJR_CHALLENGE)
        )
        return true
    }

    /** Regular prayer time alarm. */
    fun schedulePrayer(context: Context, prayerName: String, triggerAtMillis: Long): Boolean {
        val requestCode = prayerRequestCodes[prayerName] ?: return false
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isSpecialTime = prayerName in listOf("Sunrise", "First Third", "Midnight", "Last Third")
        val isAyatEnabled = flutterPrefs.getBoolean("flutter.ayat_hadith_$prayerName", !isSpecialTime)

        // If disabled by user, ensure any existing alarm is cancelled and return
        if (!isAyatEnabled) {
            cancel(context, requestCode, PrayerAlarmReceiver.ACTION_PRAYER, prayerName)
            return false
        }

        if (triggerAtMillis <= System.currentTimeMillis() + 30_000) return false
        if (!canScheduleExact(context)) return false
        val alarmManager = alarmManager(context)
        cancel(context, requestCode, PrayerAlarmReceiver.ACTION_PRAYER, prayerName)
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP, triggerAtMillis,
            pendingIntent(context, requestCode, PrayerAlarmReceiver.ACTION_PRAYER, prayerName)
        )
        return true
    }

    fun cancel(context: Context, requestCode: Int, action: String, prayerName: String? = null) {
        val alarmManager = alarmManager(context)
        val pi = pendingIntent(context, requestCode, action, prayerName)
        alarmManager.cancel(pi)
        pi.cancel()
    }

    fun cancelChallenge(context: Context) {
        cancel(context, REQUEST_CHALLENGE, PrayerAlarmReceiver.ACTION_FAJR_CHALLENGE)
        // Clear the persisted timestamp so a later reboot cannot resurrect
        // a cancelled/disabled alarm.
        context.getSharedPreferences("prayer_service_prefs", Context.MODE_PRIVATE)
            .edit()
            .remove("challenge_timestamp")
            .remove("challenge_triggered")
            .apply()
    }

    fun cancelAll(context: Context) {
        cancelChallenge(context)
        for ((name, code) in prayerRequestCodes) {
            cancel(context, code, PrayerAlarmReceiver.ACTION_PRAYER, name)
        }
    }

    /** Rebuild future alarms after a reboot from the persisted service data. */
    fun scheduleAllFromPrefs(context: Context) {
        val prefs = context.getSharedPreferences("prayer_service_prefs", Context.MODE_PRIVATE)
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // Never resurrect a challenge the user disabled before the reboot.
        val challengeEnabled = flutterPrefs.getBoolean("flutter.fajrChallengeEnabled", false)
        val now = System.currentTimeMillis()
        val challenge = prefs.getLong("challenge_timestamp", 0)
        val targetTime = prefs.getLong("target_timestamp", 0)
        val targetName = prefs.getString("next_prayer_name", "") ?: ""
        if (challengeEnabled && challenge > now + 30_000) scheduleChallenge(context, challenge)
        if (targetTime > now + 30_000 && targetName.isNotEmpty()) {
            schedulePrayer(context, targetName, targetTime)
        }
    }
}
