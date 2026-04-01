import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:convert';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/core/utils/asset_loader.dart';

class FajrChallengeScreen extends StatefulWidget {
  const FajrChallengeScreen({super.key});

  @override
  State<FajrChallengeScreen> createState() => _FajrChallengeScreenState();
}

class _FajrChallengeScreenState extends State<FajrChallengeScreen>
    with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  static const platform = MethodChannel('com.yourapp/volume_lock');
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswerCorrect = false;
  int _correctAnswersCount = 0;
  int _targetQuestionsCount = 3;
  bool _isTextInputMode = false;
  bool _isLoading = true;
  final TextEditingController _textController = TextEditingController();
  List<Question> _questions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final logic = PrayerTimesLogic();
    _targetQuestionsCount = logic.fajrChallengeQuestionsCount;
    _isTextInputMode = logic.fajrChallengeIsTextInput;

    _loadQuestionsFromJSON();
    _initAudio();
    _lockVolumeAtMax();
  }

  Future<void> _loadQuestionsFromJSON() async {
    try {
      String jsonData = await loadAzkarJson();
      List<dynamic> categories = json.decode(jsonData);

      List<Map<String, String>> allDhikrs = [];
      Set<String> allCategoryNames = {};

      for (var cat in categories) {
        String catName = cat['category'] as String;
        allCategoryNames.add(catName);
        List<dynamic> dhikrs = cat['array'];
        for (var dhikr in dhikrs) {
          String text = dhikr['text'] as String;
          // Filter out very short or very long texts
          if (text.length > 30 && text.length < 300) {
            allDhikrs.add({
              'text': text,
              'category': catName,
            });
          }
        }
      }

      if (allDhikrs.isEmpty) {
        // Fallback or handle error
        _stopAlarmAndExit();
        return;
      }

      allDhikrs.shuffle(Random());
      List<Question> generatedQuestions = [];

      // We want to generate more than needed to allow cycling
      int countToGenerate = max(20, _targetQuestionsCount * 2);

      for (int i = 0; i < min(allDhikrs.length, countToGenerate); i++) {
        var dhikr = allDhikrs[i];
        String correctCat = dhikr['category']!;

        // Pick 3 random wrong categories
        List<String> wrongCats = allCategoryNames
            .where((c) => c != correctCat)
            .toList()
          ..shuffle(Random());

        List<String> options = [
          correctCat,
          wrongCats[0],
          wrongCats[1],
          wrongCats[2],
        ];

        options.shuffle(Random());
        int correctIdx = options.indexOf(correctCat);

        generatedQuestions.add(Question(
          text: dhikr['text']!,
          options: options,
          correctAnswerIndex: correctIdx,
        ));
      }

      setState(() {
        _questions = generatedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dynamic questions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _lockVolumeAtMax() async {
    try {
      await platform.invokeMethod('lockVolumeAtMax');
    } catch (e) {
      debugPrint('Error locking volume: $e');
    }
  }

  Future<void> _unlockVolume() async {
    try {
      await platform.invokeMethod('unlockVolume');
    } catch (e) {
      debugPrint('Error unlocking volume: $e');
    }
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(1.0);
    try {
      await _audioPlayer.play(AssetSource('adan.mp3'));
    } catch (e) {
      debugPrint('Error playing alarm: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unlockVolume();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _normalizeString(String input) {
    String text = input.trim();
    text = text.replaceAll(RegExp(r'[\u064B-\u065F]'), '');
    text = text.replaceAll(RegExp(r'[أإآ]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ـ', '');
    return text;
  }

  void _checkTextAnswer() {
    final question = _questions[_currentQuestionIndex];
    final correctAnswer = question.options[question.correctAnswerIndex];
    final userText = _normalizeString(_textController.text);
    final correctText = _normalizeString(correctAnswer);

    bool correct =
        userText.contains(correctText) || correctText.contains(userText);

    if (correct && userText.length > 2) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }
    _textController.clear();
  }

  void _handleCorrectAnswer() {
    setState(() {
      _isAnswerCorrect = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _correctAnswersCount++;
        if (_correctAnswersCount >= _targetQuestionsCount) {
          // Keep the success state (Green) visible until we exit
          _stopAlarmAndExit();
        } else {
          // Reset for next question
          _isAnswerCorrect = false;
          _selectedAnswerIndex = null; // Important: Clear selection
          _nextQuestion();
        }
      });
    });
  }

  void _handleWrongAnswer() {
    Get.snackbar(
      'إجابة خاطئة',
      'حاول مرة أخرى',
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _checkAnswer(int index) {
    setState(() {
      _selectedAnswerIndex = index;
      _isAnswerCorrect =
          index == _questions[_currentQuestionIndex].correctAnswerIndex;
    });

    if (_isAnswerCorrect) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex + 1) % _questions.length;
      if (_currentQuestionIndex == 0) {
        _questions.shuffle(Random());
      }
    });
  }

  Future<void> _stopAlarmAndExit() async {
    await _unlockVolume();
    await _audioPlayer.stop();
    PrayerTimesLogic().stopAudio();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade900,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : _questions.isEmpty
                ? const Center(
                    child: Text('حدث خطأ في تحميل الأسئلة',
                        style: TextStyle(color: Colors.white)))
                : SafeArea(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Builder(builder: (context) {
                          final question = _questions[_currentQuestionIndex];
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.alarm_on,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'تحدي صلاة الفجر',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'أجب عن السؤال لإيقاف المنبه',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'المتبقي: ${_targetQuestionsCount - _correctAnswersCount}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _isTextInputMode
                                          ? "اكتب اسم الفئة التي ينتمي إليها هذا الذكر:"
                                          : question.text,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (_isTextInputMode) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        question.text,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.blueGrey.shade700,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    if (_isTextInputMode) ...[
                                      TextField(
                                        controller: _textController,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 18, color: Colors.black),
                                        decoration: InputDecoration(
                                          hintText: 'اكتب الإجابة هنا',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade100,
                                        ),
                                        onSubmitted: (_) => _checkTextAnswer(),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFD64463),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: _checkTextAnswer,
                                          child: const Text(
                                            'تحقق من الإجابة',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      ...List.generate(question.options.length,
                                          (index) {
                                        final isSelected =
                                            _selectedAnswerIndex == index;
                                        Color? tileColor = Colors.grey.shade100;
                                        Color textColor = Colors.black87;

                                        if (isSelected) {
                                          if (_isAnswerCorrect) {
                                            tileColor = Colors.green.shade100;
                                            textColor = Colors.green.shade900;
                                          } else {
                                            tileColor = Colors.red.shade100;
                                            textColor = Colors.red.shade900;
                                          }
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 12.0),
                                          child: InkWell(
                                            onTap: () => _checkAnswer(index),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 16,
                                                horizontal: 16,
                                              ),
                                              decoration: BoxDecoration(
                                                color: tileColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? (_isAnswerCorrect
                                                          ? Colors.green
                                                          : Colors.red)
                                                      : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Text(
                                                question.options[index],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class Question {
  final String text;
  final List<String> options;
  final int correctAnswerIndex;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });
}
