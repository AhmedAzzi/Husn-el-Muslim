// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Husn el-Muslim';

  @override
  String get navAdhkar => 'Adhkar';

  @override
  String get navDua => 'Dua';

  @override
  String get navNames => 'Noms d\'Allah';

  @override
  String get navRuqyah => 'Roqya';

  @override
  String get navMasbaha => 'Masbaha';

  @override
  String get navPrayerTimes => 'Horaires de prière';

  @override
  String get navMosqueMap => 'Carte des mosquées';

  @override
  String get navQibla => 'Qibla';

  @override
  String get navFajrLog => 'Suivi des prières';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get trackCurrent => 'Série actuelle';

  @override
  String get trackLongest => 'Plus longue série';

  @override
  String get trackToday => 'Aujourd\'hui';

  @override
  String trackDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return '$_temp0';
  }

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String get qiblaNorth => 'N';

  @override
  String qiblaBearing(String deg) {
    return 'Direction de la Qibla : $deg°';
  }

  @override
  String qiblaDistance(String km) {
    return 'Distance à la Kaaba : $km km';
  }

  @override
  String get qiblaFacing => 'Vous êtes face à la Qibla ✓';

  @override
  String qiblaTurn(String deg, String direction) {
    return 'Tournez de $deg° vers la $direction';
  }

  @override
  String get qiblaRight => 'droite';

  @override
  String get qiblaLeft => 'gauche';

  @override
  String get qiblaCalibrate =>
      'Déplacez le téléphone en forme de 8 pour calibrer la boussole en cas d\'interférence magnétique. Fonctionne hors ligne.';

  @override
  String get qiblaRetry => 'Réessayer';

  @override
  String get qiblaNoLocation =>
      'Position introuvable — activez le GPS ou définissez d\'abord le lieu de prière';

  @override
  String get qiblaNoSensor =>
      'Boussole indisponible sur cet appareil — la direction de la Qibla ci-dessous est calculée sans boussole';

  @override
  String get awakeTitle => 'Êtes-vous réveillé ?';

  @override
  String get awakeSubtitle =>
      'Défi terminé — confirmez votre réveil pour enregistrer le Fajr';

  @override
  String get iAmAwake => 'Je suis réveillé';

  @override
  String get wellDone => 'Bravo';

  @override
  String get wokeForFajr => 'Vous vous êtes réveillé pour la prière du Fajr';

  @override
  String get continueBtn => 'Continuer';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSubtitle => 'Langue de l\'interface';

  @override
  String get langArabic => 'العربية';

  @override
  String get langEnglish => 'English';

  @override
  String get langFrench => 'Français';

  @override
  String get diagTitle => 'Diagnostic avancé';

  @override
  String get diagPermissions => 'État des autorisations';

  @override
  String get diagExactTitle => 'Alarmes exactes';

  @override
  String get diagExactOk => 'Autorisé — l\'alarme du Fajr sonne à l\'heure';

  @override
  String get diagExactDenied =>
      'Non autorisé — les alarmes peuvent ne pas sonner à l\'heure';

  @override
  String get diagOpenSettings => 'Ouvrir les paramètres';

  @override
  String get diagBatteryTitle => 'Optimisation de la batterie';

  @override
  String get diagBatteryOn => 'Activée — le système peut arrêter les alarmes';

  @override
  String get diagBatteryOff => 'Exemptée — l\'application fonctionne librement';

  @override
  String get diagRequestExemption => 'Demander l\'exemption';

  @override
  String get diagOverlayTitle => 'Affichage par-dessus';

  @override
  String get diagOverlayOk => 'Accordée — les fenêtres flottantes fonctionnent';

  @override
  String get diagOverlayDenied =>
      'Non accordée — alertes flottantes désactivées';

  @override
  String get diagRequestPermission => 'Demander l\'autorisation';

  @override
  String get diagScheduled => 'Alarmes programmées';

  @override
  String get diagReadFailed => 'Lecture du diagnostic impossible';

  @override
  String get diagRescheduleAll => 'Reprogrammer toutes les alarmes';

  @override
  String get diagRescheduled => 'Toutes les alarmes reprogrammées';

  @override
  String get diagRescheduleFailed => 'Reprogrammation impossible';

  @override
  String get diagTracking => 'Suivi';

  @override
  String get diagCurrent => 'Actuelle';

  @override
  String get diagLongest => 'La plus longue';

  @override
  String get diagTest => 'Test';

  @override
  String get diagTestDesc =>
      'Programme la vraie alarme du défi Fajr dans 5 secondes (son + notification + écran du défi).';

  @override
  String get diagTestScheduling => 'Programmation…';

  @override
  String get diagTestButton => 'Tester l\'alarme du Fajr (5 secondes)';

  @override
  String get diagTestWillRing => 'L\'alarme de test sonnera dans 5 secondes';

  @override
  String get diagTestFailed =>
      'Test impossible — vérifiez l\'autorisation d\'alarmes exactes';

  @override
  String get chTitle => 'Défi de la prière du Fajr';

  @override
  String get chAnswerToStop => 'Répondez à la question pour arrêter l\'alarme';

  @override
  String chRemaining(int count) {
    return 'Restant : $count';
  }

  @override
  String get chWriteCategory => 'Écrivez la catégorie de ce dhikr :';

  @override
  String get chWriteAnswerHint => 'Écrivez la réponse ici';

  @override
  String get chVerifyAnswer => 'Vérifier la réponse';

  @override
  String get chWrongAnswer => 'Mauvaise réponse';

  @override
  String get chTryAgain => 'Réessayez';

  @override
  String get chLoadError => 'Échec du chargement des questions';

  @override
  String get chMathSubtitle => 'Résolvez le calcul pour arrêter l\'alarme';

  @override
  String get chMathHint => 'Écrivez la réponse en chiffres';

  @override
  String get chMemoryTitle => 'Défi mémoire';

  @override
  String get chMemorySubtitle =>
      'Retournez les cartes et associez les quatre paires';

  @override
  String chMatched(int done, int total) {
    return 'Associées : $done / $total';
  }

  @override
  String get chShakeTitle => 'Secouez le téléphone pour vous réveiller';

  @override
  String get chShakeSubtitle => 'Secouez fermement jusqu\'à remplir la barre';

  @override
  String get chSensorUnavailable =>
      'Capteur de mouvement indisponible sur cet appareil';

  @override
  String get chSwitchToQuestions => 'Passer au défi des questions';

  @override
  String chCardHidden(int n) {
    return 'Carte retournée $n';
  }

  @override
  String chCardShown(String face) {
    return 'Carte $face';
  }

  @override
  String get chPreviewBanner => 'Aperçu — rien ne sera enregistré';

  @override
  String get sheetExactTitle => 'Autorisation d\'alarmes exactes requise';

  @override
  String get sheetExactBody =>
      'Sans l\'autorisation « Alarmes et rappels » du système, l\'alarme du défi Fajr ne sonnera pas à l\'heure. Ouvrir les paramètres pour l\'accorder ?';

  @override
  String get sheetLater => 'Plus tard';

  @override
  String get sheetTitle => 'Défi du réveil pour le Fajr';

  @override
  String get sheetSubtitle =>
      'Une alarme interactive qui ne s\'arrête qu\'après avoir résolu les questions';

  @override
  String get sheetEnable => 'Activer l\'alarme interactive';

  @override
  String get sheetEnabledOn => 'L\'alarme est activée et sonnera à l\'heure';

  @override
  String get sheetEnabledOff => 'L\'alarme est désactivée';

  @override
  String get sheetWarnTitle => 'Remarque';

  @override
  String get sheetWarnBody =>
      'Activée, mais l\'alarme ne sonnera pas sans l\'autorisation d\'alarmes exactes';

  @override
  String get sheetRingTime => 'Heure de l\'alarme';

  @override
  String get sheetLastThird => 'Dernier tiers de la nuit';

  @override
  String get sheetLastThirdSub => 'Automatique, pour la prière nocturne';

  @override
  String get sheetCustom => 'Heure personnalisée';

  @override
  String get sheetCustomSub => 'Minutes définies avant le Fajr';

  @override
  String get sheetBeforeFajrBy => 'Sonner avant le Fajr de :';

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
  String get sheetQuestionCount => 'Nombre de questions du défi';

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
  String get sheetTextMode => 'Écrire la réponse';

  @override
  String get sheetTextModeSub =>
      'Plus difficile : écrire au lieu du choix multiple';

  @override
  String get sheetTestAt => 'Sonnerie de test dans :';

  @override
  String sheetSeconds(int count) {
    return '$count s';
  }

  @override
  String get sheetTestScheduled => 'Alarme de test programmée';

  @override
  String sheetTestWillRing(int seconds) {
    return 'La vraie alarme du défi Fajr sonnera dans $seconds secondes';
  }

  @override
  String get sheetTestFailedTitle => 'Test impossible';

  @override
  String get sheetTestFailedBody =>
      'Vérifiez l\'autorisation d\'alarmes exactes dans les paramètres système';

  @override
  String get sheetTestButton => 'Tester la vraie sonnerie (alarme réelle)';

  @override
  String get nsTitle => 'Paramètres des notifications et de l\'adhan';

  @override
  String get nsBatteryTitle => 'Optimisation de la batterie activée';

  @override
  String get nsBatteryBody =>
      'Le système peut arrêter les notifications de l\'adhan pour économiser la batterie. Exemptez l\'application pour des alertes fiables.';

  @override
  String get nsBatteryButton => 'Exempter l\'application';

  @override
  String get nsPersistentSection => 'Notifications système persistantes';

  @override
  String get nsPersistent => 'Notification persistante';

  @override
  String get nsPersistentSub =>
      'Toujours afficher la date hégirienne et la prochaine prière';

  @override
  String get nsFajrEnable => 'Activer l\'alarme du défi Fajr';

  @override
  String get nsFajrEnableSub =>
      'Alarme interactive qui ne s\'arrête qu\'après avoir résolu des questions';

  @override
  String get nsChallengeType => 'Type de défi';

  @override
  String get nsTypeQuestions => 'Questions';

  @override
  String get nsTypeQuestionsSub => 'Adhkar et dua';

  @override
  String get nsTypeMath => 'Maths';

  @override
  String get nsTypeMathSub => 'Calcul mental';

  @override
  String get nsTypeMemory => 'Mémoire';

  @override
  String get nsTypeMemorySub => 'Association de cartes';

  @override
  String get nsTypeShake => 'Secouer';

  @override
  String get nsTypeShakeSub => 'Secouer le téléphone';

  @override
  String get nsTypeRandom => 'Aléatoire';

  @override
  String get nsTypeRandomSub => 'Type surprise';

  @override
  String get nsRandomPool => 'Types inclus dans l\'aléatoire';

  @override
  String get nsShakeSensitivity => 'Sensibilité de secousse';

  @override
  String get nsLow => 'Faible';

  @override
  String get nsShakeMedium => 'Moyenne';

  @override
  String get nsHigh => 'Haute';

  @override
  String get nsDifficulty => 'Niveau de difficulté';

  @override
  String get nsEasy => 'Facile';

  @override
  String get nsDiffMedium => 'Moyen';

  @override
  String get nsHard => 'Difficile';

  @override
  String get nsHardSub => 'Saisie obligatoire';

  @override
  String get nsWakeConfirm => 'Confirmation du réveil';

  @override
  String get nsWakeConfirmSub =>
      'Après le défi : Êtes-vous réveillé ? puis enregistrer le succès';

  @override
  String get nsTryNow => 'Essayer le défi';

  @override
  String get nsOpenLog => 'Suivi du Fajr';

  @override
  String get nsAlarmSound => 'Son de l\'alarme';

  @override
  String get nsSoundAdhan => 'Adhan';

  @override
  String get nsSoundAdhanSub => 'Inclus dans l\'application';

  @override
  String get nsSoundSystem => 'Sonnerie système';

  @override
  String get nsSoundSystemSub => 'Sonnerie du téléphone';

  @override
  String get nsSoundCustom => 'Fichier personnalisé';

  @override
  String get nsSoundCustomSub => 'Fichier audio de votre appareil';

  @override
  String get nsPickAudio => 'Choisir un fichier audio';

  @override
  String get nsChangeAudio => 'Sélectionné — changer de fichier';

  @override
  String get nsPreviewSound => 'Apercevoir le son';

  @override
  String get nsPreviewPlaying => 'Lecture de l\'aperçu…';

  @override
  String get nsStop => 'Arrêter';

  @override
  String get nsAlarmVolume => 'Volume de l\'alarme';

  @override
  String get nsAlarmVibrate => 'Vibrer pendant la sonnerie';

  @override
  String get nsAlarmLoop => 'Répéter jusqu\'à l\'arrêt';

  @override
  String get nsGentleWake => 'Réveil doux (montée du volume)';

  @override
  String get nsInstant => 'Immédiat';

  @override
  String get nsExtraAlarms => 'Alarmes supplémentaires';

  @override
  String get nsSuhoor => 'Alarme du Suhoor';

  @override
  String get nsSuhoorSub =>
      'Heure du Suhoor avant le Fajr (distincte de l\'adhan)';

  @override
  String get nsBeforeFajrBy => 'Avant le Fajr de :';

  @override
  String get nsPreFajr => 'Alerte avant le Fajr';

  @override
  String get nsPreFajrSub =>
      'Avertissement doux avant l\'adhan (5 / 10 / 15 minutes)';

  @override
  String get nsTahajjud => 'Alarme du Tahajjud';

  @override
  String get nsTahajjudSub =>
      'Réveil nocturne au dernier tiers ou à heure fixe';

  @override
  String get nsTahajjudLastThird => 'Dernier tiers (auto)';

  @override
  String get nsTahajjudFixed => 'Heure fixe';

  @override
  String get nsFajrExtra => 'Rappel gros dormeurs';

  @override
  String get nsFajrExtraSub => 'Relance le défi Fajr après le Fajr (+minutes)';

  @override
  String get nsPreviewTry => 'Essayer le défi maintenant';

  @override
  String get nsBedtime => 'Rappel du coucher';

  @override
  String get nsBedtimeSub => 'Vous aide à dormir tôt pour le Fajr';

  @override
  String get nsBedtimeRelative => 'Relatif au Fajr';

  @override
  String nsBedtimeRelativeSub(int h) {
    String _temp0 = intl.Intl.pluralLogic(
      h,
      locale: localeName,
      other: '$h heures',
      one: '$h heure',
    );
    return 'Fajr − $_temp0';
  }

  @override
  String get nsSkipTonight => 'Sauter ce soir seulement';

  @override
  String get nsSkippedTonight => 'Rappel de ce soir sauté';

  @override
  String get nsPrePrayer => 'Rappel avant la prière';

  @override
  String get nsPrePrayerSub =>
      'Alerte discrète avant chaque prière sélectionnée';

  @override
  String get nsBeforePrayerBy => 'Avant la prière de :';

  @override
  String get nsPostPrayer => 'Rappel après la prière';

  @override
  String get nsPostPrayerSub =>
      'Rappel des adhkar après chaque prière sélectionnée';

  @override
  String get nsAfterPrayerBy => 'Après la prière de :';

  @override
  String get nsAdhkarSection => 'Alertes des adhkar du matin et du soir';

  @override
  String get nsMorning => 'Alerte des adhkar du matin';

  @override
  String get nsMorningSub => 'Rappel béni une heure après le Fajr';

  @override
  String get nsEvening => 'Alerte des adhkar du soir';

  @override
  String get nsEveningSub => 'Rappel béni une heure après le Asr';

  @override
  String get nsPrayerFajr => 'Fajr';

  @override
  String get nsPrayerDhuhr => 'Dhuhr';

  @override
  String get nsPrayerAsr => 'Asr';

  @override
  String get nsPrayerMaghrib => 'Maghrib';

  @override
  String get nsPrayerIsha => 'Icha';

  @override
  String get nsPrayerSunrise => 'Lever du soleil';

  @override
  String get stAppearance => 'Apparence et général';

  @override
  String get stSettingsTitle => 'Paramètres et préférences';

  @override
  String get ptFajrChallengeTip => 'Défi du réveil pour le Fajr';

  @override
  String get ptLocationUpdated => 'Position mise à jour';

  @override
  String get ptLoading => 'Chargement des horaires…';

  @override
  String get ptLoadFailed => 'Horaires introuvables';

  @override
  String get ptLoadFailedSub => 'Vérifiez le GPS et la connexion internet';

  @override
  String get ptLoadingShort => 'Chargement…';

  @override
  String ptCorresponding(String date) {
    return ' correspondant au $date';
  }

  @override
  String get ptFajrChallenge => 'Défi Fajr';

  @override
  String get ptListFailed => 'Échec du chargement des horaires';

  @override
  String get ptSourceTitle => 'Source des horaires';

  @override
  String get ptSourceSub =>
      'Choisissez le calcul ou trouvez une mosquée proche';

  @override
  String get ptCalcSub => 'Calcul selon le madhab depuis votre position';

  @override
  String get ptNearbyMosques => 'Mosquées proches';

  @override
  String ptAllMosques(String country, int count) {
    return 'Toutes les mosquées — $country ($count)';
  }

  @override
  String get ptNoResults => 'Aucun résultat pour le moment';

  @override
  String ptMosqueAdopted(String name) {
    return '($name) définie comme votre mosquée';
  }

  @override
  String get ptMosqueFailed => 'Horaires introuvables, réessayez';

  @override
  String ptMeters(String m) {
    return '$m m';
  }

  @override
  String ptKm(String km) {
    return '$km km';
  }

  @override
  String get ptIqamaAfter => 'Iqama dans';

  @override
  String ptPrayerAfter(String name) {
    return '$name dans';
  }

  @override
  String get ptAyatOff => 'Désactiver le verset';

  @override
  String get ptAyatOn => 'Activer le verset';

  @override
  String get ctCopied => 'Texte copié dans le presse-papiers';

  @override
  String get ctCopy => 'Copier';

  @override
  String get ctCopyAll => 'Copier tout le texte';

  @override
  String get ctShare => 'Partager';

  @override
  String get ctShareAll => 'Partager tout le texte';

  @override
  String get ctClose => 'Fermer';

  @override
  String get ctCancel => 'Annuler';

  @override
  String get ctNoSearchResults => 'Aucun résultat correspondant';

  @override
  String get ctSearch => 'Rechercher';

  @override
  String get ctRefresh => 'Actualiser';

  @override
  String get obPermNotif => 'Notifications';

  @override
  String get obPermNotifSub => 'Pour les horaires de prière et les adhkar';

  @override
  String get obPermLocation => 'Position';

  @override
  String get obPermLocationSub => 'Pour des horaires précis';

  @override
  String get obPermOverlay => 'Affichage par-dessus';

  @override
  String get obPermOverlaySub => 'Pour afficher adhkar et versets';

  @override
  String get obWelcome => 'Bienvenue dans Husn el-Muslim';

  @override
  String get obSubtitle => 'Certaines autorisations sont nécessaires';

  @override
  String get obSkip => 'Passer';

  @override
  String get azEmpty => 'Aucun résultat';

  @override
  String get duCopied => 'Dua copié dans le presse-papiers';

  @override
  String get duLoadFailed => 'Données des duas introuvables';

  @override
  String get duQuranSection => 'Duas coraniques';

  @override
  String get duSunnahSection => 'Duas de la Sunna';

  @override
  String get duAdabSection => 'Vertus et convenances du dua';

  @override
  String get duQuranBadge => 'Coranique';

  @override
  String get duSunnahBadge => 'Sunna';

  @override
  String duShareSubject(int n) {
    return 'Dua n° $n';
  }

  @override
  String get rqLoadFailed => 'Données de roqya introuvables';

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
  String get asCopiedDefault => 'Copié ✿';

  @override
  String get asTapHint => 'Toucher pour voir, appui long pour copier';

  @override
  String get azSpeedTitle => 'Vitesse du compteur auto';

  @override
  String get azSeconds => 'Temps en secondes';

  @override
  String get azAuto => 'Auto';

  @override
  String get azReset => 'Réinitialiser';

  @override
  String azTimes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m fois',
      one: 'une fois',
    );
    return '$_temp0';
  }

  @override
  String azTimesHundred(int m) {
    return '$m fois';
  }

  @override
  String azOfTotal(int i, int n) {
    return 'Dhikr $i sur $n';
  }

  @override
  String get azCopiedDhikr => 'Dhikr copié dans le presse-papiers';

  @override
  String get azSave => 'Enregistrer';

  @override
  String get azCopied => 'Copié dans le presse-papiers';

  @override
  String azSharePrefix(Object cat) {
    return 'Depuis les dhikr : $cat';
  }

  @override
  String get msSaveFolder => 'Choisir le dossier';

  @override
  String msBackupSaved(String f) {
    return 'Sauvegarde enregistrée : $f';
  }

  @override
  String msExportFailed(String e) {
    return 'Échec de l\'export : $e';
  }

  @override
  String get msImported => 'Données importées';

  @override
  String msImportFailed(String e) {
    return 'Échec de l\'import : $e';
  }

  @override
  String get msAdded => 'Dhikr ajouté !';

  @override
  String get msEdited => 'Dhikr modifié !';

  @override
  String get msDeleted => 'Dhikr supprimé !';

  @override
  String get msPickCount => 'Choisir le nombre de tasbih';

  @override
  String get msCountHint => 'Nombre de tasbih (ouvert par défaut)';

  @override
  String get msStart => 'Commencer';

  @override
  String get msEdit => 'Modifier';

  @override
  String get msDelete => 'Supprimer';

  @override
  String get msAddNew => 'Ajouter un dhikr';

  @override
  String get msRestoreTitle => 'Restaurer les adhkar par défaut ?';

  @override
  String get msRestoreBody =>
      'Vos adhkar actuels seront supprimés et remplacés par la liste par défaut.';

  @override
  String get msRestore => 'Restaurer';

  @override
  String get msHideScores => 'Masquer les scores';

  @override
  String get msShowScores => 'Afficher les scores';

  @override
  String get msResetDefault => 'Restaurer les défauts';

  @override
  String get msExport => 'Exporter les données';

  @override
  String get msImport => 'Importer les données';

  @override
  String get msAddTitle => 'Ajouter un dhikr';

  @override
  String get msEditTitle => 'Modifier un dhikr';

  @override
  String get msFieldDhikr => 'Dhikr *';

  @override
  String get msFieldBenefit => 'Vertu';

  @override
  String get msFieldSource => 'Source';

  @override
  String get msFieldSpeed => 'Vitesse du compteur auto (secondes)';

  @override
  String get msCounterTitle => 'Compteur de dhikr';

  @override
  String msVirtue(String t) {
    return 'Vertu : $t';
  }

  @override
  String msSource(String t) {
    return 'Source : $t';
  }

  @override
  String get msOpen => 'Ouvert';

  @override
  String get msSave => 'Enregistrer';

  @override
  String get stDarkMode => 'Mode sombre';

  @override
  String get stDarkOn => 'Thème nuit activé';

  @override
  String get stDarkOff => 'Thème clair activé';

  @override
  String get stDefaultHome => 'Écran d\'accueil par défaut';

  @override
  String get stDefaultHomeSub => 'Écran affiché au lancement';

  @override
  String get stHomeAzkarSub => 'Adhkar du jour et Husn el-Muslim';

  @override
  String get stHomeMisbahaSub => 'Compteur de tasbih et adhkar personnalisés';

  @override
  String get stHomePrayerSub => 'Horaires de l\'adhan, alertes et Qibla';

  @override
  String get stHomeSet => 'Écran d\'accueil défini (appliqué au redémarrage)';

  @override
  String get stLanguageTitle => 'Langue';

  @override
  String get stLanguagePicker => 'Langue';

  @override
  String get stLanguagePickerSub => 'Choisissez la langue de l\'interface';

  @override
  String get stLangArSub => 'Langue par défaut';

  @override
  String get stLangEnSub => 'Langue de l\'application';

  @override
  String get stLangFrSub => 'Langue de l\'interface';

  @override
  String get stInteraction => 'Masbaha et interaction';

  @override
  String get stClickSound => 'Son du clic';

  @override
  String get stClickSoundSub => 'Petit son au toucher du masbaha';

  @override
  String get stHaptic => 'Vibration tactile';

  @override
  String get stHapticSub => 'Le téléphone vibre à chaque tasbih';

  @override
  String get stReminder => 'Rappels automatiques des adhkar';

  @override
  String get stFloatingDhikr => 'Adhkar flottants périodiques';

  @override
  String get stFloatingDhikrSub =>
      'Un court dhikr apparaît automatiquement par-dessus les applications';

  @override
  String get stReminderRate => 'Fréquence des rappels';

  @override
  String get stReminderRateSub => 'Intervalle entre les adhkar';

  @override
  String get stEveryHour => 'Chaque heure';

  @override
  String stEveryMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m minutes',
      one: '$m minute',
    );
    return 'Toutes les $_temp0';
  }

  @override
  String get stIntervalTitle => 'Fréquence des rappels automatiques';

  @override
  String get stIntervalSub => 'Temps entre les adhkar flottants';

  @override
  String get stOverlayTitle => 'Autorisation d\'affichage par-dessus';

  @override
  String get stOverlayBody =>
      'Pour afficher de courts adhkar pendant l\'utilisation d\'autres applications, l\'application a besoin de l\'autorisation d\'affichage par-dessus. L\'activer ?';

  @override
  String get stActivateNow => 'Activer';

  @override
  String get stHomePicker => 'Écran d\'accueil par défaut';

  @override
  String get stHomePickerSub =>
      'Choisissez l\'écran d\'ouverture de l\'application';

  @override
  String get stPrayerData => 'Horaires de prière et source';

  @override
  String get stSourcePicker => 'Source des horaires de prière';

  @override
  String get stSourcePickerSub =>
      'Choisissez entre les horaires de mosquée ou le calcul hors ligne';

  @override
  String get stSourceMosque => 'Horaires de mosquée (en ligne avec cache)';

  @override
  String get stSourceMosqueSub =>
      'Récupère les horaires de votre mosquée via Mawaqit pour une utilisation hors ligne';

  @override
  String get stSourceCalc => 'Horaires calculés (hors ligne)';

  @override
  String get stSourceCalcMode => 'Calculés astronomiquement (hors ligne)';

  @override
  String get stSourceCalcSub =>
      'Calcul astronomique selon votre position et votre madhab, sans internet';

  @override
  String get stSourceMosqueSet => 'Source définie : horaires de mosquée';

  @override
  String get stSourceCalcSet => 'Source définie : horaires calculés';

  @override
  String get stCalcPicker => 'Méthode de calcul des prières';

  @override
  String get stCalcPickerSub => 'Choisissez l\'autorité de votre région';

  @override
  String get stCalcSaved => 'Méthode enregistrée et horaires réinitialisés';

  @override
  String get stAsrPicker => 'Madhab du Asr';

  @override
  String get stAsrPickerSub => 'Début du Asr selon les madhabs';

  @override
  String get stAsrShafi => 'Majorité (Shafi, Maliki, Hanbali)';

  @override
  String get stAsrShafiSub => 'Quand l\'ombre égale sa longueur';

  @override
  String get stAsrHanafi => 'Madhab hanafi';

  @override
  String get stAsrHanafiSub => 'Quand l\'ombre égale deux fois sa longueur';

  @override
  String get stAsrSaved => 'Madhab du Asr enregistré';

  @override
  String get stMethodMakkah => 'Oum al-Qoura (La Mecque)';

  @override
  String get stMethodMakkahSub => 'Arabie saoudite et Golfe';

  @override
  String get stMethodEgypt => 'Autorité égyptienne de topographie';

  @override
  String get stMethodEgyptSub => 'Égypte, Soudan et Afrique';

  @override
  String get stMethodMwl => 'Ligue islamique mondiale';

  @override
  String get stMethodMwlSub => 'Europe, Extrême-Orient et Amérique';

  @override
  String get stMethodKarachi => 'Univ. des sciences islamiques, Karachi';

  @override
  String get stMethodKarachiSub => 'Pakistan, Inde, Bangladesh et Afghanistan';

  @override
  String get stMethodIsna => 'Société islamique d\'Amérique du Nord (ISNA)';

  @override
  String get stMethodIsnaSub => 'États-Unis et Canada';

  @override
  String get stMethodKuwait => 'État du Koweït';

  @override
  String get stMethodKuwaitSub => 'Koweït (Fajr 18, Icha 17.5)';

  @override
  String get stMethodQatar => 'État du Qatar';

  @override
  String get stMethodQatarSub =>
      'Qatar (Fajr 18, Icha 90 min après le Maghrib)';

  @override
  String get stMethodSingapore => 'Singapour';

  @override
  String get stMethodSingaporeSub => 'Singapour et Malaisie (Fajr 20, Icha 18)';

  @override
  String get stMethodTurkey => 'Diyanet turc';

  @override
  String get stMethodTurkeySub => 'Turquie (Diyanet)';

  @override
  String get stMethodDubai => 'Émirats et Golfe (Dubaï)';

  @override
  String get stMethodDubaiSub => 'Émirats et Golfe (18.2)';

  @override
  String get stMethodMoon => 'Comité d\'observation lunaire';

  @override
  String get stMethodMoonSub => 'Amérique du Nord et régions polaires';

  @override
  String get stCalcMethod => 'Méthode de calcul';

  @override
  String get stCalcMethodSub =>
      'Autorité pour les angles du Fajr et de l\'Icha';

  @override
  String get stAsrMethod => 'Madhab du Asr';

  @override
  String get stAsrMethodSub => 'Critère d\'ombre pour le début du Asr';

  @override
  String get stDst => 'Heure d\'été';

  @override
  String get stDstSub => 'Ajouter automatiquement une heure aux prières';

  @override
  String get stManualTitle => 'Ajuster les horaires manuellement';

  @override
  String get stManualTileSub =>
      'Ajouter ou retirer des minutes selon votre adhan local';

  @override
  String get stReset => 'Réinitialiser';

  @override
  String get stManualSub =>
      'Ajoutez ou retirez des minutes par prière selon l\'adhan de votre mosquée';

  @override
  String get stZeroMin => '0 minute';

  @override
  String stMinDelta(String signed) {
    return '$signed min';
  }

  @override
  String get stManualSaved => 'Ajustements enregistrés';

  @override
  String get stSaveEdits => 'Enregistrer';

  @override
  String get stSave => 'Enregistrer';

  @override
  String get stIqamaTitle => 'Iqama (minutes après l\'adhan)';

  @override
  String get stIqamaSub =>
      'Définissez les minutes de l\'iqama après l\'adhan pour un compte à rebours exact';

  @override
  String get stIqamaTile => 'Iqama';

  @override
  String get stIqamaTileSub => 'Minutes de l\'iqama après l\'adhan par prière';

  @override
  String get stNoAdjust => 'Sans ajustement';

  @override
  String get stNoIqama => 'Sans iqama';

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
  String get stIqamaSaved => 'Paramètres de l\'iqama enregistrés';

  @override
  String get stHijriTitle => 'Ajuster la date hégirienne';

  @override
  String get stHijriSub =>
      'Décalez la date hégirienne pour suivre l\'observation lunaire';

  @override
  String get stHijriExact => 'Date conforme au calcul astronomique';

  @override
  String stHijriAdjusted(String text) {
    return 'Ajusté de ($text)';
  }

  @override
  String stHijriDays(int d) {
    String _temp0 = intl.Intl.pluralLogic(
      d,
      locale: localeName,
      other: '# jours',
      one: '# jour',
    );
    return '$_temp0';
  }

  @override
  String get stAdjust => 'Ajuster';

  @override
  String get stHijriSaved => 'Ajustement hégirien enregistré';

  @override
  String get stGpsRefreshed => 'Position et horaires mis à jour';

  @override
  String get stGpsFailed => 'Position introuvable, vérifiez le GPS';

  @override
  String get stGpsTile => 'Position (GPS)';

  @override
  String get stRefresh => 'Actualiser';

  @override
  String stCoords(String lat, String lon) {
    return 'Coordonnées : $lat, $lon';
  }

  @override
  String get stNoMosque => 'Aucune mosquée sélectionnée';

  @override
  String get stOpenMapChoose => 'Ouvrez la carte pour choisir votre mosquée';

  @override
  String stCityChange(String city) {
    return 'Ville : $city • changer';
  }

  @override
  String get stChangeMosque => 'Changer de mosquée';

  @override
  String get stChooseMosque => 'Choisir une mosquée';

  @override
  String get stMosqueBadge => 'Horaires de mosquée';

  @override
  String get stCalcBadge => 'Calculés';

  @override
  String get stNotifHub => 'Notifications et adhan';

  @override
  String get stHubTitle => 'Personnaliser notifications et adhan';

  @override
  String get stHubSub =>
      'Notification persistante, défi Fajr, adhkar du matin et du soir';

  @override
  String get stAdvanced => 'Avancé';

  @override
  String get stSearchHint => 'Rechercher dans les réglages';

  @override
  String get stAdvancedMode => 'Paramètres avancés';

  @override
  String get stAdvancedModeSub =>
      'Afficher les options techniques (décalages, iqama, réglages fins)';

  @override
  String get stHiddenAdvanced => 'Certains réglages techniques sont masqués';

  @override
  String get stDiagTile => 'Diagnostic avancé';

  @override
  String get stDiagTileSub => 'Autorisations, alarmes programmées et test';

  @override
  String get stAbout => 'À propos et partage';

  @override
  String get stAboutApp => 'À propos de Husn el-Muslim';

  @override
  String stAboutAppSub(String v) {
    return 'Version $v • Open source';
  }

  @override
  String get stOfficialSite => 'Site du cheikh Saeed bin Wahf';

  @override
  String get stOfficialSiteSub => 'Auteur de Husn el-Muslim';

  @override
  String get stGithub => 'Projet sur GitHub';

  @override
  String get stGithubSub => 'Contribuer et code source';

  @override
  String get stGithubSheetSub => 'Dépôt du code de l\'application sur GitHub';

  @override
  String stAboutSheetLine(String v) {
    return 'Version $v • Application islamique open source';
  }

  @override
  String get mmSearchHint => 'Rechercher par mosquée ou ville...';

  @override
  String get mmTitle => 'Carte des mosquées';

  @override
  String get mmCloseSearch => 'Fermer la recherche';

  @override
  String get mmSearch => 'Recherche';

  @override
  String get mmShowMap => 'Afficher la carte';

  @override
  String get mmShowList => 'Afficher la liste';

  @override
  String get mmChangeCountry => 'Changer de pays';

  @override
  String mmMosqueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mosquées',
      one: '$count mosquée',
    );
    return '$_temp0';
  }

  @override
  String get mmOfflineBanner => 'Hors ligne — affichage des mosquées en cache';

  @override
  String get mmLocateMe => 'Ma position';

  @override
  String get mmCountryPickerTitle => 'Sélectionnez le pays';

  @override
  String get mmAdoptMosque => 'Définir comme mosquée principale';

  @override
  String get mmRetry => 'Réessayer';

  @override
  String get mmEmptyNoMosques => 'Aucune mosquée en attente de chargement';

  @override
  String get mmEmptyNoResults => 'Aucun résultat correspondant';

  @override
  String get mmRefreshTimes => 'Actualiser les horaires';

  @override
  String get mmActiveMosqueBadge =>
      'C\'est la mosquée actuellement adoptée dans l\'application';

  @override
  String mmDistanceKm(Object d) {
    return 'à $d km';
  }

  @override
  String mmAdoptedNow(Object name) {
    return '($name) définie comme mosquée principale';
  }

  @override
  String get mmActiveMosque => 'Mosquée adoptée';

  @override
  String get mmAdoptThis => 'Adopter cette mosquée';

  @override
  String get mmDirections => 'Itinéraire';

  @override
  String get mmDirectionsFailed =>
      'Impossible d\'ouvrir l\'itinéraire. Aucune application de cartes.';

  @override
  String get mmShare => 'Partager les horaires';

  @override
  String mmJumua(Object t) {
    return 'Jumu\'ah : $t';
  }

  @override
  String get mmFriday => 'Vendredi';

  @override
  String get mmAppName => 'Application Hisn al-Muslim';

  @override
  String mmPrayerTimesFor(Object city, Object name) {
    return 'Horaires de prière pour $name ($city) :';
  }

  @override
  String get mmErrorNetwork =>
      'Impossible de se connecter au serveur. Vérifiez votre connexion.';

  @override
  String get mmErrorParsing =>
      'Erreur de lecture des données du serveur. Réessayez plus tard.';

  @override
  String get mmErrorNotFound => 'Aucune mosquée trouvée pour ce pays.';

  @override
  String get mmErrorServer => 'Erreur du serveur. Réessayez plus tard.';

  @override
  String get mmErrorTimeout =>
      'Délai de connexion dépassé. Veuillez réessayer.';

  @override
  String get mmErrorGeneral =>
      'Impossible de charger les mosquées. Vérifiez votre connexion.';

  @override
  String get mmScheduleErrorNetwork =>
      'Impossible de charger les horaires de la mosquée.';

  @override
  String get mmScheduleErrorParsing =>
      'Erreur de lecture des horaires de la mosquée.';

  @override
  String get mmScheduleErrorNotFound =>
      'Aucun horaire trouvé pour cette mosquée.';

  @override
  String get mmScheduleErrorServer =>
      'Erreur du serveur lors du chargement des horaires.';

  @override
  String get mmScheduleErrorTimeout =>
      'Délai dépassé lors du chargement des horaires.';

  @override
  String get mmScheduleErrorGeneral =>
      'Impossible de charger les horaires de cette mosquée.';

  @override
  String get nsExtraAdhkarSection => 'Rappels d\'adhkar supplémentaires';

  @override
  String get nsWakeupAdhkar => 'Rappel des adhkar du réveil';

  @override
  String get nsWakeupAdhkarSub =>
      'Rappel béni pour les adhkar du réveil au Fajr';

  @override
  String get nsSleepAdhkar => 'Rappel des adhkar du coucher';

  @override
  String get nsSleepAdhkarSub =>
      'Rappel béni pour les adhkar du coucher avant de dormir';

  @override
  String get nsFridayKahf => 'Rappel de la sourate Al-Kahf (Vendredi)';

  @override
  String get nsFridayKahfSub =>
      'Rappel chaque vendredi matin pour lire la sourate Al-Kahf';

  @override
  String get nsFridayKahfTitle => 'Sourate Al-Kahf';

  @override
  String get nsFridayKahfBody =>
      'N\'oubliez pas de lire la sourate Al-Kahf aujourd\'hui — une lumière entre deux vendredis';

  @override
  String get nsDndSection => 'Automatisation Ne pas déranger (DND)';

  @override
  String get nsDndTitle => 'Silencieux pendant la prière';

  @override
  String get nsDndSub =>
      'Activer automatiquement le mode Ne pas déranger à l\'heure de la prière';

  @override
  String get nsDndDuration => 'Durée du silencieux après l\'adhan';

  @override
  String get nsDndPermNeeded => 'Nécessite l\'autorisation Ne pas déranger';

  @override
  String get nsDndPermGrant => 'Accorder l\'autorisation';

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
  String get diagDndTitle => 'Règle Ne pas déranger (DND)';

  @override
  String get diagDndOk => 'Accordé — mode silencieux automatique disponible';

  @override
  String get diagDndDenied =>
      'Refusé — impossible de passer automatiquement en silencieux';

  @override
  String get ptTrackerTitle => 'Suivi des prières';

  @override
  String ptLevelTitle(int level) {
    return 'Niveau $level';
  }

  @override
  String get ptDailyGoal => 'Objectif quotidien';

  @override
  String get ptEdit => 'Modifier';

  @override
  String get ptGoalToday => 'Objectif du jour';

  @override
  String get ptOverview => 'Aperçu des prières';

  @override
  String get ptLast30Days => '30 derniers jours';

  @override
  String get ptEmptyTitle => 'Aucune prière enregistrée';

  @override
  String get ptEmptyHint => 'Enregistrez vos prières pour voir l’aperçu ici';

  @override
  String get ptGoalDialogTitle => 'Votre objectif quotidien';

  @override
  String get ptGoalDialogHint => 'Prières requises par jour';

  @override
  String get ptSave => 'Enregistrer';

  @override
  String get ptTotalPrayers => 'Total des prières';

  @override
  String get ptOnTimeRate => 'Assiduité';

  @override
  String get ptTotalPoints => 'Total des points';

  @override
  String get ptHowPrayed => 'Comment avez-vous prié ?';

  @override
  String get ptOptTakbeer => 'Takbir d’ouverture';

  @override
  String get ptOptMosque => 'À la mosquée';

  @override
  String get ptOptJamaa => 'En groupe';

  @override
  String get ptOptOnTime => 'À l’heure, seul';

  @override
  String get ptOptLate => 'Après l’heure';

  @override
  String get ptOptMissed => 'Manquée';

  @override
  String get ptClearEntry => 'Effacer';

  @override
  String ptPointsNum(int points) {
    return '+$points pts';
  }

  @override
  String get ptDetails => 'Détails';

  @override
  String get ptBasedOn30 => 'Basé sur les 30 derniers jours';

  @override
  String get ptHowItWorks => 'Comment ça marche';

  @override
  String get ptStages => 'Étapes';

  @override
  String get ptStagesHint => 'Points requis pour chaque niveau';

  @override
  String get ptContext => 'Contexte';

  @override
  String get ptContextHint => 'Les règles diffèrent et influencent le score';

  @override
  String get ptMan => 'Homme';

  @override
  String get ptWoman => 'Femme';

  @override
  String get ptPointsInApp => 'Points dans l’app';

  @override
  String get ptOptionMeanings => 'Signification des options';

  @override
  String get ptMultipliers => 'Multiplicateurs';

  @override
  String get ptMultipliersHint => 'Plus d’effort, plus de points';

  @override
  String ptPointsCount(int points) {
    return '$points pts';
  }

  @override
  String get ptMeanTakbeer => 'A rejoint le takbir d’ouverture avec l’imam';

  @override
  String get ptMeanMosque => 'Prié à la mosquée';

  @override
  String get ptMeanJamaa => 'Prié en groupe hors mosquée';

  @override
  String get ptMeanOnTime => 'Prié à l’heure, seul';

  @override
  String get ptMeanLate => 'Rattrapée après l’heure';

  @override
  String get ptMeanMissed => 'Manquée entièrement';

  @override
  String get ptOnboardTitle => 'Suivez vos prières';

  @override
  String get ptOnboardHint =>
      'Gardez votre régularité, créez des habitudes porteuses de sens et rapprochez-vous dans votre adoration quotidienne';

  @override
  String get ptOnboardF1T => 'Enregistrez chaque prière en un geste';

  @override
  String get ptOnboardF1D =>
      'D’un simple geste, enregistrez votre prière et restez suivi';

  @override
  String get ptOnboardF2T => 'Choisissez comment vous avez prié';

  @override
  String get ptOnboardF2D =>
      'Dites comment vous avez prié — takbir, groupe ou à l’heure';

  @override
  String get ptOnboardF3T => 'Rappels intelligents';

  @override
  String get ptOnboardF3D =>
      'Ne manquez aucune prière — nous vous rappellerons pour l’enregistrer';

  @override
  String get ptOnboardAccept => 'Oui, je suis partant !';

  @override
  String get ptOnboardLater => 'Pas maintenant';

  @override
  String get ptMenuSettings => 'Paramètres du suivi';

  @override
  String get ptMenuReplay => 'Configuration initiale';

  @override
  String get ptMenuWidget => 'Ajouter un widget';

  @override
  String get ptMenuDisable => 'Suspendre le suivi';

  @override
  String get ptMenuEnable => 'Reprendre le suivi';

  @override
  String get ptMenuClear => 'Effacer les données';

  @override
  String get ptClearTitle => 'Effacer les données ?';

  @override
  String get ptClearHint =>
      'Toutes les prières et séries seront supprimées. Irréversible.';

  @override
  String get ptDelete => 'Supprimer';

  @override
  String get ptWidgetTitle => 'Ajouter le widget';

  @override
  String get ptWidgetHint =>
      'Depuis l’accueil : appui long sur un espace vide, puis Widgets, puis choisissez Husn el-Muslim';

  @override
  String get ptPausedTitle => 'Suivi suspendu';

  @override
  String get ptPausedHint => 'Les prières ne compteront pas jusqu’à la reprise';

  @override
  String get ptResume => 'Reprendre';

  @override
  String get ptRemindTitle => 'Rappel d’enregistrement';

  @override
  String ptRemindBody(String prayer) {
    return '$prayer n’est pas encore enregistrée — faites-le maintenant';
  }

  @override
  String get ptRemindToggle => 'Rappels d’enregistrement';

  @override
  String get ptRemindHint => 'Me rappeler en cas d’oubli d’enregistrement';

  @override
  String get diagFivePrayer => 'Suivi des cinq prières';
}
