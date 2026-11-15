import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'hosted_localizations_en.dart';
import 'hosted_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of HostedLocalizations
/// returned by `HostedLocalizations.of(context)`.
///
/// Applications need to include `HostedLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/hosted_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: HostedLocalizations.localizationsDelegates,
///   supportedLocales: HostedLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the HostedLocalizations.supportedLocales
/// property.
abstract class HostedLocalizations {
  HostedLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static HostedLocalizations of(BuildContext context) {
    return Localizations.of<HostedLocalizations>(context, HostedLocalizations)!;
  }

  static const LocalizationsDelegate<HostedLocalizations> delegate =
      _HostedLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @accountTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'帳號與訂閱'**
  String get accountTitle;

  /// No description provided for @currentPlan.
  ///
  /// In zh_Hant, this message translates to:
  /// **'目前方案'**
  String get currentPlan;

  /// No description provided for @refresh.
  ///
  /// In zh_Hant, this message translates to:
  /// **'重新整理'**
  String get refresh;

  /// No description provided for @emailMissing.
  ///
  /// In zh_Hant, this message translates to:
  /// **'未提供 Email'**
  String get emailMissing;

  /// No description provided for @signOut.
  ///
  /// In zh_Hant, this message translates to:
  /// **'登出'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In zh_Hant, this message translates to:
  /// **'刪除帳號'**
  String get deleteAccount;

  /// No description provided for @free.
  ///
  /// In zh_Hant, this message translates to:
  /// **'免費'**
  String get free;

  /// No description provided for @planLoadFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法載入'**
  String get planLoadFailed;

  /// No description provided for @planNotConfigured.
  ///
  /// In zh_Hant, this message translates to:
  /// **'尚未設定'**
  String get planNotConfigured;

  /// No description provided for @billingUnavailable.
  ///
  /// In zh_Hant, this message translates to:
  /// **'尚未設定 RevenueCat 公開 SDK key，因此目前不能顯示或購買訂閱。'**
  String get billingUnavailable;

  /// No description provided for @proActiveHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'目前已有有效 Pro 權益。若換機，可按下方「恢復購買」。'**
  String get proActiveHint;

  /// No description provided for @freePlanSummary.
  ///
  /// In zh_Hant, this message translates to:
  /// **'免費方案：會議每天合計 30 分鐘；專案問答 5 次、計畫建議 5 次。同一支手機每天只能使用一個帳號的免費額度。'**
  String get freePlanSummary;

  /// No description provided for @noOfferings.
  ///
  /// In zh_Hant, this message translates to:
  /// **'還沒有可購買的方案。請到 RevenueCat 的 Current Offering，加入 {store} 商品。'**
  String noOfferings(String store);

  /// No description provided for @restorePurchases.
  ///
  /// In zh_Hant, this message translates to:
  /// **'恢復購買'**
  String get restorePurchases;

  /// No description provided for @manageSubscription.
  ///
  /// In zh_Hant, this message translates to:
  /// **'管理商店訂閱'**
  String get manageSubscription;

  /// No description provided for @restoreSuccess.
  ///
  /// In zh_Hant, this message translates to:
  /// **'已恢復 Pro 購買。'**
  String get restoreSuccess;

  /// No description provided for @restoreEmpty.
  ///
  /// In zh_Hant, this message translates to:
  /// **'沒有找到可恢復的 Pro 購買。'**
  String get restoreEmpty;

  /// No description provided for @purchaseFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'購買未完成：{error}'**
  String purchaseFailed(String error);

  /// No description provided for @restoreFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法恢復購買：{error}'**
  String restoreFailed(String error);

  /// No description provided for @manageFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法開啟商店訂閱頁。請到 Google Play 或 App Store 的「付款與訂閱」取消。'**
  String get manageFailed;

  /// No description provided for @linkFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法開啟連結。'**
  String get linkFailed;

  /// No description provided for @privacyLabel.
  ///
  /// In zh_Hant, this message translates to:
  /// **'隱私權政策'**
  String get privacyLabel;

  /// No description provided for @termsLabel.
  ///
  /// In zh_Hant, this message translates to:
  /// **'使用條款（EULA）'**
  String get termsLabel;

  /// No description provided for @autoRenewDisclosure.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Cloakly Pro 是自動續訂訂閱。月繳：USD 19.99／月，期間 1 個月。年繳：USD 199.99／年，期間 1 年。每個方案上的價格與期間就是這次訂閱的價格與長度。這裡列出的是美元價格；確認購買前，商店會顯示你所在地區的價格、稅與幣別。除非你在目前週期結束前至少 24 小時取消，否則訂閱會自動續約，並在週期結束前 24 小時內扣款。iOS 請到「設定 > Apple ID > 訂閱」管理或取消；Android 請到 Google Play 的「付款與訂閱」。若商店提供免費試用，在該商店規則適用時，購買付費訂閱會放棄未使用的試用。刪除 Cloakly 帳號、登出或卸載 App 都不會取消訂閱，也不會自動退款。'**
  String get autoRenewDisclosure;

