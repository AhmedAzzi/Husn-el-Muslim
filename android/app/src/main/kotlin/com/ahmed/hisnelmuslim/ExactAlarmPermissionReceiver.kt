package com.ahmed.hisnelmuslim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Reacts to the user granting / revoking the exact-alarm permission
 * (Android 12+, `SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED`).
 *
 * - Granted  → re-arm everything from persisted prefs so the Fajr challenge
 *   and prayer alarms resume without the user reopening the app.
 * - Revoked  → cancel armed exact alarms (they can no longer fire) so we
 *   never report phantom successes; the service fallback + Dart timer keep
 *   a best-effort inexact path until permission returns.
 */
class ExactAlarmPermissionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED") return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        try {
            if (AlarmScheduler.canScheduleExact(context)) {
                Log.d("ExactAlarm", "Permission granted — rescheduling all alarms")
                BootReceiver.reschedule(context)
            } else {
                Log.d("ExactAlarm", "Permission revoked — cancelling armed exact alarms")
                AlarmScheduler.cancelAll(context)
            }
        } catch (e: Exception) {
            Log.w("ExactAlarm", "Handling failed: ${e.message}")
        }
    }
}
