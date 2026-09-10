import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:convert';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:small_husn_muslim/features/book/services/book_service.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/features/fajr_challenge/domain/challenge_models.dart'
    as engine;
import 'package:small_husn_muslim/features/tracking/data/fajr_tracking_repository.dart';
import 'package:small_husn_muslim/core/utils/asset_loader.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Post-challenge phases. Success is recorded ONLY after the user confirms
/// "أنا مستيقظ" — opening the screen or finishing questions is not enough.
enum _WakePhase { challenge, confirm, done }

class FajrChallengeScreen extends StatefulWidget {
  /// When true, the screen runs as a try-out: no volume lock, no alarm audio
  /// loop, nothing is recorded to tracking/streak, exiting just pops.
  final bool preview;
  const FajrChallengeScreen({super.key, this.preview = false});

  @override
  State<FajrChallengeScreen> createState() => _FajrChallengeScreenState();
}

class _FajrChallengeScreenState extends State<FajrChallengeScreen>
    with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  static const platform = MethodChannel('com.ahmed.hisnelmuslim/volume_lock');
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswerCorrect = false;
  int _correctAnswersCount = 0;
  int _targetQuestionsCount = 3;
  bool _isTextInputMode = false;
  bool _isLoading = true;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _mathController = TextEditingController();
  List<Question> _questions = [];
  _WakePhase _phase = _WakePhase.challenge;
  engine.ChallengeType _mode = engine.ChallengeType.questions;
  engine.MathChallenge? _math;
  engine.MemoryChallenge? _mem;
  engine.ShakeChallenge? _shake;
  // Memory UI state: transiently revealed tiles + input lock during mismatch.
  final Set<int> _revealed = {};
  bool _tilesLocked = false;
  // Shake sensor state: subscription lives ONLY inside this challenge.
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _sensorUnavailable = false;
  int _streakDays = 0;

  /// Tracks whether WE locked the volume, so dispose never mutes the user
  /// when the lock call itself failed.
  bool _volumeLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final logic = PrayerTimesLogic();
    _targetQuestionsCount = logic.fajrChallengeQuestionsCount;
    // Hard difficulty forces text-input mode (real complexity increase);
    // otherwise honor the user's explicit toggle.
    _isTextInputMode =
        logic.fajrChallengeIsTextInput || logic.fajrChallengeDifficulty == 'hard';
    _mode = _resolveMode(logic);
    final diff = switch (logic.fajrChallengeDifficulty) {
      'easy' => engine.ChallengeDifficulty.easy,
      'hard' => engine.ChallengeDifficulty.hard,
      _ => engine.ChallengeDifficulty.medium,
    };
    if (_mode == engine.ChallengeType.math) {
      _math = engine.MathChallenge(
          difficulty: diff, questionCount: _targetQuestionsCount)
        ..start();
      setState(() => _isLoading = false);
    } else if (_mode == engine.ChallengeType.memory) {
      _mem = engine.MemoryChallenge(pairs: 4, difficulty: diff)..start();
      setState(() => _isLoading = false);
    } else if (_mode == engine.ChallengeType.shake) {
      _shake = engine.ShakeChallenge(difficulty: diff)..start();
      setState(() => _isLoading = false);
      _listenToAccelerometer();
    } else {
      _loadQuestionsFromJSON();
    }
    // Stop any in-flight alarm audio (native AlarmSound / stray Dart player)
    // before starting our own loop — otherwise they overlap and echo.
    // Preview mode never touches real alarm audio or volume.
    if (!widget.preview) {
      PrayerTimesLogic().stopAudio();
      PrayerNotificationHelper.cancelAlarmNotification();
      _initAudio();
      _lockVolumeAtMax();
    } else {
      // Keep the player initialized so dispose() stays safe, but play nothing.
      _audioPlayer = AudioPlayer();
    }
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
      _volumeLocked = true;
    } catch (e) {
      debugPrint('Error locking volume: $e');
    }
  }

  Future<void> _unlockVolume() async {
    if (!_volumeLocked) return;
    _volumeLocked = false;
    try {
      await platform.invokeMethod('unlockVolume');
    } catch (e) {
      debugPrint('Error unlocking volume: $e');
    }
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    final logic = PrayerTimesLogic();
    // Honor the in-app sound toggle — native AlarmSound already does too.
    if (!logic.notificationSoundEnabled) return;
    await _audioPlayer.setReleaseMode(
        logic.alarmLoop ? ReleaseMode.loop : ReleaseMode.release);
    // Volume floor (20%) is enforced at save time: the alarm stays audible.
    await _audioPlayer.setVolume(logic.alarmVolumePercent / 100.0);
    try {
      final custom = logic.alarmCustomPath;
      if (logic.alarmSound == 'custom' &&
          custom.isNotEmpty &&
          await File(custom).exists()) {
        await _audioPlayer.play(DeviceFileSource(custom));
      } else {
        // `system` ringtone already rang natively; the screen loops the
        // bundled adhan so playback never depends on a missing URI.
        await _audioPlayer.play(AssetSource('adan.mp3'));
      }
    } catch (e) {
      debugPrint('Error playing alarm: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopShakeListening();
    _unlockVolume();
    _textController.dispose();
    _mathController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _normalizeString(String input) {
    String text = BookService.normalizeArabic(input);
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
          _onChallengeComplete();
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
    final loc = AppLocalizations.of(context)!;
    Get.snackbar(
      loc.chWrongAnswer,
      loc.chTryAgain,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Resolves the effective challenge, mapping `random` onto one of the
  /// user-enabled types (persisted pool; defaults to all four).
  engine.ChallengeType _resolveMode(PrayerTimesLogic logic) {
    return switch (logic.fajrChallengeType) {
      'math' => engine.ChallengeType.math,
      'memory' => engine.ChallengeType.memory,
      'shake' => engine.ChallengeType.shake,
      'random' => engine.pickRandomChallenge(
          logic.fajrRandomPool.map((e) => switch (e) {
                'math' => engine.ChallengeType.math,
                'memory' => engine.ChallengeType.memory,
                'shake' => engine.ChallengeType.shake,
                _ => engine.ChallengeType.questions,
              }).toList()),
      _ => engine.ChallengeType.questions,
    };
  }

  /// Shake detector: normalized acceleration magnitude with debounce and
  /// configurable sensitivity. The subscription is cancelled the moment the
  /// challenge completes (battery-efficient; no listener outside the game).
  void _listenToAccelerometer() {
    // Sum-of-abs threshold on the raw signal (gravity included): at rest this
    // reads ~10–17, a real shake spikes past 20. Higher bar = less sensitive.
    final threshold = switch (PrayerTimesLogic().fajrShakeSensitivity) {
      'low' => 25.0,
      'high' => 16.0,
      _ => 20.0,
    };
    _accelSub = accelerometerEventStream().listen((event) {
      final s = _shake;
      if (s == null || s.isCompleted || _phase != _WakePhase.challenge) {
        return;
      }
      final dynamic_ = event.x.abs() + event.y.abs() + event.z.abs();
      if (dynamic_ < threshold) return; // ignore gravity + small motion
      final now = DateTime.now();
      if (now.difference(_lastShakeAt).inMilliseconds < 300) return;
      _lastShakeAt = now;
      setState(() => s.addShake(amount: 10));
      if (s.isCompleted) {
        _stopShakeListening();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _onChallengeComplete();
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _sensorUnavailable = true);
      _stopShakeListening();
    });
  }

  void _stopShakeListening() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  void _onMemoryFlip(int index) {
    final m = _mem;
    if (m == null || m.isCompleted || _tilesLocked) return;
    if (m.matched.contains(index) || _revealed.contains(index)) return;
    final res = m.flip(index);
    setState(() {
      if (res == 0) {
        _revealed.add(index);
      } else if (res == 1) {
        _revealed.add(index);
        // Keep matched tiles visible via m.matched; drop from transient set.
        _revealed.removeWhere((i) => m.matched.contains(i));
      } else if (res == 2) {
        _revealed.add(index);
      }
    });
    if (res == 2) {
      // Incorrect pair: brief delay so the user sees both, then hide.
      _tilesLocked = true;
      final a = _revealed.toList();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          for (final i in a) {
            if (!m.matched.contains(i)) _revealed.remove(i);
          }
          _tilesLocked = false;
        });
      });
    }
    if (m.isCompleted) {
      _tilesLocked = true;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _onChallengeComplete();
      });
    }
  }

  void _checkMathAnswer() {
    final m = _math;
    if (m == null || m.isCompleted) return;
    final value = int.tryParse(_mathController.text.trim());
    if (value == null) {
      _handleWrongAnswer();
      return;
    }
    final ok = m.answer(value);
    _mathController.clear();
    if (!ok) {
      _handleWrongAnswer();
      setState(() {});
      return;
    }
    if (m.isCompleted) {
      setState(() {});
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _onChallengeComplete();
      });
    } else {
      setState(() {});
    }
  }

  /// Challenge finished → stop the alarm sound, then require an explicit
  /// "أنا مستيقظ" confirmation before anything is recorded.
  /// In preview mode nothing is recorded; the flow is visual only.
  Future<void> _onChallengeComplete() async {
    _stopShakeListening();
    if (!widget.preview) {
      await _audioPlayer.stop();
      PrayerTimesLogic().stopAudio();
      await PrayerNotificationHelper.cancelAlarmNotification();
    }
    if (!mounted) return;
    if (widget.preview) {
      setState(() => _phase = _WakePhase.done);
      return;
    }
    if (PrayerTimesLogic().wakeUpConfirmationEnabled) {
      setState(() => _phase = _WakePhase.confirm);
    } else {
      await _confirmWakeUp();
    }
  }

  /// Final confirmation step. ONLY here is the wake-up recorded + streak
  /// updated. Then the Well Done screen shows the real streak.
  /// Preview mode skips recording entirely.
  Future<void> _confirmWakeUp() async {
    if (widget.preview) {
      if (!mounted) return;
      setState(() => _phase = _WakePhase.done);
      return;
    }
    try {
      await FajrTrackingRepository.instance.recordWakeUpSuccess();
      _streakDays =
          await FajrTrackingRepository.instance.currentStreak();
    } catch (e) {
      debugPrint('Tracking record failed: $e');
    }
    if (!mounted) return;
    setState(() => _phase = _WakePhase.done);
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
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    if (!widget.preview) {
      PrayerTimesLogic().stopAudio();
      PrayerTimesLogic().resetFajrChallengeFired();
      await PrayerNotificationHelper.cancelAlarmNotification();
      await PrayerNotificationHelper.setLockScreenMode(false);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewBanner = widget.preview
        ? Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(color: Color(0xFFD64463)),
            child: Row(
              children: [
                const Icon(Icons.visibility_rounded,
                    size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.chPreviewBanner,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: _stopAlarmAndExit,
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: Colors.white),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
    Widget body = _phase == _WakePhase.confirm
            ? _buildConfirm()
            : _phase == _WakePhase.done
                ? _buildDone()
                : _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _mode == engine.ChallengeType.math
                        ? _buildMath()
                        : _mode == engine.ChallengeType.memory
                            ? _buildMemory()
                            : _mode == engine.ChallengeType.shake
                                ? _buildShake()
                                : _questions.isEmpty
                            ? Center(
                                child: Text(
                                    AppLocalizations.of(context)!.chLoadError,
                                    style: const TextStyle(
                                        color: Colors.white)))
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
                              Text(
                                AppLocalizations.of(context)!.chTitle,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.chAnswerToStop,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.chRemaining(
                                    _targetQuestionsCount -
                                        _correctAnswersCount),
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
                                          ? AppLocalizations.of(context)!
                                              .chWriteCategory
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
                                          hintText:
                                              AppLocalizations.of(context)!
                                                  .chWriteAnswerHint,
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
                                          child: Text(
                                            AppLocalizations.of(context)!
                                                .chVerifyAnswer,
                                            style: const TextStyle(
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
                  );
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade900,
        body: SafeArea(
          child: Column(
            children: [
              previewBanner,
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMath() {
    final loc = AppLocalizations.of(context)!;
    final m = _math;
    if (m == null || m.current == null) {
      return Center(
          child: Text(loc.chLoadError,
              style: const TextStyle(color: Colors.white)));
    }
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calculate, size: 64, color: Colors.white),
              const SizedBox(height: 24),
              Text(loc.chTitle,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(loc.chMathSubtitle,
                  style:
                      const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 16),
              Text(loc.chRemaining(m.targetCount - m.completedCount),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                  value: m.progress,
                  backgroundColor: Colors.white24,
                  color: Colors.amber),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text(m.current!.prompt,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _mathController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 22, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: loc.chMathHint,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onSubmitted: (_) => _checkMathAnswer(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD64463),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: _checkMathAnswer,
                        child: Text(loc.chVerifyAnswer,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _memoryFaces = ['🌙', '⭐', '🕌', '📿'];

  Widget _buildMemory() {
    final loc = AppLocalizations.of(context)!;
    final m = _mem;
    if (m == null) {
      return Center(
          child: Text(loc.chLoadError,
              style: const TextStyle(color: Colors.white)));
    }
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.grid_view_rounded,
                  size: 64, color: Colors.white),
              const SizedBox(height: 24),
              Text(loc.chMemoryTitle,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(loc.chMemorySubtitle,
                  style:
                      const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 16),
              Text(loc.chMatched(m.completedCount, m.targetCount),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                  value: m.progress,
                  backgroundColor: Colors.white24,
                  color: Colors.amber),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: m.tiles.length,
                itemBuilder: (context, i) {
                  final matched = m.matched.contains(i);
                  final shown = matched || _revealed.contains(i);
                  return Semantics(
                    button: true,
                    label: shown
                        ? loc.chCardShown(_memoryFaces[m.tiles[i]])
                        : loc.chCardHidden(i + 1),
                    child: GestureDetector(
                      onTap: () => _onMemoryFlip(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: matched
                              ? Colors.green.shade400
                              : shown
                                  ? Colors.white
                                  : Colors.blueGrey.shade700,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: matched
                                  ? Colors.green.shade100
                                  : Colors.white24,
                              width: 2),
                        ),
                        child: Center(
                          child: Text(
                            shown ? _memoryFaces[m.tiles[i]] : '؟',
                            style: TextStyle(
                                fontSize: 32,
                                color: shown
                                    ? Colors.black87
                                    : Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShake() {
    final loc = AppLocalizations.of(context)!;
    final s = _shake;
    if (_sensorUnavailable || s == null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sensors_off_rounded,
                    size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                Text(loc.chSensorUnavailable,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 18, color: Colors.white)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD64463),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    // Fallback so the user is never trapped: questions mode.
                    _stopShakeListening();
                    setState(() {
                      _mode = engine.ChallengeType.questions;
                      _isLoading = true;
                    });
                    _loadQuestionsFromJSON();
                  },
                  child: Text(loc.chSwitchToQuestions,
                      style:
                          const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.vibration_rounded,
                  size: 72, color: Colors.white),
              const SizedBox(height: 24),
              Text(loc.chShakeTitle,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(loc.chShakeSubtitle,
                  style:
                      const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 32),
              LinearProgressIndicator(
                  value: s.progress,
                  minHeight: 18,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: Colors.white24,
                  color: Colors.amber),
              const SizedBox(height: 16),
              Text('${(s.progress * 100).toInt()}٪',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirm() {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny_outlined,
                  size: 72, color: Colors.amber),
              const SizedBox(height: 24),
              Text(loc.awakeTitle,
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Text(loc.awakeSubtitle,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD64463),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: _confirmWakeUp,
                  child: Text(loc.iAmAwake,
                      style:
                          const TextStyle(fontSize: 20, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDone() {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌙',
                  style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(loc.wellDone,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(loc.wokeForFajr,
                  style:
                      const TextStyle(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('🔥 ${loc.trackDays(_streakDays)}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD64463),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: _stopAlarmAndExit,
                  child: Text(loc.continueBtn,
                      style:
                          const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
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

