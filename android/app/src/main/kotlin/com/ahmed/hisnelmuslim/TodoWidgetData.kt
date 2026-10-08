package com.ahmed.hisnelmuslim

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar

/**
 * Interactive todo home-screen widget: tap the circle to mark a task done
 * without opening the app.
 *
 * Single source of truth is the same SQLite database Dart uses
 * (`khatma_app.db`, table `todo_tasks`). Dart publishes the absolute path
 * once in `FlutterSharedPreferences` (`flutter.todo_db_path`); the fallback
 * is the standard `getDatabasePath` location.
 *
 * Toggle semantics mirror `TodoController.toggleTaskCompletion`:
 * flip `is_completed` (+ timestamps), spawn the next recurrence for
 * repeating tasks, and cancel the exact reminder alarm (id persisted by
 * Dart in `flutter.todo_notif_id_<taskId>` — Dart `hashCode` is not
 * reproducible in Kotlin, hence the mapping).
 */
object TodoWidgetData {

    private const val TAG = "TodoWidget"
    private const val PREFS_DB_PATH = "flutter.todo_db_path"
    private const val MAX_ITEMS = 8
    private const val MAX_ACTIVE = 7

    // ---- Theme palette (mirrors the app) ----
    private const val DARK_TITLE = 0xFFFFFFFF.toInt()
    private const val DARK_SUBTLE = 0xFFB9B9C4.toInt()
    private const val DARK_DIM = 0xFF8E8E9A.toInt()
    private const val DARK_OVERDUE = 0xFFFF7A93.toInt()
    private const val DARK_COUNT = 0xFFFFD700.toInt()

    private const val LIGHT_TITLE = 0xFF1A1A1A.toInt()
    private const val LIGHT_SUBTLE = 0xFF5A5A5A.toInt()
    private const val LIGHT_DIM = 0xFF9A9AA5.toInt()
    private const val LIGHT_OVERDUE = 0xFFD64463.toInt()
    private const val LIGHT_COUNT = 0xFF996515.toInt()

    data class TaskRow(
        val id: String,
        val title: String,
        val done: Boolean,
        val dueDate: String?, // yyyy-MM-dd (from ISO), null when undated
        val dueTime: String?, // HH:MM, null when unset
        val sortOrder: Int,
        val completedAtMs: Long,
    )

    data class DueLabel(val text: String, val overdue: Boolean)

    // ------------------------------ database ------------------------------

    private fun dbPath(context: Context): String {
        try {
            val p = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            val saved = p.getString(PREFS_DB_PATH, "") ?: ""
            if (saved.isNotEmpty()) return saved
        } catch (_: Exception) {
        }
        return context.getDatabasePath("khatma_app.db").absolutePath
    }

    private fun openDb(context: Context, writable: Boolean): SQLiteDatabase {
        val mode = if (writable) SQLiteDatabase.OPEN_READWRITE
        else SQLiteDatabase.OPEN_READONLY
        return SQLiteDatabase.openDatabase(dbPath(context), null, mode)
    }

    private fun Cursor.optStringCol(name: String): String? {
        val i = getColumnIndex(name)
        return if (i < 0 || isNull(i)) null else getString(i)
    }

    private fun Cursor.optIntCol(name: String, fallback: Int = 0): Int {
        val i = getColumnIndex(name)
        return if (i < 0 || isNull(i)) fallback else getInt(i)
    }

    private fun mapRow(c: Cursor): TaskRow {
        val dueIso = c.optStringCol("due_date")
        return TaskRow(
            id = c.getString(c.getColumnIndexOrThrow("id")),
            title = c.getString(c.getColumnIndexOrThrow("title")) ?: "",
            done = c.optIntCol("is_completed") == 1,
            dueDate = dueIso?.takeIf { it.length >= 10 }?.substring(0, 10),
            dueTime = c.optStringCol("due_time")?.takeIf { it.contains(":") },
            sortOrder = c.optIntCol("sort_order"),
            completedAtMs = parseIsoMs(c.optStringCol("completed_at")),
        )
    }

