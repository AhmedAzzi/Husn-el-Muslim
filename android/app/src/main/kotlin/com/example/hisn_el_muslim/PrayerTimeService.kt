package com.example.hisn_el_muslim

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import android.media.RingtoneManager

class PrayerTimeService : Service() {
    private val CHANNEL_ID = "prayer_notification_channel"
    private val NOTIFICATION_ID = 1001
    private val ALARM_CHANNEL_ID = "fajr_challenge_alarm_channel"
    private val ALARM_NOTIFICATION_ID = 9999
    private var handler: Handler? = null
    private var runnable: Runnable? = null
    private var wakeLock: PowerManager.WakeLock? = null
    
    // Missing properties added
    private var hijriDate: String = ""
    private var prayerInfoOriginal: String = ""
    private var targetTimestamp: Long = 0
    private var isBlackBackground: Boolean = false
    
    private var nextTargetTimestamp: Long = 0
    private var nextPrayerInfo: String = ""
    
    private var challengeTimestamp: Long = 0
    private var challengeTriggered: Boolean = false
    private var lastTriggeredTimestamp: Long = 0
    private var targetPrayerName: String = ""
    private var serviceStartTime: Long = System.currentTimeMillis()

    override fun onCreate() {
        super.onCreate()
        loadData()
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP_SERVICE") {
            releaseWakeLock()
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        // Load data from intent
        intent?.let {
            hijriDate = it.getStringExtra("hijri_date") ?: hijriDate
            prayerInfoOriginal = it.getStringExtra("prayer_info") ?: prayerInfoOriginal
            targetTimestamp = it.getLongExtra("target_timestamp", 0) ?: targetTimestamp
            targetPrayerName = it.getStringExtra("next_prayer_name") ?: targetPrayerName
            
            nextTargetTimestamp = it.getLongExtra("next_target_timestamp", 0) ?: nextTargetTimestamp
            nextPrayerInfo = it.getStringExtra("next_prayer_info") ?: nextPrayerInfo
        
            val newChallengeTimestamp = it.getLongExtra("challenge_timestamp", 0) ?: challengeTimestamp
            if (newChallengeTimestamp != challengeTimestamp) {
                challengeTimestamp = newChallengeTimestamp
                challengeTriggered = false
            }
            saveData()
        }
        


        // Acquire wake lock to prevent CPU sleep
        acquireWakeLock()
        
        // Ensure both channels exist
        createNotificationChannel()
        createAlarmChannel()
        
        startUpdatingNotification()

        // START_STICKY ensures service restarts if killed by system
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Prayer Time Display"
            val descriptionText = "Persistent display of Hijri date and next prayer time"
            // Use IMPORTANCE_DEFAULT for better persistence on Samsung devices
            // LOW importance can be killed more aggressively by battery optimization
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                // Disable sound and vibration for persistent notification
                setSound(null, null)
                enableVibration(false)
                enableLights(false)
                // Lock screen visibility
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createAlarmChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Fajr Challenge Alarm"
            val descriptionText = "Full screen alarm for Fajr Challenge"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(ALARM_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                // We handle audio via player, but valid implementation might use channel sound
                // For now, let's keep it default or silent if app plays sound
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun startUpdatingNotification() {
        handler?.removeCallbacksAndMessages(null)
        handler = Handler(Looper.getMainLooper())
        
        runnable = object : Runnable {
            override fun run() {
                updateNotification()
                handler?.postDelayed(this, 1000)
            }
        }
        handler?.post(runnable!!)
    }
    
    // Helper to launch app
    private fun launchAppForChallenge() {
        try {
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            intent.addCategory(Intent.CATEGORY_LAUNCHER)
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun triggerAlarm(title: String, body: String, prayerName: String?) {
        // 1. Fire Full Screen Intent Notification (Standard Android Alarm behavior)
        // This will wake the screen and show an alert. 
        // We removed direct launch here so it stays behind lock screen.
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            if (prayerName != null) {
                putExtra("triggered_prayer", prayerName)
            }
        }
        
        val fullScreenPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.getActivity(this, 0, openAppIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        } else {
            PendingIntent.getActivity(this, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }

        val notification = NotificationCompat.Builder(this, ALARM_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setFullScreenIntent(fullScreenPendingIntent, true) // CRITICAL for full screen
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(ALARM_NOTIFICATION_ID, notification)
    }

    private fun launchAppWithPrayer(prayerName: String?) {
        try {
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            intent.addCategory(Intent.CATEGORY_LAUNCHER)
            if (prayerName != null) {
                intent.putExtra("triggered_prayer", prayerName)
            }
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun updateNotification() {
        val now = System.currentTimeMillis()
        var diff = targetTimestamp - now
        
        // Check Challenge Trigger
        if (challengeTimestamp > 0 && !challengeTriggered) {
             val challengeDiff = challengeTimestamp - now
             // Trigger if time reached (and not more than 60s past)
             if (challengeDiff <= 0 && challengeDiff > -60000) {
                 challengeTriggered = true
                 triggerAlarm("تحدي الفجر", "حان وقت الاستيقاظ لتحدي الفجر!", "Fajr_Challenge")
             }
        }

        // Check General Prayer Trigger
        if (targetTimestamp > 0 && lastTriggeredTimestamp != targetTimestamp) {
            val prayerDiff = targetTimestamp - now
            if (prayerDiff <= 0 && prayerDiff > -5000) { // 5s window for general prayers
                lastTriggeredTimestamp = targetTimestamp
                if (targetPrayerName != "الشروق") { // Usually don't alarm for Sunrise unless asked
                    triggerAlarm("وقت الصلاة", "حان الآن موعد أذان $targetPrayerName", targetPrayerName)
                }
            }
        }
        
        // Auto-switch to next prayer if current one passed
        // Switch immediately (within 5 seconds) to avoid showing blank time
        if (diff < -5000 && nextTargetTimestamp > 0 && nextTargetTimestamp > now) {
            targetTimestamp = nextTargetTimestamp
            prayerInfoOriginal = nextPrayerInfo
            // Reset next to 0 so we don't swap again until updated
            nextTargetTimestamp = 0 
            nextPrayerInfo = ""
            diff = targetTimestamp - now
        }
        
        val remainingTimeText = when {
            diff > 0 -> {
                // Show countdown
                val hours = diff / (1000 * 60 * 60)
                val minutes = (diff / (1000 * 60)) % 60
                val seconds = (diff / 1000) % 60
                String.format("%02d:%02d:%02d", hours, minutes, seconds)
            }
            diff > -60000 -> {
                // Prayer time is now (within 1 minute past)
                "الآن"
            }
            else -> {
                // Prayer time has passed, waiting for next update
                ""
            }
        }

        val remainingWithComma = if (remainingTimeText.isNotEmpty()) "  - $remainingTimeText" else ""
        val notification = buildNotification(prayerInfoOriginal, remainingWithComma)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID, 
                notification, 
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
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
        
        val openAppPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.getActivity(this, 0, openAppIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        } else {
            PendingIntent.getActivity(this, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }

        val refreshGpsIntent = Intent(this, RefreshGpsReceiver::class.java).apply {
            action = MainActivity.ACTION_REFRESH_GPS
        }

        val refreshGpsPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.getBroadcast(this, 1, refreshGpsIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        } else {
            PendingIntent.getBroadcast(this, 1, refreshGpsIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }

        val collapsedView = RemoteViews(packageName, R.layout.notification_prayer_times).apply {
            setTextViewText(R.id.hijri_date, hijriDate)
            setTextViewText(R.id.prayer_info, prayerInfo)
            setTextViewText(R.id.remaining_time, remainingTime)
            // Hide buttons in collapsed view
            setViewVisibility(R.id.button_row, android.view.View.GONE)
        }

        val expandedView = RemoteViews(packageName, R.layout.notification_prayer_times).apply {
            setTextViewText(R.id.hijri_date, hijriDate)
            setTextViewText(R.id.prayer_info, prayerInfo)
            setTextViewText(R.id.remaining_time, remainingTime)
            // Ensure buttons are visible in expanded view
            setViewVisibility(R.id.button_row, android.view.View.VISIBLE)
            setOnClickPendingIntent(R.id.open_app_button, openAppPendingIntent)
            setOnClickPendingIntent(R.id.refresh_gps_button, refreshGpsPendingIntent)
        }
        // Determine colors based on system style (Light/Dark mode)
        var titleColor = 0xFFFFFFFF.toInt()
        var bodyColor = 0xFFEEEEEE.toInt()
        var accentColor = 0xFFFFD700.toInt()
        
        val uiMode = resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
        if (uiMode == android.content.res.Configuration.UI_MODE_NIGHT_YES) {
            // Dark Mode: Light Text
            titleColor = 0xFFFFFFFF.toInt()
            bodyColor = 0xFFE0E0E0.toInt()
            accentColor = 0xFFFFD700.toInt() // Bright Gold
        } else {
            // Light Mode: Dark Text
            titleColor = 0xFF1A1A1A.toInt() // Almost Black
            bodyColor = 0xFF424242.toInt() // Dark Grey
            accentColor = 0xFF996515.toInt() // Dark Goldenrod / Brown for contrast
        }

        // Apply colors to views
        collapsedView.setTextColor(R.id.hijri_date, titleColor)
        collapsedView.setTextColor(R.id.prayer_info, titleColor) // White for Name + Time
        collapsedView.setTextColor(R.id.remaining_time, accentColor) // Specific color for Remaining Time
        // Buttons
        collapsedView.setTextColor(R.id.open_app_button, titleColor)
        collapsedView.setTextColor(R.id.refresh_gps_button, titleColor)

        expandedView.setTextColor(R.id.hijri_date, titleColor)
        expandedView.setTextColor(R.id.prayer_info, titleColor) // White for Name + Time
        expandedView.setTextColor(R.id.remaining_time, accentColor) // Specific color for Remaining Time
        expandedView.setTextColor(R.id.open_app_button, titleColor)
        expandedView.setTextColor(R.id.refresh_gps_button, titleColor)

        // Build notification with custom layouts
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(collapsedView)
            .setCustomBigContentView(expandedView)
            .setPriority(NotificationCompat.PRIORITY_LOW) // HIGH priority for better persistence
            .setCategory(NotificationCompat.CATEGORY_SERVICE) // Mark as service notification
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(false)
            .setWhen(serviceStartTime)
            .setSound(null)
            .setVibrate(null)
            .setOnlyAlertOnce(true)
            .setContentIntent(openAppPendingIntent)

        builder.setColorized(false)
            
        return builder.build()
    }
    
    private fun resolveColor(attr: Int): Int {
        val typedValue = android.util.TypedValue()
        val theme = applicationContext.theme
        theme.resolveAttribute(attr, typedValue, true)
        // Handle different types (color int vs resource id)
        if (typedValue.type >= android.util.TypedValue.TYPE_FIRST_INT && 
            typedValue.type <= android.util.TypedValue.TYPE_LAST_INT) {
            return typedValue.data
        } else if (typedValue.type == android.util.TypedValue.TYPE_STRING) {
             // Try to parse if it's a resource (unlikely for standard attrs usually direct color)
             return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    resources.getColor(typedValue.resourceId, theme)
                } else {
                    resources.getColor(typedValue.resourceId)
                }
             } catch(e: Exception) {
                 0xFF000000.toInt() // Fallback
             }
        }
        return 0xFF000000.toInt() // Fallback
    }    
    
    private fun acquireWakeLock() {
        try {
            if (wakeLock == null || wakeLock?.isHeld == false) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "PrayerTimeService::WakeLock"
                )
                // Acquire indefinitely - will be released in onDestroy
                wakeLock?.acquire()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
            wakeLock = null
        } catch (e: Exception) {
            e.printStackTrace()
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
            putString("next_prayer_info", nextPrayerInfo)
            putLong("challenge_timestamp", challengeTimestamp)
            putBoolean("challenge_triggered", challengeTriggered)
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
        nextPrayerInfo = prefs.getString("next_prayer_info", "") ?: ""
        challengeTimestamp = prefs.getLong("challenge_timestamp", 0)
        challengeTriggered = prefs.getBoolean("challenge_triggered", false)
    }
    
    override fun onTaskRemoved(rootIntent: Intent?) {
        // Ensure service continues even when app is swiped away
        super.onTaskRemoved(rootIntent)
        // Service will restart due to START_STICKY
    }
    
    override fun onDestroy() {
        handler?.removeCallbacksAndMessages(null)
        releaseWakeLock()
        super.onDestroy()
    }
}
