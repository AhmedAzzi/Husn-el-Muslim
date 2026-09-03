package com.ahmed.hisnelmuslim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {

            Log.d("BootReceiver", "Device rebooted, rescheduling alarms and restarting PrayerTimeService")

            // Rebuild exact AlarmManager alarms from the persisted timestamps
            AlarmScheduler.scheduleAllFromPrefs(context)

            // Render cached data into any pinned widgets immediately
            try {
                PrayerWidgetData.updateAll(context)
            } catch (e: Exception) {
                Log.d("BootReceiver", "Widget refresh failed: ${e.message}")
            }

            val serviceIntent = Intent(context, PrayerTimeService::class.java)
            // The service will load its own last saved data from SharedPreferences
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}