    /** Local "yyyy-MM-dd" for today scoping (matches Dart DateTime.now()). */
    private fun todayStr(): String =
        java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
            .format(java.util.Date())

    /**
     * Today only, mirroring the app's Today filter (due today or overdue).
     * Active first (manual order), then tasks completed today — capped.
     * due_date/completed_at are Dart ISO strings; first 10 chars are the
     * local yyyy-MM-dd, so plain string comparison is date-correct.
     */
    fun loadRows(context: Context): List<TaskRow> {
        val today = todayStr()
        var db: SQLiteDatabase? = null
        try {
            db = openDb(context, false)
            val rows = mutableListOf<TaskRow>()
            var c: Cursor? = null
            try {
                c = db.rawQuery(
                    "SELECT id,title,is_completed,due_date,due_time," +
                        "sort_order,completed_at FROM todo_tasks " +
                        "WHERE is_completed=0 " +
                        "AND length(due_date) >= 10 " +
                        "AND substr(due_date,1,10) <= ? " +
                        "ORDER BY sort_order ASC LIMIT $MAX_ACTIVE",
                    arrayOf(today)
                )
                while (c.moveToNext()) rows.add(mapRow(c))
            } finally {
                c?.close()
            }
            if (rows.size < MAX_ITEMS) {
                var c2: Cursor? = null
                try {
                    c2 = db.rawQuery(
                        "SELECT id,title,is_completed,due_date,due_time," +
                            "sort_order,completed_at FROM todo_tasks " +
                            "WHERE is_completed=1 " +
                            "AND length(completed_at) >= 10 " +
                            "AND substr(completed_at,1,10) = ? " +
                            "ORDER BY completed_at DESC LIMIT ${MAX_ITEMS - rows.size}",
                        arrayOf(today)
                    )
                    while (c2.moveToNext()) rows.add(mapRow(c2))
                } finally {
                    c2?.close()
                }
            }
            return rows
        } finally {
            try {
                db?.close()
            } catch (_: Exception) {
            }
        }
    }

    /** Returns (doneToday, totalToday) scoped to the same today filter. */
    fun loadCounts(context: Context): Pair<Int, Int> {
        val today = todayStr()
        var db: SQLiteDatabase? = null
        var c: Cursor? = null
        try {
            db = openDb(context, false)
            c = db.rawQuery(
                "SELECT " +
                    "(SELECT COUNT(*) FROM todo_tasks " +
                    "WHERE is_completed=0 " +
                    "AND length(due_date) >= 10 " +
                    "AND substr(due_date,1,10) <= ?), " +
                    "(SELECT COUNT(*) FROM todo_tasks " +
                    "WHERE is_completed=1 " +
                    "AND length(completed_at) >= 10 " +
                    "AND substr(completed_at,1,10) = ?)",
                arrayOf(today, today)
            )
            return if (c.moveToFirst()) {
                val active = c.getInt(0)
                val done = c.getInt(1)
                Pair(done, active + done)
            } else {
                Pair(0, 0)
            }
        } catch (_: Exception) {
            return Pair(0, 0)
        } finally {
            try {
                c?.close()
            } catch (_: Exception) {
            }
            try {
                db?.close()
            } catch (_: Exception) {
            }
        }
    }

    // ------------------------------ dates ------------------------------

    /** Parses "yyyy-MM-ddTHH:mm:ss.SSS" (Dart toIso8601String shape). */
    private fun parseIsoMs(iso: String?): Long {
        if (iso == null || iso.length < 10) return 0L
        return try {
            val y = iso.substring(0, 4).toInt()
            val m = iso.substring(5, 7).toInt()
            val d = iso.substring(8, 10).toInt()
            var hh = 0
            var mm = 0
            var ss = 0
            if (iso.length >= 16) {
                hh = iso.substring(11, 13).toInt()
                mm = iso.substring(14, 16).toInt()
                if (iso.length >= 19) ss = iso.substring(17, 19).toInt()
            }
            val cal = Calendar.getInstance()
            cal.set(y, m - 1, d, hh, mm, ss)
            cal.set(Calendar.MILLISECOND, 0)
            cal.timeInMillis
        } catch (_: Exception) {
            0L
        }
    }

