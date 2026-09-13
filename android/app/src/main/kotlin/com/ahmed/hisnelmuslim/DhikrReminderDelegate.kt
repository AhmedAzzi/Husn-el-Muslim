package com.ahmed.hisnelmuslim

import android.animation.ValueAnimator
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import com.ahmed.hisnelmuslim.databinding.OverlayDhikrReminderBinding

/**
 * Dhikr floating-reminder logic, extracted from [PrayerTimeService] for
 * separation of responsibility — NOT a second service.
 *
 * - [PrayerTimeService] keeps the foreground service, its 1-second tick,
 *   and all prayer/ayat logic. It drives this delegate via [onTick] and
 *   forwards the `dhikr_*` intent extras / persistence through the plain
 *   `var` properties below.
 * - This delegate owns the dhikr interval check, show/dismiss state, the
 *   30s minimum-gap debounce, and the overlay lifecycle. It uses the
 *   service only as a [Context] (WindowManager, overlay permission,
 *   fallback activity) on the main thread — no timer, no Handler, no
 *   service lifecycle of its own.
 *
 * Timing, persistence keys, overlay visuals, and the ayat-priority rule
 * are byte-for-byte the pre-extraction behavior.
 */
class DhikrReminderDelegate(private val service: Service) {

    companion object {
        // Minimum gap between two attached dhikr cards. The user-facing
        // minimum interval is 1 minute, so this only ever drops glitch
        // re-triggers, never legitimate shows.
        private const val MIN_DHIKR_GAP_MS = 30_000L
    }

    // Live state, mirrored to `prayer_service_prefs` by the service.
    var enabled: Boolean = false
    var intervalMinutes: Int = 15
    var adhkar: ArrayList<String> = arrayListOf()
    var lastTimestamp: Long = 0

    /** True while the dhikr card is attached (or being attached). */
    var isShowing: Boolean = false
        private set

    // Wall-clock of the last attached card (debounce, not persistence).
    private var lastShownAt: Long = 0

    // Fades out the visible card. Invoked by the ayat trigger so the
    // full-screen prayer alert never stacks on top of a dhikr card.
    private var dismissHandle: (() -> Unit)? = null

    /**
     * Heartbeat from the service tick. Returns true when a show was
     * initiated (the service persists state in that case, as before).
     *
     * @param now current wall-clock millis from the tick.
     * @param ayatShowing true while the prayer alert owns the screen —
     *   the dhikr is skipped, never stacked; the interval gate re-fires
     *   it on its next due tick.
     */
    fun onTick(now: Long, ayatShowing: Boolean): Boolean {
        if (!enabled || adhkar.isEmpty()) return false
        if (isShowing) return false
        // Debounce: never attach a fresh card within MIN_DHIKR_GAP_MS of
        // the previous one.
        if (now - lastShownAt < MIN_DHIKR_GAP_MS) return false
        // The prayer alert owns the screen: skip while it is up.
        if (ayatShowing) return false
        if (lastTimestamp == 0L) lastTimestamp = now
        if (now - lastTimestamp < (intervalMinutes * 60 * 1000)) return false

        isShowing = true
        Handler(Looper.getMainLooper()).post { showOnce() }
        lastTimestamp = now
        return true
    }

    /** Dismisses the visible card (fade-out), if any. Main thread only. */
    fun dismiss() {
        try {
            dismissHandle?.invoke()
        } catch (_: Exception) {
        }
        dismissHandle = null
    }

    /** Resets the interval timer to [now] (enable / interval change). */
    fun resetTimer(now: Long) {
        lastTimestamp = now
    }

    private fun showOnce() {
        val dhikr = if (adhkar.isNotEmpty())
            adhkar[(adhkar.indices).random()] else "سبحان الله"

        val canDraw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            Settings.canDrawOverlays(service) else true

        if (!canDraw) {
            Log.w("DhikrReminder", "No SYSTEM_ALERT_WINDOW permission – falling back to activity")
            isShowing = false
            dismissHandle = null
            val intent = Intent(service, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("triggered_dhikr", true)
            }
            try {
                service.startActivity(intent)
            } catch (e: Exception) {
                Log.e("DhikrReminder", "Fallback activity failed: ${e.message}")
            }
            return
        }

        // Static structure is res/layout/overlay_dhikr_reminder.xml — only
        // the dhikr text, the Amiri typeface and the animations are bound
        // in code via DhikrOverlayUi (mirrors PrayerAlertUi).
        val wm = service.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        var wasDismissed = false
        var progressAnimator: ValueAnimator? = null
        var binding: OverlayDhikrReminderBinding? = null

        // Exactly-once exit: tap-to-dismiss cancels the progress animator
        // (cancel also fires onAnimationEnd — the guard absorbs it).
        val exit = {
            if (!wasDismissed) {
                wasDismissed = true
                progressAnimator?.cancel()
                val b = binding
                if (b == null) {
                    isShowing = false
                    dismissHandle = null
                } else {
                    DhikrOverlayUi.animateExit(wm, b) {
                        isShowing = false
                        dismissHandle = null
                    }
                }
            }
        }
        dismissHandle = { exit() }

        try {
            binding = DhikrOverlayUi.inflate(service, dhikr) { exit() }
            wm.addView(binding.dhikrRoot, DhikrOverlayUi.overlayParams(service))
            lastShownAt = System.currentTimeMillis()
            DhikrOverlayUi.animateEntrance(binding) {
                progressAnimator = DhikrOverlayUi.startProgress(service, binding) {
                    exit()
                }.also { it.start() }
            }
        } catch (e: Exception) {
            Log.e("DhikrReminder", "Failed to add overlay view: ${e.message}")
            isShowing = false
            dismissHandle = null
        }
    }
}
