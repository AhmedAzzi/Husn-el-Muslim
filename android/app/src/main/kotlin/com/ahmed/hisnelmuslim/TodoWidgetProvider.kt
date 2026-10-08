package com.ahmed.hisnelmuslim

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log

/** Interactive todo widget (4x3): tap the circle to mark a task done. */
class TodoWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Never let anything escape: a throwing onUpdate = "can't load widget".
        val views = try {
            TodoWidgetData.build(context)
        } catch (t: Throwable) {
            Log.e("TodoWidget", "build failed", t)
            return
        }
        for (appWidgetId in appWidgetIds) {
            try {
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (t: Throwable) {
                Log.e("TodoWidget", "update failed", t)
            }
        }
    }
}
