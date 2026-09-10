package com.ahmed.hisnelmuslim

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log

/** Tracking widget (2x1): streak + today's 5-prayer progress. Tap opens the tracker. */
class TrackingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val views = try {
            PrayerWidgetData.buildTracking(context)
        } catch (t: Throwable) {
            Log.e("TrackingWidget", "buildTracking failed", t)
            return
        }
        for (appWidgetId in appWidgetIds) {
            try {
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e("TrackingWidget", "update failed", t)
            }
        }
    }
}
