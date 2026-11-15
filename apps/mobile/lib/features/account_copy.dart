import 'package:cloakly_core/l10n/app_localizations.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_mobile/l10n/hosted_localizations.dart';
import 'package:cloakly_mobile/services/hosted_plan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PlanRowPhase { loading, ready, failed, unavailable }

/// zh-Hant is the product default. English follows the resolved locale:
/// any zh* locale stays Chinese, and every other language uses English.
class AccountCopy {
  AccountCopy.zh()
    : english = false,
      _hosted = lookupHostedLocalizations(cloaklyZhHant);

  AccountCopy.en()
    : english = true,
      _hosted = lookupHostedLocalizations(cloaklyEn);

  factory AccountCopy.of(BuildContext context) {
    return AccountCopy.forLocale(Localizations.localeOf(context));
  }

  static AccountCopy forLocale(Locale locale) {
    final resolved = resolveCloaklyLocale(
      locale,
      HostedLocalizations.supportedLocales,
    );
    return resolved.languageCode == 'en' ? AccountCopy.en() : AccountCopy.zh();
  }

  final bool english;
  final HostedLocalizations _hosted;

  static const privacyUrlZh =
      'https://kk034kk034.github.io/cloakly/legal/privacy.zh-TW.html';
  static const privacyUrlEn =
      'https://kk034kk034.github.io/cloakly/legal/privacy.en.html';
  static const termsUrlZh =
      'https://kk034kk034.github.io/cloakly/legal/terms.zh-TW.html';
  static const termsUrlEn =
      'https://kk034kk034.github.io/cloakly/legal/terms.en.html';

  String get accountTitle => _hosted.accountTitle;

  String get currentPlan => _hosted.currentPlan;

  String get refresh => _hosted.refresh;

  String get emailMissing => _hosted.emailMissing;

  String get signOut => _hosted.signOut;

  String get deleteAccount => _hosted.deleteAccount;

  String get free => _hosted.free;

  String get planLoadFailed => _hosted.planLoadFailed;

  String get planNotConfigured => _hosted.planNotConfigured;

  String get billingUnavailable => _hosted.billingUnavailable;

  String get proActiveHint => _hosted.proActiveHint;

  String get freePlanSummary => _hosted.freePlanSummary;

  String noOfferings(bool ios) {
    final store = ios ? 'App Store' : 'Google Play';
    return _hosted.noOfferings(store);
  }

  String get restorePurchases => _hosted.restorePurchases;

  String get manageSubscription => _hosted.manageSubscription;

  String get restoreSuccess => _hosted.restoreSuccess;

  String get restoreEmpty => _hosted.restoreEmpty;

  String purchaseFailed(Object error) => _hosted.purchaseFailed('$error');

  String restoreFailed(Object error) => _hosted.restoreFailed('$error');

  String get manageFailed => _hosted.manageFailed;

  String get linkFailed => _hosted.linkFailed;

  String get privacyLabel => _hosted.privacyLabel;

  String get termsLabel => _hosted.termsLabel;

  String get privacyUrl => english ? privacyUrlEn : privacyUrlZh;

  String get termsUrl => english ? termsUrlEn : termsUrlZh;

  String get autoRenewDisclosure => _hosted.autoRenewDisclosure;

  String planTitle(bool isPro) =>
      isPro ? _hosted.planTitlePro : _hosted.planTitleFree;

  String validUntil(DateTime expires) {
    final formatted = DateFormat('yyyy/MM/dd HH:mm').format(expires.toLocal());
    return _hosted.validUntil(formatted);
  }

  String get lifetimePro => _hosted.lifetimePro;

  String productLine(String productId) => _hosted.productLine(productId);

  String rowStatus({
    required PlanRowPhase phase,
    required bool isPro,
    HostedPlanSnapshot? plan,
  }) {
    switch (phase) {
      case PlanRowPhase.loading:
        return '';
      case PlanRowPhase.failed:
        return _hosted.planLoadFailed;
      case PlanRowPhase.unavailable:
        return _hosted.planNotConfigured;
      case PlanRowPhase.ready:
        if (isPro) {
          final expires = plan?.expiresAt;
          if (expires != null) {
            final date = DateFormat('yyyy/MM/dd').format(expires.toLocal());
            return _hosted.proValidUntil(date);
          }
          if (plan != null) return _hosted.proLifetime;
          return 'Pro';
        }
        if (plan == null) return _hosted.free;
        return _freeWithRemaining(plan.remainingFreeSeconds);
    }
  }

  String _freeWithRemaining(int seconds) {
    final safe = seconds.clamp(0, hostedFreeDailyLimitSeconds);
    final minutes = safe ~/ 60;
    final remainder = safe % 60;
    if (minutes == 0) return _hosted.freeSecondsLeft(remainder);
    if (remainder == 0) return _hosted.freeMinutesLeft(minutes);
    return _hosted.freeMinutesSecondsLeft(minutes, remainder);
  }

  String get deleteNeedsEmail => _hosted.deleteNeedsEmail;

  String get deleteIntro => _hosted.deleteIntro;

  String get deleteStoreWarning => _hosted.deleteStoreWarning;

  String get deleteAcknowledge => _hosted.deleteAcknowledge;

  String get deletePasswordLabel => _hosted.deletePasswordLabel;

  String get cancel =>
      lookupAppLocalizations(english ? cloaklyEn : cloaklyZhHant).cancel;

  String get wrongPassword => _hosted.wrongPassword;

  String deleteFailed(Object error) => _hosted.deleteFailed('$error');

  String get deleteConfirmationMismatch => _hosted.deleteConfirmationMismatch;

  String get deleteAuthExpired => _hosted.deleteAuthExpired;

  String get deleteIncomplete => _hosted.deleteIncomplete;

  String get deleteNotDeployed => _hosted.deleteNotDeployed;

  String deleteFailedStatus(int status) => _hosted.deleteFailedStatus(status);
}
