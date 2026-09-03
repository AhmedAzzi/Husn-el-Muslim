package com.ahmed.hisnelmuslim

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log

/** Full prayer-screen replica widget (4x4): all prayers + spotlight. */
class PrayerWidgetLargeProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Never let anything escape: a throwing onUpdate = "can't load widget".
        val views = try {
            PrayerWidgetData.buildLarge(context)
        } catch (t: Throwable) {
            Log.e("PrayerWidget", "buildLarge failed", t)
            return
        }
        for (appWidgetId in appWidgetIds) {
            try {
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e("PrayerWidget", "update large failed", t)
            }
        }
    }
}
