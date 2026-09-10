import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/fajr_challenge/presentation/fajr_challenge_screen.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

void showFajrChallengeBottomSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  Get.bottomSheet(
    const FajrChallengeBottomSheetContent(),
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF1E1E28) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  );
}

class FajrChallengeBottomSheetContent extends StatefulWidget {
  const FajrChallengeBottomSheetContent({super.key});

  @override
  State<FajrChallengeBottomSheetContent> createState() =>
      _FajrChallengeBottomSheetContentState();
}

class _FajrChallengeBottomSheetContentState
    extends State<FajrChallengeBottomSheetContent> {
  final PrayerTimesLogic _logic = Get.isRegistered<PrayerTimesLogic>()
      ? Get.find<PrayerTimesLogic>()
      : Get.put(PrayerTimesLogic());

  int _testDelaySeconds = 10;

  /// Checks the Android 12+ exact-alarm permission. Non-blocking: the user
  /// can still enable the challenge (it starts working once granted — the
  /// logic re-syncs every 60s), but they are told the truth instead of
  /// getting a silent alarm. Returns true when scheduling will work now.
  Future<bool> _ensureExactAlarmPermission() async {
    bool can;
    try {
      can = await PrayerNotificationHelper.canScheduleExactAlarms();
    } catch (_) {
      return true;
    }
    if (can || !mounted) return can;
    final loc = AppLocalizations.of(context)!;
    final open = await Get.dialog<bool>(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          loc.sheetExactTitle,
          style:
              const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
        ),
        content: Text(
          loc.sheetExactBody,
          style: const TextStyle(fontFamily: 'Amiri', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(loc.sheetLater,
                style: const TextStyle(fontFamily: 'Amiri')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD64463),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(loc.diagOpenSettings,
                style: const TextStyle(fontFamily: 'Amiri')),
          ),
        ],
      ),
    );
    if (open == true) {
      await PrayerNotificationHelper.openExactAlarmSettings();
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logic.loadNotificationPreference().then((_) {
        if (mounted) setState(() {});
      });
    });
  }

  Future<void> _saveSettings({
    bool? fajrChallengeValue,
    int? challengeQuestionsCount,
    bool? challengeIsTextInput,
    String? challengeWakeUpMode,
    int? challengeCustomOffset,
    String? challengeType,
    String? challengeDifficulty,
    List<String>? challengePool,
    String? shakeSensitivity,
  }) async {
    await _logic.saveNotificationPreference(
      _logic.notificationsEnabled,
      _logic.prayerNotificationsEnabled,
      _logic.notificationSoundEnabled,
      persistentValue: _logic.persistentNotificationEnabled,
      persistentBgValue: _logic.persistentNotificationBlackBg,
      fajrChallengeValue: fajrChallengeValue ?? _logic.fajrChallengeEnabled,
      challengeQuestionsCount:
          challengeQuestionsCount ?? _logic.fajrChallengeQuestionsCount,
      challengeIsTextInput:
          challengeIsTextInput ?? _logic.fajrChallengeIsTextInput,
      challengeWakeUpMode:
          challengeWakeUpMode ?? _logic.fajrChallengeWakeUpMode,
      challengeCustomOffset:
          challengeCustomOffset ?? _logic.fajrChallengeCustomOffsetMinutes,
      challengeType: challengeType ?? _logic.fajrChallengeType,
      challengeDifficulty:
          challengeDifficulty ?? _logic.fajrChallengeDifficulty,
      challengePool: challengePool ?? _logic.fajrRandomPool,
      shakeSensitivity: shakeSensitivity ?? _logic.fajrShakeSensitivity,
      morningAdhkarValue: _logic.morningAdhkarEnabled,
      eveningAdhkarValue: _logic.eveningAdhkarEnabled,
      nightPrayerTimesValue: _logic.nightPrayerTimesEnabled,
      notificationModeValue: _logic.notificationMode,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD64463).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.alarm_on_rounded,
                      color: Color(0xFFD64463),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.sheetTitle,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        loc.sheetSubtitle,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Toggle switch card
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF282836)
                    : const Color(0xFFF5F5F8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: SwitchListTile(
                value: _logic.fajrChallengeEnabled,
                onChanged: (value) async {
                  setState(() => _logic.fajrChallengeEnabled = value);
                  await _saveSettings(fajrChallengeValue: value);
                  if (value) {
                    final ok = await _ensureExactAlarmPermission();
                    if (!ok && mounted) {
                      Get.snackbar(
                        loc.sheetWarnTitle,
                        loc.sheetWarnBody,
                        backgroundColor: Colors.orange.shade800,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 4),
                      );
                    }
                  }
                },
                activeThumbColor: const Color(0xFFD64463),
                activeTrackColor:
                    const Color(0xFFD64463).withValues(alpha: 0.3),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  loc.sheetEnable,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _logic.fajrChallengeEnabled
                      ? loc.sheetEnabledOn
                      : loc.sheetEnabledOff,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
            ),

            if (_logic.fajrChallengeEnabled) ...[
              const SizedBox(height: 18),

              // Wake Up Timing Section
              Text(
                loc.sheetRingTime,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceCard(
                      title: loc.sheetLastThird,
                      subtitle: loc.sheetLastThirdSub,
                      isSelected: _logic.fajrChallengeWakeUpMode == 'auto',
                      isDark: isDark,
                      onTap: () {
                        setState(() => _logic.fajrChallengeWakeUpMode = 'auto');
                        _saveSettings(challengeWakeUpMode: 'auto');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildChoiceCard(
                      title: loc.sheetCustom,
                      subtitle: loc.sheetCustomSub,
                      isSelected: _logic.fajrChallengeWakeUpMode == 'custom',
                      isDark: isDark,
                      onTap: () {
                        setState(
                            () => _logic.fajrChallengeWakeUpMode = 'custom');
                        _saveSettings(challengeWakeUpMode: 'custom');
                      },
                    ),
                  ),
                ],
              ),

              // Custom offset slider if 'custom'
              if (_logic.fajrChallengeWakeUpMode == 'custom') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.sheetBeforeFajrBy,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD64463).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loc.sheetMinutes(
                            _logic.fajrChallengeCustomOffsetMinutes),
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD64463),
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _logic.fajrChallengeCustomOffsetMinutes.toDouble(),
                  min: 10,
                  max: 120,
                  divisions: 11,
                  activeColor: const Color(0xFFD64463),
                  inactiveColor:
                      isDark ? Colors.white12 : Colors.grey.shade300,
                  label: loc.sheetMinutes(
                      _logic.fajrChallengeCustomOffsetMinutes),
                  onChanged: (val) {
                    setState(() {
                      _logic.fajrChallengeCustomOffsetMinutes = val.toInt();
                    });
                  },
                  onChangeEnd: (val) {
                    _saveSettings(challengeCustomOffset: val.toInt());
                  },
                ),
              ],

              const SizedBox(height: 14),

              // Number of Questions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.sheetQuestionCount,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD64463).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      loc.sheetQuestions(
                          _logic.fajrChallengeQuestionsCount),
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD64463),
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _logic.fajrChallengeQuestionsCount.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: const Color(0xFFD64463),
                inactiveColor: isDark ? Colors.white12 : Colors.grey.shade300,
                label: loc
                    .sheetQuestions(_logic.fajrChallengeQuestionsCount),
                onChanged: (double value) {
                  setState(() {
                    _logic.fajrChallengeQuestionsCount = value.toInt();
                  });
                },
                onChangeEnd: (double value) {
                  _saveSettings(challengeQuestionsCount: value.toInt());
                },
              ),

              // Text Input Mode Switch
              SwitchListTile(
                activeThumbColor: const Color(0xFFD64463),
                activeTrackColor:
                    const Color(0xFFD64463).withValues(alpha: 0.3),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  loc.sheetTextMode,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  loc.sheetTextModeSub,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                value: _logic.fajrChallengeIsTextInput,
                onChanged: (value) {
                  setState(() {
                    _logic.fajrChallengeIsTextInput = value;
                  });
                  _saveSettings(challengeIsTextInput: value);
                },
              ),

              const SizedBox(height: 14),

              // Challenge type: questions / math / memory / shake / random
              Text(
                loc.nsChallengeType,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final t in [
                    ('questions', loc.nsTypeQuestions, loc.nsTypeQuestionsSub),
                    ('math', loc.nsTypeMath, loc.nsTypeMathSub),
                    ('memory', loc.nsTypeMemory, loc.nsTypeMemorySub),
                    ('shake', loc.nsTypeShake, loc.nsTypeShakeSub),
                    ('random', loc.nsTypeRandom, loc.nsTypeRandomSub),
                  ])
                    SizedBox(
                      width:
                          (MediaQuery.of(context).size.width - 72) / 2,
                      child: _buildChoiceCard(
                        title: t.$2,
                        subtitle: t.$3,
                        isSelected: _logic.fajrChallengeType == t.$1,
                        isDark: isDark,
                        onTap: () {
                          setState(
                              () => _logic.fajrChallengeType = t.$1);
                          _saveSettings(challengeType: t.$1);
                        },
                      ),
                    ),
                ],
              ),
              if (_logic.fajrChallengeType == 'random') ...[
                const SizedBox(height: 12),
                Text(
                  loc.nsRandomPool,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                for (final t in [
                  ('questions', loc.nsTypeQuestions),
                  ('math', loc.nsTypeMath),
                  ('memory', loc.nsTypeMemory),
                  ('shake', loc.nsTypeShake),
                ])
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(t.$2,
                        style: const TextStyle(fontFamily: 'Amiri')),
                    value: _logic.fajrRandomPool.contains(t.$1),
                    activeColor: const Color(0xFFD64463),
                    onChanged: (v) {
                      final pool =
                          List<String>.of(_logic.fajrRandomPool);
                      if (v == true) {
                        if (!pool.contains(t.$1)) pool.add(t.$1);
                      } else {
                        pool.remove(t.$1);
                      }
                      if (pool.isEmpty) return;
                      setState(() => _logic.fajrRandomPool = pool);
                      _saveSettings(challengePool: pool);
                    },
                  ),
              ],
              const SizedBox(height: 14),
              Text(
                loc.nsDifficulty,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final d in [
                    ('easy', loc.nsEasy),
                    ('medium', loc.nsDiffMedium),
                    ('hard', loc.nsHard),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildChoiceCard(
                          title: d.$2,
                          subtitle: '',
                          isSelected:
                              _logic.fajrChallengeDifficulty == d.$1,
                          isDark: isDark,
                          onTap: () {
                            setState(() => _logic.fajrChallengeDifficulty =
                                d.$1);
                            _saveSettings(challengeDifficulty: d.$1);
                          },
                        ),
                      ),
                    ),
                ],
              ),
              if (_logic.fajrChallengeType == 'shake' ||
                  _logic.fajrChallengeType == 'random') ...[
                const SizedBox(height: 12),
                Text(
                  loc.nsShakeSensitivity,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final s in [
                      ('low', loc.nsLow),
                      ('medium', loc.nsShakeMedium),
                      ('high', loc.nsHigh),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _buildChoiceCard(
                            title: s.$2,
                            subtitle: '',
                            isSelected:
                                _logic.fajrShakeSensitivity == s.$1,
                            isDark: isDark,
                            onTap: () {
                              setState(() => _logic.fajrShakeSensitivity =
                                  s.$1);
                              _saveSettings(shakeSensitivity: s.$1);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 18),

            // Test Challenge - real native alarm
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.sheetTestAt,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [5, 10, 20, 30]
                      .map((seconds) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                              label: Text(
                                loc.sheetSeconds(seconds),
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: _testDelaySeconds == seconds,
                              onSelected: (_) => setState(
                                  () => _testDelaySeconds = seconds),
                              selectedColor:
                                  const Color(0xFFD64463).withValues(alpha: 0.2),
                              backgroundColor: isDark
                                  ? const Color(0xFF282836)
                                  : Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final logic = Get.find<PrayerTimesLogic>();
                  // Fail fast with guidance instead of a phantom success.
                  final canSchedule = await PrayerNotificationHelper
                      .canScheduleExactAlarms()
                      .catchError((_) => false);
                  if (!canSchedule) {
                    await _ensureExactAlarmPermission();
                    return;
                  }
                  await logic.saveNotificationPreference(
                    logic.notificationsEnabled,
                    logic.prayerNotificationsEnabled,
                    logic.notificationSoundEnabled,
                    persistentValue: logic.persistentNotificationEnabled,
                    persistentBgValue: logic.persistentNotificationBlackBg,
                    fajrChallengeValue: true,
                    challengeQuestionsCount:
                        logic.fajrChallengeQuestionsCount,
                    challengeIsTextInput: logic.fajrChallengeIsTextInput,
                    challengeWakeUpMode: logic.fajrChallengeWakeUpMode,
                    challengeCustomOffset:
                        logic.fajrChallengeCustomOffsetMinutes,
                    morningAdhkarValue: logic.morningAdhkarEnabled,
                    eveningAdhkarValue: logic.eveningAdhkarEnabled,
                    nightPrayerTimesValue: logic.nightPrayerTimesEnabled,
                    notificationModeValue: logic.notificationMode,
                  );
                  final scheduled = await PrayerNotificationHelper
                      .testFajrChallengeAlarm(delaySeconds: _testDelaySeconds);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  if (scheduled) {
                    Get.snackbar(
                      loc.sheetTestScheduled,
                      loc.sheetTestWillRing(_testDelaySeconds),
                      backgroundColor: const Color(0xFFD64463),
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 4),
                    );
                  } else {
                    Get.snackbar(
                      loc.sheetTestFailedTitle,
                      loc.sheetTestFailedBody,
                      backgroundColor: Colors.redAccent,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text(
                  loc.sheetTestButton,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD64463),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Get.to(
                      () => const FajrChallengeScreen(preview: true));
                },
                icon: const Icon(Icons.visibility_rounded, size: 20),
                label: Text(
                  loc.nsPreviewTry,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD64463),
                  side: const BorderSide(
                      color: Color(0xFFD64463), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD64463).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF282836) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFD64463) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSelected
                    ? const Color(0xFFD64463)
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
