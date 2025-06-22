import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

Future<String> loadAzkarJson() async {
  return await rootBundle.loadString('assets/hisnmuslim.json');
}

Future<void> openURL(String url) async {
  final customURL = url;
  final parsed = Uri.parse(customURL);
  try {
    if (await canLaunchUrl(parsed)) {
      await launchUrl(parsed);
    }
  } catch (_) {}
}

setupAudioPlayer(AudioPlayer player, String url) async {
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
