package com.ahmed.hisnelmuslim

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log

/** Compact full-width widget (4x1): next prayer + live countdown. */
class PrayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Never let anything escape: a throwing onUpdate = "can't load widget".
        val views = try {
            PrayerWidgetData.buildSmall(context)
        } catch (t: Throwable) {
            Log.e("PrayerWidget", "buildSmall failed", t)
            return
        }
        for (appWidgetId in appWidgetIds) {
            try {
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e("PrayerWidget", "update small failed", t)
            }
        }
    }
}
