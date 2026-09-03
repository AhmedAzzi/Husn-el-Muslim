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
        private const val ALARM_CHANNEL_ID = "fajr_challenge_alarm_channel"
        private const val ALARM_NOTIFICATION_ID = 9999
    }

    override fun onReceive(context: Context, intent: Intent) {
        // Keep CPU alive while the alarm rings (auto-released after 2 minutes).
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Husn:AlarmWakeLock").apply {
            setReferenceCounted(false)
            acquire(120_000L)
        }
        try {
            when (intent.action) {
                ACTION_FAJR_CHALLENGE -> triggerFajrChallenge(context)
                ACTION_PRAYER -> {
                    val prayerName = intent.getStringExtra("prayer_name") ?: return
                    triggerPrayer(context, prayerName)
                }
            }
        } finally {
            wakeLock.release()
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

        val notification = NotificationCompat.Builder(context, ALARM_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("تحدي الفجر")
            .setContentText("حان وقت الاستيقاظ لتحدي الفجر!")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setSound(null) // AlarmSound owns playback (audible when engine is dead)
            .build()

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

    private fun triggerPrayer(context: Context, prayerName: String) {
        if (notificationMode(context) == 3) return // No alert
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

    private fun createAlarmChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                ALARM_CHANNEL_ID,
                "Fajr Challenge Alarm",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Full screen alarm for Fajr Challenge"
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            nm.createNotificationChannel(channel)
        }
    }
}
