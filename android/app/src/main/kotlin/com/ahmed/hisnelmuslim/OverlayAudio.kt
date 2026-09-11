package com.ahmed.hisnelmuslim

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build

/**
 * Tiny streaming player for the overlay's play button. The overlay is native
 * (the Dart isolate may be paused with the screen off), so playback here
 * streams via [MediaPlayer] directly against the per-ayah URLs Flutter
 * supplies (built from the selected reciter). One stream at a time; call
 * [stop] when the overlay is dismissed or replaced. Online streaming only —
 * nothing is downloaded or cached.
 */
object OverlayAudio {
    private var player: MediaPlayer? = null
    private var currentUrl: String? = null
    private var preparingUrl: String? = null

    @Synchronized
    fun isPlaying(url: String? = null): Boolean {
        val p = player ?: return false
        return try {
            p.isPlaying && (url == null || currentUrl == url)
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Toggles playback of the given candidate streams, trying each in order
     * until one prepares successfully. Flutter supplies the primary host
     * first and mirror origins after it (newline-joined by the caller), so
     * a single flaky host (4xx/5xx) never silences audio.
     * [onStarted]/[onStopped]/[onError] run on the media thread — the
     * caller must post UI work back to the main thread.
     */
    @Synchronized
    fun toggle(
        ctx: Context,
        urls: List<String>,
        onStarted: () -> Unit,
        onStopped: () -> Unit,
        onError: () -> Unit,
    ) {
        val candidates = urls.map { it.trim() }.filter { it.isNotBlank() }
        if (candidates.isEmpty()) {
            onError()
            return
        }
        // Pause when the currently-playing stream is toggled again.
        val p = player
        if (p != null && candidates.contains(currentUrl)) {
            try {
                if (p.isPlaying) {
                    p.pause()
                    onStopped()
                    return
                }
                p.start()
                onStarted()
                return
            } catch (_: Exception) {
                resetLocked()
            }
        }
        resetLocked()
        tryUrl(ctx, candidates, 0, onStarted, onStopped, onError)
    }

    /**
     * Single-URL convenience: splits Flutter's newline-joined candidate
     * string and delegates to [toggle].
     */
    @Synchronized
    fun toggle(
        ctx: Context,
        url: String,
        onStarted: () -> Unit,
        onStopped: () -> Unit,
        onError: () -> Unit,
    ) = toggle(ctx, url.split('\n'), onStarted, onStopped, onError)

    private fun tryUrl(
        ctx: Context,
        candidates: List<String>,
        index: Int,
        onStarted: () -> Unit,
        onStopped: () -> Unit,
        onError: () -> Unit,
    ) {
        if (index >= candidates.size) {
            resetLocked()
            onError()
            return
        }
        val url = candidates[index]
        preparingUrl = url
        try {
            val mp = MediaPlayer()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                mp.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
            } else {
                @Suppress("DEPRECATION")
                mp.setAudioStreamType(android.media.AudioManager.STREAM_MUSIC)
            }
            mp.setDataSource(url)
            mp.setOnPreparedListener { prepared ->
                synchronized(this) {
                    // A stop() or a newer toggle may have cancelled this load.
                    if (preparingUrl != url) {
                        try {
                            prepared.release()
                        } catch (_: Exception) {
                        }
                        return@setOnPreparedListener
                    }
                    preparingUrl = null
                    player = prepared
                    currentUrl = url
                }
                try {
                    prepared.start()
                } catch (_: Exception) {
                    stop()
                    onError()
                    return@setOnPreparedListener
                }
                onStarted()
            }
            mp.setOnCompletionListener {
                stop()
                onStopped()
            }
            // A dead host must fall through to the next mirror, not toast.
            // Only the last candidate reports failure to the UI.
            mp.setOnErrorListener { errored, _, _ ->
                try {
                    errored.reset()
                } catch (_: Exception) {
                }
                try {
                    errored.release()
                } catch (_: Exception) {
                }
                if (index + 1 < candidates.size) {
                    tryUrl(ctx, candidates, index + 1, onStarted, onStopped, onError)
                } else {
                    stop()
                    onError()
                }
                true
            }
            mp.prepareAsync()
        } catch (_: Exception) {
            // Synchronous setup failure (e.g. malformed URL): try next.
            tryUrl(ctx, candidates, index + 1, onStarted, onStopped, onError)
        }
    }

    @Synchronized
    fun stop() {
        resetLocked()
    }

    private fun resetLocked() {
        preparingUrl = null
        currentUrl = null
        val p = player
        player = null
        if (p != null) {
            try {
                p.reset()
            } catch (_: Exception) {
            }
            try {
                p.release()
            } catch (_: Exception) {
            }
        }
    }
}

