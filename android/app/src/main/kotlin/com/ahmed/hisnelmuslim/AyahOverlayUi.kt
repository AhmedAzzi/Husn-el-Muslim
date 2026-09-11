package com.ahmed.hisnelmuslim

import android.content.Context
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

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
 * dark rounded card with a gold border and ۞ ornaments, ivory AmiriQuran
 * ayah text, gold circular actions — fully RTL.
 */
object AyahOverlayUi {
    // Husn-el-Muslim palette.
    private val BURGUNDY: Int = 0xFF693B42.toInt()
    private val GOLD: Int = 0xFFC9A227.toInt()
    private val GOLD_LIGHT: Int = 0xFFE7C65A.toInt()
    private val SURFACE: Int = 0xFF1E1E28.toInt()
    private val IVORY: Int = 0xFFFFFDF5.toInt()
    private val SAND: Int = 0xFFEDE3C8.toInt()
    private val MUTED: Int = 0xFFA89B7C.toInt()
    private val ON_GOLD: Int = 0xFF3A2410.toInt()

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
     * Husn-styled card, fully RTL:
     * deep-burgundy dim backdrop, dark rounded card with gold border and a
     * ۞ badge overlapping the top, gold title + divider, ivory mushaf ayah,
     * prev/meta/next row, sand tafsir box, gold circular actions
     * (✓ done, ◷ later, ▶ play, ؟ help).
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
        val root = LinearLayout(ctx)
        root.orientation = LinearLayout.VERTICAL
        root.gravity = Gravity.CENTER
        root.layoutDirection = View.LAYOUT_DIRECTION_RTL
        root.setPadding(dp(ctx, 16), dp(ctx, 8), dp(ctx, 16), dp(ctx, 12))
        // Dim backdrop: deep burgundy-black gradient, translucent so the
        // underlying app stays faintly visible.
        root.background = GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            intArrayOf(0xD90B0714.toInt(), 0xB31A0E2E.toInt())
        )

        val wrap = FrameLayout(ctx)
        wrap.layoutDirection = View.LAYOUT_DIRECTION_RTL
        root.addView(
            wrap,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        // Dark card with gold border and soft shadow.
        val panel = LinearLayout(ctx)
        panel.orientation = LinearLayout.VERTICAL
        panel.layoutDirection = View.LAYOUT_DIRECTION_RTL
        panel.setPadding(dp(ctx, 14), dp(ctx, 16), dp(ctx, 14), dp(ctx, 12))
        panel.background = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dp(ctx, 16).toFloat()
            setColor(SURFACE)
            setStroke(dp(ctx, 2), GOLD)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            panel.elevation = dp(ctx, 10).toFloat()
        }
        wrap.addView(
            panel,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                // Room for the ۞ badge overlapping the top edge.
                topMargin = dp(ctx, 12)
            }
        )

        // ۞ badge overlapping the top edge: burgundy medallion, gold ring.
        val badgeSize = dp(ctx, 30)
        val badge = TextView(ctx)
        badge.text = "۞"
        badge.setTextColor(GOLD_LIGHT)
        badge.textSize = 13f
        badge.typeface = amiri(ctx) ?: Typeface.create("serif", Typeface.BOLD)
        badge.gravity = Gravity.CENTER
        badge.background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(BURGUNDY)
            setStroke(dp(ctx, 2), GOLD)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            badge.elevation = dp(ctx, 4).toFloat()
        }
        wrap.addView(
            badge,
            FrameLayout.LayoutParams(badgeSize, badgeSize).apply {
                gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            }
        )

        // Title row: ۞ title ۞ in gold, centered.
        val titleView = TextView(ctx)
        titleView.text = "۞  ${data.title}  ۞"
        titleView.setTextColor(GOLD_LIGHT)
        titleView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        titleView.typeface = amiri(ctx) ?: Typeface.create("serif", Typeface.BOLD)
        titleView.gravity = Gravity.CENTER
        titleView.textAlignment = View.TEXT_ALIGNMENT_CENTER
        titleView.layoutDirection = View.LAYOUT_DIRECTION_RTL
        titleView.setTextDirection(View.TEXT_DIRECTION_RTL)
        panel.addView(
            titleView,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        // Gold hairline divider.
        val divider = View(ctx)
        divider.setBackgroundColor(0x59C9A227.toInt())
        panel.addView(
            divider,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(ctx, 1)
            ).apply {
                topMargin = dp(ctx, 8)
                bottomMargin = dp(ctx, 4)
                marginStart = dp(ctx, 16)
                marginEnd = dp(ctx, 16)
            }
        )

        // One scroll for the whole card content: ayah + nav + tafsir +
        // actions. Capped below to a fraction of the screen so long ayahs
        // scroll inside the card instead of overflowing it — scroll down to
        // reach ✓/◷/▶/؟.
        val scroll = android.widget.ScrollView(ctx).apply {
          layoutDirection = View.LAYOUT_DIRECTION_RTL
          isFillViewport = false
          isVerticalScrollBarEnabled = true
          overScrollMode = View.OVER_SCROLL_IF_CONTENT_SCROLLS
        }
        val scrollContent = LinearLayout(ctx)
        scrollContent.orientation = LinearLayout.VERTICAL
        scrollContent.layoutDirection = View.LAYOUT_DIRECTION_RTL
        scroll.addView(
          scrollContent,
          FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
          )
        )

        // Ayah text: ivory mushaf font, large, centered, RTL.
        val bodyView = TextView(ctx)
        bodyView.text = data.body
        bodyView.setTextColor(IVORY)
        bodyView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 26f)
        bodyView.typeface = amiri(ctx) ?: Typeface.create("serif", Typeface.BOLD)
        bodyView.textAlignment = View.TEXT_ALIGNMENT_CENTER
        bodyView.layoutDirection = View.LAYOUT_DIRECTION_RTL
        bodyView.setTextDirection(View.TEXT_DIRECTION_RTL)
        bodyView.gravity = Gravity.CENTER
        bodyView.setLineSpacing(0f, 1.5f)
        bodyView.setPadding(dp(ctx, 2), dp(ctx, 6), dp(ctx, 2), dp(ctx, 2))
        scrollContent.addView(
            bodyView,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        // Nav row, RTL: prev on the right, meta centered, next on the left.
        val controls = LinearLayout(ctx)
        controls.orientation = LinearLayout.HORIZONTAL
        controls.layoutDirection = View.LAYOUT_DIRECTION_RTL
        controls.gravity = Gravity.CENTER_VERTICAL
        controls.setPadding(0, dp(ctx, 1), 0, dp(ctx, 1))
        scrollContent.addView(
            controls,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )
        val prevBtn = circleButton(ctx, "⏮", 0, GOLD, GOLD, onPrev)
        if (onPrev == null) prevBtn.alpha = 0.3f
        controls.addView(prevBtn)
        val metaView = TextView(ctx)
        metaView.text = data.meta.ifBlank { data.title }
        metaView.setTextColor(GOLD_LIGHT)
        metaView.textSize = 14f
        metaView.typeface = amiri(ctx) ?: Typeface.create("sans-serif", Typeface.BOLD)
        metaView.gravity = Gravity.CENTER
        metaView.textAlignment = View.TEXT_ALIGNMENT_CENTER
        // LTR paragraph keeps "(نوح - 4 / 28)" parens/digits order intact.
        metaView.setTextDirection(View.TEXT_DIRECTION_LTR)
        controls.addView(
            metaView,
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        )
        val nextBtn = circleButton(ctx, "⏭", 0, GOLD, GOLD, onNext)
        if (onNext == null) nextBtn.alpha = 0.3f
        controls.addView(nextBtn)

        // Tafsir in a sand-tinted rounded box (never hidden, never fabricated).
        if (data.tafsir.isNotBlank()) {
            val box = LinearLayout(ctx)
            box.orientation = LinearLayout.VERTICAL
            box.layoutDirection = View.LAYOUT_DIRECTION_RTL
            box.setPadding(
    dp(ctx, 10),
    dp(ctx, 13), // top +5
    dp(ctx, 10),
    dp(ctx, 13)  // bottom +5
)
            box.background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(ctx, 12).toFloat()
                setColor(0x1FC9A227.toInt())
                setStroke(dp(ctx, 1), 0x59C9A227.toInt())
            }
            // val tv = TextView(ctx)
            tv.text = data.tafsir
            tv.setTextColor(SAND)
            tv.typeface = amiri(ctx) ?: Typeface.create("serif", Typeface.NORMAL)
            tv.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            tv.textAlignment = View.TEXT_ALIGNMENT_CENTER
            tv.layoutDirection = View.LAYOUT_DIRECTION_RTL
            tv.setTextDirection(View.TEXT_DIRECTION_RTL)
            tv.gravity = Gravity.CENTER
            tv.setLineSpacing(0f, 1.4f)
            box.addView(
                tv,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            )
            scrollContent.addView(
                box,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dp(ctx, 6)
                }
            )
        }

        // Cap the scroll area so the whole card always fits on screen:
        // measure the content, then clamp to ~62% of the display height
        // (title + badge keep the rest). Short content stays
        // wrap-content — no empty gap.
        val metrics = ctx.resources.displayMetrics
        val maxScrollH = (metrics.heightPixels * 0.62).toInt()
        val contentWidthSpec = View.MeasureSpec.makeMeasureSpec(
            (metrics.widthPixels - dp(ctx, 76)).coerceAtLeast(0),
            View.MeasureSpec.AT_MOST
        )
        scroll.measure(
            contentWidthSpec,
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        )
        val scrollH = if (scroll.measuredHeight > maxScrollH && maxScrollH > 0) {
            maxScrollH
        } else {
            LinearLayout.LayoutParams.WRAP_CONTENT
        }
        panel.addView(
            scroll,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                scrollH
            )
        )

        // Action row at the end of the scroll: ✓ done, ◷ later, ▶ play,
        // ؟ help — RTL order: done first (right).
        val actions = LinearLayout(ctx)
        actions.orientation = LinearLayout.HORIZONTAL
        actions.layoutDirection = View.LAYOUT_DIRECTION_RTL
        actions.gravity = Gravity.CENTER
        actions.setPadding(0, dp(ctx, 8), 0, 0)
        scrollContent.addView(
            actions,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        val doneBtn = circleButton(ctx, "✓", GOLD, GOLD, ON_GOLD, onDone, bold = true)
        actions.addView(doneBtn)
        actions.addView(gap(ctx, 10))
        actions.addView(circleButton(ctx, "◷", 0, GOLD, GOLD_LIGHT, onLater, bold = true))

        // Play streams this ayah's audio (ordered candidates supplied by
        // Flutter: primary host first, mirrors after, newline-joined).
        // Toggles ▶/⏸; a missing URL toasts, and only when every origin
        // fails does a stream failure toast.
        val playBtn = circleButton(
            ctx,
            if (OverlayAudio.isPlaying()) "⏸" else "▶",
            0, GOLD, GOLD_LIGHT, null, bold = true
        )
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
        actions.addView(gap(ctx, 10))
        actions.addView(playBtn)

        val helpBtn = circleButton(ctx, "؟", 0, 0, MUTED, onHelp, bold = true)
        actions.addView(gap(ctx, 10))
        actions.addView(helpBtn)

        return root
    }

    /**
     * Circular action button: [fill] background (0 = transparent),
     * [stroke] ring (0 = none), [fg] glyph color. 48dp touch target.
     */
    private fun circleButton(
        ctx: Context,
        glyph: String,
        fill: Int,
        stroke: Int,
        fg: Int,
        onClick: (() -> Unit)?,
        bold: Boolean = false,
    ): TextView {
        val size = dp(ctx, 48)
        val v = TextView(ctx)
        v.text = glyph
        v.setTextColor(fg)
        v.setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
        if (bold) v.typeface = Typeface.create("sans-serif", Typeface.BOLD)
        v.gravity = Gravity.CENTER
        v.layoutDirection = View.LAYOUT_DIRECTION_RTL
        v.background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            if (fill != 0) setColor(fill)
            if (stroke != 0) setStroke(dp(ctx, 2), stroke) else setStroke(dp(ctx, 1), 0x33000000.toInt())
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            v.elevation = dp(ctx, 3).toFloat()
        }
        v.isClickable = true
        v.isFocusable = false
        if (onClick != null) v.setOnClickListener { onClick() }
        v.layoutParams = LinearLayout.LayoutParams(size, size)
        // When placed in the horizontal nav row (prev/next), wrap content
        // width is used instead — caller overrides layoutParams there.
        return v
    }

    private fun gap(ctx: Context, dpw: Int): View {
        val v = View(ctx)
        v.layoutParams = LinearLayout.LayoutParams(dp(ctx, dpw), 1)
        return v
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