  /// No description provided for @planTitlePro.
  ///
  /// In zh_Hant, this message translates to:
  /// **'目前方案：Pro'**
  String get planTitlePro;

  /// No description provided for @planTitleFree.
  ///
  /// In zh_Hant, this message translates to:
  /// **'目前方案：免費'**
  String get planTitleFree;

  /// No description provided for @validUntil.
  ///
  /// In zh_Hant, this message translates to:
  /// **'有效至 {when}'**
  String validUntil(String when);

  /// No description provided for @lifetimePro.
  ///
  /// In zh_Hant, this message translates to:
  /// **'永久 Pro 權益'**
  String get lifetimePro;

  /// No description provided for @productLine.
  ///
  /// In zh_Hant, this message translates to:
  /// **'商品：{productId}'**
  String productLine(String productId);

  /// No description provided for @proValidUntil.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Pro · 有效至 {when}'**
  String proValidUntil(String when);

  /// No description provided for @proLifetime.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Pro · 永久'**
  String get proLifetime;

  /// No description provided for @freeSecondsLeft.
  ///
  /// In zh_Hant, this message translates to:
  /// **'免費 · 今日剩餘 {seconds} 秒'**
  String freeSecondsLeft(int seconds);

  /// No description provided for @freeMinutesLeft.
  ///
  /// In zh_Hant, this message translates to:
  /// **'免費 · 今日剩餘 {minutes} 分鐘'**
  String freeMinutesLeft(int minutes);

  /// No description provided for @freeMinutesSecondsLeft.
  ///
  /// In zh_Hant, this message translates to:
  /// **'免費 · 今日剩餘 {minutes} 分 {seconds} 秒'**
  String freeMinutesSecondsLeft(int minutes, int seconds);

  /// No description provided for @allowanceSeconds.
  ///
  /// In zh_Hant, this message translates to:
  /// **'今日免費額度剩餘 {seconds} 秒'**
  String allowanceSeconds(int seconds);

  /// No description provided for @allowanceMinutes.
  ///
  /// In zh_Hant, this message translates to:
  /// **'今日免費額度剩餘 {minutes} 分鐘'**
  String allowanceMinutes(int minutes);

  /// No description provided for @allowanceMinutesSeconds.
  ///
  /// In zh_Hant, this message translates to:
  /// **'今日免費額度剩餘 {minutes} 分 {seconds} 秒'**
  String allowanceMinutesSeconds(int minutes, int seconds);

  /// No description provided for @deleteNeedsEmail.
  ///
  /// In zh_Hant, this message translates to:
  /// **'此帳號沒有 Email，無法在這裡刪除。'**
  String get deleteNeedsEmail;

  /// No description provided for @deleteIntro.
  ///
  /// In zh_Hant, this message translates to:
  /// **'刪除後無法復原。雲端帳號與訂閱權益紀錄會刪除。同一個 Email 今天已使用的免費時間會保留到今天結束，重新註冊會接著計算。這台手機上的會議、逐字稿與專案會留在裝置裡。'**
  String get deleteIntro;

  /// No description provided for @deleteStoreWarning.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Google Play 或 App Store 的訂閱要另外到商店取消。刪除 Cloakly 帳號後，商店仍可能在下一期續扣，也不會自動退款。'**
  String get deleteStoreWarning;

  /// No description provided for @deleteAcknowledge.
  ///
  /// In zh_Hant, this message translates to:
  /// **'我了解必須另外到商店取消訂閱'**
  String get deleteAcknowledge;

  /// No description provided for @deletePasswordLabel.
  ///
  /// In zh_Hant, this message translates to:
  /// **'輸入密碼以確認'**
  String get deletePasswordLabel;

  /// No description provided for @wrongPassword.
  ///
  /// In zh_Hant, this message translates to:
  /// **'密碼不正確，帳號尚未刪除。'**
  String get wrongPassword;

  /// No description provided for @deleteFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法刪除帳號：{error}'**
  String deleteFailed(String error);

  /// No description provided for @deleteConfirmationMismatch.
  ///
  /// In zh_Hant, this message translates to:
  /// **'確認資料不一致，帳號尚未刪除。'**
  String get deleteConfirmationMismatch;

  /// No description provided for @deleteAuthExpired.
  ///
  /// In zh_Hant, this message translates to:
  /// **'登入已失效，請重新登入後再刪除。'**
  String get deleteAuthExpired;

