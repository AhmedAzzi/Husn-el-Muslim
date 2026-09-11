package com.ahmed.hisnelmuslim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.provider.Settings

/**
 * Detects genuine phone wake/unlock cycles and shows the Khatma overlay
 * exactly once per cycle.
 *
 * Trigger rule (strict):
 *   SCREEN_OFF  →  (SCREEN_ON)  →  USER_PRESENT  →  show overlay once.
 *
 * Anything else — app resume, activity start, app switching, Home press,
 * touch, timers, process recreation, device boot — NEVER shows the overlay:
 * the [UnlockGate] only fires when a SCREEN_OFF was actually observed first,
 * and the cycle flag is consumed on show so bursts of SCREEN_ON /
 * USER_PRESENT / onResume / window-focus events in one unlock produce a
 * single overlay.
 *
 * NOTE: SCREEN_ON/OFF/USER_PRESENT cannot be declared in the manifest on
 * modern Android; the receiver is registered dynamically for the lifetime of
 * the app process via [register]. If the process is dead (force-stop, reboot
 * before the app is opened), nothing fires and no overlay appears — this
 * satisfies the "no auto-show on process recreation / boot" cases.
 */
class ScreenUnlockReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val appCtx = context.applicationContext
        when (intent.action) {
            Intent.ACTION_SCREEN_OFF -> UnlockGate.onScreenOff(appCtx)
            Intent.ACTION_SCREEN_ON -> UnlockGate.onScreenOn(appCtx)
            Intent.ACTION_USER_PRESENT -> UnlockGate.onUserPresent(appCtx)
        }
    }

    companion object {
        private var instance: ScreenUnlockReceiver? = null

        /** Idempotent process-scoped registration. Call from the activity. */
        @Synchronized
        fun register(ctx: Context) {
            if (instance != null) return
            val r = ScreenUnlockReceiver()
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_USER_PRESENT)
            }
            val app = ctx.applicationContext
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                app.registerReceiver(r, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                app.registerReceiver(r, filter)
            }
            instance = r
        }
    }
}

/** SharedPreferences helpers for the unlock overlay cache and cycle state. */
object OverlayPrefs {
    const val NAME = "khatma_overlay"
    const val KEY_ENABLED = "enabled"
    const val KEY_TITLE = "title"
    const val KEY_BODY = "body"
    const val KEY_META = "meta"
    const val KEY_TAFSIR = "tafsir"
    const val KEY_AUDIO_URL = "audioUrl"
    const val KEY_GLOBAL = "globalAyah"
    const val KEY_SURAH = "surah"
    const val KEY_AYAH = "ayah"
    // Neighbour bundles enabling prev/next navigation inside the overlay.
    const val KEY_PREV_TITLE = "prev_title"
    const val KEY_PREV_BODY = "prev_body"
    const val KEY_PREV_META = "prev_meta"
    const val KEY_PREV_TAFSIR = "prev_tafsir"
    const val KEY_PREV_GLOBAL = "prev_globalAyah"
    const val KEY_PREV_SURAH = "prev_surah"
    const val KEY_PREV_AYAH = "prev_ayah"
    const val KEY_NEXT_TITLE = "next_title"
    const val KEY_NEXT_BODY = "next_body"
    const val KEY_NEXT_META = "next_meta"
    const val KEY_NEXT_TAFSIR = "next_tafsir"
    const val KEY_NEXT_GLOBAL = "next_globalAyah"
    const val KEY_NEXT_SURAH = "next_surah"
    const val KEY_NEXT_AYAH = "next_ayah"
    const val KEY_OFF_SEEN = "screen_off_seen"
    const val KEY_SHOWN_CYCLE = "overlay_shown_cycle"
    const val KEY_LAST_SHOW = "last_show_at"
    const val KEY_PENDING = "pending_completed_global"

    /** Reads one cached side bundle, or null when absent/blank. */
    fun readSide(p: SharedPreferences, prefix: String): OverlayData? {
        val body = p.getString("${prefix}_body", "") ?: ""
        if (body.isBlank()) return null
        return OverlayData(
            title = p.getString("${prefix}_title", "القرآن") ?: "القرآن",
            body = body,
            meta = p.getString("${prefix}_meta", "") ?: "",
            tafsir = p.getString("${prefix}_tafsir", "") ?: "",
            globalAyah = p.getInt("${prefix}_globalAyah", 0),
            surah = p.getInt("${prefix}_surah", 0),
            ayah = p.getInt("${prefix}_ayah", 0),
            audioUrl = p.getString("${prefix}_audioUrl", "") ?: "",
        )
    }