    private fun formatIsoMs(ms: Long): String {
        val cal = Calendar.getInstance()
        cal.timeInMillis = ms
        return "%04d-%02d-%02dT%02d:%02d:%02d.000".format(
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH) + 1,
            cal.get(Calendar.DAY_OF_MONTH),
            cal.get(Calendar.HOUR_OF_DAY),
            cal.get(Calendar.MINUTE),
            cal.get(Calendar.SECOND),
        )
    }

    private fun nowIso(): String = formatIsoMs(System.currentTimeMillis())

    /** Mirrors Dart `isOverdue` labeling for the widget row. */
    fun dueLabel(row: TaskRow, nowMs: Long): DueLabel? {
        val dd = row.dueDate ?: return null
        if (dd.length < 10) return null
        val y = dd.substring(0, 4).toIntOrNull() ?: return null
        val m = dd.substring(5, 7).toIntOrNull() ?: return null
        val d = dd.substring(8, 10).toIntOrNull() ?: return null

        val today = Calendar.getInstance()
        val day = Calendar.getInstance()
        day.set(y, m - 1, d, 0, 0, 0)
        day.set(Calendar.MILLISECOND, 0)
        val todayStart = Calendar.getInstance()
        todayStart.set(
            today.get(Calendar.YEAR),
            today.get(Calendar.MONTH),
            today.get(Calendar.DAY_OF_MONTH), 0, 0, 0
        )
        todayStart.set(Calendar.MILLISECOND, 0)

        val dayMs = day.timeInMillis
        val todayMs = todayStart.timeInMillis
        return when {
            dayMs < todayMs -> DueLabel("متأخرة", true)
            dayMs == todayMs -> {
                val t = row.dueTime
                if (t != null && t.length >= 5) {
                    val hh = t.substring(0, 2).toIntOrNull() ?: 0
                    val mm = t.substring(3, 5).toIntOrNull() ?: 0
                    val deadline = Calendar.getInstance()
                    deadline.set(
                        today.get(Calendar.YEAR),
                        today.get(Calendar.MONTH),
                        today.get(Calendar.DAY_OF_MONTH), hh, mm, 0
                    )
                    deadline.set(Calendar.MILLISECOND, 0)
                    DueLabel(
                        "اليوم • $t",
                        overdue = nowMs > deadline.timeInMillis
                    )
                } else {
                    DueLabel("اليوم", false)
                }
            }
            dayMs == todayMs + 86400000L -> DueLabel("غداً", false)
            else -> DueLabel("$d/$m", false)
        }
    }

    // ------------------------------ toggle ------------------------------

    /** Dart weekday (Mon=1 … Sun=7) from a Calendar. */
    private fun dartWeekday(cal: Calendar): Int {
        return when (cal.get(Calendar.DAY_OF_WEEK)) {
            Calendar.SUNDAY -> 7
            else -> cal.get(Calendar.DAY_OF_WEEK) - 1
        }
    }

    /**
     * Mirrors `TodoRepeatRule.computeNextDue`. [dueMs] keeps its wall time;
     * returns the next due instant in millis, or null for no recurrence.
     */
    private fun computeNextDue(
        rule: String,
        dueMs: Long,
        weekdaysCsv: String?
    ): Long? {
        val base = Calendar.getInstance()
        base.timeInMillis = dueMs
        fun atSameTime(src: Calendar): Long {
            val c = Calendar.getInstance()
            c.timeInMillis = src.timeInMillis
            return c.timeInMillis
        }
        when (rule) {
            "daily" -> {
                val c = base.clone() as Calendar
                c.add(Calendar.DAY_OF_MONTH, 1)
                return atSameTime(c)
            }
            "weekdays" -> {
                // Legacy Islamic work week: skip Friday (5) + Saturday (6).
                val c = base.clone() as Calendar
                do {
                    c.add(Calendar.DAY_OF_MONTH, 1)
                } while (dartWeekday(c) == 5 || dartWeekday(c) == 6)
                return atSameTime(c)
            }
            "weekly" -> {
                val c = base.clone() as Calendar
                c.add(Calendar.DAY_OF_MONTH, 7)
                return atSameTime(c)
            }
            "monthly" -> {
                // Dart DateTime(y, m+1, d): month overflow wraps, day spill
                // flows into the following month(s).
                val c = Calendar.getInstance()
                c.timeInMillis = dueMs
                val day = c.get(Calendar.DAY_OF_MONTH)
                c.set(Calendar.DAY_OF_MONTH, 1)
                c.set(Calendar.MONTH, c.get(Calendar.MONTH) + 1)
                c.add(Calendar.DAY_OF_MONTH, day - 1)
                return atSameTime(c)
            }
            "yearly" -> {
                val c = Calendar.getInstance()
                c.timeInMillis = dueMs
                val day = c.get(Calendar.DAY_OF_MONTH)
                c.set(Calendar.DAY_OF_MONTH, 1)
                c.set(Calendar.YEAR, c.get(Calendar.YEAR) + 1)
                c.add(Calendar.DAY_OF_MONTH, day - 1)
                return atSameTime(c)
            }
            "custom" -> {
                val days = (weekdaysCsv ?: "")
                    .split(",")
                    .mapNotNull { it.trim().toIntOrNull() }
                    .filter { it in 1..7 }
                    .toSet()
                if (days.isEmpty()) return null
                for (offset in 1..7) {
                    val c = base.clone() as Calendar
                    c.add(Calendar.DAY_OF_MONTH, offset)
                    if (dartWeekday(c) in days) return atSameTime(c)
                }
                return null
            }
            else -> return null
        }
    }

    /** Resets every subtask to unchecked (mirrors Dart recurrence). */
    private fun resetSubtasks(raw: String?): String {
        if (raw.isNullOrBlank()) return raw ?: ""
        return try {
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                arr.optJSONObject(i)?.put("isCompleted", false)
            }
            arr.toString()
        } catch (_: Exception) {
            "[]"
        }
    }

    /** Cancels a flutter_local_notifications exact alarm by its stored id. */
    private fun cancelReminderAlarm(context: Context, notifId: Int) {
        try {
            val cls = Class.forName(
                "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            )
            val alarmIntent = Intent(context, cls)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    PendingIntent.FLAG_IMMUTABLE else 0)
            val pi = PendingIntent.getBroadcast(context, notifId, alarmIntent, flags)
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(pi)
            pi.cancel()
        } catch (t: Throwable) {
            Log.w(TAG, "reminder cancel failed: ${t.message}")
        }
    }

    private fun storedNotifId(prefs: android.content.SharedPreferences, taskId: String): Int {
        val v: Any? = try {
            prefs.all["flutter.todo_notif_id_$taskId"]
        } catch (_: Exception) {
            null
        }
        return when (v) {
            is Number -> v.toInt()
            is String -> v.toIntOrNull() ?: 0
            else -> 0
        }
    }

    /**
     * Flips completion for [taskId], spawning the next recurrence for
     * repeating tasks — the native mirror of the Dart toggle.
     */
    fun toggleTask(context: Context, taskId: String) {
        var db: SQLiteDatabase? = null
        try {
            db = openDb(context, true)
            db.beginTransaction()
            var c: Cursor? = null
            var done = false
            var repeatRule = "none"
            var dueIso: String? = null
            var weekdaysCsv: String? = null
            var reminderIso: String? = null
            try {
                c = db.rawQuery(
                    "SELECT is_completed,repeat_rule,due_date," +
                        "repeat_weekdays,reminder_date_time FROM todo_tasks " +
                        "WHERE id=? LIMIT 1",
                    arrayOf(taskId)
                )
                if (!c.moveToFirst()) {
                    try {
                        db.endTransaction()
                    } catch (_: Exception) {
                    }
                    return
                }
                done = c.getInt(0) == 0 // we are about to complete it
                repeatRule = c.optStringCol("repeat_rule") ?: "none"
                dueIso = c.optStringCol("due_date")
                weekdaysCsv = c.optStringCol("repeat_weekdays")
                reminderIso = c.optStringCol("reminder_date_time")
            } finally {
                c?.close()
            }

            val now = nowIso()
            val values = ContentValues().apply {
                put("is_completed", if (done) 1 else 0)
                put("completed_at", if (done) now else null as String?)
                put("updated_at", now)
            }
            db.update("todo_tasks", values, "id=?", arrayOf(taskId))

            if (done) {
                // Cancel any scheduled reminder alarm for the completed task.
                try {
                    val prefs = context.getSharedPreferences(
                        "FlutterSharedPreferences", Context.MODE_PRIVATE
                    )
                    val notifId = storedNotifId(prefs, taskId)
                    if (notifId != 0) {
                        cancelReminderAlarm(context, notifId)
                        try {
                            prefs.edit()
                                .remove("flutter.todo_notif_id_$taskId")
                                .apply()
                        } catch (_: Exception) {
                        }
                    }
                } catch (t: Throwable) {
                    Log.w(TAG, "notif cleanup failed: ${t.message}")
                }

                // Spawn the next recurrence (same shape as Dart).
                val dueMs = parseIsoMs(dueIso)
                if (repeatRule != "none" && dueMs > 0) {
                    val nextMs = computeNextDue(repeatRule, dueMs, weekdaysCsv)
                    if (nextMs != null) {
                        spawnRecurrence(db, taskId, nextMs, dueMs, reminderIso, now)
                    }
                }
            }
            db.setTransactionSuccessful()
            try {
                db.endTransaction()
            } catch (_: Exception) {
            }
        } catch (t: Throwable) {
            Log.w(TAG, "toggle failed: ${t.message}")
            try {
                db?.endTransaction()
            } catch (_: Exception) {
            }
        } finally {
            try {
                db?.close()
            } catch (_: Exception) {
            }
        }
        refreshWidget(context)
    }

    private fun spawnRecurrence(
        db: SQLiteDatabase,
        taskId: String,
        nextMs: Long,
        dueMs: Long,
        reminderIso: String?,
        nowIso: String
    ) {
        var c: Cursor? = null
        try {
            c = db.rawQuery(
                "SELECT title,notes,due_time,repeat_rule,repeat_weekdays," +
                    "priority,category_id,tags,subtasks,sort_order " +
                    "FROM todo_tasks WHERE id=? LIMIT 1",
                arrayOf(taskId)
            )
            if (!c.moveToFirst()) return
            val title = c.optStringCol("title") ?: ""
            val notes = c.optStringCol("notes")
            val dueTime = c.optStringCol("due_time")
            val rule = c.optStringCol("repeat_rule") ?: "none"
            val weekdays = c.optStringCol("repeat_weekdays")
            val priority = c.optIntCol("priority")
            val categoryId = c.optStringCol("category_id") ?: "all"
            val tags = c.optStringCol("tags")
            val subtasks = resetSubtasks(c.optStringCol("subtasks"))
            val sortOrder = c.optIntCol("sort_order")

            // Shift the reminder by the same delta Dart uses.
            var nextReminder: String? = null
            val remMs = parseIsoMs(reminderIso)
            if (remMs > 0) {
                nextReminder = formatIsoMs(nextMs - (dueMs - remMs))
            }

            val values = ContentValues().apply {
                put("id", "task_${System.currentTimeMillis()}_rec")
                put("title", title)
                put("notes", notes)
                put("is_completed", 0)
                put("completed_at", null as String?)
                put("due_date", formatIsoMs(nextMs))
                put("due_time", dueTime)
                put("reminder_date_time", nextReminder)
                put("repeat_rule", rule)
                put("repeat_weekdays", weekdays)
                put("priority", priority)
                put("category_id", categoryId)
                put("tags", tags)
                put("subtasks", subtasks)
                put("sort_order", sortOrder)
                put("created_at", nowIso)
                put("updated_at", nowIso)
            }
            db.insertWithOnConflict(
                "todo_tasks", null, values, SQLiteDatabase.CONFLICT_REPLACE
            )
        } catch (t: Throwable) {
            Log.w(TAG, "recurrence spawn failed: ${t.message}")
        } finally {
            c?.close()
        }
    }

    // ------------------------------ rendering ------------------------------

    private fun isNight(context: Context): Boolean {
        val mode = context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK
        return mode == Configuration.UI_MODE_NIGHT_YES
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("screen_to_open", "todo")
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_IMMUTABLE else 0)
        return PendingIntent.getActivity(context, 30001, intent, flags)
    }

    // Rows are always dark burgundy cards (todo_row_bg), so content is
    // always light-on-dark regardless of the root theme: white titles,
    // gold due labels, rose for overdue.
    fun buildItem(context: Context, row: TaskRow): RemoteViews {
        val titleC = if (row.done) DARK_DIM else DARK_TITLE
        val now = System.currentTimeMillis()
        val due = dueLabel(row, now)
        return RemoteViews(context.packageName, R.layout.todo_widget_item).apply {
            setImageViewResource(
                R.id.todo_item_check,
                if (row.done) R.drawable.todo_check_on else R.drawable.todo_check_off
            )
            setViewVisibility(
                R.id.todo_item_mark,
                if (row.done) View.VISIBLE else View.GONE
            )
            setTextViewText(R.id.todo_item_title, row.title)
            setTextColor(R.id.todo_item_title, titleC)
            if (due != null) {
                setViewVisibility(R.id.todo_item_due, View.VISIBLE)
                setTextViewText(R.id.todo_item_due, due.text)
                val dueC = if (due.overdue) DARK_OVERDUE else DARK_COUNT
                setTextColor(R.id.todo_item_due, dueC)
            } else {
                setViewVisibility(R.id.todo_item_due, View.GONE)
            }
            setOnClickFillInIntent(
                R.id.todo_item_check,
                Intent().putExtra(TodoWidgetToggleReceiver.EXTRA_TASK_ID, row.id)
            )
        }
    }

    fun build(context: Context): RemoteViews {
        val night = isNight(context)
        val titleC = if (night) DARK_TITLE else LIGHT_TITLE
        val countC = if (night) DARK_COUNT else LIGHT_COUNT
        val (done, total) = try {
            loadCounts(context)
        } catch (_: Exception) {
            Pair(0, 0)
        }

        return RemoteViews(context.packageName, R.layout.todo_widget).apply {
            setInt(
                R.id.todo_root, "setBackgroundResource",
                if (night) R.drawable.widget_background
                else R.drawable.widget_card_light
            )
            setTextViewText(R.id.todo_title, "المهام")
            setTextColor(R.id.todo_title, titleC)
            setTextViewText(R.id.todo_count, "✓ $done/$total")
            setTextColor(R.id.todo_count, countC)
            setRemoteAdapter(
                R.id.todo_list,
                Intent(context, TodoWidgetService::class.java)
            )
            setEmptyView(R.id.todo_list, R.id.todo_empty)
            setPendingIntentTemplate(
                R.id.todo_list,
                TodoWidgetToggleReceiver.template(context)
            )
            setOnClickPendingIntent(R.id.todo_header, openAppIntent(context))
        }
    }

    /** Re-query the collection, then repaint every pinned widget. */
    fun refreshWidget(context: Context) {
        try {
            updateAll(context)
        } catch (t: Throwable) {
            Log.w(TAG, "refresh failed: ${t.message}")
        }
    }

    /**
     * Refresh every pinned todo widget. Safe no-op when none.
     *
     * The list MUST be invalidated first: updateAppWidget alone never
     * re-queries a collection (the host caches the adapter by intent),
     * so without notifyAppWidgetViewDataChanged the rows go stale.
     */
    fun updateAll(context: Context) {
        try {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, TodoWidgetProvider::class.java)
            )
            if (ids.isEmpty()) return
            for (id in ids) {
                try {
                    mgr.notifyAppWidgetViewDataChanged(id, R.id.todo_list)
                } catch (t: Throwable) {
                    Log.w(TAG, "notify list failed: ${t.message}")
                }
            }
            val views = build(context)
            for (id in ids) {
                try {
                    mgr.updateAppWidget(id, views)
                } catch (t: Throwable) {
                    Log.w(TAG, "update failed: ${t.message}")
                }
            }
        } catch (t: Throwable) {
            Log.w(TAG, "updateAll failed: ${t.message}")
        }
    }
}
