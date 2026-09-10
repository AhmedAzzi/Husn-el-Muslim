package com.ahmed.hisnelmuslim

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONArray

/**
 * Shared brain behind both home-screen widgets (compact + full replica).
 *
 * Data contract with Dart (SharedPreferences; the `flutter.` prefix is added
 * automatically by the shared_preferences plugin):
 * - widget_hijri      : Hijri date line
 * - widget_next_en    : next prayer English key (Fajr, Dhuhr, …)
 * - widget_next_ar    : next prayer Arabic name
 * - widget_next_time  : next prayer "HH:MM"
 * - widget_target_ts  : next prayer epoch millis (countdown anchor)
 * - widget_day_json   : [{"n":"Fajr","t":"05:00","ts":…}, …] six main prayers
 * - widget_streak_current : 5-prayer streak days (written by Dart tracking sync)
 * - widget_fajr_done  : today's Fajr performed (legacy; kept for compat)
 * - widget_day_done   : prayers performed today, 0..5 (written by Dart)
 * - widget_day_goal   : daily goal, 1..5 (written by Dart)
 *
 * The countdown is computed natively at render time, so the widgets stay
 * live through the service's periodic refresh without waking Dart.
 */
object PrayerWidgetData {

    // ---- Theme palette (mirrors the app: deep-night + gold + rose) ----
    private const val DARK_TITLE = 0xFFFFFFFF.toInt()
    private const val DARK_SUBTLE = 0xFFEDEDED.toInt()
    private const val DARK_HIJRI = 0xFFFFD700.toInt()
    private const val DARK_HERO_LABEL = 0xFFC2A36B.toInt()
    private const val DARK_NEXT = 0xFFFFD700.toInt()
    private const val DARK_FOOTER = 0xFF8E8E9A.toInt()
    private const val DARK_DIVIDER = 0x26FFFFFF.toInt()

    private const val LIGHT_TITLE = 0xFF1A1A1A.toInt()
    private const val LIGHT_SUBTLE = 0xFF3A3A3A.toInt()
    private const val LIGHT_HIJRI = 0xFF996515.toInt()
    private const val LIGHT_HERO_LABEL = 0xFF996515.toInt()
    private const val LIGHT_NEXT = 0xFF996515.toInt()
    private const val LIGHT_FOOTER = 0xFF9A9AA5.toInt()
    private const val LIGHT_DIVIDER = 0xFFD8C99A.toInt()

    private const val COUNTDOWN_TEXT = 0xFFFFFFFF.toInt()

    private val ORDER = listOf("Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha")

    data class DayEntry(val en: String, val time: String, val ts: Long)

    data class Snapshot(
        val hijri: String,
        val nextEn: String,
        val nextAr: String,
        val nextTime: String,
        val targetTs: Long,
        val entries: List<DayEntry>,
        val hasData: Boolean,
    )

    data class Resolved(val en: String, val ar: String, val time: String, val ts: Long)

    // ------------------------------ reading ------------------------------

