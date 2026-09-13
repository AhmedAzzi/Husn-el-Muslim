package com.ahmed.hisnelmuslim

import android.animation.ObjectAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import com.ahmed.hisnelmuslim.databinding.OverlayPrayerAlertBinding
import java.util.ArrayList

class PrayerTimeService : Service() {
    companion object {
        const val ACTION_TRIGGER_AYAT = "com.ahmed.hisnelmuslim.ACTION_TRIGGER_AYAT"
    }

    private val CHANNEL_ID = "prayer_notification_channel"
    private val NOTIFICATION_ID = 1001
    private val ALARM_CHANNEL_ID = "fajr_challenge_alarm_channel"
    private val ALARM_NOTIFICATION_ID = 9999
    private var handler: Handler? = null
    private var runnable: Runnable? = null
    private var mediaPlayer: MediaPlayer? = null
    private var lastWidgetUpdate: Long = 0

    // Properties
    private var hijriDate: String = ""
    private var prayerInfoOriginal: String = ""
    private var targetTimestamp: Long = 0
    private var targetPrayerName: String = ""
    private var nextTargetTimestamp: Long = 0
    private var nextTargetPrayerName: String = ""
    private var nextPrayerInfo: String = ""
    private var notificationMode: Int = 0
    private var challengeTimestamp: Long = 0
    private var challengeTriggered: Boolean = false
    private var prayerTriggered: Boolean = false
    private var serviceStartTime: Long = System.currentTimeMillis()

    private var isAyatShowing: Boolean = false

    // Dhikr floating reminder. A plain delegate — same foreground service,
    // same 1-second tick, no second timer/service. It owns the dhikr
    // interval, show/dismiss state, and overlay lifecycle; this service
    // only drives it from onTick and persists its state.
    private val dhikr = DhikrReminderDelegate(this)

    override fun onCreate() {
        super.onCreate()
        loadData()
    }

    override fun onBind(intent: Intent): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP_SERVICE") {
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        if (intent?.action == ACTION_TRIGGER_AYAT) {
            // Fired by PrayerAlarmReceiver (AlarmManager exact alarm)
            val prayerName = intent.getStringExtra("prayer_name") ?: "Fajr"
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isSpecialTime = prayerName in listOf("Sunrise", "First Third", "Midnight", "Last Third")
            val isAyatEnabled = flutterPrefs.getBoolean("flutter.ayat_hadith_$prayerName", !isSpecialTime)
            if (isAyatEnabled && notificationMode != 3) {
                triggerAyatHadithOverlay(prayerName)
            }
            return START_STICKY
        }

        if (intent?.action == "TEST_AYAT_OVERLAY") {
            triggerAyatHadithOverlay("Fajr")
            return START_STICKY
        }

        intent?.let { it ->
            hijriDate = it.getStringExtra("hijri_date") ?: hijriDate
            prayerInfoOriginal = it.getStringExtra("prayer_info") ?: prayerInfoOriginal
            val newTargetTimestamp = it.getLongExtra("target_timestamp", 0)
            if (newTargetTimestamp != targetTimestamp) {
                targetTimestamp = newTargetTimestamp
                prayerTriggered = false
            }
            targetPrayerName = it.getStringExtra("next_prayer_name") ?: targetPrayerName
            nextTargetTimestamp = it.getLongExtra("next_target_timestamp", 0)
            nextTargetPrayerName = it.getStringExtra("next_target_prayer_name") ?: nextTargetPrayerName
            nextPrayerInfo = it.getStringExtra("next_prayer_info") ?: nextPrayerInfo
            notificationMode = it.getIntExtra("notification_mode", 0)

            val newChallengeTimestamp = it.getLongExtra("challenge_timestamp", 0)
            if (newChallengeTimestamp != challengeTimestamp) {
                challengeTimestamp = newChallengeTimestamp
                challengeTriggered = false
            }

            val wasEnabled = dhikr.enabled
            dhikr.enabled = it.getBooleanExtra("dhikr_enabled", false)

            if (dhikr.enabled && (dhikr.lastTimestamp == 0L || !wasEnabled)) {
                dhikr.resetTimer(System.currentTimeMillis())
            }

            if (it.hasExtra("dhikr_interval")) {
                val oldInterval = dhikr.intervalMinutes
                dhikr.intervalMinutes = it.getIntExtra("dhikr_interval", 15)
                if (oldInterval != dhikr.intervalMinutes) {
                    dhikr.resetTimer(System.currentTimeMillis())
                }
            }

            val incomingList = it.getStringArrayListExtra("dhikr_list")
            if (incomingList != null) {
                dhikr.adhkar = ArrayList(incomingList)
            }

            saveData()
        }

