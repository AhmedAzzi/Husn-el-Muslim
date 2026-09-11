// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Husn el-Muslim';

  @override
  String get navAdhkar => 'Adhkar';

  @override
  String get navDua => 'Dua';

  @override
  String get navNames => 'Names of Allah';

  @override
  String get navRuqyah => 'Ruqyah';

  @override
  String get navMasbaha => 'Masbaha';

  @override
  String get navPrayerTimes => 'Prayer Times';

  @override
  String get navMosqueMap => 'Mosque Map';

  @override
  String get navQibla => 'Qibla';

  @override
  String get navFajrLog => 'Prayer Tracker';

  @override
  String get navTracking => 'Tracking';

  @override
  String get navMushaf => 'Mushaf';

  @override
  String get navKhatma => 'Khatma';

  @override
  String get stQuran => 'Quran & Khatma';

  @override
  String get stQuranSub => 'Recitation, tajweed and daily goal settings';

  @override
  String get navSettings => 'Settings';

  @override
  String get trackCurrent => 'Current streak';

  @override
  String get trackLongest => 'Longest streak';

  @override
  String get trackToday => 'Today';

  @override
  String trackDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String get qiblaNorth => 'N';

  @override
  String qiblaBearing(String deg) {
    return 'Qibla direction: $deg°';
  }

  @override
  String qiblaDistance(String km) {
    return 'Distance to Kaaba: $km km';
  }

  @override
  String get qiblaFacing => 'You are facing the Qibla ✓';

  @override
  String qiblaTurn(String deg, String direction) {
    return 'Turn $deg° $direction';
  }

  @override
  String get qiblaRight => 'right';

  @override
  String get qiblaLeft => 'left';

  @override
  String get qiblaCalibrate =>
      'Move the phone in a figure-8 to calibrate the compass if there is magnetic interference. Works offline.';

  @override
  String get qiblaRetry => 'Retry';

  @override
  String get qiblaNoLocation =>
      'Could not determine location — enable GPS or set the prayer location first';

  @override
  String get qiblaNoSensor =>
      'Compass is unavailable on this device — the Qibla direction below is computed without a live compass';

  @override
  String get awakeTitle => 'Are you awake?';

  @override
  String get awakeSubtitle =>
      'Challenge complete — confirm you are awake to log Fajr';

  @override
  String get iAmAwake => 'I am awake';

  @override
  String get wellDone => 'Well done';

  @override
  String get wokeForFajr => 'You woke up for Fajr prayer';

  @override
  String get continueBtn => 'Continue';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Application interface language';

  @override
  String get langArabic => 'العربية';

  @override
  String get langEnglish => 'English';

  @override
  String get langFrench => 'Français';

  @override
  String get diagTitle => 'Advanced Diagnostics';

  @override
  String get diagPermissions => 'Permission status';

  @override
  String get diagExactTitle => 'Exact alarms';

  @override
  String get diagExactOk => 'Allowed — the Fajr alarm rings on time';

  @override
  String get diagExactDenied => 'Not allowed — alarms may not ring on time';

  @override
  String get diagOpenSettings => 'Open settings';

  @override
  String get diagBatteryTitle => 'Battery optimization';

  @override
  String get diagBatteryOn => 'On — the system may stop alarms';

  @override
  String get diagBatteryOff => 'Exempted — the app runs freely';

  @override
  String get diagRequestExemption => 'Request exemption';

  @override
  String get diagOverlayTitle => 'Appear on top';

  @override
  String get diagOverlayOk => 'Granted — floating windows work';

  @override
  String get diagOverlayDenied => 'Not granted — floating alerts disabled';

  @override
  String get diagRequestPermission => 'Request permission';

  @override
  String get diagScheduled => 'Scheduled alarms';

  @override
  String get diagReadFailed => 'Could not read diagnostics';

  @override
  String get diagRescheduleAll => 'Reschedule all alarms';

  @override
  String get diagRescheduled => 'All alarms rescheduled';

  @override
  String get diagRescheduleFailed => 'Rescheduling failed';

  @override
  String get diagTracking => 'Tracking';

  @override
  String get diagCurrent => 'Current';

  @override
  String get diagLongest => 'Longest';

  @override
  String get diagTest => 'Test';

  @override
  String get diagTestDesc =>
      'Schedules the real Fajr challenge alarm in 5 seconds (sound + notification + challenge screen).';

  @override
  String get diagTestScheduling => 'Scheduling…';

  @override
  String get diagTestButton => 'Test Fajr alarm (5 seconds)';

  @override
  String get diagTestWillRing => 'The test alarm will ring in 5 seconds';

  @override
  String get diagTestFailed =>
      'Could not schedule the test — check the exact-alarm permission';

  @override
  String get chTitle => 'Fajr prayer challenge';

  @override
  String get chAnswerToStop => 'Answer the question to stop the alarm';

  @override
  String chRemaining(int count) {
    return 'Remaining: $count';
  }

  @override
  String get chWriteCategory => 'Type the category this dhikr belongs to:';

  @override
  String get chWriteAnswerHint => 'Type the answer here';

  @override
  String get chVerifyAnswer => 'Check answer';

  @override
  String get chWrongAnswer => 'Wrong answer';

  @override
  String get chTryAgain => 'Try again';

  @override
  String get chLoadError => 'Failed to load questions';

  @override
  String get chMathSubtitle => 'Solve the problem to stop the alarm';

  @override
  String get chMathHint => 'Type the answer in digits';

  @override
  String get chMemoryTitle => 'Memory challenge';

  @override
  String get chMemorySubtitle => 'Flip the cards and match the four pairs';

  @override
  String chMatched(int done, int total) {
    return 'Matched: $done / $total';
  }

  @override
  String get chShakeTitle => 'Shake the phone to wake up';

  @override
  String get chShakeSubtitle => 'Shake the phone firmly until the bar fills';

  @override
  String get chSensorUnavailable => 'Motion sensor unavailable on this device';

  @override
  String get chSwitchToQuestions => 'Switch to the questions challenge';

  @override
  String chCardHidden(int n) {
    return 'Face-down card $n';
  }

  @override
  String chCardShown(String face) {
    return 'Card $face';
  }

  @override
  String get chPreviewBanner => 'Preview — nothing will be recorded';

  @override
  String get sheetExactTitle => 'Exact-alarm permission required';

  @override
  String get sheetExactBody =>
      'Without the system\'s Alarms & reminders permission, the Fajr challenge alarm will not ring on time. Open settings to grant it now?';

  @override
  String get sheetLater => 'Later';

  @override
  String get sheetTitle => 'Fajr wake-up challenge';

  @override
  String get sheetSubtitle =>
      'A smart interactive alarm that only stops after solving questions';

  @override
  String get sheetEnable => 'Enable the interactive alarm';

  @override
  String get sheetEnabledOn => 'Alarm is on and will ring on time';

  @override
  String get sheetEnabledOff => 'Alarm is currently off';

  @override
  String get sheetWarnTitle => 'Note';

  @override
  String get sheetWarnBody =>
      'Enabled, but the alarm will not ring until the exact-alarm permission is granted';

  @override
  String get sheetRingTime => 'Alarm time';

  @override
  String get sheetLastThird => 'Last third of the night';

  @override
  String get sheetLastThirdSub => 'Automatic, for night prayer';

  @override
  String get sheetCustom => 'Custom time';

  @override
  String get sheetCustomSub => 'Set minutes before Fajr';

  @override
  String get sheetBeforeFajrBy => 'Ring before Fajr prayer by:';

  @override
  String sheetMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return '$_temp0';
  }

  @override
  String get sheetQuestionCount => 'Number of challenge questions';

  @override
  String sheetQuestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '$count question',
    );
    return '$_temp0';
  }

  @override
  String get sheetTextMode => 'Type the answer as text';

  @override
  String get sheetTextModeSub => 'Harder: type instead of multiple choice';

  @override
  String get sheetTestAt => 'Test ring in:';

  @override
  String sheetSeconds(int count) {
    return '${count}s';
  }

  @override
  String get sheetTestScheduled => 'Test alarm scheduled';

  @override
  String sheetTestWillRing(int seconds) {
    return 'The real Fajr challenge alarm will ring in $seconds seconds';
  }

  @override
  String get sheetTestFailedTitle => 'Could not schedule test';

  @override
  String get sheetTestFailedBody =>
      'Make sure the exact-alarm permission is granted in system settings';

  @override
  String get sheetTestButton => 'Test the real ring (actual alarm)';

  @override
  String get nsTitle => 'Notification & Adhan Settings';

  @override
  String get nsBatteryTitle => 'Battery optimization is on';

  @override
  String get nsBatteryBody =>
      'The system may stop adhan notifications and the countdown to save power. Exempt the app from battery optimization for reliable alerts.';

  @override
  String get nsBatteryButton => 'Exempt app from battery optimization';

  @override
  String get nsPersistentSection => 'Persistent system notifications';

  @override
  String get nsPersistent => 'Persistent status-bar notification';

  @override
  String get nsPersistentSub => 'Always show the Hijri date and next prayer';

  @override
  String get nsFajrEnable => 'Enable the Fajr challenge alarm';

  @override
  String get nsFajrEnableSub =>
      'Smart interactive alarm that only stops after solving questions';

  @override
  String get nsChallengeType => 'Challenge type';

  @override
  String get nsTypeQuestions => 'Questions';

  @override
  String get nsTypeQuestionsSub => 'Adhkar & dua';

  @override
  String get nsTypeMath => 'Math';

  @override
  String get nsTypeMathSub => 'Mental arithmetic';

  @override
  String get nsTypeMemory => 'Memory';

  @override
  String get nsTypeMemorySub => 'Card matching';

  @override
  String get nsTypeShake => 'Shake';

  @override
  String get nsTypeShakeSub => 'Shake the phone';

  @override
  String get nsTypeRandom => 'Random';

  @override
  String get nsTypeRandomSub => 'Surprise type';

  @override
  String get nsRandomPool => 'Types included in random';

  @override
  String get nsShakeSensitivity => 'Shake sensitivity';

  @override
  String get nsLow => 'Low';

  @override
  String get nsShakeMedium => 'Medium';

  @override
  String get nsHigh => 'High';

  @override
  String get nsDifficulty => 'Difficulty level';

  @override
  String get nsEasy => 'Easy';

  @override
  String get nsDiffMedium => 'Medium';

  @override
  String get nsHard => 'Hard';

  @override
  String get nsHardSub => 'Mandatory typing';

  @override
  String get nsWakeConfirm => 'Wake-up confirmation';

  @override
  String get nsWakeConfirmSub =>
      'After the challenge: Are you awake? then log success';

  @override
  String get nsTryNow => 'Try the challenge now';

  @override
  String get nsOpenLog => 'Fajr log & progress';

  @override
  String get nsAlarmSound => 'Alarm sound';

  @override
  String get nsSoundAdhan => 'Adhan';

  @override
  String get nsSoundAdhanSub => 'Bundled with the app';

  @override
  String get nsSoundSystem => 'System ringtone';

  @override
  String get nsSoundSystemSub => 'Phone alarm ringtone';

  @override
  String get nsSoundCustom => 'Custom file';

  @override
  String get nsSoundCustomSub => 'Audio file from your device';

  @override
  String get nsPickAudio => 'Pick an audio file';

  @override
  String get nsChangeAudio => 'Selected — change file';

  @override
  String get nsPreviewSound => 'Preview sound';

  @override
  String get nsPreviewPlaying => 'Playing sound preview…';

  @override
  String get nsStop => 'Stop';

  @override
  String get nsAlarmVolume => 'Alarm volume';

  @override
  String get nsAlarmVibrate => 'Vibrate while ringing';

  @override
  String get nsAlarmLoop => 'Repeat until dismissed';

  @override
  String get nsGentleWake => 'Gentle wake-up (volume ramp)';

  @override
  String get nsInstant => 'Instant';

  @override
  String get nsExtraAlarms => 'Extra alarms';

  @override
  String get nsSuhoor => 'Suhoor alarm';

  @override
  String get nsSuhoorSub =>
      'Suhoor time before Fajr (separate from the Fajr adhan)';

  @override
  String get nsBeforeFajrBy => 'Before Fajr by:';

  @override
  String get nsPreFajr => 'Pre-Fajr alert';

  @override
  String get nsPreFajrSub =>
      'Gentle warning before the adhan (5 / 10 / 15 minutes)';

  @override
  String get nsTahajjud => 'Tahajjud alarm';

  @override
  String get nsTahajjudSub =>
      'Night-prayer wake-up at the Last Third or a fixed time';

  @override
  String get nsTahajjudLastThird => 'Last Third (auto)';

  @override
  String get nsTahajjudFixed => 'Fixed time';

  @override
  String get nsFajrExtra => 'Heavy-sleeper re-ring';

  @override
  String get nsFajrExtraSub =>
      'Re-fire the Fajr challenge after Fajr (+minutes)';

  @override
  String get nsPreviewTry => 'Try the challenge now';

  @override
  String get nsBedtime => 'Bedtime reminder';

  @override
  String get nsBedtimeSub => 'Helps you sleep early to catch Fajr';

  @override
  String get nsBedtimeRelative => 'Relative to Fajr';

  @override
  String nsBedtimeRelativeSub(int h) {
    String _temp0 = intl.Intl.pluralLogic(
      h,
      locale: localeName,
      other: '$h hours',
      one: '$h hour',
    );
    return 'Fajr − $_temp0';
  }

  @override
  String get nsSkipTonight => 'Skip tonight only';

  @override
  String get nsSkippedTonight => 'Tonight\'s reminder skipped only';

  @override
  String get nsPrePrayer => 'Pre-prayer reminder';

  @override
  String get nsPrePrayerSub => 'Quiet alert before each selected prayer';

  @override
  String get nsBeforePrayerBy => 'Before prayer by:';

  @override
  String get nsPostPrayer => 'Post-prayer reminder';

  @override
  String get nsPostPrayerSub => 'Adhkar reminder after each selected prayer';

  @override
  String get nsAfterPrayerBy => 'After prayer by:';

  @override
  String get nsAdhkarSection => 'Morning & evening adhkar alerts';

  @override
  String get nsMorning => 'Morning adhkar alert';

  @override
  String get nsMorningSub => 'Blessed reminder one hour after Fajr';

  @override
  String get nsEvening => 'Evening adhkar alert';

  @override
  String get nsEveningSub => 'Blessed reminder one hour after Asr';

  @override
  String get nsPrayerFajr => 'Fajr';

  @override
  String get nsPrayerDhuhr => 'Dhuhr';

  @override
  String get nsPrayerAsr => 'Asr';

  @override
  String get nsPrayerMaghrib => 'Maghrib';

  @override
  String get nsPrayerIsha => 'Isha';

  @override
  String get nsPrayerSunrise => 'Sunrise';

  @override
  String get stAppearance => 'Appearance & general';

  @override
  String get stSettingsTitle => 'Settings & preferences';

  @override
  String get ptFajrChallengeTip => 'Fajr wake-up challenge';

  @override
  String get ptLocationUpdated => 'Location updated';

  @override
  String get ptLoading => 'Loading prayer times…';

  @override
  String get ptLoadFailed => 'Could not load prayer times';

  @override
  String get ptLoadFailedSub =>
      'Make sure location services and internet are on';

  @override
  String get ptLoadingShort => 'Loading…';

  @override
  String ptCorresponding(String date) {
    return ' corresponding to $date';
  }

  @override
  String get ptFajrChallenge => 'Fajr challenge';

  @override
  String get ptListFailed => 'Sorry, times failed to load';

  @override
  String get ptSourceTitle => 'Times source';

  @override
  String get ptSourceSub => 'Choose calculated times or find a nearby mosque';

  @override
  String get ptCalcSub => 'Madhab-based calculation from your location';

  @override
  String get ptNearbyMosques => 'Mosques near you';

  @override
  String ptAllMosques(String country, int count) {
    return 'All mosques — $country ($count)';
  }

  @override
  String get ptNoResults => 'No results right now';

  @override
  String ptMosqueAdopted(String name) {
    return '($name) set as your main mosque';
  }

  @override
  String get ptMosqueFailed => 'Could not load this mosque\'s times, try again';

  @override
  String ptMeters(String m) {
    return '$m m';
  }

  @override
  String ptKm(String km) {
    return '$km km';
  }

  @override
  String get ptIqamaAfter => 'Iqama in';

  @override
  String ptPrayerAfter(String name) {
    return '$name in';
  }

  @override
  String get ptAyatOff => 'Disable verse popup';

  @override
  String get ptAyatOn => 'Enable verse popup';

  @override
  String get ctCopied => 'Text copied to clipboard';

  @override
  String get ctCopy => 'Copy';

  @override
  String get ctCopyAll => 'Copy full text';

  @override
  String get ctShare => 'Share';

  @override
  String get ctShareAll => 'Share full text';

  @override
  String get ctClose => 'Close';

  @override
  String get ctCancel => 'Cancel';

  @override
  String get ctNoSearchResults => 'No matching results';

  @override
  String get ctSearch => 'Search';

  @override
  String get ctRefresh => 'Refresh';

  @override
  String get obPermNotif => 'Notifications';

  @override
  String get obPermNotifSub => 'To alert you of prayer times & adhkar';

  @override
  String get obPermLocation => 'Location';

  @override
  String get obPermLocationSub => 'For accurate prayer times';

  @override
  String get obPermOverlay => 'Appear on top';

  @override
  String get obPermOverlaySub => 'To show adhkar & verses automatically';

  @override
  String get obWelcome => 'Welcome to Husn el-Muslim';

  @override
  String get obSubtitle => 'We need some permissions for all features to work';

  @override
  String get obSkip => 'Skip';

  @override
  String get azEmpty => 'No results';

  @override
  String get duCopied => 'Dua copied to clipboard';

  @override
  String get duLoadFailed => 'Could not load dua data';

  @override
  String get duQuranSection => 'Quranic duas';

  @override
  String get duSunnahSection => 'Sunnah duas';

  @override
  String get duAdabSection => 'Virtues & etiquette of dua';

  @override
  String get duQuranBadge => 'Quranic';

  @override
  String get duSunnahBadge => 'Sunnah';

  @override
  String duShareSubject(int n) {
    return 'Dua no. $n';
  }

  @override
  String get rqLoadFailed => 'Could not load ruqyah data';

  @override
  String rqItems(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# passages',
    );
    return '$_temp0';
  }

  @override
  String get asCopiedDefault => 'Copied ✿';

  @override
  String get asTapHint => 'Tap to view, long-press to copy';

  @override
  String get azSpeedTitle => 'Auto-counter speed';

  @override
  String get azSeconds => 'Time in seconds';

  @override
  String get azAuto => 'Auto';

  @override
  String get azReset => 'Reset';

  @override
  String azTimes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m times',
      one: 'once',
    );
    return '$_temp0';
  }

  @override
  String azTimesHundred(int m) {
    return '$m times';
  }

  @override
  String azOfTotal(int i, int n) {
    return 'Dhikr $i of $n';
  }

  @override
  String get azCopiedDhikr => 'Dhikr copied to clipboard';

  @override
  String get azSave => 'Save';

  @override
  String get azCopied => 'Copied to clipboard';

  @override
  String azSharePrefix(Object cat) {
    return 'From dhikr: $cat';
  }

  @override
  String get msSaveFolder => 'Choose save folder';

  @override
  String msBackupSaved(String f) {
    return 'Backup saved: $f';
  }

  @override
  String msExportFailed(String e) {
    return 'Export failed: $e';
  }

  @override
  String get msImported => 'Data imported successfully';

  @override
  String msImportFailed(String e) {
    return 'Import failed: $e';
  }

  @override
  String get msAdded => 'Dhikr added!';

  @override
  String get msEdited => 'Dhikr updated!';

  @override
  String get msDeleted => 'Dhikr deleted!';

  @override
  String get msPickCount => 'Choose tasbih count';

  @override
  String get msCountHint => 'Tasbih count (open by default)';

  @override
  String get msStart => 'Start';

  @override
  String get msEdit => 'Edit';

  @override
  String get msDelete => 'Delete';

  @override
  String get msAddNew => 'Add new dhikr';

  @override
  String get msRestoreTitle => 'Restore default adhkar?';

  @override
  String get msRestoreBody =>
      'All your current adhkar will be deleted and replaced with the default list.';

  @override
  String get msRestore => 'Restore';

  @override
  String get msHideScores => 'Hide scores';

  @override
  String get msShowScores => 'Show scores';

  @override
  String get msResetDefault => 'Restore defaults';

  @override
  String get msExport => 'Export data';

  @override
  String get msImport => 'Import data';

  @override
  String get msAddTitle => 'Add dhikr';

  @override
  String get msEditTitle => 'Edit dhikr';

  @override
  String get msFieldDhikr => 'Dhikr *';

  @override
  String get msFieldBenefit => 'Virtue';

  @override
  String get msFieldSource => 'Source';

  @override
  String get msFieldSpeed => 'Auto-counter speed (seconds)';

  @override
  String get msCounterTitle => 'Dhikr counter';

  @override
  String msVirtue(String t) {
    return 'Virtue: $t';
  }

  @override
  String msSource(String t) {
    return 'Source: $t';
  }

  @override
  String get msOpen => 'Open';

  @override
  String get msSave => 'Save';

  @override
  String get stDarkMode => 'Dark mode';

  @override
  String get stDarkOn => 'Night theme on, easy on the eyes';

  @override
  String get stDarkOff => 'Light theme on';

  @override
  String get stDefaultHome => 'Default home screen';

  @override
  String get stDefaultHomeSub => 'Screen shown on launch';

  @override
  String get stHomeAzkarSub => 'Daily adhkar & Husn el-Muslim';

  @override
  String get stHomeMisbahaSub => 'Tasbih counter & custom adhkar';

  @override
  String get stHomePrayerSub => 'Adhan times, alerts & Qibla';

  @override
  String get stHomeSet => 'Home screen set (applies on restart)';

  @override
  String get stLanguageTitle => 'Language';

  @override
  String get stLanguagePicker => 'Language';

  @override
  String get stLanguagePickerSub => 'Choose the interface language';

  @override
  String get stLangArSub => 'Default interface language';

  @override
  String get stLangEnSub => 'Application language';

  @override
  String get stLangFrSub => 'Interface language';

  @override
  String get stInteraction => 'Masbaha & interaction';

  @override
  String get stClickSound => 'Click sound';

  @override
  String get stClickSoundSub => 'Soft click when pressing the masbaha';

  @override
  String get stHaptic => 'Haptic feedback';

  @override
  String get stHapticSub => 'Phone vibrates on each tasbih';

  @override
  String get stReminder => 'Automatic adhkar reminders';

  @override
  String get stFloatingDhikr => 'Periodic floating adhkar';

  @override
  String get stFloatingDhikrSub =>
      'A short dhikr popup appears automatically over apps';

  @override
  String get stReminderRate => 'Reminder frequency';

  @override
  String get stReminderRateSub => 'Interval between adhkar';

  @override
  String get stEveryHour => 'Every hour';

  @override
  String stEveryMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m minutes',
      one: '$m minute',
    );
    return 'Every $_temp0';
  }

  @override
  String get stIntervalTitle => 'Automatic reminder frequency';

  @override
  String get stIntervalSub => 'Time between floating adhkar';

  @override
  String get stOverlayTitle => 'Appear-on-top permission';

  @override
  String get stOverlayBody =>
      'To show short adhkar while you use other apps, the app needs the appear-on-top permission. Enable it now?';

  @override
  String get stActivateNow => 'Enable now';

  @override
  String get stHomePicker => 'Default home screen';

  @override
  String get stHomePickerSub => 'Choose the screen the app opens with';

  @override
  String get stPrayerData => 'Prayer times & data source';

  @override
  String get stSourcePicker => 'Prayer times source';

  @override
  String get stSourcePickerSub =>
      'Choose approved mosque times or precise offline calculation';

  @override
  String get stSourceMosque => 'Mosque times (online with cache)';

  @override
  String get stSourceMosqueSub =>
      'Fetches your mosque\'s approved times via Mawaqit and caches them for offline use';

  @override
  String get stSourceCalc => 'Calculated times (fully offline)';

  @override
  String get stSourceCalcMode => 'Calculated astronomically (offline)';

  @override
  String get stSourceCalcSub =>
      'Astronomical calculation from your coordinates and madhab, no internet needed';

  @override
  String get stSourceMosqueSet => 'Source set: mosque times';

  @override
  String get stSourceCalcSet => 'Source set: calculated times';

  @override
  String get stCalcPicker => 'Prayer calculation method';

  @override
  String get stCalcPickerSub => 'Choose the authority used in your region';

  @override
  String get stCalcSaved => 'Calculation method saved and times reset';

  @override
  String get stAsrPicker => 'Asr madhab';

  @override
  String get stAsrPickerSub => 'When Asr time begins, by madhab';

  @override
  String get stAsrShafi => 'Majority (Shafi, Maliki, Hanbali)';

  @override
  String get stAsrShafiSub => 'When an object\'s shadow equals its length';

  @override
  String get stAsrHanafi => 'Hanafi madhab';

  @override
  String get stAsrHanafiSub =>
      'When an object\'s shadow equals twice its length';

  @override
  String get stAsrSaved => 'Asr madhab saved';

  @override
  String get stMethodMakkah => 'Umm al-Qura (Makkah)';

  @override
  String get stMethodMakkahSub => 'Saudi Arabia & the Gulf';

  @override
  String get stMethodEgypt => 'Egyptian General Authority of Survey';

  @override
  String get stMethodEgyptSub => 'Egypt, Sudan & parts of Africa';

  @override
  String get stMethodMwl => 'Muslim World League';

  @override
  String get stMethodMwlSub => 'Europe, Far East & America';

  @override
  String get stMethodKarachi => 'Univ. of Islamic Sciences, Karachi';

  @override
  String get stMethodKarachiSub => 'Pakistan, India, Bangladesh & Afghanistan';

  @override
  String get stMethodIsna => 'Islamic Society of North America (ISNA)';

  @override
  String get stMethodIsnaSub => 'USA & Canada';

  @override
  String get stMethodKuwait => 'State of Kuwait';

  @override
  String get stMethodKuwaitSub => 'Kuwait (Fajr 18, Isha 17.5)';

  @override
  String get stMethodQatar => 'State of Qatar';

  @override
  String get stMethodQatarSub => 'Qatar (Fajr 18, Isha 90 min after Maghrib)';

  @override
  String get stMethodSingapore => 'Singapore';

  @override
  String get stMethodSingaporeSub => 'Singapore & Malaysia (Fajr 20, Isha 18)';

  @override
  String get stMethodTurkey => 'Turkish Diyanet';

  @override
  String get stMethodTurkeySub => 'Turkey (Diyanet)';

  @override
  String get stMethodDubai => 'UAE & Gulf (Dubai)';

  @override
  String get stMethodDubaiSub => 'UAE & Gulf region (18.2)';

  @override
  String get stMethodMoon => 'Moonsighting Committee';

  @override
  String get stMethodMoonSub => 'North America & polar regions';

  @override
  String get stCalcMethod => 'Calculation method';

  @override
  String get stCalcMethodSub => 'Authority for Fajr & Isha angles';

  @override
  String get stAsrMethod => 'Asr madhab';

  @override
  String get stAsrMethodSub => 'Shadow standard for Asr start';

  @override
  String get stDst => 'Daylight saving time';

  @override
  String get stDstSub => 'Automatically add one hour to prayer times';

  @override
  String get stManualTitle => 'Adjust prayer times manually';

  @override
  String get stManualTileSub =>
      'Add or subtract minutes to match your local adhan';

  @override
  String get stReset => 'Reset';

  @override
  String get stManualSub =>
      'Add or subtract minutes per prayer to match your mosque\'s adhan';

  @override
  String get stZeroMin => '0 minutes';

  @override
  String stMinDelta(String signed) {
    return '$signed min';
  }

  @override
  String get stManualSaved => 'Time adjustments saved';

  @override
  String get stSaveEdits => 'Save changes';

  @override
  String get stSave => 'Save';

  @override
  String get stIqamaTitle => 'Iqama (minutes after adhan)';

  @override
  String get stIqamaSub =>
      'Set iqama minutes after adhan per prayer for an exact countdown';

  @override
  String get stIqamaTile => 'Iqama';

  @override
  String get stIqamaTileSub => 'Set iqama minutes after adhan per prayer';

  @override
  String get stNoAdjust => 'No adjustment';

  @override
  String get stNoIqama => 'No iqama';

  @override
  String stIqamaMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '# minutes',
      one: '# minute',
    );
    return '+$_temp0';
  }

  @override
  String get stIqamaSaved => 'Iqama settings saved';

  @override
  String get stHijriTitle => 'Adjust Hijri date';

  @override
  String get stHijriSub =>
      'Shift the Hijri date by days to match moon sighting';

  @override
  String get stHijriExact => 'Date matches astronomical calculation';

  @override
  String stHijriAdjusted(String text) {
    return 'Adjusted by ($text)';
  }

  @override
  String stHijriDays(int d) {
    String _temp0 = intl.Intl.pluralLogic(
      d,
      locale: localeName,
      other: '# days',
      one: '# day',
    );
    return '$_temp0';
  }

  @override
  String get stAdjust => 'Adjust';

  @override
  String get stHijriSaved => 'Hijri adjustment saved';

  @override
  String get stGpsRefreshed => 'Location and prayer times updated';

  @override
  String get stGpsFailed => 'Could not update location, check GPS';

  @override
  String get stGpsTile => 'Location (GPS)';

  @override
  String get stRefresh => 'Refresh';

  @override
  String stCoords(String lat, String lon) {
    return 'Coordinates: $lat, $lon';
  }

  @override
  String get stNoMosque => 'No mosque selected yet';

  @override
  String get stOpenMapChoose => 'Tap to open the map and choose your mosque';

  @override
  String stCityChange(String city) {
    return 'City: $city • tap to change';
  }

  @override
  String get stChangeMosque => 'Change mosque';

  @override
  String get stChooseMosque => 'Choose mosque';

  @override
  String get stMosqueBadge => 'Mosque times';

  @override
  String get stCalcBadge => 'Calculated';

  @override
  String get stNotifHub => 'Notifications & adhan';

  @override
  String get stHubTitle => 'Customize notifications & adhan';

  @override
  String get stHubSub =>
      'Persistent notification, Fajr challenge, morning & evening adhkar';

  @override
  String get stAdvanced => 'Advanced';

  @override
  String get stSearchHint => 'Search settings';

  @override
  String get stAdvancedMode => 'Advanced settings';

  @override
  String get stAdvancedModeSub =>
      'Show technical options (offsets, iqama, fine-tuning)';

  @override
  String get stHiddenAdvanced => 'Some technical settings are hidden';

  @override
  String get stDiagTile => 'Advanced diagnostics';

  @override
  String get stDiagTileSub => 'Permission states, scheduled alarms & testing';

  @override
  String get stAbout => 'About & sharing';

  @override
  String get stAboutApp => 'About Husn el-Muslim & version';

  @override
  String stAboutAppSub(String v) {
    return 'Version $v • Open source';
  }

  @override
  String get stOfficialSite => 'Sheikh Saeed bin Wahf\'s website';

  @override
  String get stOfficialSiteSub => 'Author of Husn el-Muslim';

  @override
  String get stGithub => 'Project on GitHub';

  @override
  String get stGithubSub => 'Contribute & source code';

  @override
  String get stGithubSheetSub => 'The app\'s code repository on GitHub';

  @override
  String stAboutSheetLine(String v) {
    return 'Version $v • Open-source Islamic app';
  }

  @override
  String get mmSearchHint => 'Search by mosque or city name...';

  @override
  String get mmTitle => 'Mosques Map';

  @override
  String get mmCloseSearch => 'Close search';

  @override
  String get mmSearch => 'Search';

  @override
  String get mmShowMap => 'Show map';

  @override
  String get mmShowList => 'Show list';

  @override
  String get mmChangeCountry => 'Change country';

  @override
  String mmMosqueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mosques',
      one: '$count mosque',
    );
    return '$_temp0';
  }

  @override
  String get mmOfflineBanner => 'Offline — showing cached mosques';

  @override
  String get mmLocateMe => 'My location';

  @override
  String get mmCountryPickerTitle => 'Select country to view mosques';

  @override
  String get mmAdoptMosque => 'Adopt as main mosque';

  @override
  String get mmSuggestTitle => 'A mosque near you';

  @override
  String get mmSuggestBody =>
      'Selecting this mosque will set it as your default mosque for prayer times.';

  @override
  String get mmSuggestSet => 'Set as Default';

  @override
  String get mmRetry => 'Retry';

  @override
  String get mmEmptyNoMosques => 'No mosques awaiting load';

  @override
  String get mmEmptyNoResults => 'No matching results';

  @override
  String get mmRefreshTimes => 'Refresh prayer times';

  @override
  String get mmActiveMosqueBadge =>
      'This is the mosque currently adopted in the app';

  @override
  String mmDistanceKm(Object d) {
    return '$d km away';
  }

  @override
  String mmAdoptedNow(Object name) {
    return '($name) set as your main mosque';
  }

  @override
  String get mmActiveMosque => 'Adopted mosque';

  @override
  String get mmAdoptThis => 'Adopt this mosque';

  @override
  String get mmDirections => 'Get directions';

  @override
  String get mmDirectionsFailed =>
      'Could not open directions. No maps app found.';

  @override
  String get mmShare => 'Share prayer times';

  @override
  String mmJumua(Object t) {
    return 'Jumu\'ah: $t';
  }

  @override
  String get mmFriday => 'Friday';

  @override
  String get mmAppName => 'Hisn al-Muslim app';

  @override
  String mmPrayerTimesFor(Object city, Object name) {
    return 'Prayer times for $name ($city):';
  }

  @override
  String get mmErrorNetwork =>
      'Could not connect to server. Check your internet connection.';

  @override
  String get mmErrorParsing =>
      'Error reading server data. Please try again later.';

  @override
  String get mmErrorNotFound => 'No mosques found for this country.';

  @override
  String get mmErrorServer => 'Server error. Please try again later.';

  @override
  String get mmErrorTimeout => 'Connection timed out. Please try again.';

  @override
  String get mmErrorGeneral =>
      'Could not load mosques list. Check internet connection.';

  @override
  String get mmScheduleErrorNetwork =>
      'Could not connect to server to load prayer times.';

  @override
  String get mmScheduleErrorParsing => 'Error parsing mosque prayer times.';

  @override
  String get mmScheduleErrorNotFound =>
      'No prayer times found for this mosque.';

  @override
  String get mmScheduleErrorServer =>
      'Server error while loading times. Please try again.';

  @override
  String get mmScheduleErrorTimeout =>
      'Connection timed out while loading prayer times.';

  @override
  String get mmScheduleErrorGeneral =>
      'Could not load prayer times for this mosque.';

  @override
  String get nsExtraAdhkarSection => 'Extra Adhkar Reminders';

  @override
  String get nsWakeupAdhkar => 'Wake-up adhkar reminder';

  @override
  String get nsWakeupAdhkarSub =>
      'Blessed reminder for waking up adhkar around Fajr';

  @override
  String get nsSleepAdhkar => 'Sleep adhkar reminder';

  @override
  String get nsSleepAdhkarSub =>
      'Blessed reminder for sleep adhkar before bedtime';

  @override
  String get nsFridayKahf => 'Friday Surah Al-Kahf reminder';

  @override
  String get nsFridayKahfSub =>
      'Friday morning reminder to recite Surah Al-Kahf';

  @override
  String get nsFridayKahfTitle => 'Surah Al-Kahf';

  @override
  String get nsFridayKahfBody =>
      'Do not forget to recite Surah Al-Kahf today — a light between two Fridays';

  @override
  String get nsDndSection => 'Do Not Disturb (DND) Automation';

  @override
  String get nsDndTitle => 'Silence phone during prayer';

  @override
  String get nsDndSub =>
      'Automatically enable DND at prayer times to prevent ringing in the mosque';

  @override
  String get nsDndDuration => 'Silence duration after adhan';

  @override
  String get nsDndPermNeeded => 'Requires Do Not Disturb policy access';

  @override
  String get nsDndPermGrant => 'Grant DND Permission';

  @override
  String nsDndMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m minutes',
      one: '$m minute',
    );
    return '$_temp0';
  }

  @override
  String get diagDndTitle => 'Do Not Disturb (DND) Policy';

  @override
  String get diagDndOk => 'Granted — automatic prayer silencing available';

  @override
  String get diagDndDenied =>
      'Denied — cannot automatically silence phone during prayer';

  @override
  String get ptTrackerTitle => 'Prayer Tracker';

  @override
  String ptLevelTitle(int level) {
    return 'Level $level';
  }

  @override
  String get ptDailyGoal => 'Daily goal';

  @override
  String get ptEdit => 'Edit';

  @override
  String get ptGoalToday => 'Today\'s goal';

  @override
  String get ptOverview => 'Prayer overview';

  @override
  String get ptLast30Days => 'Last 30 days';

  @override
  String get ptEmptyTitle => 'No prayers logged yet';

  @override
  String get ptEmptyHint => 'Log your prayers to see your overview here';

  @override
  String get ptGoalDialogTitle => 'Your daily goal';

  @override
  String get ptGoalDialogHint => 'Prayers required per day';

  @override
  String get ptSave => 'Save';

  @override
  String get ptTotalPrayers => 'Total prayers';

  @override
  String get ptOnTimeRate => 'Consistency';

  @override
  String get ptTotalPoints => 'Total points';

  @override
  String get ptHowPrayed => 'How did you pray?';

  @override
  String get ptOptTakbeer => 'Opening takbeer';

  @override
  String get ptOptMosque => 'In the mosque';

  @override
  String get ptOptJamaa => 'In congregation';

  @override
  String get ptOptOnTime => 'On time, alone';

  @override
  String get ptOptLate => 'After its time';

  @override
  String get ptOptMissed => 'Missed';

  @override
  String get ptClearEntry => 'Clear entry';

  @override
  String ptPointsNum(int points) {
    return '+$points pts';
  }

  @override
  String get ptDetails => 'Details';

  @override
  String get ptBasedOn30 => 'Based on the last 30 days';

  @override
  String get ptHowItWorks => 'How it works';

  @override
  String get ptStages => 'Levels';

  @override
  String get ptStagesHint => 'Points needed to unlock each level';

  @override
  String get ptContext => 'Context';

  @override
  String get ptContextHint => 'Prayer rulings differ and affect scoring';

  @override
  String get ptMan => 'Man';

  @override
  String get ptWoman => 'Woman';

  @override
  String get ptPointsInApp => 'App points';

  @override
  String get ptOptionMeanings => 'What the options mean';

  @override
  String get ptMultipliers => 'Points multipliers';

  @override
  String get ptMultipliersHint => 'More effort, more points';

  @override
  String ptPointsCount(int points) {
    return '$points pts';
  }

  @override
  String get ptMeanTakbeer => 'Caught the opening takbeer with the imam';

  @override
  String get ptMeanMosque => 'Prayed in the mosque';

  @override
  String get ptMeanJamaa => 'Prayed in congregation outside the mosque';

  @override
  String get ptMeanOnTime => 'Prayed on time, alone';

  @override
  String get ptMeanLate => 'Made up after its time';

  @override
  String get ptMeanMissed => 'Missed entirely';

  @override
  String get ptOnboardTitle => 'Track your prayers';

  @override
  String get ptOnboardHint =>
      'Keep your streak, build meaningful habits, and grow closer in your daily worship';

  @override
  String get ptOnboardF1T => 'Log every prayer in one tap';

  @override
  String get ptOnboardF1D =>
      'With a simple tap, log your prayer and stay on track';

  @override
  String get ptOnboardF2T => 'Choose how you prayed';

  @override
  String get ptOnboardF2D =>
      'Say how you prayed — opening takbeer, congregation, or on time';

  @override
  String get ptOnboardF3T => 'Smart reminders';

  @override
  String get ptOnboardF3D =>
      'Never miss a prayer — we remind you so you remember to log it';

  @override
  String get ptOnboardAccept => 'Yes, I\'m in!';

  @override
  String get ptOnboardLater => 'Not now';

  @override
  String get ptMenuSettings => 'Tracking settings';

  @override
  String get ptMenuReplay => 'Initial setup';

  @override
  String get ptMenuWidget => 'Add widget';

  @override
  String get ptMenuDisable => 'Pause tracking';

  @override
  String get ptMenuEnable => 'Resume tracking';

  @override
  String get ptMenuClear => 'Clear tracking data';

  @override
  String get ptClearTitle => 'Clear tracking data?';

  @override
  String get ptClearHint =>
      'All logged prayers and streaks will be deleted. This cannot be undone.';

  @override
  String get ptDelete => 'Delete';

  @override
  String get ptWidgetTitle => 'Add the widget';

  @override
  String get ptWidgetHint =>
      'From your home screen: long-press an empty area, then Widgets, then choose Husn el-Muslim';

  @override
  String get ptPausedTitle => 'Tracking paused';

  @override
  String get ptPausedHint => 'Prayers won\'t count until you resume tracking';

  @override
  String get ptResume => 'Resume';

  @override
  String get ptRemindTitle => 'Prayer log reminder';

  @override
  String ptRemindBody(String prayer) {
    return '$prayer is not logged yet — log it now';
  }

  @override
  String get ptRemindToggle => 'Logging reminders';

  @override
  String get ptRemindHint => 'Remind me when I forget to log a prayer';

  @override
  String get diagFivePrayer => 'Five-prayer tracking';

  @override
  String get navSunnah => 'Sunnah Tracker';

  @override
  String get snTitle => 'Sunnah Tracker';

  @override
  String get snSubtitle => 'Rawatib • Duha • Witr • Night prayer';

  @override
  String get snRawatibSection => 'Rawatib Sunan (12 rak\'as)';

  @override
  String get snExtraSection => 'Duha, Witr & night prayer';

  @override
  String get snDailyGoal => 'Daily goal';

  @override
  String get snWeekOverview => 'Last 7 days';

  @override
  String get snTotal30 => 'Last 30 days\' points';

  @override
  String get snEmptyTitle => 'No sunan logged today';

  @override
  String get snEmptyHint =>
      'Start with the 2 Fajr sunnah rak\'as — tap any sunnah to log it';

  @override
  String get snRawatibBonus => 'Full-Rawatib bonus: +10';

  @override
  String get snOpenSunnah => 'Sunnah tracker: Rawatib • Duha • Witr';

  @override
  String get snClear => 'Clear sunnah data';

  @override
  String get snClearTitle => 'Clear sunnah data?';

  @override
  String get snClearHint =>
      'All logged sunan and streaks will be deleted. This cannot be undone.';

  @override
  String get snFajrSunnah => 'Fajr sunnah';

  @override
  String get snFajrSunnahSub => '2 rak\'as before Fajr';

  @override
  String get snDhuhrBefore => 'Pre-Dhuhr sunnah';

  @override
  String get snDhuhrBeforeSub => '4 rak\'as before Dhuhr';

  @override
  String get snDhuhrAfter => 'Post-Dhuhr sunnah';

  @override
  String get snDhuhrAfterSub => '2 rak\'as after Dhuhr';

  @override
  String get snMaghribAfter => 'Maghrib sunnah';

  @override
  String get snMaghribAfterSub => '2 rak\'as after Maghrib';

  @override
  String get snIshaAfter => 'Isha sunnah';

  @override
  String get snIshaAfterSub => '2 rak\'as after Isha';

  @override
  String get snDuha => 'Duha prayer';

  @override
  String get snDuhaSub => '2+ rak\'as after sunrise';

  @override
  String get snWitr => 'Witr';

  @override
  String get snWitrSub => '1 or 3 rak\'as after Isha';

  @override
  String get snQiyam => 'Night prayer';

  @override
  String get snQiyamSub => 'Blessed night rak\'as';

  @override
  String snProgress(int done, int goal) {
    return '$done of $goal';
  }

  @override
  String get diagSunnah => 'Sunnah tracking';

  @override
  String get navWorship => 'Fasting & Wird Tracker';

  @override
  String get wtTitle => 'Fasting & Wird Tracker';

  @override
  String get wtSubtitle => 'Fasting • Wird • Good deeds';

  @override
  String get wtFastingSection => 'Voluntary fasting';

  @override
  String get wtWeekHint => 'Monday & Thursday of the shown week';

  @override
  String get wtMonday => 'Monday';

  @override
  String get wtThursday => 'Thursday';

  @override
  String get wtLogOtherFast => 'Log another fast';

  @override
  String get wtFastSheetTitle => 'What kind of fast?';

  @override
  String get wtKindMonday => 'Monday fast';

  @override
  String get wtKindThursday => 'Thursday fast';

  @override
  String get wtKindWhite => 'White days (13th–15th)';

  @override
  String get wtKindArafah => 'Day of Arafah';

  @override
  String get wtKindAshura => 'Ashura / Tasua';

  @override
  String get wtKindShawwal => 'Six of Shawwal';

  @override
  String get wtKindQadaa => 'Make-up (qadaa)';

  @override
  String get wtKindNafl => 'General voluntary fast';

  @override
  String get wtWeeksStreak => 'Fasting weeks';

  @override
  String get wtTotalFasts => 'Fast days (30 days)';

  @override
  String get wtWeeksOverview => 'Last 8 weeks';

  @override
  String get wtWhiteHint => 'Today is a White day — fasting is recommended';

  @override
  String get wtArafahHint => 'Today is Arafah — its fast expiates two years';

  @override
  String get wtAshuraHint => 'Today is Ashura — fasting is recommended';

  @override
  String get wtMondayHint => 'Today is Monday — deeds are raised';

  @override
  String get wtThursdayHint => 'Today is Thursday — deeds are raised';

  @override
  String get wtWirdSection => 'Daily wird';

  @override
  String get wtDeedsSection => 'Good deeds';

  @override
  String get wtQuran => 'Quran portion';

  @override
  String get wtQuranSub => 'Daily recitation';

  @override
  String get wtMorning => 'Morning adhkar';

  @override
  String get wtMorningSub => 'After Fajr';

  @override
  String get wtEvening => 'Evening adhkar';

  @override
  String get wtEveningSub => 'After Asr';

  @override
  String get wtIstighfar => 'Istighfar (100 times)';

  @override
  String get wtIstighfarSub => 'Astaghfirullah';

  @override
  String get wtSalawat => 'Salawat (100 times)';

  @override
  String get wtSalawatSub => 'Upon the Prophet';

  @override
  String get wtSadaqah => 'Charity';

  @override
  String get wtSadaqahSub => 'Even a little';

  @override
  String get wtSilah => 'Family ties';

  @override
  String get wtSilahSub => 'A call or visit';

  @override
  String get wtBirr => 'Kindness to parents';

  @override
  String get wtBirrSub => 'A kind word or act';

  @override
  String get wtDailyGoal => 'Daily goal';

  @override
  String get wtTotal30 => 'Last 30 days\' points';

  @override
  String get wtClear => 'Clear worship data';

  @override
  String get wtClearTitle => 'Clear worship data?';

  @override
  String get wtClearHint =>
      'All logged wird, fasts and streaks will be deleted. This cannot be undone.';

  @override
  String get wtOpenWorship => 'Fasting & wird: Mon & Thu • wird • charity';

  @override
  String get diagWorship => 'Fasting & wird tracking';
}
