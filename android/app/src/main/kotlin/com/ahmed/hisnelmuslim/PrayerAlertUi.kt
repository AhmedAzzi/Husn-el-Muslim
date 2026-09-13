package com.ahmed.hisnelmuslim

import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.os.Build
import android.util.TypedValue
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.animation.PathInterpolator
import android.widget.TextView
import com.ahmed.hisnelmuslim.databinding.OverlayPrayerAlertBinding

/**
 * Single builder for the full-screen prayer-time alert, mirroring
 * [AyahOverlayUi]: static structure lives in
 * `res/layout/overlay_prayer_alert.xml`, dynamic state (prayer title, Amiri
 * typeface, entrance + icon-pulse animations, dismiss wiring) is bound here.
 *
 * The single caller is `PrayerTimeService.triggerAyatHadithOverlay`, which
 * owns the adhan [android.media.MediaPlayer] and the WindowManager attach /
 * detach lifecycle — this object never holds a view reference.
 */
object PrayerAlertUi {

    fun arabicName(en: String): String = when (en) {
        "Fajr" -> "الفجر"
        "Sunrise" -> "الشروق"
        "Dhuhr" -> "الظهر"
        "Asr" -> "العصر"
        "Maghrib" -> "المغرب"
        "Isha" -> "العشاء"
        else -> en
    }

    fun overlayParams(): WindowManager.LayoutParams {
        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        )
    }

    /**
     * Inflates the alert, binds `صلاة <arabic>`, applies the Amiri typeface
     * (falls back to serif when the asset is missing) and wires dismiss:
     * backdrop tap and the pinned close button call [onDismiss]; taps on the
     * content column are consumed so they don't dismiss.
     */
    fun inflate(
        ctx: Context,
        arabicPrayerName: String,
        onDismiss: () -> Unit,
    ): OverlayPrayerAlertBinding {
        val binding = OverlayPrayerAlertBinding.inflate(LayoutInflater.from(ctx))
        val amiri = AyahOverlayUi.amiri(ctx) ?: Typeface.create("serif", Typeface.NORMAL)

        binding.prayerAlertBasmala.typeface = amiri
        binding.prayerAlertTitle.typeface = amiri
        binding.prayerAlertTitle.text = "صلاة $arabicPrayerName"
        binding.prayerAlertBadge.typeface = amiri
        binding.prayerAlertVerse.typeface = amiri
        binding.prayerAlertSource.typeface = amiri
        binding.prayerAlertDua.typeface = amiri
        binding.prayerAlertClose.typeface = amiri

        binding.prayerAlertClose.setOnClickListener { onDismiss() }
        binding.prayerAlertRoot.setOnClickListener { onDismiss() }
        // Consume taps inside the card column so only backdrop/close dismiss.
        binding.prayerAlertContent.setOnClickListener { /* no-op */ }
        return binding
    }

    /**
     * Shrinks the content tree (text sizes, paddings, margins, fixed sizes)
     * just enough to fit the screen height — the alert never scrolls and
     * never clips. Only ever shrinks: tall screens keep the designed sizes.
     * Up to 3 measure-and-shrink passes so very short (landscape) screens
     * converge. Must be called after [inflate] and before attaching the view.
     *
     * The close button is pinned outside this tree (anchored to the root
     * bottom), so its zone is reserved top AND bottom: the centered content
     * can never slide under the button, which stays full-size and tappable.
     */
    fun fitContentToHeight(ctx: Context, binding: OverlayPrayerAlertBinding) {
        val metrics = ctx.resources.displayMetrics
        binding.prayerAlertClose.measure(
            View.MeasureSpec.makeMeasureSpec(
                metrics.widthPixels - dp(ctx, 40), View.MeasureSpec.EXACTLY
            ),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        )
        val zone = binding.prayerAlertClose.measuredHeight + dp(ctx, 40)
        val maxH = metrics.heightPixels - zone * 2 - dp(ctx, 8)
        if (maxH <= 0) return
        val widthSpec = View.MeasureSpec.makeMeasureSpec(metrics.widthPixels, View.MeasureSpec.EXACTLY)
        repeat(3) {
            binding.prayerAlertContent.measure(
                widthSpec,
                View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
            )
            val h = binding.prayerAlertContent.measuredHeight
            if (h <= maxH || h <= 0) return
            scaleTree(binding.prayerAlertContent, (maxH.toFloat() / h).coerceIn(0.6f, 0.95f))
        }
    }

    private fun dp(ctx: Context, v: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            v.toFloat(),
            ctx.resources.displayMetrics
        ).toInt()

    private fun scaleTree(view: View, f: Float) {
        view.setPadding(
            (view.paddingLeft * f).toInt(),
            (view.paddingTop * f).toInt(),
            (view.paddingRight * f).toInt(),
            (view.paddingBottom * f).toInt()
        )
        (view.layoutParams as? ViewGroup.MarginLayoutParams)?.let { lp ->
            if (lp.width > 0) lp.width = (lp.width * f).toInt()
            if (lp.height > 0) lp.height = (lp.height * f).toInt()
            lp.setMargins(
                (lp.leftMargin * f).toInt(),
                (lp.topMargin * f).toInt(),
                (lp.rightMargin * f).toInt(),
                (lp.bottomMargin * f).toInt()
            )
        }
        if (view is TextView) {
            view.setTextSize(TypedValue.COMPLEX_UNIT_PX, view.textSize * f)
        }
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) scaleTree(view.getChildAt(i), f)
        }
    }

    /** Gentle infinite pulse for the mosque marker; caller cancels on dismiss. */
    fun startIconPulse(icon: View): ObjectAnimator =
        ObjectAnimator.ofPropertyValuesHolder(
            icon,
            PropertyValuesHolder.ofFloat(View.SCALE_X, 1f, 1.12f, 1f),
            PropertyValuesHolder.ofFloat(View.SCALE_Y, 1f, 1.12f, 1f)
        ).apply {
            duration = 2000
            repeatCount = ValueAnimator.INFINITE
            interpolator = PathInterpolator(0.215f, 0.61f, 0.355f, 1f)
            start()
        }

    /** Fade the backdrop in, then slide the content column up underneath. */
    fun animateEntrance(binding: OverlayPrayerAlertBinding, dp: Float) {
        val interpolator = PathInterpolator(0.215f, 0.61f, 0.355f, 1f)
        binding.prayerAlertRoot.alpha = 0f
        binding.prayerAlertRoot.animate()
            .alpha(1f)
            .setDuration(700)
            .setInterpolator(interpolator)
            .start()
        binding.prayerAlertContent.alpha = 0f
        binding.prayerAlertContent.translationY = 60f * dp
        binding.prayerAlertContent.animate()
            .alpha(1f)
            .translationY(0f)
            .setDuration(800)
            .setStartDelay(200)
            .setInterpolator(interpolator)
            .start()

        // The pinned button rises in last so the eye lands on the action.
        binding.prayerAlertClose.alpha = 0f
        binding.prayerAlertClose.translationY = 30f * dp
        binding.prayerAlertClose.animate()
            .alpha(1f)
            .translationY(0f)
            .setDuration(600)
            .setStartDelay(350)
            .setInterpolator(interpolator)
            .start()
    }
}