        createNotificationChannel()
        createAlarmChannel()
        startUpdatingNotification()

        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Prayer Time Display", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Persistent display of prayer times"
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun createAlarmChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(ALARM_CHANNEL_ID, "Fajr Challenge Alarm", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Full screen alarm for Fajr Challenge"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun startUpdatingNotification() {
        handler?.removeCallbacksAndMessages(null)
        handler = Handler(Looper.getMainLooper())
        runnable = object : Runnable {
            override fun run() {
                updateNotification()
                handler?.postDelayed(this, 1000L)
            }
        }
        handler?.post(runnable!!)
    }

    private fun updateNotification() {
        val now = System.currentTimeMillis()

        // Keep home-screen widgets live. Per-second ticking is handled
        // natively by the Chronometer countdown; this 30s re-render only
        // advances prayer transitions and the static texts around them.
        if (now - lastWidgetUpdate >= 30_000L) {
            lastWidgetUpdate = now
            try {
                PrayerWidgetData.updateAll(this)
            } catch (e: Exception) {
                Log.w("PrayerTimeService", "Widget refresh failed: ${e.message}")
            }
        }

        var diff = targetTimestamp - now

        if (challengeTimestamp > 0 && !challengeTriggered) {
             val challengeDiff = challengeTimestamp - now
             if (challengeDiff <= 0 && challengeDiff > -60000) {
                 challengeTriggered = true
                 // Fallback trigger for when the exact alarm was missed
                 // (e.g. permission revoked). AlarmSound is idempotent, so no
                 // double playback if the receiver already fired.
                 AlarmSound.play(this)
                 triggerAlarm("تحدي الفجر", "حان وقت الاستيقاظ لتحدي الفجر!", "Fajr_Challenge")
                 // Also bring the app to the front directly: the full-screen
                 // intent may be suppressed while the app is in the foreground.
                 try {
                     val intent = Intent(this, MainActivity::class.java).apply {
                         action = Intent.ACTION_MAIN
                         addCategory(Intent.CATEGORY_LAUNCHER)
                         flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                 Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                 Intent.FLAG_ACTIVITY_SINGLE_TOP
                         putExtra("triggered_prayer", "Fajr_Challenge")
                     }
                     startActivity(intent)
                 } catch (e: Exception) {
                     // Blocked (background launch restriction) - rely on the notification.
                 }
             }
        }

        if (targetTimestamp > 0 && !prayerTriggered) {
             val prayerDiff = targetTimestamp - now
              if (prayerDiff <= 0 && prayerDiff > -60000) {
                  prayerTriggered = true
                  // Check user preference from Flutter SharedPreferences
                  val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                  val isSpecialTime = targetPrayerName in listOf("Sunrise", "First Third", "Midnight", "Last Third")
                  val isAyatEnabled = flutterPrefs.getBoolean("flutter.ayat_hadith_$targetPrayerName", !isSpecialTime)

                  if (isAyatEnabled && notificationMode != 3) {
                      triggerAyatHadithOverlay(targetPrayerName)
                  }
              }
        }

        // Dhikr heartbeat: same tick, no second timer. The delegate owns
        // the interval check and show/dismiss state; a fired show is
        // persisted exactly as before.
        if (dhikr.onTick(now, isAyatShowing)) {
            saveData()
        }

        if (diff < -5000 && nextTargetTimestamp > 0 && nextTargetTimestamp > now) {
            targetTimestamp = nextTargetTimestamp
            targetPrayerName = nextTargetPrayerName
            prayerTriggered = false
            prayerInfoOriginal = nextPrayerInfo
            nextTargetTimestamp = 0
            nextTargetPrayerName = ""
            nextPrayerInfo = ""
            diff = targetTimestamp - now
            saveData() // persist the roll-forward so BootReceiver can reschedule the new target
        }

        val remainingTimeText = when {
            diff > 0 -> {
                val hours = diff / 3600000
                val minutes = (diff / 60000) % 60
                val seconds = (diff / 1000) % 60
                String.format("%02d:%02d:%02d", hours, minutes, seconds)
            }
            diff > -60000 -> "الآن"
            else -> ""
        }

        val remainingWithComma = if (remainingTimeText.isNotEmpty()) "  - $remainingTimeText" else ""
        val notification = buildNotification(prayerInfoOriginal, remainingWithComma)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(prayerInfo: String, remainingTime: String): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("screen_to_open", "prayer_times")
        }

        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0) or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val refreshGpsIntent = Intent(this, RefreshGpsReceiver::class.java).apply {
            action = "com.ahmed.hisnelmuslim.ACTION_REFRESH_GPS"
        }

        val refreshGpsPendingIntent = PendingIntent.getBroadcast(
            this, 1, refreshGpsIntent,
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0) or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val collapsedView = RemoteViews(packageName, R.layout.notification_prayer_times).apply {
            setTextViewText(R.id.hijri_date, hijriDate)
            setTextViewText(R.id.prayer_info, prayerInfo)
            setTextViewText(R.id.remaining_time, remainingTime)
            setViewVisibility(R.id.button_row, android.view.View.GONE)
        }

        val expandedView = RemoteViews(packageName, R.layout.notification_prayer_times).apply {
            setTextViewText(R.id.hijri_date, hijriDate)
            setTextViewText(R.id.prayer_info, prayerInfo)
            setTextViewText(R.id.remaining_time, remainingTime)
            setViewVisibility(R.id.button_row, android.view.View.VISIBLE)
            setOnClickPendingIntent(R.id.open_app_button, openAppPendingIntent)
            setOnClickPendingIntent(R.id.refresh_gps_button, refreshGpsPendingIntent)
        }

        val uiMode = resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
        val titleColor = if (uiMode == android.content.res.Configuration.UI_MODE_NIGHT_YES) 0xFFFFFFFF.toInt() else 0xFF1A1A1A.toInt()
        val accentColor = if (uiMode == android.content.res.Configuration.UI_MODE_NIGHT_YES) 0xFFFFD700.toInt() else 0xFF996515.toInt()

        collapsedView.setTextColor(R.id.hijri_date, titleColor)
        collapsedView.setTextColor(R.id.prayer_info, titleColor)
        collapsedView.setTextColor(R.id.remaining_time, accentColor)

        expandedView.setTextColor(R.id.hijri_date, titleColor)
        expandedView.setTextColor(R.id.prayer_info, titleColor)
        expandedView.setTextColor(R.id.remaining_time, accentColor)
        expandedView.setTextColor(R.id.open_app_button, titleColor)
        expandedView.setTextColor(R.id.refresh_gps_button, titleColor)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(collapsedView)
            .setCustomBigContentView(expandedView)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .setShowWhen(false)
            .setWhen(serviceStartTime)
            .setOnlyAlertOnce(true)
            .setContentIntent(openAppPendingIntent)
            .build()
    }

    private fun triggerAlarm(title: String, body: String, prayerName: String?) {
        if (notificationMode == 3) return

        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            if (prayerName != null) putExtra("triggered_prayer", prayerName)
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0) or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, ALARM_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true)
            .setAutoCancel(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).notify(ALARM_NOTIFICATION_ID, notification)
    }

    private fun triggerAyatHadithOverlay(prayerName: String) {
        if (isAyatShowing) return
        isAyatShowing = true

        // The full-screen prayer alert has priority: fade out any visible
        // dhikr card first so the two overlays never stack (a dhikr card
        // surfacing from under a dismissed prayer alert looks like a
        // glitch double-show).
        dhikr.dismiss()

        Handler(Looper.getMainLooper()).post {
            val canDraw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                Settings.canDrawOverlays(this) else true

            if (!canDraw) {
                Log.w("PrayerTimeService", "No SYSTEM_ALERT_WINDOW permission – falling back to activity for Ayat dialog")
                val fallbackIntent = Intent(this, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("triggered_prayer", prayerName)
                }
                try { startActivity(fallbackIntent) } catch (e: Exception) {
                    Log.e("PrayerTimeService", "Ayat Fallback activity failed: ${e.message}")
                }
                return@post
            }

            // Start Adhan audio
            try {
                mediaPlayer?.release()
                mediaPlayer = MediaPlayer.create(this, R.raw.adan)
                mediaPlayer?.apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .build()
                    )
                    isLooping = false
                    start()
                }
            } catch (e: Exception) {
                Log.e("PrayerTimeService", "Failed to play Adhan: ${e.message}")
            }

            // Static structure is res/layout/overlay_prayer_alert.xml — only
            // the prayer title, the Amiri typeface and the animations are
            // bound in code via PrayerAlertUi (mirrors AyahOverlayUi).
            val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val arabicName = PrayerAlertUi.arabicName(prayerName)
            var alertBinding: OverlayPrayerAlertBinding? = null
            var iconPulse: ObjectAnimator? = null
            var dismissed = false

            val dismissOverlay = {
                if (!dismissed) {
                    dismissed = true
                    iconPulse?.cancel()
                    try {
                        mediaPlayer?.stop()
                        mediaPlayer?.release()
                        mediaPlayer = null
                    } catch (_: Exception) {
                    }
                    val view = alertBinding
                    if (view == null) {
                        isAyatShowing = false
                    } else {
                        try {
                            view.prayerAlertRoot.animate()
                                .alpha(0f)
                                .setDuration(400)
                                .withEndAction {
                                    try {
                                        wm.removeView(view.root)
                                    } catch (_: Exception) {
                                    }
                                    isAyatShowing = false
                                }
                                .start()
                        } catch (_: Exception) {
                            try {
                                wm.removeView(view.root)
                            } catch (_: Exception) {
                            }
                            isAyatShowing = false
                        }
                    }
                    sendBroadcast(Intent(this@PrayerTimeService, StopAdhanReceiver::class.java))
                }
            }

            try {
                val inflated = PrayerAlertUi.inflate(this, arabicName, dismissOverlay)
                PrayerAlertUi.fitContentToHeight(this, inflated)
                alertBinding = inflated
                wm.addView(inflated.root, PrayerAlertUi.overlayParams())
                iconPulse = PrayerAlertUi.startIconPulse(inflated.prayerAlertIcon)
                PrayerAlertUi.animateEntrance(inflated, resources.displayMetrics.density)
            } catch (e: Exception) {
                Log.e("PrayerTimeService", "Overlay failed: ${e.message}")
                dismissOverlay()
            }
        }
    }

    private fun saveData() {
        val prefs = getSharedPreferences("prayer_service_prefs", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putString("hijri_date", hijriDate)
            putString("prayer_info", prayerInfoOriginal)
            putLong("target_timestamp", targetTimestamp)
            putString("next_prayer_name", targetPrayerName)
            putLong("next_target_timestamp", nextTargetTimestamp)
            putString("next_target_prayer_name", nextTargetPrayerName)
            putString("next_prayer_info", nextPrayerInfo)
            putLong("challenge_timestamp", challengeTimestamp)
            putBoolean("challenge_triggered", challengeTriggered)
            putBoolean("prayer_triggered", prayerTriggered)
            putBoolean("dhikr_enabled", dhikr.enabled)
            putInt("dhikr_interval", dhikr.intervalMinutes)
            putLong("last_dhikr_timestamp", dhikr.lastTimestamp)
            putStringSet("dhikr_list", dhikr.adhkar.toSet())
            apply()
        }
    }

    private fun loadData() {
        val prefs = getSharedPreferences("prayer_service_prefs", Context.MODE_PRIVATE)
        hijriDate = prefs.getString("hijri_date", "") ?: ""
        prayerInfoOriginal = prefs.getString("prayer_info", "") ?: ""
        targetTimestamp = prefs.getLong("target_timestamp", 0)
        targetPrayerName = prefs.getString("next_prayer_name", "") ?: ""
        nextTargetTimestamp = prefs.getLong("next_target_timestamp", 0)
        nextTargetPrayerName = prefs.getString("next_target_prayer_name", "") ?: ""
        nextPrayerInfo = prefs.getString("next_prayer_info", "") ?: ""
        challengeTimestamp = prefs.getLong("challenge_timestamp", 0)
        challengeTriggered = prefs.getBoolean("challenge_triggered", false)
        prayerTriggered = prefs.getBoolean("prayer_triggered", false)
        dhikr.enabled = prefs.getBoolean("dhikr_enabled", false)
        dhikr.intervalMinutes = prefs.getInt("dhikr_interval", 15)
        dhikr.lastTimestamp = prefs.getLong("last_dhikr_timestamp", 0)
        val savedList: Set<String>? = prefs.getStringSet("dhikr_list", null)
        if (savedList != null) dhikr.adhkar = ArrayList(savedList.toList())
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        handler?.removeCallbacksAndMessages(null)
        super.onDestroy()
    }
}