    fun prefs(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences(NAME, Context.MODE_PRIVATE)

    fun writePending(ctx: Context, globalAyah: Int) {
        if (globalAyah <= 0) return
        prefs(ctx).edit().putInt(KEY_PENDING, globalAyah).apply()
    }

    /** Returns the pending ✔️ completion and clears it (single-consume). */
    fun consumePending(ctx: Context): Int {
        val p = prefs(ctx)
        val v = p.getInt(KEY_PENDING, 0)
        if (v != 0) p.edit().remove(KEY_PENDING).apply()
        return v
    }
}

/**
 * The single gate for unlock overlays. All entry points funnel through here
 * so one wake cycle can never produce more than one overlay.
 */
object UnlockGate {
    private const val DEBOUNCE_MS = 2500L

    /** A new OFF cycle starts: arm the gate, drop any stale overlay. */
    @Synchronized
    fun onScreenOff(ctx: Context) {
        OverlayPrefs.prefs(ctx).edit()
            .putBoolean(OverlayPrefs.KEY_OFF_SEEN, true)
            .putBoolean(OverlayPrefs.KEY_SHOWN_CYCLE, false)
            .apply()
        try {
            ctx.stopService(Intent(ctx, AyahOverlayService::class.java))
        } catch (_: Exception) {
        }
        AyahOverlayUi.removeFallback()
    }

    /**
     * Display ON alone NEVER shows the overlay (Case G): we wait for the
     * USER_PRESENT unlock event instead.
     */
    fun onScreenOn(@Suppress("UNUSED_PARAMETER") ctx: Context) {
    }

    /** Unlock: show once iff a genuine OFF → unlock transition armed the gate. */
    @Synchronized
    fun onUserPresent(ctx: Context) {
        val p = OverlayPrefs.prefs(ctx)
        if (!p.getBoolean(OverlayPrefs.KEY_ENABLED, false)) return
        if (!p.getBoolean(OverlayPrefs.KEY_OFF_SEEN, false)) return
        if (p.getBoolean(OverlayPrefs.KEY_SHOWN_CYCLE, false)) return
        if (!Settings.canDrawOverlays(ctx)) return
        if (AyahOverlayService.isShowing || AyahOverlayUi.isFallbackShowing) return
        val now = SystemClock.elapsedRealtime()
        if (now - p.getLong(OverlayPrefs.KEY_LAST_SHOW, 0L) < DEBOUNCE_MS) return

        val body = p.getString(OverlayPrefs.KEY_BODY, "") ?: ""
        if (body.isBlank()) return // no cached ayah: keep gate armed, try next cycle

        val data = OverlayData(
            title = p.getString(OverlayPrefs.KEY_TITLE, "القرآن") ?: "القرآن",
            body = body,
            meta = p.getString(OverlayPrefs.KEY_META, "") ?: "",
            tafsir = p.getString(OverlayPrefs.KEY_TAFSIR, "") ?: "",
            globalAyah = p.getInt(OverlayPrefs.KEY_GLOBAL, 0),
            surah = p.getInt(OverlayPrefs.KEY_SURAH, 0),
            ayah = p.getInt(OverlayPrefs.KEY_AYAH, 0),
            audioUrl = p.getString(OverlayPrefs.KEY_AUDIO_URL, "") ?: "",
        )
        val prev = OverlayPrefs.readSide(p, "prev")
        val next = OverlayPrefs.readSide(p, "next")

        // Consume the cycle BEFORE showing so duplicate USER_PRESENT /
        // SCREEN_ON bursts in the same unlock cannot re-enter.
        p.edit()
            .putBoolean(OverlayPrefs.KEY_OFF_SEEN, false)
            .putBoolean(OverlayPrefs.KEY_SHOWN_CYCLE, true)
            .putLong(OverlayPrefs.KEY_LAST_SHOW, now)
            .apply()

        // NEVER start AyahOverlayService from here. startForegroundService()
        // requires startForeground() within seconds, but on low-end devices
        // the main thread is routinely blocked 10-20s, so onStartCommand
        // dispatch misses the FGS timeout and the whole process dies with
        // ForegroundServiceDidNotStartInTimeException (crashed every ~6th
        // overlay on Galaxy M11). On Android 12+ a background FGS start is
        // banned outright. SYSTEM_ALERT_WINDOW draws the IDENTICAL card
        // directly with no service, on ALL API levels — so always use it.
        try {
            ctx.stopService(Intent(ctx, AyahOverlayService::class.java))
        } catch (_: Exception) {
        }
        AyahOverlayUi.removeFallback()
        AyahOverlayUi.showFallback(ctx.applicationContext, data, prev, next)
    }
}

