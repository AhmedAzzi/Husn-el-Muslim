package com.ahmed.hisnelmuslim

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Handles circle taps from the todo widget. Runs entirely natively
 * (same SQLite database Dart uses), so it works with a dead app process.
 * `exported=false`: shell broadcasts are blocked, but explicit widget
 * PendingIntents carry the app identity and are delivered fine.
 */
class TodoWidgetToggleReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_TOGGLE = "com.ahmed.hisnelmuslim.TODO_WIDGET_TOGGLE"
        const val EXTRA_TASK_ID = "task_id"

        /**
         * Template PendingIntent for the widget collection.
         *
         * MUST be MUTABLE (Android 12+): the system merges each row's
         * fill-in extras into this intent before delivery. An immutable
         * template silently drops the extras, so taps do nothing.
         */
        fun template(context: Context): PendingIntent {
            val intent = Intent(context, TodoWidgetToggleReceiver::class.java).apply {
                action = ACTION_TOGGLE
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                    PendingIntent.FLAG_MUTABLE else 0)
            return PendingIntent.getBroadcast(context, 20001, intent, flags)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TOGGLE) return
        val taskId = intent.getStringExtra(EXTRA_TASK_ID)
        if (taskId.isNullOrEmpty()) return
        try {
            TodoWidgetData.toggleTask(context.applicationContext, taskId)
        } catch (t: Throwable) {
            Log.w("TodoWidget", "toggle failed: ${t.message}")
        }
    }
}
