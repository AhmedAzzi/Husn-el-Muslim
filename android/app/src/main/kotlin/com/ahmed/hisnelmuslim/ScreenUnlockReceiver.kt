package com.ahmed.hisnelmuslim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.util.Log

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
        // Display ON alone NEVER shows the overlay (Case G): no work at all.
        if (intent.action == Intent.ACTION_SCREEN_ON) return
        // Return in <1ms. SCREEN_OFF/USER_PRESENT arrive as FOREGROUND
        // broadcasts (~10s ANR budget), and on slow devices the main thread
        // is routinely congested (cold start, engine init): doing binder
        // (stopService), MediaPlayer (OverlayAudio.stop) or WindowManager
        // work here risks a "bg anr" kill that takes the receiver — and the
        // whole overlay feature — down with it. Everything runs on
        // [OverlayThread], which owns its own Looper so addView/removeView
        // never touch the main thread. The wake lock bridges the gap while
        // the screen (and possibly the CPU) is off.
        val pending = goAsync()
        val appCtx = context.applicationContext
        val action = intent.action
        OverlayThread.post {
            var wakeLock: PowerManager.WakeLock? = null
            try {
                val pm = appCtx.getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = pm.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK, "Husn:UnlockOverlay"
                ).apply {
                    setReferenceCounted(false)
                    acquire(15_000L)
                }
                when (action) {
                    Intent.ACTION_SCREEN_OFF -> UnlockGate.onScreenOff(appCtx)
                    Intent.ACTION_USER_PRESENT -> UnlockGate.onUserPresent(appCtx)
                }
            } catch (_: Exception) {
            } finally {
                try {
                    if (wakeLock?.isHeld == true) wakeLock?.release()
                } catch (_: Exception) {
                }
                try {
                    pending.finish()
                } catch (_: Exception) {
                }
            }
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
                // MUST be exported: USER_PRESENT is sent by SystemUI
                // (uid 10045), not system_server (uid 1000), and a
                // NOT_EXPORTED receiver silently never receives it on
                // API 33+ — while SCREEN_OFF/ON keep arriving because the
                // system sends those. Spoof risk is nil: a forged broadcast
                // can at most show (or dismiss) our own cached ayah card.
                app.registerReceiver(r, filter, Context.RECEIVER_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                app.registerReceiver(r, filter)
            }
            instance = r
        }
    }
}

/** Dedicated Looper thread owning ALL unlock-overlay work (prefs, audio stop,
 * card inflation, WindowManager add/remove). ViewRootImpl binds to whichever
 * Looper thread calls addView, so the overlay window lives here — never on
 * the app main thread. Started lazily on first post, lives with the process.
 * All entry points funnel through [post] so OFF → unlock sequences stay
 * ordered even when broadcasts arrive in bursts. */
object OverlayThread {
    private val thread = HandlerThread("HusnUnlockOverlay").apply { start() }
    private val handler = Handler(thread.looper)
    val main = Handler(Looper.getMainLooper())

    fun post(block: () -> Unit) {
        handler.post(block)
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
    private const val TAG = "UnlockGate"
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
        Log.d(TAG, "onScreenOff: gate armed")
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
        val enabled = p.getBoolean(OverlayPrefs.KEY_ENABLED, false)
        val offSeen = p.getBoolean(OverlayPrefs.KEY_OFF_SEEN, false)
        val shownCycle = p.getBoolean(OverlayPrefs.KEY_SHOWN_CYCLE, false)
        val canDraw = Settings.canDrawOverlays(ctx)
        val bodyLen = (p.getString(OverlayPrefs.KEY_BODY, "") ?: "").length
        val now = SystemClock.elapsedRealtime()
        val sinceLast = now - p.getLong(OverlayPrefs.KEY_LAST_SHOW, 0L)
        Log.d(TAG, "onUserPresent: enabled=$enabled offSeen=$offSeen shownCycle=$shownCycle canDraw=$canDraw bodyLen=$bodyLen sinceLastMs=$sinceLast showing=${AyahOverlayService.isShowing}/${AyahOverlayUi.isFallbackShowing}")
        if (!enabled) return
        if (!offSeen) return
        if (shownCycle) return
        if (!canDraw) return
        if (AyahOverlayService.isShowing || AyahOverlayUi.isFallbackShowing) return
        if (sinceLast < DEBOUNCE_MS) return

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
        val shown = AyahOverlayUi.showFallback(ctx.applicationContext, data, prev, next)
        Log.d(TAG, "onUserPresent: showFallback=$shown globalAyah=${data.globalAyah}")
    }
}