    fun read(context: Context): Snapshot {
        return try {
            val p = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            val hijri = p.getString("flutter.widget_hijri", "") ?: ""
            val nextEn = p.getString("flutter.widget_next_en", "") ?: ""
            val nextAr = p.getString("flutter.widget_next_ar", "") ?: ""
            val nextTime = p.getString("flutter.widget_next_time", "") ?: ""
            val targetTs = flutterLong(p.all["flutter.widget_target_ts"])
            val entries = mutableListOf<DayEntry>()
            try {
                val raw = p.getString("flutter.widget_day_json", "") ?: ""
                if (raw.isNotEmpty()) {
                    val arr = JSONArray(raw)
                    for (i in 0 until arr.length()) {
                        val o = arr.optJSONObject(i) ?: continue
                        entries.add(
                            DayEntry(
                                o.optString("n"),
                                o.optString("t"),
                                o.optLong("ts", 0L)
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                Log.w("PrayerWidget", "Bad widget_day_json: ${e.message}")
            }
            Snapshot(
                hijri, nextEn, nextAr, nextTime, targetTs, entries,
                hasData = entries.isNotEmpty() && targetTs > 0
            )
        } catch (e: Exception) {
            Log.w("PrayerWidget", "read failed: ${e.message}")
            Snapshot("", "", "", "", 0L, emptyList(), false)
        }
    }

    /** shared_preferences stores Dart ints as Long — coerce safely. */
    private fun flutterLong(v: Any?): Long = when (v) {
        is Long -> v
        is Int -> v.toLong()
        is Number -> v.toLong()
        is String -> v.toLongOrNull() ?: 0L
        else -> 0L
    }

    // ---------------------------- countdown ------------------------------

    /**
     * Effective next prayer: stored target while still in the future,
     * otherwise the first future entry of the cached day, otherwise
     * tomorrow's Fajr (+24h on today's Fajr — corrected on next Dart sync).
     */
    fun resolveNext(snap: Snapshot, now: Long): Resolved? {
        if (!snap.hasData) return null
        if (snap.targetTs > now - 60_000L && snap.nextEn.isNotEmpty()) {
            return Resolved(snap.nextEn, snap.nextAr, snap.nextTime, snap.targetTs)
        }
        val future = snap.entries
            .filter { it.ts > now }
            .minByOrNull { it.ts }
        if (future != null) {
            return Resolved(future.en, arabic(future.en), future.time, future.ts)
        }
        val fajr = snap.entries.firstOrNull { it.en == "Fajr" }
        if (fajr != null && fajr.ts > 0) {
            return Resolved("Fajr", arabic("Fajr"), fajr.time, fajr.ts + 86400000L)
        }
        return null
    }

    fun countdownText(diffMs: Long): String {
        if (diffMs <= 0 && diffMs > -60_000L) return "الآن"
        if (diffMs <= -60_000L) return "…"
        val totalSec = diffMs / 1000
        val h = totalSec / 3600
        val m = (totalSec % 3600) / 60
        val s = totalSec % 60
        return "- %02d:%02d:%02d".format(h, m, s)
    }

    /**
     * Live per-second countdown. The Chronometer ticks natively every
     * second, so the display stays exact between re-renders — and even when
     * the service/app is idle. Prayer *transitions* still rely on the
     * periodic re-render (service tick / app open / boot).
     *
     * Base uses elapsedRealtime (immune to wall-clock changes).
     * Pre-API-24 (no setChronometerCountDown) falls back to static text.
     */
    fun setLiveCountdown(
        views: RemoteViews,
        viewId: Int,
        targetTs: Long,
        now: Long
    ) {
        val remaining = targetTs - now
        if (remaining > 0 && Build.VERSION.SDK_INT >= 24) {
            val base = SystemClock.elapsedRealtime() + remaining
            views.setChronometer(viewId, base, "- %s", true)
            views.setChronometerCountDown(viewId, true)
        } else {
            // Static fallback: at/past time, or old platform.
            try {
                views.setBoolean(viewId, "setStarted", false)
            } catch (e: Exception) {
                Log.w("PrayerWidget", "chronometer stop failed: ${e.message}")
            }
            views.setTextViewText(viewId, countdownText(remaining))
        }
    }

    private fun arabic(en: String): String = when (en) {
        "Fajr" -> "الفجر"
        "Sunrise" -> "الشروق"
        "Dhuhr" -> "الظهر"
        "Asr" -> "العصر"
        "Maghrib" -> "المغرب"
        "Isha" -> "العشاء"
        else -> en
    }

    // ----------------------------- rendering -----------------------------

    private fun isNight(context: Context): Boolean {
        val mode = context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK
        return mode == Configuration.UI_MODE_NIGHT_YES
    }

    private fun openAppIntent(
        context: Context,
        requestCode: Int,
        screen: String = "prayer_times"
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("screen_to_open", screen)
        }
        return PendingIntent.getActivity(
            context, requestCode, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    fun buildSmall(context: Context): RemoteViews {
        val night = isNight(context)
        val now = System.currentTimeMillis()
        val snap = read(context)
        val next = resolveNext(snap, now)

        val title = if (night) DARK_TITLE else LIGHT_TITLE
        val hijriC = if (night) DARK_HIJRI else LIGHT_HIJRI

        return RemoteViews(context.packageName, R.layout.prayer_widget).apply {
            setInt(
                R.id.widget_small_root, "setBackgroundResource",
                if (night) R.drawable.widget_background else R.drawable.widget_card_light
            )
            setTextViewText(R.id.widget_small_title, "مواقيت الصلاة")
            setTextColor(R.id.widget_small_title, title)
            setTextViewText(
                R.id.widget_small_hijri,
                snap.hijri.ifEmpty { "حصن المسلم" }
            )
            setTextColor(R.id.widget_small_hijri, hijriC)
            if (next != null) {
                setTextViewText(R.id.widget_small_next_name, next.ar)
                setTextColor(R.id.widget_small_next_name, title)
                setTextViewText(R.id.widget_small_next_time, next.time)
                setTextColor(R.id.widget_small_next_time, title)
                setLiveCountdown(this, R.id.widget_small_countdown, next.ts, now)
            } else {
                setTextViewText(R.id.widget_small_next_name, "—")
                setTextViewText(R.id.widget_small_next_time, "")
                setTextViewText(R.id.widget_small_countdown, "…")
            }
            setTextColor(R.id.widget_small_countdown, COUNTDOWN_TEXT)
            setOnClickPendingIntent(
                R.id.widget_small_root,
                openAppIntent(context, 10001)
            )
        }
    }

    private val ROW_IDS = intArrayOf(
        R.id.widget_row_0, R.id.widget_row_1, R.id.widget_row_2,
        R.id.widget_row_3, R.id.widget_row_4, R.id.widget_row_5
    )
    private val NAME_IDS = intArrayOf(
        R.id.widget_name_0, R.id.widget_name_1, R.id.widget_name_2,
        R.id.widget_name_3, R.id.widget_name_4, R.id.widget_name_5
    )
    private val TIME_IDS = intArrayOf(
        R.id.widget_time_0, R.id.widget_time_1, R.id.widget_time_2,
        R.id.widget_time_3, R.id.widget_time_4, R.id.widget_time_5
    )

    fun buildLarge(context: Context): RemoteViews {
        val night = isNight(context)
        val now = System.currentTimeMillis()
        val snap = read(context)
        val next = resolveNext(snap, now)

        val title = if (night) DARK_TITLE else LIGHT_TITLE
        val subtle = if (night) DARK_SUBTLE else LIGHT_SUBTLE
        val hijriC = if (night) DARK_HIJRI else LIGHT_HIJRI
        val heroLabelC = if (night) DARK_HERO_LABEL else LIGHT_HERO_LABEL
        val nextC = if (night) DARK_NEXT else LIGHT_NEXT
        val footerC = if (night) DARK_FOOTER else LIGHT_FOOTER

        val byName = snap.entries.associateBy { it.en }

        return RemoteViews(context.packageName, R.layout.widget_prayer_large).apply {
            setInt(
                R.id.widget_large_root, "setBackgroundResource",
                if (night) R.drawable.widget_background else R.drawable.widget_card_light
            )
            setInt(
                R.id.widget_large_hero, "setBackgroundResource",
                if (night) R.drawable.widget_hero_dark else R.drawable.widget_hero_light
            )
            setInt(R.id.widget_large_divider, "setBackgroundColor",
                if (night) DARK_DIVIDER else LIGHT_DIVIDER)

            setTextColor(R.id.widget_large_title, title)
            setTextViewText(
                R.id.widget_large_hijri,
                snap.hijri.ifEmpty { "حصن المسلم" }
            )
            setTextColor(R.id.widget_large_hijri, hijriC)
            setTextColor(R.id.widget_large_hero_label, heroLabelC)

            if (next != null) {
                setTextViewText(R.id.widget_large_next_name, next.ar)
                setTextColor(R.id.widget_large_next_name, title)
                setTextViewText(R.id.widget_large_next_time, next.time)
                setTextColor(R.id.widget_large_next_time, title)
                setLiveCountdown(this, R.id.widget_large_countdown, next.ts, now)
            } else {
                setTextViewText(R.id.widget_large_next_name, "—")
                setTextViewText(R.id.widget_large_next_time, "")
                setTextViewText(R.id.widget_large_countdown, "…")
            }
            setTextColor(R.id.widget_large_countdown, COUNTDOWN_TEXT)

            for (i in ORDER.indices) {
                val en = ORDER[i]
                val t = byName[en]?.time ?: "--:--"
                setTextViewText(TIME_IDS[i], t)
                val isNext = next?.en == en
                if (isNext) {
                    setInt(ROW_IDS[i], "setBackgroundResource", R.drawable.widget_row_next)
                    setTextColor(NAME_IDS[i], nextC)
                    setTextColor(TIME_IDS[i], nextC)
                } else {
                    setTextColor(NAME_IDS[i], subtle)
                    setTextColor(TIME_IDS[i], title)
                }
            }

            setTextColor(R.id.widget_large_footer, footerC)
            setOnClickPendingIntent(
                R.id.widget_large_root,
                openAppIntent(context, 10002)
            )
        }
    }

    // ------------------------------ updates ------------------------------

    /**
     * Tracking snapshot: streak days + today's 5-prayer progress.
     * Same SharedPreferences contract as the prayer snapshot above.
     * Missing keys (pre-upgrade installs) fall back to 0 done / goal 5.
     */
    data class TrackingSnapshot(
        val streak: Long,
        val dayDone: Int,
        val dayGoal: Int
    )

    fun readTracking(context: Context): TrackingSnapshot {
        return try {
            val p = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            val goal = (p.all["flutter.widget_day_goal"] as? Number)?.toInt() ?: 5
            val done = (p.all["flutter.widget_day_done"] as? Number)?.toInt() ?: 0
            TrackingSnapshot(
                streak = flutterLong(p.all["flutter.widget_streak_current"]),
                dayDone = done.coerceIn(0, goal.coerceAtLeast(1)),
                dayGoal = goal.coerceIn(1, 5),
            )
        } catch (e: Exception) {
            Log.w("TrackingWidget", "readTracking failed: ${e.message}")
            TrackingSnapshot(0L, 0, 5)
        }
    }

    /** Five-dot day progress, e.g. "●●●○○ 3/5". Count-based (glanceable). */
    fun dotsLine(done: Int, goal: Int): String {
        val filled = "●".repeat(done)
        val empty = "○".repeat((goal - done).coerceAtLeast(0))
        return "$filled$empty $done/$goal"
    }

    fun buildTracking(context: Context): RemoteViews {
        val night = isNight(context)
        val t = readTracking(context)
        val title = if (night) DARK_TITLE else LIGHT_TITLE
        val hijriC = if (night) DARK_HIJRI else LIGHT_HIJRI
        return RemoteViews(context.packageName, R.layout.widget_tracking).apply {
            setTextViewText(R.id.widget_tracking_title, "تتبع الصلوات")
            setTextColor(R.id.widget_tracking_title, hijriC)
            setTextViewText(R.id.widget_tracking_streak, "🔥 ${t.streak}")
            setTextColor(R.id.widget_tracking_streak, title)
            setTextViewText(
                R.id.widget_tracking_today,
                dotsLine(t.dayDone, t.dayGoal)
            )
            setTextColor(R.id.widget_tracking_today, title)
            setOnClickPendingIntent(
                R.id.widget_tracking_root,
                openAppIntent(context, 10003, "tracking")
            )
        }
    }

    /** Refresh every pinned widget of both sizes. Safe no-op when none. */
    fun updateAll(context: Context) {
        try {
            val mgr = AppWidgetManager.getInstance(context)
            val smallIds = mgr.getAppWidgetIds(
                ComponentName(context, PrayerWidgetProvider::class.java)
            )
            if (smallIds.isNotEmpty()) {
                val views = buildSmall(context)
                for (id in smallIds) {
                    try {
                        mgr.updateAppWidget(id, views)
                    } catch (t: Throwable) {
                        Log.w("PrayerWidget", "update small failed: ${t.message}")
                    }
                }
            }
            val largeIds = mgr.getAppWidgetIds(
                ComponentName(context, PrayerWidgetLargeProvider::class.java)
            )
            if (largeIds.isNotEmpty()) {
                val views = buildLarge(context)
                for (id in largeIds) {
                    try {
                        mgr.updateAppWidget(id, views)
                    } catch (t: Throwable) {
                        Log.w("PrayerWidget", "update large failed: ${t.message}")
                    }
                }
            }
            val trackingIds = mgr.getAppWidgetIds(
                ComponentName(context, TrackingWidgetProvider::class.java)
            )
            if (trackingIds.isNotEmpty()) {
                val views = buildTracking(context)
                for (id in trackingIds) {
                    try {
                        mgr.updateAppWidget(id, views)
                    } catch (t: Throwable) {
                        Log.w("TrackingWidget", "update failed: ${t.message}")
                    }
                }
            }
        } catch (t: Throwable) {
            Log.w("PrayerWidget", "updateAll failed: ${t.message}")
        }
    }
}