  /// No description provided for @deleteIncomplete.
  ///
  /// In zh_Hant, this message translates to:
  /// **'刪除尚未完成，請再試一次。帳號可能還在。'**
  String get deleteIncomplete;

  /// No description provided for @deleteNotDeployed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'後端尚未部署刪除帳號，帳號尚未刪除。'**
  String get deleteNotDeployed;

  /// No description provided for @deleteFailedStatus.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法刪除帳號（{status}）。帳號尚未刪除。'**
  String deleteFailedStatus(int status);

  /// No description provided for @periodAnnual.
  ///
  /// In zh_Hant, this message translates to:
  /// **'年繳'**
  String get periodAnnual;

  /// No description provided for @periodSixMonth.
  ///
  /// In zh_Hant, this message translates to:
  /// **'半年繳'**
  String get periodSixMonth;

  /// No description provided for @periodThreeMonth.
  ///
  /// In zh_Hant, this message translates to:
  /// **'季繳'**
  String get periodThreeMonth;

  /// No description provided for @periodTwoMonth.
  ///
  /// In zh_Hant, this message translates to:
  /// **'兩個月'**
  String get periodTwoMonth;

  /// No description provided for @periodMonthly.
  ///
  /// In zh_Hant, this message translates to:
  /// **'月繳'**
  String get periodMonthly;

  /// No description provided for @periodWeekly.
  ///
  /// In zh_Hant, this message translates to:
  /// **'週繳'**
  String get periodWeekly;

  /// No description provided for @periodLifetime.
  ///
  /// In zh_Hant, this message translates to:
  /// **'永久'**
  String get periodLifetime;

  /// No description provided for @periodSubscription.
  ///
  /// In zh_Hant, this message translates to:
  /// **'訂閱'**
  String get periodSubscription;

  /// No description provided for @signUpTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'建立 Cloakly 帳號'**
  String get signUpTitle;

  /// No description provided for @signInTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'登入 Cloakly'**
  String get signInTitle;

  /// No description provided for @password.
  ///
  /// In zh_Hant, this message translates to:
  /// **'密碼'**
  String get password;

  /// No description provided for @hidePassword.
  ///
  /// In zh_Hant, this message translates to:
  /// **'隱藏密碼'**
  String get hidePassword;

  /// No description provided for @showPassword.
  ///
  /// In zh_Hant, this message translates to:
  /// **'顯示密碼'**
  String get showPassword;

  /// No description provided for @working.
  ///
  /// In zh_Hant, this message translates to:
  /// **'處理中…'**
  String get working;

  /// No description provided for @signUp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'註冊'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In zh_Hant, this message translates to:
  /// **'登入'**
  String get signIn;

  /// No description provided for @switchToSignIn.
  ///
  /// In zh_Hant, this message translates to:
  /// **'已有帳號？登入'**
  String get switchToSignIn;

  /// No description provided for @switchToSignUp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'沒有帳號？註冊'**
  String get switchToSignUp;

  /// No description provided for @credentialsHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'請輸入 Email，密碼至少 8 個字元。'**
  String get credentialsHint;

  /// No description provided for @connectionFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法連線：{error}'**
  String connectionFailed(String error);

  /// No description provided for @emailNotConfirmed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'請先到信箱點確認信，確認後才能登入。'**
  String get emailNotConfirmed;

  /// No description provided for @hostedNotConfigured.
  ///
  /// In zh_Hant, this message translates to:
  /// **'手機 Hosted 版尚未設定'**
  String get hostedNotConfigured;

  /// No description provided for @hostedConfigHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'請使用 --dart-define 提供 SUPABASE_URL 和 SUPABASE_PUBLISHABLE_KEY。RevenueCat 金鑰可在完成商店設定後加入。'**
  String get hostedConfigHelp;

  /// No description provided for @startupFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'啟動失敗'**
  String get startupFailed;

  /// No description provided for @freePoolExhausted.
  ///
  /// In zh_Hant, this message translates to:
  /// **'今天的免費會議名額已滿，請明天再試或升級 Pro。'**
  String get freePoolExhausted;

  /// No description provided for @freeDailyLimit.
  ///
  /// In zh_Hant, this message translates to:
  /// **'今天的免費會議額度已使用完畢。可到帳號與訂閱頁升級 Pro。'**
  String get freeDailyLimit;

  /// No description provided for @freeQuestionLimit.
  ///
  /// In zh_Hant, this message translates to:
  /// **'今天的免費專案問答已使用 5 次。'**
  String get freeQuestionLimit;

  /// No description provided for @freePlanLimit.
  ///
  /// In zh_Hant, this message translates to:
  /// **'今天的免費計畫建議已使用 5 次。'**
  String get freePlanLimit;

  /// No description provided for @deviceFreeAccountInUse.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這支手機今天已經使用過另一個帳號的免費額度。'**
  String get deviceFreeAccountInUse;

