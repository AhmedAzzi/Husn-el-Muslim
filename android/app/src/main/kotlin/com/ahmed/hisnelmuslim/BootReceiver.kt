package com.ahmed.hisnelmuslim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED -> {
                Log.d("BootReceiver", "Alarm reschedule trigger: ${intent.action}")
                reschedule(context)
            }
        }
    }

    companion object {
        /** Rebuild exact AlarmManager alarms + refresh widgets + restart service. */
        fun reschedule(context: Context) {
            // Rebuild exact AlarmManager alarms from the persisted timestamps
            try {
                AlarmScheduler.scheduleAllFromPrefs(context)
            } catch (e: Exception) {
                Log.w("BootReceiver", "Alarm reschedule failed: ${e.message}")
            }

            // Render cached data into any pinned widgets immediately
            try {
                PrayerWidgetData.updateAll(context)
            } catch (e: Exception) {
                Log.d("BootReceiver", "Widget refresh failed: ${e.message}")
            }

            // Direct-boot: the service needs user-unlocked storage; skip the
            // restart there (alarms are already re-armed above).
            try {
                val userLocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    context.getSystemService(android.os.UserManager::class.java)
                        ?.isUserUnlocked == false
                } else {
                    false
                }
                if (userLocked) return
            } catch (_: Exception) {
            }

            try {
                val serviceIntent = Intent(context, PrayerTimeService::class.java)
                // The service will load its own last saved data from SharedPreferences
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } catch (e: Exception) {
                Log.d("BootReceiver", "Service restart failed: ${e.message}")
            }
        }
    }
}
