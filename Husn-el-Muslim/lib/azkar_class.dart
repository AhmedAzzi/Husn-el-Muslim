import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

class AzkarInfo {
  final int id;
  final String category;
  final String audio;
  final String filename;
  final List<AzkarArrayInfo> array;

  AzkarInfo({
    required this.id,
    required this.category,
    required this.audio,
    required this.filename,
    required this.array,
  });

  factory AzkarInfo.fromJson(Map<String, dynamic> json) {
    return AzkarInfo(
      id: json['id'],
      category: json['category'],
      audio: json['audio'],
      filename: json['filename'],
      array: (json['array'] as List)
          .map((arrayItem) => AzkarArrayInfo.fromJson(arrayItem))
          .toList(),
    );
  }
}

class AzkarArrayInfo {
  final int id;
  final String text;
  int count;
  final int fix;
  final String audio;
  final String filename;

  AzkarArrayInfo({
    required this.id,
    required this.text,
    required this.count,
    required this.fix,
    required this.audio,
    required this.filename,
  });

  factory AzkarArrayInfo.fromJson(Map<String, dynamic> json) {
    return AzkarArrayInfo(
      id: json['id'],
      text: json['text'],
      count: json['count'],
      fix: json['count'],
      audio: json['audio'],
      filename: json['filename'],
    );
  }
}

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
