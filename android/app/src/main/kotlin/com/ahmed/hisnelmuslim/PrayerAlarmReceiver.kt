package com.ahmed.hisnelmuslim

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat

/**
 * Fired by AlarmManager exact alarms. Reference-app parity:
 * - Acquires a PARTIAL_WAKE_LOCK with a 2-minute timeout while "ringing".
 * - Fajr challenge -> HIGH-importance full-screen-intent notification -> MainActivity
 *   (renders above the keyguard via setShowWhenLocked).
 * - Prayer time -> ayat/hadith overlay (if enabled for that prayer) via PrayerTimeService.
 */
class PrayerAlarmReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_FAJR_CHALLENGE = "com.ahmed.hisnelmuslim.ACTION_FAJR_CHALLENGE"
        const val ACTION_PRAYER = "com.ahmed.hisnelmuslim.ACTION_PRAYER"
        const val ACTION_SUHOOR = "com.ahmed.hisnelmuslim.ACTION_SUHOOR"
        const val ACTION_PRE_FAJR = "com.ahmed.hisnelmuslim.ACTION_PRE_FAJR"
        const val ACTION_TAHAJJUD = "com.ahmed.hisnelmuslim.ACTION_TAHAJJUD"
        const val ACTION_FAJR_EXTRA_1 = "com.ahmed.hisnelmuslim.ACTION_FAJR_EXTRA_1"
        const val ACTION_FAJR_EXTRA_2 = "com.ahmed.hisnelmuslim.ACTION_FAJR_EXTRA_2"
        const val ACTION_BEDTIME = "com.ahmed.hisnelmuslim.ACTION_BEDTIME"
        const val ACTION_PRE_PRAYER = "com.ahmed.hisnelmuslim.ACTION_PRE_PRAYER"
        const val ACTION_POST_PRAYER = "com.ahmed.hisnelmuslim.ACTION_POST_PRAYER"
        private const val ALARM_CHANNEL_ID = "fajr_challenge_alarm_channel"
        private const val SUHOOR_CHANNEL_ID = "suhoor_alarm_channel"
        private const val PREFAJR_CHANNEL_ID = "prefajr_alarm_channel"
        private const val TAHAJJUD_CHANNEL_ID = "tahajjud_alarm_channel"
        private const val BEDTIME_CHANNEL_ID = "bedtime_channel"
        private const val PREPOST_CHANNEL_ID = "prepost_prayer_channel"
        private const val ALARM_NOTIFICATION_ID = 9999
        private const val SUHOOR_NOTIFICATION_ID = 9998
        private const val PREFAJR_NOTIFICATION_ID = 9997
        private const val TAHAJJUD_NOTIFICATION_ID = 9993
        private const val FAJR_EXTRA_1_NOTIFICATION_ID = 9992
        private const val FAJR_EXTRA_2_NOTIFICATION_ID = 9991
        private const val BEDTIME_NOTIFICATION_ID = 9996
        private const val PREPRAYER_NOTIFICATION_ID = 9995
        private const val POSTPRAYER_NOTIFICATION_ID = 9994
    }

    override fun onReceive(context: Context, intent: Intent) {
        // goAsync keeps the process alive while we dispatch; the PARTIAL
        // wake lock below has a 120s timeout and is intentionally NOT
        // released immediately — releasing in `finally` (as before) would
        // drop the CPU before the service/activity even starts.
        val pending = goAsync()
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK, "Husn:AlarmWakeLock").apply {
            setReferenceCounted(false)
            acquire(120_000L)
        }
        try {
            when (intent.action) {
                ACTION_FAJR_CHALLENGE -> triggerFajrChallenge(context)
                ACTION_FAJR_EXTRA_1 -> triggerFajrChallenge(context)
                ACTION_FAJR_EXTRA_2 -> triggerFajrChallenge(context)
                ACTION_SUHOOR -> triggerWakeUp(
                    context, SUHOOR_CHANNEL_ID, SUHOOR_NOTIFICATION_ID,
                    "وقت السحور", "حان وقت السحور قبل الفجر",
                    "Suhoor", "suhoor_timestamp",
                )
                ACTION_PRE_FAJR -> triggerWakeUp(
                    context, PREFAJR_CHANNEL_ID, PREFAJR_NOTIFICATION_ID,
                    "اقترب الفجر", "بقي القليل على أذان الفجر — استعد",
                    "PreFajr", "prefajr_timestamp",
                )
                ACTION_TAHAJJUD -> triggerWakeUp(
                    context, TAHAJJUD_CHANNEL_ID, TAHAJJUD_NOTIFICATION_ID,
                    "قيام الليل", "حان وقت التهجد — قم للصلاة",
                    "Tahajjud", "tahajjud_timestamp",
                )
                ACTION_BEDTIME -> triggerBedtime(context)
                ACTION_PRE_PRAYER -> {
                    val prayerName = intent.getStringExtra("prayer_name") ?: return
                    triggerPrePost(
                        context, PREPOST_CHANNEL_ID, PREPRAYER_NOTIFICATION_ID,
                        "اقتربت الصلاة",
                        "بقي القليل على ${arabicName(prayerName)} — استعد",
                        prayerName,
                    )
                }
                ACTION_POST_PRAYER -> {
                    val prayerName = intent.getStringExtra("prayer_name") ?: return
                    triggerPrePost(
                        context, PREPOST_CHANNEL_ID, POSTPRAYER_NOTIFICATION_ID,
                        "تقبل الله",
                        "انتهت صلاة ${arabicName(prayerName)} — لا تنس الأذكار",
                        prayerName,
                    )
                }
                ACTION_PRAYER -> {
                    val prayerName = intent.getStringExtra("prayer_name") ?: return
                    triggerPrayer(context, prayerName)
                }
            }
        } finally {
            // Do NOT wakeLock.release() here: the alarm audio (AlarmSound)
            // and the brought-to-front activity still need the CPU. The
            // 120s timeout above auto-releases as a safety net.
            try {
                pending.finish()
            } catch (_: Exception) {
            }
        }
    }

