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
 * - Wake-up alarms (Fajr challenge, Suhoor, Pre-Fajr): [AlarmManager.setAlarmClock]
 *   (highest priority, survives Doze / app standby / battery optimization, and
 *   is shown in the system clock UI).
 * - Informational alarms (prayer times, bedtime): [AlarmManager.setExactAndAllowWhileIdle].
 *
 * Identity: every alarm has a deterministic request code derived from its
 * [AlarmKind], so reschedule() always cancels the old PendingIntent first and
 * can never create duplicates. All schedule functions return whether an alarm
 * was actually armed, so callers (and the UI) never report phantom successes.
 */
object AlarmScheduler {
    const val REQUEST_CHALLENGE = 9001

    /** Stable alarm kinds. Codes are part of the PendingIntent identity — never reuse. */
    enum class AlarmKind(val requestCode: Int, val action: String) {
        FAJR_CHALLENGE(9001, PrayerAlarmReceiver.ACTION_FAJR_CHALLENGE),
        SUHOOR(9101, PrayerAlarmReceiver.ACTION_SUHOOR),
        PRE_FAJR(9102, PrayerAlarmReceiver.ACTION_PRE_FAJR),
        BEDTIME(9103, PrayerAlarmReceiver.ACTION_BEDTIME),
        PRE_PRAYER(9104, PrayerAlarmReceiver.ACTION_PRE_PRAYER),
        POST_PRAYER(9105, PrayerAlarmReceiver.ACTION_POST_PRAYER),
        TAHAJJUD(9106, PrayerAlarmReceiver.ACTION_TAHAJJUD),
        FAJR_EXTRA_1(9107, PrayerAlarmReceiver.ACTION_FAJR_EXTRA_1),
        FAJR_EXTRA_2(9108, PrayerAlarmReceiver.ACTION_FAJR_EXTRA_2),
    }

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
        cancelKind(context, AlarmKind.FAJR_CHALLENGE)
        // Clear the persisted timestamp so a later reboot cannot resurrect
        // a cancelled/disabled alarm.
        context.getSharedPreferences("prayer_service_prefs", Context.MODE_PRIVATE)
            .edit()
            .remove("challenge_timestamp")
            .remove("challenge_triggered")
            .apply()
    }

    // ---------------- generic wake-up kinds (Suhoor / Pre-Fajr / Bedtime) -----

    private fun prefs(context: Context) =
        context.getSharedPreferences("prayer_service_prefs", Context.MODE_PRIVATE)

    private fun showIntent(context: Context, requestCode: Int): PendingIntent =
        PendingIntent.getActivity(
            context, requestCode,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

    private fun cancelKind(context: Context, kind: AlarmKind) {
        cancel(context, kind.requestCode, kind.action)
    }

    /**
     * Generic wake-up alarm via setAlarmClock (Doze-proof). Persists under
     * [prefKey] so [scheduleAllFromPrefs] can rebuild it after reboot/tz change.
     * Cancel-before-schedule guarantees no duplicates.
     */
    private fun scheduleWakeUpKind(
        context: Context,
        kind: AlarmKind,
        triggerAtMillis: Long,
        prefKey: String,
        enabledPrefKey: String,
    ): Boolean {
        if (triggerAtMillis <= System.currentTimeMillis() + 30_000) return false
        if (!canScheduleExact(context)) return false
        cancelKind(context, kind)
        alarmManager(context).setAlarmClock(
            AlarmManager.AlarmClockInfo(triggerAtMillis, showIntent(context, kind.requestCode)),
            pendingIntent(context, kind.requestCode, kind.action)
        )
        prefs(context).edit()
            .putLong(prefKey, triggerAtMillis)
            .putBoolean("${prefKey}_triggered", false)
            .apply()
        // Remember which user toggle gates this alarm so reboot never
        // resurrects something the user disabled.
        prefs(context).edit().putString("${prefKey}_gate", enabledPrefKey).apply()
        return true
    }

    /** Suhoor alarm anchored to Fajr (Fajr − offset). Distinct UI from Fajr. */
    fun scheduleSuhoor(context: Context, triggerAtMillis: Long): Boolean =
        scheduleWakeUpKind(context, AlarmKind.SUHOOR, triggerAtMillis,
            "suhoor_timestamp", "flutter.suhoorAlarmEnabled")

    /** Pre-Fajr gentle warning (5/10/15 min or custom 10–120, anchored to Fajr). */
    fun schedulePreFajr(context: Context, triggerAtMillis: Long): Boolean =
        scheduleWakeUpKind(context, AlarmKind.PRE_FAJR, triggerAtMillis,
            "prefajr_timestamp", "flutter.preFajrAlarmEnabled")

    /** Tahajjud / night-prayer wake-up: Last-Third auto or fixed clock time (Dart decides). */
    fun scheduleTahajjud(context: Context, triggerAtMillis: Long): Boolean =
        scheduleWakeUpKind(context, AlarmKind.TAHAJJUD, triggerAtMillis,
            "tahajjud_timestamp", "flutter.tahajjudEnabled")

    /** Heavy-sleeper chain: re-fires the Fajr challenge +N minutes after Fajr. */
    fun scheduleFajrExtra1(context: Context, triggerAtMillis: Long): Boolean =
        scheduleWakeUpKind(context, AlarmKind.FAJR_EXTRA_1, triggerAtMillis,
            "fajrextra1_timestamp", "flutter.fajrExtra1Enabled")

    fun scheduleFajrExtra2(context: Context, triggerAtMillis: Long): Boolean =
        scheduleWakeUpKind(context, AlarmKind.FAJR_EXTRA_2, triggerAtMillis,
            "fajrextra2_timestamp", "flutter.fajrExtra2Enabled")

    /** Bedtime reminder: exact clock time or Fajr-relative. Lower priority. */
    fun scheduleBedtime(context: Context, triggerAtMillis: Long): Boolean {
        if (triggerAtMillis <= System.currentTimeMillis() + 30_000) return false
        if (!canScheduleExact(context)) return false
        cancelKind(context, AlarmKind.BEDTIME)
        alarmManager(context).setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP, triggerAtMillis,
            pendingIntent(context, AlarmKind.BEDTIME.requestCode, AlarmKind.BEDTIME.action)
        )
        prefs(context).edit()
            .putLong("bedtime_timestamp", triggerAtMillis)
            .putBoolean("bedtime_timestamp_triggered", false)
            .putString("bedtime_timestamp_gate", "flutter.bedtimeAlarmEnabled")
            .apply()
        return true
    }

    /**
     * Pre/post prayer reminders (informational, exact-while-idle). Each is a
     * single "next occurrence" alarm carrying the prayer name; Dart recomputes
     * and re-arms after every prayer-time refresh, cancel-before-schedule.
     */
    fun schedulePrePrayer(context: Context, prayerName: String, triggerAtMillis: Long): Boolean {
        if (triggerAtMillis <= System.currentTimeMillis() + 30_000) return false
        if (!canScheduleExact(context)) return false
        cancelKind(context, AlarmKind.PRE_PRAYER)
        val pi = PendingIntent.getBroadcast(
            context, AlarmKind.PRE_PRAYER.requestCode,
            Intent(context, PrayerAlarmReceiver::class.java).apply {
                action = AlarmKind.PRE_PRAYER.action
                putExtra("prayer_name", prayerName)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager(context).setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        prefs(context).edit()
            .putLong("preprayer_timestamp", triggerAtMillis)
            .putString("preprayer_name", prayerName)
            .apply()
        return true
    }

    fun schedulePostPrayer(context: Context, prayerName: String, triggerAtMillis: Long): Boolean {
        if (triggerAtMillis <= System.currentTimeMillis() + 30_000) return false
        if (!canScheduleExact(context)) return false
        cancelKind(context, AlarmKind.POST_PRAYER)
        val pi = PendingIntent.getBroadcast(
            context, AlarmKind.POST_PRAYER.requestCode,
            Intent(context, PrayerAlarmReceiver::class.java).apply {
                action = AlarmKind.POST_PRAYER.action
                putExtra("prayer_name", prayerName)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager(context).setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        prefs(context).edit()
            .putLong("postprayer_timestamp", triggerAtMillis)
            .putString("postprayer_name", prayerName)
            .apply()
        return true
    }

    fun cancelSuhoor(context: Context) {
        cancelKind(context, AlarmKind.SUHOOR)
        prefs(context).edit().remove("suhoor_timestamp")
            .remove("suhoor_timestamp_triggered").apply()
    }

    fun cancelPreFajr(context: Context) {
        cancelKind(context, AlarmKind.PRE_FAJR)
        prefs(context).edit().remove("prefajr_timestamp")
            .remove("prefajr_timestamp_triggered").apply()
    }

    fun cancelTahajjud(context: Context) {
        cancelKind(context, AlarmKind.TAHAJJUD)
        prefs(context).edit().remove("tahajjud_timestamp")
            .remove("tahajjud_timestamp_triggered").apply()
    }

    fun cancelFajrExtra1(context: Context) {
        cancelKind(context, AlarmKind.FAJR_EXTRA_1)
        prefs(context).edit().remove("fajrextra1_timestamp")
            .remove("fajrextra1_timestamp_triggered").apply()
    }

    fun cancelFajrExtra2(context: Context) {
        cancelKind(context, AlarmKind.FAJR_EXTRA_2)
        prefs(context).edit().remove("fajrextra2_timestamp")
            .remove("fajrextra2_timestamp_triggered").apply()
    }

    fun cancelBedtime(context: Context) {
        cancelKind(context, AlarmKind.BEDTIME)
        prefs(context).edit().remove("bedtime_timestamp")
            .remove("bedtime_timestamp_triggered").apply()
    }

    fun cancelPrePrayer(context: Context) {
        cancelKind(context, AlarmKind.PRE_PRAYER)
        prefs(context).edit().remove("preprayer_timestamp")
            .remove("preprayer_name").apply()
    }

    fun cancelPostPrayer(context: Context) {
        cancelKind(context, AlarmKind.POST_PRAYER)
        prefs(context).edit().remove("postprayer_timestamp")
            .remove("postprayer_name").apply()
    }

    fun cancelAll(context: Context) {
        cancelChallenge(context)
        cancelSuhoor(context)
        cancelPreFajr(context)
        cancelTahajjud(context)
        cancelFajrExtra1(context)
        cancelFajrExtra2(context)
        cancelBedtime(context)
        cancelPrePrayer(context)
        cancelPostPrayer(context)
        for ((name, code) in prayerRequestCodes) {
            cancel(context, code, PrayerAlarmReceiver.ACTION_PRAYER, name)
        }
    }

    /** Human-readable diagnostics for the Advanced → Diagnostics screen. */
    fun diagnostics(context: Context): String {
        val sb = StringBuilder()
        val now = System.currentTimeMillis()
        fun line(label: String, ts: Long) {
            if (ts <= 0) {
                sb.appendLine("$label: —")
            } else {
                val deltaMin = (ts - now) / 60000
                sb.appendLine("$label: ${java.util.Date(ts)} (${deltaMin}min)")
            }
        }
        val p = prefs(context)
        line("challenge", p.getLong("challenge_timestamp", 0))
        line("suhoor", p.getLong("suhoor_timestamp", 0))
        line("prefajr", p.getLong("prefajr_timestamp", 0))
        line("tahajjud", p.getLong("tahajjud_timestamp", 0))
        line("fajrextra1", p.getLong("fajrextra1_timestamp", 0))
        line("fajrextra2", p.getLong("fajrextra2_timestamp", 0))
        line("bedtime", p.getLong("bedtime_timestamp", 0))
        line("preprayer", p.getLong("preprayer_timestamp", 0))
        line("postprayer", p.getLong("postprayer_timestamp", 0))
        line("nextPrayer", p.getLong("target_timestamp", 0))
        sb.appendLine("canExact=${canScheduleExact(context)} sdk=${Build.VERSION.SDK_INT}")
        return sb.toString()
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
        // Additional wake-up alarms: only when their own toggle is still on.
        if (flutterPrefs.getBoolean("flutter.suhoorAlarmEnabled", false)) {
            val ts = prefs.getLong("suhoor_timestamp", 0)
            if (ts > now + 30_000) scheduleSuhoor(context, ts)
        }
        if (flutterPrefs.getBoolean("flutter.preFajrAlarmEnabled", false)) {
            val ts = prefs.getLong("prefajr_timestamp", 0)
            if (ts > now + 30_000) schedulePreFajr(context, ts)
        }
        if (flutterPrefs.getBoolean("flutter.tahajjudEnabled", false)) {
            val ts = prefs.getLong("tahajjud_timestamp", 0)
            if (ts > now + 30_000) scheduleTahajjud(context, ts)
        }
        if (flutterPrefs.getBoolean("flutter.fajrExtra1Enabled", false)) {
            val ts = prefs.getLong("fajrextra1_timestamp", 0)
            if (ts > now + 30_000) scheduleFajrExtra1(context, ts)
        }
        if (flutterPrefs.getBoolean("flutter.fajrExtra2Enabled", false)) {
            val ts = prefs.getLong("fajrextra2_timestamp", 0)
            if (ts > now + 30_000) scheduleFajrExtra2(context, ts)
        }
        if (flutterPrefs.getBoolean("flutter.bedtimeAlarmEnabled", false)) {
            val ts = prefs.getLong("bedtime_timestamp", 0)
            if (ts > now + 30_000) scheduleBedtime(context, ts)
        }
        run {
            val ts = prefs.getLong("preprayer_timestamp", 0)
            val nm = prefs.getString("preprayer_name", "") ?: ""
            if (ts > now + 30_000 && nm.isNotEmpty() &&
                flutterPrefs.getBoolean("flutter.prePrayerEnabled", false) &&
                flutterPrefs.getBoolean("flutter.prePrayer_$nm", true)) {
                schedulePrePrayer(context, nm, ts)
            }
        }
        run {
            val ts = prefs.getLong("postprayer_timestamp", 0)
            val nm = prefs.getString("postprayer_name", "") ?: ""
            if (ts > now + 30_000 && nm.isNotEmpty() &&
                flutterPrefs.getBoolean("flutter.postPrayerEnabled", false) &&
                flutterPrefs.getBoolean("flutter.postPrayer_$nm", true)) {
                schedulePostPrayer(context, nm, ts)
            }
        }
    }
}
