package com.ahmed.hisnelmuslim

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.WindowManager
import io.flutter.plugin.common.EventChannel

/**
 * Draws the current ayah as a floating overlay using SYSTEM_ALERT_WINDOW
 * ("Display over other apps"). The card UI is built by [AyahOverlayUi] so the
 * service and the unlock-time fallback draw exactly the same overlay.
 *
 * Triggering is owned by [ScreenUnlockReceiver]/[UnlockGate] (genuine
 * SCREEN_OFF → USER_PRESENT cycles only). This service never shows itself.
 *
 * Dismissal contract (unchanged):
 *   * green check (✓) — records a completed read, persists a pending
 *     completion for Flutter to reconcile, and advances to the next ayah.
 *   * gold clock (◷) — postpones; the same ayah is shown next time.
 * Both notify Flutter via [CHANNEL_ACTIONS] when the engine is alive.
 */
class AyahOverlayService : Service() {
    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private val notificationId = 2144

    companion object {
        const val CHANNEL_ACTIONS = "khatmah/overlay_actions"
        private const val TAG = "AyahOverlayService"
        private const val CHANNEL_ID = "khatmah_overlay"
        @Volatile
        var actionsSink: EventChannel.EventSink? = null

        /// Data of the currently displayed ayah, so ✓ advances correctly.
        @Volatile
        var currentGlobalAyah: Int = 0
        @Volatile
        var currentSurah: Int = 0
        @Volatile
        var currentAyah: Int = 0

        /// True while the service overlay view is attached (dedup gate).
        @Volatile
        var isShowing: Boolean = false
            private set

        fun notifyCompletedRead() {
            actionsSink?.success(
                mapOf(
                    "action" to "completed",
                    "globalAyah" to currentGlobalAyah,
                    "surah" to currentSurah,
                    "ayah" to currentAyah,
                )
            )
        }

        fun notifyLater() {
            actionsSink?.success(
                mapOf(
                    "action" to "later",
                    "globalAyah" to currentGlobalAyah,
                )
            )
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        ensureChannel()
        // Safety net: promote immediately so a delayed onStartCommand can
        // never trip ForegroundServiceDidNotStartInTimeException.
        try {
            promoteToForeground()
        } catch (e: Exception) {
            Log.w(TAG, "onCreate: startForeground failed", e)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // startForeground() MUST be first: after startForegroundService()
        // the system kills the process if promotion doesn't happen within
        // seconds. Validate only afterwards; every exit path goes through
        // stopForegroundAndSelf(), safe only AFTER promotion.
        try {
            promoteToForeground()
        } catch (e: Exception) {
            Log.w(TAG, "onStartCommand: startForeground rejected", e)
            stopSelf(startId)
            return START_NOT_STICKY
        }
        if (intent?.getBooleanExtra("dismiss", false) == true) {
            stopForegroundAndSelf()
            return START_NOT_STICKY
        }
        val center = OverlayData(
            title = intent?.getStringExtra("title") ?: "القرآن",
            body = intent?.getStringExtra("body") ?: "",
            meta = intent?.getStringExtra("meta") ?: "",
            tafsir = intent?.getStringExtra("tafsir") ?: "",
            globalAyah = intent?.getIntExtra("globalAyah", 0) ?: 0,
            surah = intent?.getIntExtra("surah", 0) ?: 0,
            ayah = intent?.getIntExtra("ayah", 0) ?: 0,
            audioUrl = intent?.getStringExtra("audioUrl") ?: "",
        )
        if (!Settings.canDrawOverlays(this) || center.body.isBlank()) {
            stopForegroundAndSelf()
            return START_NOT_STICKY
        }
        OverlayNav.reset(center, readSide(intent, "prev"), readSide(intent, "next"))

        render()
        // Never auto-restart: an overlay may only appear on the next genuine
        // unlock cycle (process recreation / boot must NOT show one).
        return START_NOT_STICKY
    }

    /**
     * Promotes this service to foreground. Must be called FIRST in
     * onStartCommand (and defensively in onCreate). Throws on background-
     * start bans / type errors — callers must catch and stop quietly.
     */
    private fun promoteToForeground() {
        val notification = buildForegroundNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                notificationId,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(notificationId, notification)
        }
    }

    /** Safe shutdown: removes the foreground notification then stops. */
    private fun stopForegroundAndSelf() {
        removeOverlay()
        stopForegroundRemove()
        stopSelf()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "آية عائمة",
                    NotificationManager.IMPORTANCE_LOW,
                )
            )
        } catch (_: Exception) {
        }
    }

    private fun stopForegroundRemove() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (_: Exception) {
        }
    }

    override fun onDestroy() {
        removeOverlay()
        stopForegroundRemove()
        super.onDestroy()
    }

    private fun buildForegroundNotification(): android.app.Notification {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                nm.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "آية عائمة",
                        NotificationManager.IMPORTANCE_LOW,
                    )
                )
            } catch (_: Exception) {
            }
        }
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val pi = if (launch == null) null else PendingIntent.getActivity(
            this,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return androidx.core.app.NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_popup_sync)
            .setContentTitle("آية من القرآن")
            .setContentText("اضغط للعودة إلى القراءة")
            .setOngoing(true)
            .setContentIntent(pi)
            .build()
    }

    private fun readSide(intent: Intent?, prefix: String): OverlayData? {
        val body = intent?.getStringExtra("${prefix}_body") ?: ""
        if (body.isBlank()) return null
        return OverlayData(
            title = intent?.getStringExtra("${prefix}_title") ?: "",
            body = body,
            meta = intent?.getStringExtra("${prefix}_meta") ?: "",
            tafsir = intent?.getStringExtra("${prefix}_tafsir") ?: "",
            globalAyah = intent?.getIntExtra("${prefix}_globalAyah", 0) ?: 0,
            surah = intent?.getIntExtra("${prefix}_surah", 0) ?: 0,
            ayah = intent?.getIntExtra("${prefix}_ayah", 0) ?: 0,
            audioUrl = intent?.getStringExtra("${prefix}_audioUrl") ?: "",
        )
    }

    /** (Re)draws the currently navigated-to ayah; companions track it so ✓
     * completes exactly what is displayed. */
    private fun render() {
        val data = OverlayNav.current ?: run {
            stopForegroundAndSelf()
            return
        }
        currentGlobalAyah = data.globalAyah
        currentSurah = data.surah
        currentAyah = data.ayah
        removeOverlay()
        val view = AyahOverlayUi.buildCard(
            this,
            data,
            onDone = {
                // Persist even if the Flutter engine is dead; Dart reconciles
                // via consumePendingCompletion on next resume/startup.
                OverlayPrefs.writePending(this, currentGlobalAyah)
                notifyCompletedRead()
                stopForegroundAndSelf()
            },
            onLater = {
                notifyLater()
                stopForegroundAndSelf()
            },
            onPrev = if (OverlayNav.hasPrev) ({
                OverlayNav.goPrev()
                render()
            }) else null,
            onNext = if (OverlayNav.hasNext) ({
                OverlayNav.goNext()
                render()
            }) else null,
            onHelp = { AyahOverlayUi.showHelp(this) },
        )
        try {
            windowManager.addView(view, AyahOverlayUi.overlayParams())
            overlayView = view
            isShowing = true
        } catch (_: Exception) {
            overlayView = null
            isShowing = false
        }
    }

    private fun removeOverlay() {
        OverlayAudio.stop()
        if (!::windowManager.isInitialized) {
            overlayView = null
            isShowing = false
            return
        }
        overlayView?.let {
            try {
                windowManager.removeView(it)
            } catch (_: Exception) {
            }
            overlayView = null
        }
        isShowing = false
    }
}

