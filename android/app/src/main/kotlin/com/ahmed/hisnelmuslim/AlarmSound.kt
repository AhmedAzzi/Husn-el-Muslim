package com.ahmed.hisnelmuslim

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import java.io.File

/**
 * Single owner of the Fajr-challenge alarm audio on the native side.
 *
 * Why this exists: the Dart engine (and therefore every Dart AudioPlayer)
 * is dead when the app has been swiped away or hasn't started yet. An
 * AlarmManager trigger in that state must still be audible, so the sound
 * is played here — from the receiver / service process — instead of
 * relying on the challenge screen to start playback.
 *
 * Reads the user's sound settings from Flutter prefs (same keys as Dart):
 * - `flutter.alarmSound` — adhan | system | custom
 * - `flutter.alarmCustomPath` — local file for `custom`
 * - `flutter.alarmVolumePercent` — 20..100 (never silent)
 * - `flutter.alarmVibrate` — vibration while ringing
 * - `flutter.alarmLoop` — loop until dismissed
 * - `flutter.gentleWakeSeconds` — 0/30/60/120 volume ramp
 *
 * Contract:
 * - [play] is idempotent (re-entry restarts cleanly, never overlaps).
 * - Loops until [stop] or a 5-minute safety timeout (never rings forever
 *   if the user never opens the challenge).
 * - Holds a partial wake lock via [MediaPlayer.setWakeMode] so Doze
 *   cannot silence playback mid-alarm.
 */
object AlarmSound {
    private var mediaPlayer: MediaPlayer? = null
    private var stopRunnable: Runnable? = null
    private var rampRunnable: Runnable? = null
    private val handler = Handler(Looper.getMainLooper())

    /** Maximum ring duration as a safety net. */
    private const val MAX_DURATION_MS = 5 * 60 * 1000L

    @Synchronized
    fun play(context: Context) {
        startInternal(context, preview = false)
    }

    /** Short preview for the sound picker (no loop, auto-stops). */
    @Synchronized
    fun preview(context: Context) {
        startInternal(context, preview = true)
    }

    private fun startInternal(context: Context, preview: Boolean) {
        try {
            val flutterPrefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            if (!preview && !flutterPrefs.getBoolean("flutter.notificationSoundEnabled", true)) {
                return
            }
        } catch (e: Exception) {
            Log.w("AlarmSound", "Could not read sound toggle, defaulting to play: ${e.message}")
        }

        stopLocked()
        try {
            val appContext = context.applicationContext
            lastContext = appContext
            val prefs = appContext.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            val sound = prefs.getString("flutter.alarmSound", "adhan") ?: "adhan"
            val customPath = prefs.getString("flutter.alarmCustomPath", "") ?: ""
            val rawVol = (prefs.all["flutter.alarmVolumePercent"] as? Number)?.toInt() ?: 100
            val targetVol = (rawVol.coerceIn(20, 100)) / 100f
            val loop = prefs.getBoolean("flutter.alarmLoop", true) && !preview
            val vibrate = prefs.getBoolean("flutter.alarmVibrate", true) && !preview
            val gentleSecs = if (preview) 0 else when (
                (prefs.all["flutter.gentleWakeSeconds"] as? Number)?.toInt() ?: 0
            ) {
                30, 60, 120 -> (prefs.all["flutter.gentleWakeSeconds"] as Number).toInt()
                else -> 0
            }

            val mp = openPlayer(appContext, sound, customPath) ?: run {
                Log.e("AlarmSound", "Could not open alarm audio, falling back to bundled adhan")
                MediaPlayer.create(appContext, R.raw.adan) ?: run {
                    Log.e("AlarmSound", "MediaPlayer.create returned null")
                    return
                }
            }
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()
            )
            mp.setWakeMode(appContext, PowerManager.PARTIAL_WAKE_LOCK)
            mp.isLooping = loop
            mp.setOnErrorListener { _, _, _ ->
                stop()
                true
            }
            mediaPlayer = mp

            // Gentle wake-up: start quiet, ramp to the target volume.
            if (gentleSecs > 0) {
                mp.setVolume(0.1f * targetVol, 0.1f * targetVol)
                val steps = gentleSecs
                var step = 0
                val ramp = object : Runnable {
                    override fun run() {
                        step++
                        val f = (0.1f + 0.9f * (step.toFloat() / steps)) * targetVol
                        try {
                            mediaPlayer?.setVolume(f.coerceAtMost(targetVol), f.coerceAtMost(targetVol))
                        } catch (_: Exception) {
                        }
                        if (step < steps && mediaPlayer != null) {
                            rampRunnable = this
                            handler.postDelayed(this, 1000L)
                        } else {
                            rampRunnable = null
                        }
                    }
                }
                rampRunnable = ramp
                handler.postDelayed(ramp, 1000L)
            } else {
                mp.setVolume(targetVol, targetVol)
            }

            if (vibrate) startVibration(appContext)
            mp.start()

            val timeout = Runnable { stop() }
            stopRunnable = timeout
            handler.postDelayed(timeout, if (preview) 4000L else MAX_DURATION_MS)
        } catch (e: Exception) {
            Log.e("AlarmSound", "Failed to play alarm sound: ${e.message}")
            stopLocked()
        }
    }

    private fun openPlayer(appContext: Context, sound: String, customPath: String): MediaPlayer? {
        return try {
            when (sound) {
                "system" -> {
                    val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        ?: return null
                    MediaPlayer().apply {
                        setDataSource(appContext, uri)
                        prepare()
                    }
                }
                "custom" -> {
                    val f = File(customPath)
                    if (customPath.isEmpty() || !f.exists()) return null
                    MediaPlayer().apply {
                        setDataSource(customPath)
                        prepare()
                    }
                }
                else -> MediaPlayer.create(appContext, R.raw.adan)
            }
        } catch (e: Exception) {
            Log.w("AlarmSound", "openPlayer($sound) failed: ${e.message}")
            null
        }
    }

    @Suppress("DEPRECATION")
    private fun startVibration(appContext: Context) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = appContext.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator.vibrate(
                    VibrationEffect.createWaveform(longArrayOf(0, 1000, 1000), 0)
                )
            } else {
                @Suppress("DEPRECATION")
                val v = appContext.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    v.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 1000, 1000), 0))
                } else {
                    v.vibrate(longArrayOf(0, 1000, 1000), 0)
                }
            }
        } catch (e: Exception) {
            Log.w("AlarmSound", "Vibration failed: ${e.message}")
        }
    }

    @Suppress("DEPRECATION")
    private fun stopVibration(appContext: Context?) {
        try {
            if (appContext == null) return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = appContext.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator.cancel()
            } else {
                @Suppress("DEPRECATION")
                val v = appContext.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                v.cancel()
            }
        } catch (_: Exception) {
        }
    }

    private var lastContext: Context? = null

    @Synchronized
    fun stop() {
        stopVibration(lastContext?.applicationContext)
        lastContext = null
        stopLocked()
    }

    private fun stopLocked() {
        stopRunnable?.let { handler.removeCallbacks(it) }
        stopRunnable = null
        rampRunnable?.let { handler.removeCallbacks(it) }
        rampRunnable = null
        try {
            mediaPlayer?.let {
                try {
                    if (it.isPlaying) it.stop()
                } catch (_: Exception) {
                }
                try {
                    it.release()
                } catch (_: Exception) {
                }
            }
        } catch (_: Exception) {
        }
        mediaPlayer = null
    }
}
