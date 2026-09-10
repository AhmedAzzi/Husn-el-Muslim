import 'package:flutter/widgets.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';
import 'package:small_husn_muslim/l10n/app_localizations_ar.dart';

/// Null-safe localization lookup.
///
/// Falls back to Arabic (the app default and `fallbackLocale`) while the
/// delegates are still loading — e.g. the first frames in widget tests —
/// instead of crashing on a force-unwrap. In production the delegates resolve
/// before meaningful interaction, so the fallback is invisible.
extension L10nX on BuildContext {
  AppLocalizations get loc =>
      AppLocalizations.of(this) ?? AppLocalizationsAr();
}
