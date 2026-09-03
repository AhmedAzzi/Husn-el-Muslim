package com.ahmed.hisnelmuslim

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log

/**
 * Single owner of the Fajr-challenge alarm audio on the native side.
 *
 * Why this exists: the Dart engine (and therefore every Dart AudioPlayer)
 * is dead when the app has been swiped away or hasn't started yet. An
 * AlarmManager trigger in that state must still be audible, so the sound
 * is played here — from the receiver / service process — instead of
 * relying on the challenge screen to start playback.
 *
 * Contract:
 * - [play] is idempotent (re-entry restarts cleanly, never overlaps).
 * - Honors the in-app `notificationSoundEnabled` toggle.
 * - Loops until [stop] or a 5-minute safety timeout (never rings forever
 *   if the user never opens the challenge).
 * - Holds a partial wake lock via [MediaPlayer.setWakeMode] so Doze
 *   cannot silence playback mid-alarm.
 */
object AlarmSound {
    private var mediaPlayer: MediaPlayer? = null
    private var stopRunnable: Runnable? = null
    private val handler = Handler(Looper.getMainLooper())

    /** Maximum ring duration as a safety net. */
    private const val MAX_DURATION_MS = 5 * 60 * 1000L

    @Synchronized
    fun play(context: Context) {
        try {
            val flutterPrefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            if (!flutterPrefs.getBoolean("flutter.notificationSoundEnabled", true)) {
                return
            }
        } catch (e: Exception) {
            Log.w("AlarmSound", "Could not read sound toggle, defaulting to play: ${e.message}")
        }

        stopLocked()
        try {
            val appContext = context.applicationContext
            val mp = MediaPlayer.create(appContext, R.raw.adan) ?: run {
                Log.e("AlarmSound", "MediaPlayer.create returned null")
                return
            }
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()
            )
            mp.setWakeMode(appContext, PowerManager.PARTIAL_WAKE_LOCK)
            mp.isLooping = true
            mp.setOnErrorListener { _, _, _ ->
                stop()
                true
            }
            mediaPlayer = mp
            mp.start()

            val timeout = Runnable { stop() }
            stopRunnable = timeout
            handler.postDelayed(timeout, MAX_DURATION_MS)
        } catch (e: Exception) {
            Log.e("AlarmSound", "Failed to play alarm sound: ${e.message}")
            stopLocked()
        }
    }

    @Synchronized
    fun stop() {
        stopLocked()
    }

    private fun stopLocked() {
        stopRunnable?.let { handler.removeCallbacks(it) }
        stopRunnable = null
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
