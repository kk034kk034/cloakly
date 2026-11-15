// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'hosted_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class HostedLocalizationsEn extends HostedLocalizations {
  HostedLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountTitle => 'Account & Subscription';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get refresh => 'Refresh';

  @override
  String get emailMissing => 'Email not provided';

  @override
  String get signOut => 'Log out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get free => 'Free';

  @override
  String get planLoadFailed => 'Couldn\'t load';

  @override
  String get planNotConfigured => 'Not set up';

  @override
  String get billingUnavailable =>
      'The RevenueCat public SDK key is not set, so subscriptions cannot be shown or purchased.';

  @override
  String get proActiveHint =>
      'Pro is already active. If you change devices, tap Restore Purchases below.';

  @override
  String get freePlanSummary =>
      'Free plan: 30 minutes of meetings per day in total; 5 project questions and 5 plan suggestions. One phone can use only one account\'s free allowance per day.';

  @override
  String noOfferings(String store) {
    return 'No plans are available to purchase yet. In RevenueCat, add $store products to the Current Offering.';
  }

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get restoreSuccess => 'Pro purchases restored.';

  @override
  String get restoreEmpty => 'No Pro purchase was found to restore.';

  @override
  String purchaseFailed(String error) {
    return 'Purchase did not finish: $error';
  }

  @override
  String restoreFailed(String error) {
    return 'Could not restore purchases: $error';
  }

  @override
  String get manageFailed =>
      'Could not open the store subscription page. Cancel it in Google Play or the App Store under payments and subscriptions.';

  @override
  String get linkFailed => 'Could not open the link.';

  @override
  String get privacyLabel => 'Privacy Policy';

  @override
  String get termsLabel => 'Terms of Use (EULA)';

  @override
  String get autoRenewDisclosure =>
      'Cloakly Pro is an auto-renewable subscription. Monthly: USD 19.99 per month, length 1 month. Yearly: USD 199.99 per year, length 1 year. The price and length on each plan are the subscription you are buying. Prices in US dollars are listed here; before you confirm, the store shows your region\'s price, tax, and currency. The subscription renews unless you cancel at least 24 hours before the end of the current period, and the renewal is charged within 24 hours before the period ends. On iOS, manage or cancel in Settings > Apple ID > Subscriptions. On Android, use Google Play > Payments and subscriptions. If the store offers a free trial, buying a paid subscription forfeits the unused trial where that store\'s rule applies. Deleting the Cloakly account, signing out, or uninstalling does not cancel the subscription and does not refund a charge.';

  @override
  String get planTitlePro => 'Current plan: Pro';

  @override
  String get planTitleFree => 'Current plan: Free';

  @override
  String validUntil(String when) {
    return 'Valid until $when';
  }

  @override
  String get lifetimePro => 'Lifetime Pro access';

  @override
  String productLine(String productId) {
    return 'Product: $productId';
  }

  @override
  String proValidUntil(String when) {
    return 'Pro · Valid until $when';
  }

  @override
  String get proLifetime => 'Pro · Lifetime';

  @override
  String freeSecondsLeft(int seconds) {
    return 'Free · $seconds sec left today';
  }

  @override
  String freeMinutesLeft(int minutes) {
    return 'Free · $minutes min left today';
  }

  @override
  String freeMinutesSecondsLeft(int minutes, int seconds) {
    return 'Free · $minutes min $seconds sec left today';
  }

  @override
  String allowanceSeconds(int seconds) {
    return '$seconds seconds of free time left today';
  }

  @override
  String allowanceMinutes(int minutes) {
    return '$minutes minutes of free time left today';
  }

  @override
  String allowanceMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds sec of free time left today';
  }

  @override
  String get deleteNeedsEmail =>
      'This account has no email, so it can\'t be deleted here.';

  @override
  String get deleteIntro =>
      'This cannot be undone. The cloud account and subscription entitlement records are deleted. Free time this email already used today stays until the end of today, and a new sign-up continues from that usage. Meetings, transcripts, and projects on this phone stay on the device.';

  @override
  String get deleteStoreWarning =>
      'Cancel the Google Play or App Store subscription in the store. After the Cloakly account is deleted, the store can still renew the next period, and it does not refund the charge.';

  @override
  String get deleteAcknowledge =>
      'I understand I must cancel the subscription in the store separately';

  @override
  String get deletePasswordLabel => 'Enter password to confirm';

  @override
  String get wrongPassword => 'Wrong password. The account was not deleted.';

  @override
  String deleteFailed(String error) {
    return 'Could not delete the account: $error';
  }

  @override
  String get deleteConfirmationMismatch =>
      'Confirmation did not match. The account was not deleted.';

  @override
  String get deleteAuthExpired =>
      'Your session expired. Sign in again, then delete the account.';

  @override
  String get deleteIncomplete =>
      'Deletion did not finish. Try again. The account may still be there.';

  @override
  String get deleteNotDeployed =>
      'Account deletion is not deployed yet. The account was not deleted.';

  @override
  String deleteFailedStatus(int status) {
    return 'Could not delete the account ($status). The account was not deleted.';
  }

  @override
  String get periodAnnual => 'Yearly';

  @override
  String get periodSixMonth => '6 months';

  @override
  String get periodThreeMonth => '3 months';

  @override
  String get periodTwoMonth => '2 months';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get periodWeekly => 'Weekly';

  @override
  String get periodLifetime => 'Lifetime';

  @override
  String get periodSubscription => 'Subscription';

  @override
  String get signUpTitle => 'Create a Cloakly account';

  @override
  String get signInTitle => 'Sign in to Cloakly';

  @override
  String get password => 'Password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get showPassword => 'Show password';

  @override
  String get working => 'Working…';

  @override
  String get signUp => 'Sign up';

  @override
  String get signIn => 'Sign in';

  @override
  String get switchToSignIn => 'Already have an account? Sign in';

  @override
  String get switchToSignUp => 'No account yet? Sign up';

  @override
  String get credentialsHint =>
      'Enter an email. The password must be at least 8 characters.';

  @override
  String connectionFailed(String error) {
    return 'Couldn\'t connect: $error';
  }

  @override
  String get emailNotConfirmed =>
      'Open the confirmation email and confirm it before you sign in.';

  @override
  String get hostedNotConfigured => 'The hosted phone build is not configured';

  @override
  String get hostedConfigHelp =>
      'Pass SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY with --dart-define. The RevenueCat key can be added after the store is set up.';

  @override
  String get startupFailed => 'Couldn\'t start';

  @override
  String get freePoolExhausted =>
      'Today\'s free meeting slots are full. Try again tomorrow, or upgrade to Pro.';

  @override
  String get freeDailyLimit =>
      'Today\'s free meeting allowance is used up. You can upgrade to Pro on the account and subscription page.';

  @override
  String get freeQuestionLimit =>
      'Today\'s 5 free project questions are used up.';

  @override
  String get freePlanLimit => 'Today\'s 5 free plan suggestions are used up.';

  @override
  String get deviceFreeAccountInUse =>
      'This phone already used another account\'s free allowance today.';

  @override
  String get deviceRequired =>
      'This phone could not be confirmed. Update the app and try again.';

  @override
  String get meetingAllowanceRequired =>
      'Start today\'s meeting first, or upgrade to Pro.';

  @override
  String get allowanceReservationFailed =>
      'Couldn\'t reserve meeting time. If a meeting was just interrupted, wait a few minutes and try again. If it keeps failing, report it.';

  @override
  String get duplicateClientRequest =>
      'This meeting authorization was already sent. Try again shortly.';

  @override
  String get transcriptionNotConfigured =>
      'Transcription is not configured on the server yet.';

  @override
  String get transcriptionProviderFailed =>
      'Transcription is temporarily unavailable. Try again shortly.';

  @override
  String get serverError =>
      'The server hit a temporary error. Try again shortly.';

  @override
  String hostedFallback(String fallback, String code) {
    return '$fallback ($code)';
  }

  @override
  String get hostedNoAnswer => 'Hosted AI did not return a project answer';

  @override
  String get hostedNoSuggestion =>
      'Hosted AI did not return an answer suggestion';

  @override
  String get hostedNoPlan => 'Hosted AI did not return a plan';

  @override
  String hostedFeatureFailed(int status) {
    return 'This AI feature could not finish ($status).';
  }

  @override
  String get hostedBadPayload => 'The hosted API response could not be read';

  @override
  String get deviceIdUnreadable =>
      'This phone\'s identifier could not be read.';

  @override
  String get meetingAuthTimeout => 'Getting meeting access timed out';

  @override
  String get meetingAuthCancelled => 'Meeting access was cancelled';

  @override
  String get meetingAuthFailed => 'Couldn\'t get meeting access.';

  @override
  String get noTemporaryKey =>
      'The server did not return a short-lived Soniox key';

  @override
  String get sessionNotDeployed =>
      'The phone backend does not have create-meeting-session deployed yet.';

  @override
  String get sessionSignedOut =>
      'Your session expired. Log out and sign in again.';

  @override
  String get freeAllowanceBlocked => 'This free allowance cannot be used.';

  @override
  String get sonioxKeyRejected =>
      'The Soniox key is invalid, not permitted, or transcription is temporarily unavailable.';

  @override
  String get sonioxKeyMissingServer =>
      'The server does not have a Soniox API key yet.';

  @override
  String meetingAuthStatus(int status) {
    return 'Couldn\'t get meeting access ($status).';
  }

  @override
  String get meetingAuthUnreadable =>
      'The meeting authorization could not be read';

  @override
  String get coordinatorNeedsClient =>
      'HostedSessionCoordinator needs Supabase or a test invoker';
}
