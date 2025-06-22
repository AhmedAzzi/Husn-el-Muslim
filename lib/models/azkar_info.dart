import 'package:flutter/foundation.dart';

class AzkarInfo {
  final int id;
  final String category;
  final String audio;
  final String filename;
  final List<AzkarArrayInfo> array;
  final List<String> footnote;

  AzkarInfo({
    required this.id,
    required this.category,
    required this.audio,
    required this.filename,
    required this.array,
    required this.footnote,
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
      footnote: List<String>.from(json['footnote']),
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
