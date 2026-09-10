package com.ahmed.hisnelmuslim

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.view.WindowManager
import android.app.KeyguardManager
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ahmed.hisnelmuslim/prayer_notification"
    private val BATTERY_CHANNEL = "com.ahmed.hisnelmuslim/battery_optimization"
    private val LOCATION_CHANNEL = "com.ahmed.hisnelmuslim/location"
    private val NOTIFICATION_ID = 1001
    private val CHANNEL_ID = "prayer_notification_channel"
    private val BACKGROUND_LOCATION_REQUEST_CODE = 1002

    companion object {
        const val ACTION_REFRESH_GPS = "com.ahmed.hisnelmuslim.ACTION_REFRESH_GPS"
        var methodChannel: MethodChannel? = null
        var pendingScreen: String? = null
        var pendingTriggeredPrayer: String? = null
    }

    private val VOLUME_CHANNEL = "com.ahmed.hisnelmuslim/volume_lock"
    private var audioManager: android.media.AudioManager? = null
    private var originalVolume: Int = 0
    private var isVolumeLocked = false
    private var backgroundLocationResult: io.flutter.plugin.common.MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Keep the screen awake while the app is in the foreground. The
        // ability to render above the lock screen (showWhenLocked/turnScreenOn)
        // is applied dynamically ONLY when an alarm / Fajr challenge trigger
        // fires (see handleIntent), so a normal app launch stays off the keyguard.
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        // Reset any leaked show-when-locked flag (e.g. process died mid-alarm
        // while lock-screen mode was enabled). handleIntent() re-enables it
        // below for genuine alarm triggers.
        setLockScreenMode(false)

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val triggeredPrayer = intent?.getStringExtra("triggered_prayer")
        if (triggeredPrayer != null) {
            // This is an alarm / Fajr challenge trigger: allow the challenge
            // to render above the lock screen and wake the screen.
            setLockScreenMode(true)
            // Remember the trigger so it survives a cold start (Flutter may not
            // be ready to receive the method call yet).
            pendingTriggeredPrayer = triggeredPrayer
            // Wait slightly for Flutter to be ready if app was killed
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                methodChannel?.invokeMethod("triggerPrayerAlarm", mapOf("prayer_name" to triggeredPrayer))
            }, 1000)
        }

        val screenToOpen = intent?.getStringExtra("screen_to_open")
        if (screenToOpen != null) {
            pendingScreen = screenToOpen
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                methodChannel?.invokeMethod("openScreen", mapOf("screen_name" to screenToOpen))
            }, 1000)
        }

    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize AudioManager
        audioManager = getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager

        // Location Permission Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestBackgroundLocationPermission" -> {
                    requestBackgroundLocationPermission(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Volume Lock Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "lockVolumeAtMax" -> {
                    lockVolumeAtMax()
                    result.success(null)
                }
                "unlockVolume" -> {
                    unlockVolume()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Battery Optimization Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBatteryOptimizationEnabled" -> {
                    val isOptimized = isBatteryOptimizationEnabled()
                    result.success(isOptimized)
                }
                "openBatteryOptimizationSettings" -> {
                    val success = openBatteryOptimizationSettings()
                    result.success(success)
                }
                "requestIgnoreBatteryOptimization" -> {
                    val success = requestIgnoreBatteryOptimization()
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Notification Channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingScreen" -> {
                    result.success(pendingScreen)
                    pendingScreen = null // Clear after reading
                }
                "getPendingAlarm" -> {
                    result.success(pendingTriggeredPrayer)
                    pendingTriggeredPrayer = null // Clear after reading
                }
                "canScheduleExactAlarms" -> {
                    result.success(AlarmScheduler.canScheduleExact(this))
                }
                "openExactAlarmSettings" -> {
                    // Deep-link to the per-app "Alarms & reminders" screen (Android 12+).
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM
                            ).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.success(false)
                    }
                }
                "cancelAlarmNotification" -> {
                    AlarmSound.stop()
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    notificationManager.cancel(9999)
                    AlarmScheduler.cancelChallenge(this)
                    result.success(true)
                }
                "previewAlarmSound" -> {
                    AlarmSound.preview(this)
                    result.success(true)
                }
                "stopAlarmPreview" -> {
                    AlarmSound.stop()
                    result.success(true)
                }
                "showPrayerNotification" -> {
                    val hijriDate = call.argument<String>("hijri_date") ?: ""
                    val prayerInfo = call.argument<String>("prayer_info") ?: ""
                    val remainingTime = call.argument<String>("remaining_time") ?: ""

                    showPrayerNotification(hijriDate, prayerInfo, remainingTime)
                    result.success(true)
                }
                "startPrayerCountdown" -> {
                    val hijriDate = call.argument<String>("hijri_date") ?: ""
                    val prayerInfo = call.argument<String>("prayer_info") ?: ""
                    val targetTimestamp = call.argument<Number>("target_timestamp")?.toLong() ?: 0L
                    val nextTargetTimestamp = call.argument<Number>("next_target_timestamp")?.toLong() ?: 0L
                    val challengeTimestamp = call.argument<Number>("challenge_timestamp")?.toLong() ?: 0L
                    val nextPrayerInfo = call.argument<String>("next_prayer_info") ?: ""
                    val nextPrayerName = call.argument<String>("next_prayer_name") ?: ""
                    val nextTargetPrayerName = call.argument<String>("next_target_prayer_name") ?: ""
                    val notificationMode = call.argument<Int>("notification_mode") ?: 0
                    val isBlackBackground = call.argument<Boolean>("is_black_background") ?: false

                    // Dhikr parameters
                    val dhikrEnabled = call.argument<Boolean>("dhikr_enabled") ?: false
                    val dhikrInterval = call.argument<Int>("dhikr_interval") ?: 15
                    val dhikrList = call.argument<List<String>>("dhikr_list")

                    val serviceIntent = Intent(this, PrayerTimeService::class.java).apply {
                        putExtra("hijri_date", hijriDate)
                        putExtra("prayer_info", prayerInfo)
                        putExtra("target_timestamp", targetTimestamp)
                        putExtra("next_target_timestamp", nextTargetTimestamp)
                        putExtra("challenge_timestamp", challengeTimestamp)
                        putExtra("next_prayer_info", nextPrayerInfo)
                        putExtra("next_prayer_name", nextPrayerName)
                        putExtra("next_target_prayer_name", nextTargetPrayerName)
                        putExtra("notification_mode", notificationMode)
                        putExtra("is_black_background", isBlackBackground)

                        // Pass Dhikr extras
                        putExtra("dhikr_enabled", dhikrEnabled)
                        putExtra("dhikr_interval", dhikrInterval)
                        if (dhikrList != null) {
                            putStringArrayListExtra("dhikr_list", ArrayList(dhikrList))
                        }
                    }

                    // Exact alarm scheduling (reference-app parity):
                    // reschedule everything whenever the timestamps change.
                    AlarmScheduler.cancelAll(this)
                    if (challengeTimestamp > 0) {
                        AlarmScheduler.scheduleChallenge(this, challengeTimestamp)
                    }
                    if (targetTimestamp > 0 && nextPrayerName.isNotEmpty()) {
                        AlarmScheduler.schedulePrayer(this, nextPrayerName, targetTimestamp)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                "testFajrChallengeAlarm" -> {
                    val delaySeconds = call.argument<Int>("delay_seconds") ?: 5
                    // Return the REAL outcome: false when exact alarms are not
                    // permitted, so the UI never reports a phantom success.
                    result.success(AlarmScheduler.testChallenge(this, delaySeconds))
                }
                "scheduleFajrChallengeAlarm" -> {
                    val challengeTimestamp =
                        call.argument<Number>("challenge_timestamp")?.toLong() ?: 0L
                    AlarmScheduler.cancelChallenge(this)
                    if (challengeTimestamp > 0) {
                        result.success(
                            AlarmScheduler.scheduleChallenge(this, challengeTimestamp)
                        )
                    } else {
                        result.success(true)
                    }
                }
                "scheduleSuhoorAlarm" -> {
                    val ts = call.argument<Number>("trigger_at")?.toLong() ?: 0L
                    AlarmScheduler.cancelSuhoor(this)
                    result.success(if (ts > 0) AlarmScheduler.scheduleSuhoor(this, ts) else true)
                }
                "schedulePreFajrAlarm" -> {
                    val ts = call.argument<Number>("trigger_at")?.toLong() ?: 0L
                    AlarmScheduler.cancelPreFajr(this)
                    result.success(if (ts > 0) AlarmScheduler.schedulePreFajr(this, ts) else true)
                }
                "scheduleTahajjudAlarm" -> {
                    val ts = call.argument<Number>("trigger_at")?.toLong() ?: 0L
                    AlarmScheduler.cancelTahajjud(this)
                    result.success(if (ts > 0) AlarmScheduler.scheduleTahajjud(this, ts) else true)
                }
                "scheduleFajrExtra1Alarm" -> {
                    val ts = call.argument<Number>("trigger_at")?.toLong() ?: 0L
                    AlarmScheduler.cancelFajrExtra1(this)
                    result.success(if (ts > 0) AlarmScheduler.scheduleFajrExtra1(this, ts) else true)
                }
                "scheduleFajrExtra2Alarm" -> {
                    val ts = call.argument<Number>("trigger_at")?.toLong() ?: 0L
                    AlarmScheduler.cancelFajrExtra2(this)
                    result.success(if (ts > 0) AlarmScheduler.scheduleFajrExtra2(this, ts) else true)
                }
                "scheduleBedtimeAlarm" -> {
                    val ts = call.argument<Number>("trigger_at")?.toLong() ?: 0L
                    AlarmScheduler.cancelBedtime(this)
                    result.success(if (ts > 0) AlarmScheduler.scheduleBedtime(this, ts) else true)
                }
                "schedulePrePrayerAlarm" -> {
                    val ts = call.argument<Number>("trigger_at")?.toLong() ?: 0L
                    val name = call.argument<String>("prayer_name") ?: ""
                    AlarmScheduler.cancelPrePrayer(this)
                    result.success(if (ts > 0 && name.isNotEmpty()) AlarmScheduler.schedulePrePrayer(this, name, ts) else true)
                }
                "schedulePostPrayerAlarm" -> {
                    val ts = call.argument<Number>("trigger_at")?.toLong() ?: 0L
                    val name = call.argument<String>("prayer_name") ?: ""
                    AlarmScheduler.cancelPostPrayer(this)
                    result.success(if (ts > 0 && name.isNotEmpty()) AlarmScheduler.schedulePostPrayer(this, name, ts) else true)
                }
                "rescheduleAllAlarms" -> {
                    try {
                        AlarmScheduler.scheduleAllFromPrefs(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "getAlarmDiagnostics" -> {
                    try {
                        result.success(AlarmScheduler.diagnostics(this))
                    } catch (e: Exception) {
                        result.success("diagnostics failed: ${e.message}")
                    }
                }
                "checkOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivityForResult(intent, 1234)
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                }
                "updatePrayerWidgets" -> {
                    PrayerWidgetData.updateAll(this)
                    result.success(true)
                }
                "hideNotification" -> {
                    hideNotification()
                    val stopIntent = Intent(this, PrayerTimeService::class.java).apply {
                        action = "STOP_SERVICE"
                    }
                    startService(stopIntent)
                    result.success(true)
                }
                "bringAppToForeground" -> {
                    bringAppToForeground()
                    result.success(true)
                }
                "enableLockScreenMode" -> {
                    setLockScreenMode(true)
                    result.success(true)
                }
                "disableLockScreenMode" -> {
                    setLockScreenMode(false)
                    result.success(true)
                }
                "testAyatOverlay" -> {
                    val intent = Intent(this, PrayerTimeService::class.java).apply {
                        action = "TEST_AYAT_OVERLAY"
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "isDndAccessGranted" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        result.success(nm.isNotificationPolicyAccessGranted)
                    } else {
                        result.success(true)
                    }
                }
                "openDndSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.success(false)
                    }
                }
                "setDndMode" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        if (nm.isNotificationPolicyAccessGranted) {
                            try {
                                if (enable) {
                                    nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                                } else {
                                    nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                                }
                                result.success(true)
                            } catch (e: Exception) {
                                e.printStackTrace()
                                result.success(false)
                            }
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(true)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun bringAppToForeground() {
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)
        startActivity(intent)
    }

    /**
     * Toggles the ability to render the activity above the keyguard and to
     * wake the screen. Used ONLY while an alarm / Fajr challenge is active.
     */
    @Suppress("DEPRECATION")
    private fun setLockScreenMode(enable: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(enable)
            setTurnScreenOn(enable)
        } else {
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            if (enable) {
                window.addFlags(flags)
            } else {
                window.clearFlags(flags)
            }
        }
    }

    private fun requestBackgroundLocationPermission(result: io.flutter.plugin.common.MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ requires separate background location permission
            backgroundLocationResult = result
            requestPermissions(
                arrayOf(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                BACKGROUND_LOCATION_REQUEST_CODE
            )
        } else {
            // Pre-Android 10 doesn't need separate background permission
            result.success(true)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == BACKGROUND_LOCATION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                         grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED
            backgroundLocationResult?.success(granted)
            backgroundLocationResult = null
        }
    }


    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Prayer Time Display"
            val descriptionText = "Persistent display of Hijri date and next prayer time"
            // Use IMPORTANCE_LOW for silent persistent notification
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                // Disable sound and vibration for persistent notification
                setSound(null, null)
                enableVibration(false)
                enableLights(false)
            }

            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showPrayerNotification(hijriDate: String, prayerInfo: String, remainingTime: String) {
        createNotificationChannel()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val customTime = System.currentTimeMillis()

        // Create an Intent for opening the app (bring to front if running, launch if not)
        val openAppIntent = Intent(this, MainActivity::class.java)
        openAppIntent.action = Intent.ACTION_MAIN
        openAppIntent.addCategory(Intent.CATEGORY_LAUNCHER)
        openAppIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        openAppIntent.putExtra("screen_to_open", "prayer_times")

        val openAppPendingIntent: PendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.getActivity(this, 0, openAppIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        } else {
            PendingIntent.getActivity(this, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }

        // Create an Intent for refreshing GPS
        val refreshGpsIntent = Intent(this, RefreshGpsReceiver::class.java)
        refreshGpsIntent.action = ACTION_REFRESH_GPS

        val refreshGpsPendingIntent: PendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.getBroadcast(this, 1, refreshGpsIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        } else {
            PendingIntent.getBroadcast(this, 1, refreshGpsIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }

        val remainingWithComma = if (remainingTime.isNotEmpty()) "  - $remainingTime" else ""

        // Collapsed view (Small - Compact layout to fit all info)
        val collapsedView = android.widget.RemoteViews(packageName, R.layout.notification_prayer_times).apply {
            setTextViewText(R.id.hijri_date, hijriDate)
            setTextViewText(R.id.prayer_info, prayerInfo)
            setTextViewText(R.id.remaining_time, remainingWithComma)
            // Hide buttons in collapsed view
            setViewVisibility(R.id.button_row, android.view.View.GONE)
            setOnClickPendingIntent(R.id.open_app_button, openAppPendingIntent)
            setOnClickPendingIntent(R.id.refresh_gps_button, refreshGpsPendingIntent)
        }

        // Expanded view (Large - Standard layout)
        val expandedView = android.widget.RemoteViews(packageName, R.layout.notification_prayer_times).apply {
            setTextViewText(R.id.hijri_date, hijriDate)
            setTextViewText(R.id.prayer_info, prayerInfo)
            setTextViewText(R.id.remaining_time, remainingWithComma)
            // Ensure buttons are visible in expanded view
            setViewVisibility(R.id.button_row, android.view.View.VISIBLE)
            setOnClickPendingIntent(R.id.open_app_button, openAppPendingIntent)
            setOnClickPendingIntent(R.id.refresh_gps_button, refreshGpsPendingIntent)
        }

        // Build notification with custom layouts
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(collapsedView)  // Custom collapsed view
            .setCustomBigContentView(expandedView)  // Custom expanded view
            .setPriority(NotificationCompat.PRIORITY_LOW) // Low priority for silent updates
            .setOngoing(true)  // Makes it persistent (cannot be dismissed)
            .setAutoCancel(false)
            .setColor(0xFF693B42.toInt())  // App's primary color
            .setColorized(true)  // Apply color to entire notification
            .setShowWhen(false)
            .setSound(null)  // No sound for persistent notification
            .setVibrate(null)  // No vibration
            .setOnlyAlertOnce(true) // Prevent alerting on updates
            .setContentIntent(openAppPendingIntent) // Open app on click
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun hideNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
    }

    private fun lockVolumeAtMax() {
        audioManager?.let { am ->
            try {
                // Save original volume
                originalVolume = am.getStreamVolume(android.media.AudioManager.STREAM_MUSIC)

                // Set to max volume
                val maxVolume = am.getStreamMaxVolume(android.media.AudioManager.STREAM_MUSIC)
                am.setStreamVolume(android.media.AudioManager.STREAM_MUSIC, maxVolume, 0)

                isVolumeLocked = true
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun unlockVolume() {
        audioManager?.let { am ->
            try {
                // Restore original volume
                am.setStreamVolume(android.media.AudioManager.STREAM_MUSIC, originalVolume, 0)
                isVolumeLocked = false
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: android.view.KeyEvent?): Boolean {
        // Intercept volume key presses
        if (isVolumeLocked) {
            when (keyCode) {
                android.view.KeyEvent.KEYCODE_VOLUME_DOWN,
                android.view.KeyEvent.KEYCODE_VOLUME_UP -> {
                    // Keep volume at max
                    audioManager?.let { am ->
                        val maxVolume = am.getStreamMaxVolume(android.media.AudioManager.STREAM_MUSIC)
                        am.setStreamVolume(android.media.AudioManager.STREAM_MUSIC, maxVolume, 0)
                    }
                    return true // Consume the event
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    // Battery Optimization Methods
    private fun isBatteryOptimizationEnabled(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            val packageName = packageName
            return !powerManager.isIgnoringBatteryOptimizations(packageName)
        }
        return false // Pre-M devices don't have battery optimization
    }

    private fun openBatteryOptimizationSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun requestIgnoreBatteryOptimization(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
                true
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }
        return false
    }
}

class RefreshGpsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == MainActivity.ACTION_REFRESH_GPS) {
            // Call Flutter method to refresh GPS
            MainActivity.methodChannel?.invokeMethod("refreshGps", null)
        }
    }
}

class StopAdhanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        // Stop native alarm audio first (covers receiver/service playback).
        AlarmSound.stop()

        // Call Flutter method to stop audio
        MainActivity.methodChannel?.invokeMethod("stopAdhan", null)

        // Dismiss the notification
        val notificationManager = context?.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(9999) // ALARM_NOTIFICATION_ID
    }
}
