import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:vibration/vibration.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';

/// Shared config for tactile/audio feedback used by the interactive
/// counters (misbaha, azkar details). Both players enable/disable the same
/// behaviour based on the shared click-sound / vibration preferences.
class ClickFeedback {
  ClickFeedback() : clickPlayer = ap.AudioPlayer() {
    _loadSettings();
  }

  final ap.AudioPlayer clickPlayer;
  bool _clickSoundEnabled = true;
  bool _vibrationEnabled = true;

  Future<void> _loadSettings() async {
    final prefs = await SharedPrefsCache.instanceAsync;
    _clickSoundEnabled = prefs.getBool('click_sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
  }

  Future<void> playClickSound() async {
    if (!_clickSoundEnabled) return;
    try {
      await clickPlayer.play(ap.AssetSource('click.wav'));
    } catch (_) {
      // Silently fail
    }
  }

  Future<void> vibrateDevice() async {
    if (!_vibrationEnabled) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 50);
      }
    } catch (_) {
      // Silently fail
    }
  }

  void dispose() {
    clickPlayer.dispose();
  }
}

Future<void> setupAudioPlayer(AudioPlayer player, String url) async {
  player.playbackEventStream.listen((event) {},
      onError: (Object e, StackTrace stacktrace) {
    if (kDebugMode) {
      print("A stream error occurred: $e");
    }
  });
  try {
    await player.setAudioSource(AudioSource.uri(Uri.parse(url)));
  } catch (e) {
    if (kDebugMode) {
      print("Error loading audio source: $e");
    }
  }
}

Widget playbackControlButton(AudioPlayer player, {double iconSize = 50}) {
  return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final processingState = snapshot.data?.processingState;
        final playing = snapshot.data?.playing;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          return IconButton(
            icon: const Icon(Icons.play_arrow),
            iconSize: iconSize,
            onPressed: player.play,
          );
        } else if (processingState != ProcessingState.completed) {
          return IconButton(
            icon: const Icon(Icons.pause),
            iconSize: iconSize,
            onPressed: player.pause,
          );
        } else {
          return IconButton(
              icon: const Icon(Icons.replay),
              iconSize: iconSize,
              onPressed: () => player.seek(Duration.zero));
        }
      });
}

Widget progressBar(AudioPlayer player,
    {double topPadding = 20,
    double thumbRadius = 7,
    double barHeight = 2,
    TextStyle? timeLabelTextStyle}) {
  return StreamBuilder<Duration?>(
    stream: player.positionStream,
    builder: (context, snapshot) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: ProgressBar(
          thumbRadius: thumbRadius,
          timeLabelTextStyle: timeLabelTextStyle,
          barHeight: barHeight,
          progress: snapshot.data ?? Duration.zero,
          buffered: player.bufferedPosition,
          total: player.duration ?? Duration.zero,
          onSeek: (duration) {
            player.seek(duration);
          },
        ),
      );
    },
  );
}
