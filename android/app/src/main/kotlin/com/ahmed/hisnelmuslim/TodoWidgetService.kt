package com.ahmed.hisnelmuslim

import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService

/** Collection backend for the todo widget list. */
class TodoWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        TodoWidgetViewsFactory(applicationContext)
}

class TodoWidgetViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private var rows: List<TodoWidgetData.TaskRow> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        // Rows are always dark cards; no theme state needed.
        rows = try {
            TodoWidgetData.loadRows(context)
        } catch (t: Throwable) {
            Log.w("TodoWidget", "factory load failed: ${t.message}")
            emptyList()
        }
    }

    override fun onDestroy() {
        rows = emptyList()
    }

    override fun getCount(): Int = rows.size

    override fun getViewAt(position: Int): RemoteViews {
        return try {
            TodoWidgetData.buildItem(context, rows[position])
        } catch (t: Throwable) {
            Log.w("TodoWidget", "getViewAt failed: ${t.message}")
            RemoteViews(context.packageName, R.layout.todo_widget_item)
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false
}
