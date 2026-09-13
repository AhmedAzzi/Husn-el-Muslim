package com.ahmed.hisnelmuslim

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.os.Build
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.animation.LinearInterpolator
import android.view.animation.PathInterpolator
import android.widget.FrameLayout
import com.ahmed.hisnelmuslim.databinding.OverlayDhikrReminderBinding

/**
 * Single builder for the floating dhikr reminder card, mirroring
 * [PrayerAlertUi] / [AyahOverlayUi]: static structure lives in
 * `res/layout/overlay_dhikr_reminder.xml`, dynamic state (dhikr text, Amiri
 * typeface, entrance + countdown-progress animations, dismiss wiring) is
 * bound here.
 *
 * The single caller is `PrayerTimeService.triggerDhikrOverlay`, which owns
 * the WindowManager attach / detach lifecycle and the `isDhikrShowing` guard
 * — this object never holds a view reference.
 */
object DhikrOverlayUi {

    /** Auto-dismiss duration, matching the previous programmatic card. */
    const val DISPLAY_MS = 5000L

    fun overlayParams(ctx: Context): WindowManager.LayoutParams {
        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        val width = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            280f,
            ctx.resources.displayMetrics
        ).toInt()
        return WindowManager.LayoutParams(
            width,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.CENTER }
    }

    /**
     * Inflates the card, binds [dhikr] text with the Amiri typeface (falls
     * back to serif when the asset is missing) and wires tap-to-dismiss:
     * any tap on the root calls [onDismiss].
     */
    fun inflate(
        ctx: Context,
        dhikr: String,
        onDismiss: () -> Unit,
    ): OverlayDhikrReminderBinding {
        val binding = OverlayDhikrReminderBinding.inflate(LayoutInflater.from(ctx))
        binding.dhikrText.typeface =
            AyahOverlayUi.amiri(ctx) ?: Typeface.create("serif", Typeface.NORMAL)
        binding.dhikrText.text = dhikr
        binding.dhikrRoot.setOnClickListener { onDismiss() }
        return binding
    }

    /** Fade + scale entrance (500ms, ease-out), then starts [onEntered]. */
    fun animateEntrance(binding: OverlayDhikrReminderBinding, onEntered: () -> Unit) {
        val interpolator = PathInterpolator(0.215f, 0.61f, 0.355f, 1f)
        binding.dhikrRoot.alpha = 0f
        binding.dhikrRoot.scaleX = 0.8f
        binding.dhikrRoot.scaleY = 0.6f
        binding.dhikrRoot.animate()
            .alpha(1f)
            .scaleX(1f)
            .scaleY(1f)
            .setDuration(500)
            .setInterpolator(interpolator)
            .withEndAction { onEntered() }
            .start()
    }

    /** Fade + shrink exit (300ms, ease-out), then detaches via [onDetached]. */
    fun animateExit(
        wm: WindowManager,
        binding: OverlayDhikrReminderBinding,
        onDetached: () -> Unit,
    ) {
        binding.dhikrRoot.animate()
            .alpha(0f)
            .scaleX(0.9f)
            .scaleY(0.9f)
            .setDuration(300)
            .setInterpolator(PathInterpolator(0.215f, 0.61f, 0.355f, 1f))
            .withEndAction {
                try {
                    wm.removeView(binding.dhikrRoot)
                } catch (_: Exception) {
                }
                onDetached()
            }
            .start()
    }

    /**
     * Shrinks the progress fill from full width to zero over [DISPLAY_MS].
     * Returns the animator so the caller can `cancel()` it on tap-to-dismiss
     * (cancelling suppresses the end callback — exit runs exactly once via
     * the caller's `wasDismissed` guard).
     */
    fun startProgress(
        ctx: Context,
        binding: OverlayDhikrReminderBinding,
        onFinished: () -> Unit,
    ): ValueAnimator {
        val fullWidth = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            280f,
            ctx.resources.displayMetrics
        ).toInt()
        return ValueAnimator.ofFloat(1f, 0f).apply {
            duration = DISPLAY_MS
            interpolator = LinearInterpolator()
            addUpdateListener { animator ->
                val fraction = animator.animatedValue as Float
                val lp = binding.dhikrProgress.layoutParams as FrameLayout.LayoutParams
                lp.width = (fullWidth * fraction).toInt()
                binding.dhikrProgress.layoutParams = lp
            }
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    onFinished()
                }
            })
        }
    }
}
