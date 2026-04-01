package com.example.hisn_el_muslim

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class PrayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val widgetData = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget).apply {
                setTextViewText(R.id.next_prayer_countdown, widgetData.getString("flutter.prayer_countdown", widgetData.getString("prayer_countdown", "")))
                setTextViewText(R.id.fajr_time, widgetData.getString("flutter.fajr_time", widgetData.getString("fajr_time", "الفجر 05:00")))
                setTextViewText(R.id.sunrise_time, widgetData.getString("flutter.sunrise_time", widgetData.getString("sunrise_time", "الشروق 06:00")))
                setTextViewText(R.id.dhuhr_time, widgetData.getString("flutter.dhuhr_time", widgetData.getString("dhuhr_time", "الظهر 12:00")))
                setTextViewText(R.id.asr_time, widgetData.getString("flutter.asr_time", widgetData.getString("asr_time", "العصر 15:00")))
                setTextViewText(R.id.maghrib_time, widgetData.getString("flutter.maghrib_time", widgetData.getString("maghrib_time", "المغرب 18:00")))
                setTextViewText(R.id.isha_time, widgetData.getString("flutter.isha_time", widgetData.getString("isha_time", "العشاء 19:00")))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