  /// No description provided for @deviceRequired.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法確認這支手機，請更新 App 後再試。'**
  String get deviceRequired;

  /// No description provided for @meetingAllowanceRequired.
  ///
  /// In zh_Hant, this message translates to:
  /// **'請先開始今天的會議，或升級 Pro。'**
  String get meetingAllowanceRequired;

  /// No description provided for @allowanceReservationFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法預約會議額度。若剛才開會中斷，請等幾分鐘再試；持續失敗請回報。'**
  String get allowanceReservationFailed;

  /// No description provided for @duplicateClientRequest.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這次會議授權已經送出，請稍後再試。'**
  String get duplicateClientRequest;

  /// No description provided for @transcriptionNotConfigured.
  ///
  /// In zh_Hant, this message translates to:
  /// **'後端尚未設定轉寫服務。'**
  String get transcriptionNotConfigured;

  /// No description provided for @transcriptionProviderFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'轉寫服務暫時無法使用，請稍後再試。'**
  String get transcriptionProviderFailed;

  /// No description provided for @serverError.
  ///
  /// In zh_Hant, this message translates to:
  /// **'伺服器暫時發生錯誤，請稍後再試。'**
  String get serverError;

  /// No description provided for @hostedFallback.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{fallback}（{code}）'**
  String hostedFallback(String fallback, String code);

  /// No description provided for @hostedNoAnswer.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Hosted AI 沒有回傳專案回答'**
  String get hostedNoAnswer;

  /// No description provided for @hostedNoSuggestion.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Hosted AI 沒有回傳回答建議'**
  String get hostedNoSuggestion;

  /// No description provided for @hostedNoPlan.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Hosted AI 沒有回傳 WBS'**
  String get hostedNoPlan;

  /// No description provided for @hostedFeatureFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法完成這個 AI 功能（{status}）。'**
  String hostedFeatureFailed(int status);

  /// No description provided for @hostedBadPayload.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Hosted API 回傳格式無法解析'**
  String get hostedBadPayload;

  /// No description provided for @deviceIdUnreadable.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法讀取這支手機的識別。'**
  String get deviceIdUnreadable;

  /// No description provided for @meetingAuthTimeout.
  ///
  /// In zh_Hant, this message translates to:
  /// **'取得會議授權逾時'**
  String get meetingAuthTimeout;

  /// No description provided for @meetingAuthCancelled.
  ///
  /// In zh_Hant, this message translates to:
  /// **'已取消會議授權'**
  String get meetingAuthCancelled;

  /// No description provided for @meetingAuthFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法取得會議授權。'**
  String get meetingAuthFailed;

  /// No description provided for @noTemporaryKey.
  ///
  /// In zh_Hant, this message translates to:
  /// **'後端沒有回傳 Soniox 短效金鑰'**
  String get noTemporaryKey;

  /// No description provided for @sessionNotDeployed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'手機版後端尚未部署 create-meeting-session。'**
  String get sessionNotDeployed;

  /// No description provided for @sessionSignedOut.
  ///
  /// In zh_Hant, this message translates to:
  /// **'登入已失效，請登出後重新登入。'**
  String get sessionSignedOut;

  /// No description provided for @freeAllowanceBlocked.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這次免費額度無法使用。'**
  String get freeAllowanceBlocked;

  /// No description provided for @sonioxKeyRejected.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Soniox 金鑰無效、權限不足，或轉寫服務暫時無法使用。'**
  String get sonioxKeyRejected;

  /// No description provided for @sonioxKeyMissingServer.
  ///
  /// In zh_Hant, this message translates to:
  /// **'後端尚未設定 Soniox API 金鑰。'**
  String get sonioxKeyMissingServer;

  /// No description provided for @meetingAuthStatus.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法取得會議授權（{status}）。'**
  String meetingAuthStatus(int status);

  /// No description provided for @meetingAuthUnreadable.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法解析會議授權'**
  String get meetingAuthUnreadable;

  /// No description provided for @coordinatorNeedsClient.
  ///
  /// In zh_Hant, this message translates to:
  /// **'HostedSessionCoordinator 需要 Supabase 或測試用 invoker'**
  String get coordinatorNeedsClient;
}

class _HostedLocalizationsDelegate
    extends LocalizationsDelegate<HostedLocalizations> {
  const _HostedLocalizationsDelegate();

  @override
  Future<HostedLocalizations> load(Locale locale) {
    return SynchronousFuture<HostedLocalizations>(
      lookupHostedLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_HostedLocalizationsDelegate old) => false;
}

HostedLocalizations lookupHostedLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return HostedLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return HostedLocalizationsEn();
    case 'zh':
      return HostedLocalizationsZh();
  }

  throw FlutterError(
    'HostedLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
