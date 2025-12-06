package com.example.hisn_el_muslim

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.hisn_el_muslim/prayer_notification"
    private val NOTIFICATION_ID = 1001
    private val CHANNEL_ID = "prayer_notification_channel"
    
    companion object {
        const val ACTION_REFRESH_GPS = "com.example.hisn_el_muslim.ACTION_REFRESH_GPS"
        var methodChannel: MethodChannel? = null
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showPrayerNotification" -> {
                    val hijriDate = call.argument<String>("hijri_date") ?: ""
                    val prayerInfo = call.argument<String>("prayer_info") ?: ""
                    val remainingTime = call.argument<String>("remaining_time") ?: ""
                    
                    showPrayerNotification(hijriDate, prayerInfo, remainingTime)
                    result.success(true)
                }
                "hideNotification" -> {
                    hideNotification()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Prayer Time Notifications"
            val descriptionText = "Displays current Hijri date and next prayer time"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
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
        
        // Collapsed view (Small - Compact layout to fit all info)
        val collapsedView = android.widget.RemoteViews(packageName, R.layout.notification_prayer_times_small).apply {
            setTextViewText(R.id.hijri_date, hijriDate)
            setTextViewText(R.id.prayer_info, prayerInfo)
            setTextViewText(R.id.remaining_time, remainingTime)
            setOnClickPendingIntent(R.id.open_app_button, openAppPendingIntent)
            setOnClickPendingIntent(R.id.refresh_gps_button, refreshGpsPendingIntent)
        }

        // Expanded view (Large - Standard layout)
        val expandedView = android.widget.RemoteViews(packageName, R.layout.notification_prayer_times).apply {
            setTextViewText(R.id.hijri_date, hijriDate)
            setTextViewText(R.id.prayer_info, prayerInfo)
            setTextViewText(R.id.remaining_time, remainingTime)
            setOnClickPendingIntent(R.id.open_app_button, openAppPendingIntent)
            setOnClickPendingIntent(R.id.refresh_gps_button, refreshGpsPendingIntent)
        }
        
        // Build notification with custom layouts
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(collapsedView)  // Custom collapsed view
            .setCustomBigContentView(expandedView)  // Custom expanded view
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setOngoing(true)  // Makes it persistent (cannot be dismissed)
            .setAutoCancel(false)
            .setColor(0xFF693B42.toInt())  // App's primary color
            .setColorized(true)  // Apply color to entire notification
            .setShowWhen(true)  // Hide timestamp
            .setWhen(customTime)  // Inject custom time
            .setSound(null)  // No sound for persistent notification
            .setVibrate(null)  // No vibration
            .setContentIntent(openAppPendingIntent) // Open app on click
            .build()
        
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    private fun hideNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
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
