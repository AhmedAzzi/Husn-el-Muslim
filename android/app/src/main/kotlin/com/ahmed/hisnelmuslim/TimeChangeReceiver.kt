package com.ahmed.hisnelmuslim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Re-arms all exact alarms when wall-clock or timezone data changes.
 *
 * The Dart side recomputes prayer times on its minute tick / next launch and
 * calls back into [AlarmScheduler] with fresh timestamps; this receiver
 * guarantees the *native* AlarmManager side is rebuilt immediately (with
 * cancel-before-schedule, so no duplicates) instead of waiting for that tick.
 *
 * Actions are manifest-declared (see AndroidManifest.xml):
 * - ACTION_TIME_CHANGED (user / network set a new wall-clock time)
 * - ACTION_TIMEZONE_CHANGED (timezone / DST shift)
 * - ACTION_DATE_CHANGED (date rollover; delivered to manifest receivers on
 *   most OEMs, otherwise picked up on next process start)
 * - ACTION_MY_PACKAGE_REPLACED (app updated — all PendingIntents survive,
 *   but prayer times may be stale)
 */
class TimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d("TimeChange", "Clock/date/tz/package change: ${intent.action} — rescheduling")
                BootReceiver.reschedule(context)
            }
        }
    }
}
