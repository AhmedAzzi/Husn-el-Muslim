package com.ahmed.hisnelmuslim

import android.content.Context
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Toast
import com.ahmed.hisnelmuslim.databinding.OverlayAyahCardBinding

/**
 * Data shown in the unlock overlay card.
 */
data class OverlayData(
    val title: String,
    val body: String,
    val meta: String,
    val tafsir: String,
    val globalAyah: Int,
    val surah: Int,
    val ayah: Int,
    /** Ordered stream candidates, newline-joined (primary host first). */
    val audioUrl: String = "",
)

/**
 * Browsing state inside one overlay session: the chain is
 * [prev?, center, next?] (max 3) and [pos] points at the displayed ayah,
 * so the user can step to a neighbour and always step back. Shared by the
 * service and the unlock-time fallback so both navigate identically.
 */
object OverlayNav {
    var chain: List<OverlayData> = emptyList()
        private set
    var pos: Int = 0
        private set

    fun reset(center: OverlayData, prev: OverlayData?, next: OverlayData?) {
        val list = ArrayList<OverlayData>(3)
        if (prev != null) list.add(prev)
        list.add(center)
        if (next != null) list.add(next)
        chain = list
        pos = if (prev != null) 1 else 0
    }

    val current: OverlayData? get() = chain.getOrNull(pos)
    val hasPrev: Boolean get() = pos > 0
    val hasNext: Boolean get() = pos < chain.size - 1

    fun goPrev(): OverlayData? {
        if (pos > 0) pos--
        return current
    }

    fun goNext(): OverlayData? {
        if (pos < chain.size - 1) pos++
        return current
    }
}

/**
 * Single builder for the overlay card, shared by [AyahOverlayService] and the
 * unlock-time fallback path, so there is exactly one overlay UI definition.
 *
 * Design follows the Husn-el-Muslim identity: deep burgundy dim backdrop,
 * dark rounded card with a gold border and ۞ ornaments, ivory Amiri
 * ayah text, gold circular actions — fully RTL.
 */
object AyahOverlayUi {
    const val HELP_TEXT =
        "اقرأ الآية، ثم اضغط ✓ لحفظها والانتقال للآية التالية، أو ◷ للتأجيل، واستخدم ⏮ ⏭ للتنقل بين الآيات"

    @Volatile
    private var fallbackView: View? = null
    private var fallbackWm: WindowManager? = null

    val isFallbackShowing: Boolean get() = fallbackView != null

    // Amiri (the app's UI font), loaded once from
    // android/app/src/main/assets/fonts. Null when unavailable → system serif.
    @Volatile
    private var amiri: Typeface? = null
    @Volatile
    private var amiriTried = false

    fun amiri(ctx: Context): Typeface? {
        if (!amiriTried) {
            amiriTried = true
            amiri = try {
                Typeface.createFromAsset(ctx.assets, "fonts/Amiri-Regular.ttf")
            } catch (_: Exception) {
                null
            }
        }
        return amiri
    }

    fun dp(ctx: Context, v: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            v.toFloat(),
            ctx.resources.displayMetrics
        ).toInt()