private fun notificationMode(context: Context): Int {
    val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    // Flutter's shared_preferences stores Dart ints as Java Long, so read the
    // raw value and coerce to Int instead of calling getInt (which would throw
    // a ClassCastException when the value was written from Dart).
    val value = flutterPrefs.all["flutter.notificationMode"]
    return when (value) {
        is Int -> value
        is Long -> value.toInt()
        is Number -> value.toInt()
        else -> 0
    }
}

    private fun triggerFajrChallenge(context: Context) {
        // 3 = "No alert"
        if (notificationMode(context) == 3) return
        createAlarmChannel(context)

        // Audible even when the Dart engine is dead (app killed / cold).
        // The challenge screen stops this on open and starts its own loop.
        // The notification itself stays silent to avoid double playback.
        AlarmSound.play(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("triggered_prayer", "Fajr_Challenge")
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0) or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = NotificationCompat.Builder(context, ALARM_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("تحدي الفجر")
            .setContentText("حان وقت الاستيقاظ لتحدي الفجر!")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setSound(null) // AlarmSound owns playback (audible when engine is dead)
        // Android 14+: full-screen intent requires user grant; otherwise fall
        // back to a heads-up notification instead of pretending it worked.
        if (canUseFullScreen(context)) {
            builder.setFullScreenIntent(pendingIntent, true)
        }
        val notification = builder.build()

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(ALARM_NOTIFICATION_ID, notification)

        // The full-screen intent may not auto-launch while the app is running
        // (device unlocked / app in foreground). Bring the activity to the front
        // directly so the challenge always opens immediately. If the system
        // blocks background activity starts, the notification above is the backup.
        try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (e: Exception) {
            // Blocked (background launch restriction) - rely on the notification.
        }
    }

    /**
     * Suhoor / Pre-Fajr wake-up path. Separate channel + ID + payload from the
     * Fajr challenge so the UI can never confuse "وقت السحور قبل الفجر" with
     * the actual Fajr prayer alarm. Uses setAlarmClock priority like Fajr.
     */
    private fun triggerWakeUp(
        context: Context,
        channelId: String,
        notificationId: Int,
        title: String,
        body: String,
        payload: String,
        prefKey: String,
    ) {
        if (notificationMode(context) == 3) return
        createChannel(context, channelId, title, NotificationManager.IMPORTANCE_HIGH)
        AlarmSound.play(context)

        // Mark consumed so a reboot cannot re-fire a stale alarm.
        try {
            context.getSharedPreferences("prayer_service_prefs", Context.MODE_PRIVATE)
                .edit().putBoolean("${prefKey}_triggered", true).apply()
        } catch (_: Exception) {
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("triggered_prayer", payload)
        }
        val pendingIntent = PendingIntent.getActivity(
            context, notificationId, intent,
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0) or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setSound(null)
        if (canUseFullScreen(context)) builder.setFullScreenIntent(pendingIntent, true)
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(notificationId, builder.build())
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
        }
    }

    /** Bedtime is informational: exact alarm but no alarm sound loop, no challenge. */    private fun triggerBedtime(context: Context) {
        if (notificationMode(context) == 3) return
        createChannel(context, BEDTIME_CHANNEL_ID, "Bedtime", NotificationManager.IMPORTANCE_HIGH)
        try {
            context.getSharedPreferences("prayer_service_prefs", Context.MODE_PRIVATE)
                .edit().putBoolean("bedtime_timestamp_triggered", true).apply()
        } catch (_: Exception) {
        }
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("triggered_prayer", "Bedtime")
        }
        val pendingIntent = PendingIntent.getActivity(
            context, BEDTIME_NOTIFICATION_ID, intent,
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0) or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val notification = NotificationCompat.Builder(context, BEDTIME_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("وقت النوم")
            .setContentText("حان وقت الاستعداد للنوم لتدرك الفجر")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(BEDTIME_NOTIFICATION_ID, notification)
    }

    /** Pre/post prayer: quiet informational reminder, no sound loop. */
    private fun triggerPrePost(
        context: Context,
        channelId: String,
        notificationId: Int,
        title: String,
        body: String,
        prayerName: String,
    ) {
        if (notificationMode(context) == 3) return
        createChannel(context, channelId, "Pre/Post prayer", NotificationManager.IMPORTANCE_DEFAULT)
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("screen_to_open", "prayer_times")
        }
        val pendingIntent = PendingIntent.getActivity(
            context, notificationId, intent,
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0) or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(notificationId, notification)
    }

    private fun arabicName(en: String): String = when (en) {
        "Fajr" -> "الفجر"
        "Sunrise" -> "الشروق"
        "Dhuhr" -> "الظهر"
        "Asr" -> "العصر"
        "Maghrib" -> "المغرب"
        "Isha" -> "العشاء"
        else -> en
    }

    private fun canUseFullScreen(context: Context): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= 34) {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.canUseFullScreenIntent()
            } else {
                true
            }
        } catch (_: Exception) {
            true
        }
    }

    private fun triggerPrayer(context: Context, prayerName: String) {
        if (notificationMode(context) == 3) return // No alert

        handleDndDuringPrayer(context, prayerName)

        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isSpecialTime = prayerName in listOf("Sunrise", "First Third", "Midnight", "Last Third")
        val isAyatEnabled = flutterPrefs.contains("flutter.ayat_hadith_$prayerName")
            && flutterPrefs.getBoolean("flutter.ayat_hadith_$prayerName", !isSpecialTime)
        if (!isAyatEnabled) return

        val serviceIntent = Intent(context, PrayerTimeService::class.java).apply {
            action = PrayerTimeService.ACTION_TRIGGER_AYAT
            putExtra("prayer_name", prayerName)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    private fun handleDndDuringPrayer(context: Context, prayerName: String) {
        if (prayerName !in listOf("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")) return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        try {
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val dndEnabled = flutterPrefs.getBoolean("flutter.dndDuringPrayerEnabled", false)
            if (!dndEnabled) return

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (!nm.isNotificationPolicyAccessGranted) return

            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)

            val durationMin = when (val v = flutterPrefs.all["flutter.dndDurationMinutes"]) {
                is Int -> v
                is Long -> v.toInt()
                is Number -> v.toInt()
                else -> 20
            }.coerceIn(5, 120)

            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try {
                    if (nm.isNotificationPolicyAccessGranted) {
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    }
                } catch (_: Exception) {}
            }, durationMin * 60_000L)
        } catch (_: Exception) {
        }
    }

    private fun createAlarmChannel(context: Context) {
        createChannel(context, ALARM_CHANNEL_ID, "Fajr Challenge Alarm", NotificationManager.IMPORTANCE_HIGH)
    }

    private fun createChannel(context: Context, id: String, name: String, importance: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(id, name, importance).apply {
                description = name
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            nm.createNotificationChannel(channel)
        }
    }
}