    fun overlayParams(): WindowManager.LayoutParams =
        WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.TOP }

    /**
     * Husn-styled card, fully RTL, compact header style — structure from
     * `res/layout/overlay_ayah_card.xml`, dynamic state bound here:
     * texts + Amiri typeface, tafsir visibility (never hidden, never
     * fabricated), prev/next dimming, scroll cap (~62% of the screen so long
     * ayahs scroll inside the card), inline header actions (✓ done, ◷ later,
     * ▶ play, ؟ help). Signature unchanged: [AyahOverlayService] and the
     * unlock-time fallback share this single definition.
     */
    fun buildCard(
        ctx: Context,
        data: OverlayData,
        onDone: () -> Unit,
        onLater: () -> Unit,
        onPrev: (() -> Unit)? = null,
        onNext: (() -> Unit)? = null,
        onHelp: (() -> Unit)? = null,
    ): View {
        val binding = OverlayAyahCardBinding.inflate(LayoutInflater.from(ctx))
        val serifBold = amiri(ctx) ?: Typeface.create("serif", Typeface.BOLD)
        val serif = amiri(ctx) ?: Typeface.create("serif", Typeface.NORMAL)
        val sansBold =
            amiri(ctx) ?: Typeface.create("sans-serif", Typeface.BOLD)

        binding.overlayBody.typeface = serifBold
        binding.overlayBody.text = data.body

        binding.overlayMeta.typeface = sansBold
        binding.overlayMeta.text = data.meta.ifBlank { data.title }

        if (onPrev == null) binding.overlayPrev.alpha = 0.3f
        else binding.overlayPrev.setOnClickListener { onPrev() }
        if (onNext == null) binding.overlayNext.alpha = 0.3f
        else binding.overlayNext.setOnClickListener { onNext() }

        // Tafsir in a sand-tinted rounded box (never hidden, never fabricated).
        if (data.tafsir.isNotBlank()) {
            binding.overlayTafsirBox.visibility = View.VISIBLE
            binding.overlayTafsir.typeface = serif
            binding.overlayTafsir.text = data.tafsir
        }

        // Cap the scroll area so the whole card always fits on screen:
        // measure the content, then clamp to ~62% of the display height
        // (header keeps the rest). Short content stays
        // wrap-content — no empty gap.
        val scroll = binding.overlayScroll
        val metrics = ctx.resources.displayMetrics
        val maxScrollH = (metrics.heightPixels * 0.62).toInt()
        // Horizontal insets: root padding (12+12) + card padding (12+12).
        val contentWidthSpec = View.MeasureSpec.makeMeasureSpec(
            (metrics.widthPixels - dp(ctx, 64)).coerceAtLeast(0),
            View.MeasureSpec.AT_MOST
        )
        scroll.measure(
            contentWidthSpec,
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        )
        if (scroll.measuredHeight > maxScrollH && maxScrollH > 0) {
            scroll.layoutParams = scroll.layoutParams.apply {
                height = maxScrollH
            }
        }

        binding.overlayDone.setOnClickListener { onDone() }
        binding.overlayLater.setOnClickListener { onLater() }

        // Play streams this ayah's audio (ordered candidates supplied by
        // Flutter: primary host first, mirrors after, newline-joined).
        // Toggles ▶/⏸; a missing URL toasts, and only when every origin
        // fails does a stream failure toast.
        val playBtn = binding.overlayPlay
        playBtn.text = if (OverlayAudio.isPlaying()) "⏸" else "▶"
        playBtn.setOnClickListener {
            val appCtx = ctx.applicationContext
            if (data.audioUrl.isBlank()) {
                try {
                    Toast.makeText(
                        appCtx,
                        "اختر القارئ في التطبيق أولاً",
                        Toast.LENGTH_SHORT
                    ).show()
                } catch (_: Exception) {
                }
                return@setOnClickListener
            }
            OverlayAudio.toggle(
                appCtx,
                data.audioUrl,
                onStarted = { playBtn.post { playBtn.text = "⏸" } },
                onStopped = { playBtn.post { playBtn.text = "▶" } },
                onError = {
                    playBtn.post { playBtn.text = "▶" }
                    try {
                        Toast.makeText(
                            appCtx,
                            "تعذّر تشغيل الصوت",
                            Toast.LENGTH_SHORT
                        ).show()
                    } catch (_: Exception) {
                    }
                },
            )
        }

        if (onHelp != null) binding.overlayHelp.setOnClickListener { onHelp() }

        return binding.root
    }

    fun showHelp(ctx: Context) {
        try {
            Toast.makeText(ctx, HELP_TEXT, Toast.LENGTH_LONG).show()
        } catch (_: Exception) {
        }
    }

    /**
     * Fallback used only when the overlay service cannot be started from a
     * background unlock event: draws the same card directly through the
     * WindowManager (allowed by SYSTEM_ALERT_WINDOW, no service start needed).
     */
    fun showFallback(
        ctx: Context,
        center: OverlayData,
        prev: OverlayData?,
        next: OverlayData?,
    ): Boolean {
        if (!Settings.canDrawOverlays(ctx)) return false
        OverlayNav.reset(center, prev, next)
        return renderFallback(ctx)
    }

    fun renderFallback(ctx: Context): Boolean {
        val appCtx = ctx.applicationContext
        val d = OverlayNav.current ?: return false
        if (!Settings.canDrawOverlays(appCtx)) return false
        removeFallback()
        return try {
            val wm = appCtx.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val view = buildCard(
                appCtx,
                d,
                onDone = {
                    OverlayPrefs.writePending(appCtx, d.globalAyah)
                    AyahOverlayService.notifyCompletedRead()
                    removeFallback()
                },
                onLater = {
                    AyahOverlayService.notifyLater()
                    removeFallback()
                },
                onPrev = if (OverlayNav.hasPrev) ({
                    OverlayNav.goPrev()
                    renderFallback(ctx)
                }) else null,
                onNext = if (OverlayNav.hasNext) ({
                    OverlayNav.goNext()
                    renderFallback(ctx)
                }) else null,
                onHelp = { showHelp(appCtx) },
            )
            wm.addView(view, overlayParams())
            fallbackView = view
            fallbackWm = wm
            true
        } catch (_: Exception) {
            fallbackView = null
            fallbackWm = null
            false
        }
    }

    fun removeFallback() {
        OverlayAudio.stop()
        val wm = fallbackWm
        val v = fallbackView
        fallbackView = null
        fallbackWm = null
        if (wm != null && v != null) {
            try {
                wm.removeView(v)
            } catch (_: Exception) {
            }
        }
    }
}
