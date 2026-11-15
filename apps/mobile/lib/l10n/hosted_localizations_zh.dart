// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'hosted_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class HostedLocalizationsZh extends HostedLocalizations {
  HostedLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get accountTitle => '帳號與訂閱';

  @override
  String get currentPlan => '目前方案';

  @override
  String get refresh => '重新整理';

  @override
  String get emailMissing => '未提供 Email';

  @override
  String get signOut => '登出';

  @override
  String get deleteAccount => '刪除帳號';

  @override
  String get free => '免費';

  @override
  String get planLoadFailed => '無法載入';

  @override
  String get planNotConfigured => '尚未設定';

  @override
  String get billingUnavailable => '尚未設定 RevenueCat 公開 SDK key，因此目前不能顯示或購買訂閱。';

  @override
  String get proActiveHint => '目前已有有效 Pro 權益。若換機，可按下方「恢復購買」。';

  @override
  String get freePlanSummary =>
      '免費方案：會議每天合計 30 分鐘；專案問答 5 次、計畫建議 5 次。同一支手機每天只能使用一個帳號的免費額度。';

  @override
  String noOfferings(String store) {
    return '還沒有可購買的方案。請到 RevenueCat 的 Current Offering，加入 $store 商品。';
  }

  @override
  String get restorePurchases => '恢復購買';

  @override
  String get manageSubscription => '管理商店訂閱';

  @override
  String get restoreSuccess => '已恢復 Pro 購買。';

  @override
  String get restoreEmpty => '沒有找到可恢復的 Pro 購買。';

  @override
  String purchaseFailed(String error) {
    return '購買未完成：$error';
  }

  @override
  String restoreFailed(String error) {
    return '無法恢復購買：$error';
  }

  @override
  String get manageFailed => '無法開啟商店訂閱頁。請到 Google Play 或 App Store 的「付款與訂閱」取消。';

  @override
  String get linkFailed => '無法開啟連結。';

  @override
  String get privacyLabel => '隱私權政策';

  @override
  String get termsLabel => '使用條款（EULA）';

  @override
  String get autoRenewDisclosure =>
      'Cloakly Pro 是自動續訂訂閱。月繳：USD 19.99／月，期間 1 個月。年繳：USD 199.99／年，期間 1 年。每個方案上的價格與期間就是這次訂閱的價格與長度。這裡列出的是美元價格；確認購買前，商店會顯示你所在地區的價格、稅與幣別。除非你在目前週期結束前至少 24 小時取消，否則訂閱會自動續約，並在週期結束前 24 小時內扣款。iOS 請到「設定 > Apple ID > 訂閱」管理或取消；Android 請到 Google Play 的「付款與訂閱」。若商店提供免費試用，在該商店規則適用時，購買付費訂閱會放棄未使用的試用。刪除 Cloakly 帳號、登出或卸載 App 都不會取消訂閱，也不會自動退款。';

  @override
  String get planTitlePro => '目前方案：Pro';

  @override
  String get planTitleFree => '目前方案：免費';

  @override
  String validUntil(String when) {
    return '有效至 $when';
  }

  @override
  String get lifetimePro => '永久 Pro 權益';

  @override
  String productLine(String productId) {
    return '商品：$productId';
  }

  @override
  String proValidUntil(String when) {
    return 'Pro · 有效至 $when';
  }

  @override
  String get proLifetime => 'Pro · 永久';

  @override
  String freeSecondsLeft(int seconds) {
    return '免費 · 今日剩餘 $seconds 秒';
  }

  @override
  String freeMinutesLeft(int minutes) {
    return '免費 · 今日剩餘 $minutes 分鐘';
  }

  @override
  String freeMinutesSecondsLeft(int minutes, int seconds) {
    return '免費 · 今日剩餘 $minutes 分 $seconds 秒';
  }

  @override
  String allowanceSeconds(int seconds) {
    return '今日免費額度剩餘 $seconds 秒';
  }

  @override
  String allowanceMinutes(int minutes) {
    return '今日免費額度剩餘 $minutes 分鐘';
  }

  @override
  String allowanceMinutesSeconds(int minutes, int seconds) {
    return '今日免費額度剩餘 $minutes 分 $seconds 秒';
  }

  @override
  String get deleteNeedsEmail => '此帳號沒有 Email，無法在這裡刪除。';

  @override
  String get deleteIntro =>
      '刪除後無法復原。雲端帳號與訂閱權益紀錄會刪除。同一個 Email 今天已使用的免費時間會保留到今天結束，重新註冊會接著計算。這台手機上的會議、逐字稿與專案會留在裝置裡。';

  @override
  String get deleteStoreWarning =>
      'Google Play 或 App Store 的訂閱要另外到商店取消。刪除 Cloakly 帳號後，商店仍可能在下一期續扣，也不會自動退款。';

  @override
  String get deleteAcknowledge => '我了解必須另外到商店取消訂閱';

  @override
  String get deletePasswordLabel => '輸入密碼以確認';

  @override
  String get wrongPassword => '密碼不正確，帳號尚未刪除。';

  @override
  String deleteFailed(String error) {
    return '無法刪除帳號：$error';
  }

  @override
  String get deleteConfirmationMismatch => '確認資料不一致，帳號尚未刪除。';

  @override
  String get deleteAuthExpired => '登入已失效，請重新登入後再刪除。';

  @override
  String get deleteIncomplete => '刪除尚未完成，請再試一次。帳號可能還在。';

  @override
  String get deleteNotDeployed => '後端尚未部署刪除帳號，帳號尚未刪除。';

  @override
  String deleteFailedStatus(int status) {
    return '無法刪除帳號（$status）。帳號尚未刪除。';
  }

  @override
  String get periodAnnual => '年繳';

  @override
  String get periodSixMonth => '半年繳';

  @override
  String get periodThreeMonth => '季繳';

  @override
  String get periodTwoMonth => '兩個月';

  @override
  String get periodMonthly => '月繳';

  @override
  String get periodWeekly => '週繳';

  @override
  String get periodLifetime => '永久';

  @override
  String get periodSubscription => '訂閱';

  @override
  String get signUpTitle => '建立 Cloakly 帳號';

  @override
  String get signInTitle => '登入 Cloakly';

  @override
  String get password => '密碼';

  @override
  String get hidePassword => '隱藏密碼';

  @override
  String get showPassword => '顯示密碼';

  @override
  String get working => '處理中…';

  @override
  String get signUp => '註冊';

  @override
  String get signIn => '登入';

  @override
  String get switchToSignIn => '已有帳號？登入';

  @override
  String get switchToSignUp => '沒有帳號？註冊';

  @override
  String get credentialsHint => '請輸入 Email，密碼至少 8 個字元。';

  @override
  String connectionFailed(String error) {
    return '無法連線：$error';
  }

  @override
  String get emailNotConfirmed => '請先到信箱點確認信，確認後才能登入。';

  @override
  String get hostedNotConfigured => '手機 Hosted 版尚未設定';

  @override
  String get hostedConfigHelp =>
      '請使用 --dart-define 提供 SUPABASE_URL 和 SUPABASE_PUBLISHABLE_KEY。RevenueCat 金鑰可在完成商店設定後加入。';

  @override
  String get startupFailed => '啟動失敗';

  @override
  String get freePoolExhausted => '今天的免費會議名額已滿，請明天再試或升級 Pro。';

  @override
  String get freeDailyLimit => '今天的免費會議額度已使用完畢。可到帳號與訂閱頁升級 Pro。';

  @override
  String get freeQuestionLimit => '今天的免費專案問答已使用 5 次。';

  @override
  String get freePlanLimit => '今天的免費計畫建議已使用 5 次。';

  @override
  String get deviceFreeAccountInUse => '這支手機今天已經使用過另一個帳號的免費額度。';

  @override
  String get deviceRequired => '無法確認這支手機，請更新 App 後再試。';

  @override
  String get meetingAllowanceRequired => '請先開始今天的會議，或升級 Pro。';

  @override
  String get allowanceReservationFailed => '無法預約會議額度。若剛才開會中斷，請等幾分鐘再試；持續失敗請回報。';

  @override
  String get duplicateClientRequest => '這次會議授權已經送出，請稍後再試。';

  @override
  String get transcriptionNotConfigured => '後端尚未設定轉寫服務。';

  @override
  String get transcriptionProviderFailed => '轉寫服務暫時無法使用，請稍後再試。';

  @override
  String get serverError => '伺服器暫時發生錯誤，請稍後再試。';

  @override
  String hostedFallback(String fallback, String code) {
    return '$fallback（$code）';
  }

  @override
  String get hostedNoAnswer => 'Hosted AI 沒有回傳專案回答';

  @override
  String get hostedNoSuggestion => 'Hosted AI 沒有回傳回答建議';

  @override
  String get hostedNoPlan => 'Hosted AI 沒有回傳 WBS';

  @override
  String hostedFeatureFailed(int status) {
    return '無法完成這個 AI 功能（$status）。';
  }

  @override
  String get hostedBadPayload => 'Hosted API 回傳格式無法解析';

  @override
  String get deviceIdUnreadable => '無法讀取這支手機的識別。';

  @override
  String get meetingAuthTimeout => '取得會議授權逾時';

  @override
  String get meetingAuthCancelled => '已取消會議授權';

  @override
  String get meetingAuthFailed => '無法取得會議授權。';

  @override
  String get noTemporaryKey => '後端沒有回傳 Soniox 短效金鑰';

  @override
  String get sessionNotDeployed => '手機版後端尚未部署 create-meeting-session。';

  @override
  String get sessionSignedOut => '登入已失效，請登出後重新登入。';

  @override
  String get freeAllowanceBlocked => '這次免費額度無法使用。';

  @override
  String get sonioxKeyRejected => 'Soniox 金鑰無效、權限不足，或轉寫服務暫時無法使用。';

  @override
  String get sonioxKeyMissingServer => '後端尚未設定 Soniox API 金鑰。';

  @override
  String meetingAuthStatus(int status) {
    return '無法取得會議授權（$status）。';
  }

  @override
  String get meetingAuthUnreadable => '無法解析會議授權';

  @override
  String get coordinatorNeedsClient =>
      'HostedSessionCoordinator 需要 Supabase 或測試用 invoker';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class HostedLocalizationsZhHant extends HostedLocalizationsZh {
  HostedLocalizationsZhHant() : super('zh_Hant');

  @override
  String get accountTitle => '帳號與訂閱';

  @override
  String get currentPlan => '目前方案';

  @override
  String get refresh => '重新整理';

  @override
  String get emailMissing => '未提供 Email';

  @override
  String get signOut => '登出';

  @override
  String get deleteAccount => '刪除帳號';

  @override
  String get free => '免費';

  @override
  String get planLoadFailed => '無法載入';

  @override
  String get planNotConfigured => '尚未設定';

  @override
  String get billingUnavailable => '尚未設定 RevenueCat 公開 SDK key，因此目前不能顯示或購買訂閱。';

  @override
  String get proActiveHint => '目前已有有效 Pro 權益。若換機，可按下方「恢復購買」。';

  @override
  String get freePlanSummary =>
      '免費方案：會議每天合計 30 分鐘；專案問答 5 次、計畫建議 5 次。同一支手機每天只能使用一個帳號的免費額度。';

  @override
  String noOfferings(String store) {
    return '還沒有可購買的方案。請到 RevenueCat 的 Current Offering，加入 $store 商品。';
  }

  @override
  String get restorePurchases => '恢復購買';

  @override
  String get manageSubscription => '管理商店訂閱';

  @override
  String get restoreSuccess => '已恢復 Pro 購買。';

  @override
  String get restoreEmpty => '沒有找到可恢復的 Pro 購買。';

  @override
  String purchaseFailed(String error) {
    return '購買未完成：$error';
  }

  @override
  String restoreFailed(String error) {
    return '無法恢復購買：$error';
  }

  @override
  String get manageFailed => '無法開啟商店訂閱頁。請到 Google Play 或 App Store 的「付款與訂閱」取消。';

  @override
  String get linkFailed => '無法開啟連結。';

  @override
  String get privacyLabel => '隱私權政策';

  @override
  String get termsLabel => '使用條款（EULA）';

  @override
  String get autoRenewDisclosure =>
      'Cloakly Pro 是自動續訂訂閱。月繳：USD 19.99／月，期間 1 個月。年繳：USD 199.99／年，期間 1 年。每個方案上的價格與期間就是這次訂閱的價格與長度。這裡列出的是美元價格；確認購買前，商店會顯示你所在地區的價格、稅與幣別。除非你在目前週期結束前至少 24 小時取消，否則訂閱會自動續約，並在週期結束前 24 小時內扣款。iOS 請到「設定 > Apple ID > 訂閱」管理或取消；Android 請到 Google Play 的「付款與訂閱」。若商店提供免費試用，在該商店規則適用時，購買付費訂閱會放棄未使用的試用。刪除 Cloakly 帳號、登出或卸載 App 都不會取消訂閱，也不會自動退款。';

  @override
  String get planTitlePro => '目前方案：Pro';

  @override
  String get planTitleFree => '目前方案：免費';

  @override
  String validUntil(String when) {
    return '有效至 $when';
  }

  @override
  String get lifetimePro => '永久 Pro 權益';

  @override
  String productLine(String productId) {
    return '商品：$productId';
  }

  @override
  String proValidUntil(String when) {
    return 'Pro · 有效至 $when';
  }

  @override
  String get proLifetime => 'Pro · 永久';

  @override
  String freeSecondsLeft(int seconds) {
    return '免費 · 今日剩餘 $seconds 秒';
  }

  @override
  String freeMinutesLeft(int minutes) {
    return '免費 · 今日剩餘 $minutes 分鐘';
  }

  @override
  String freeMinutesSecondsLeft(int minutes, int seconds) {
    return '免費 · 今日剩餘 $minutes 分 $seconds 秒';
  }

  @override
  String allowanceSeconds(int seconds) {
    return '今日免費額度剩餘 $seconds 秒';
  }

  @override
  String allowanceMinutes(int minutes) {
    return '今日免費額度剩餘 $minutes 分鐘';
  }

  @override
  String allowanceMinutesSeconds(int minutes, int seconds) {
    return '今日免費額度剩餘 $minutes 分 $seconds 秒';
  }

  @override
  String get deleteNeedsEmail => '此帳號沒有 Email，無法在這裡刪除。';

  @override
  String get deleteIntro =>
      '刪除後無法復原。雲端帳號與訂閱權益紀錄會刪除。同一個 Email 今天已使用的免費時間會保留到今天結束，重新註冊會接著計算。這台手機上的會議、逐字稿與專案會留在裝置裡。';

  @override
  String get deleteStoreWarning =>
      'Google Play 或 App Store 的訂閱要另外到商店取消。刪除 Cloakly 帳號後，商店仍可能在下一期續扣，也不會自動退款。';

  @override
  String get deleteAcknowledge => '我了解必須另外到商店取消訂閱';

  @override
  String get deletePasswordLabel => '輸入密碼以確認';

  @override
  String get wrongPassword => '密碼不正確，帳號尚未刪除。';

  @override
  String deleteFailed(String error) {
    return '無法刪除帳號：$error';
  }

  @override
  String get deleteConfirmationMismatch => '確認資料不一致，帳號尚未刪除。';

  @override
  String get deleteAuthExpired => '登入已失效，請重新登入後再刪除。';

  @override
  String get deleteIncomplete => '刪除尚未完成，請再試一次。帳號可能還在。';

  @override
  String get deleteNotDeployed => '後端尚未部署刪除帳號，帳號尚未刪除。';

  @override
  String deleteFailedStatus(int status) {
    return '無法刪除帳號（$status）。帳號尚未刪除。';
  }

  @override
  String get periodAnnual => '年繳';

  @override
  String get periodSixMonth => '半年繳';

  @override
  String get periodThreeMonth => '季繳';

  @override
  String get periodTwoMonth => '兩個月';

  @override
  String get periodMonthly => '月繳';

  @override
  String get periodWeekly => '週繳';

  @override
  String get periodLifetime => '永久';

  @override
  String get periodSubscription => '訂閱';

  @override
  String get signUpTitle => '建立 Cloakly 帳號';

  @override
  String get signInTitle => '登入 Cloakly';

  @override
  String get password => '密碼';

  @override
  String get hidePassword => '隱藏密碼';

  @override
  String get showPassword => '顯示密碼';

  @override
  String get working => '處理中…';

  @override
  String get signUp => '註冊';

  @override
  String get signIn => '登入';

  @override
  String get switchToSignIn => '已有帳號？登入';

  @override
  String get switchToSignUp => '沒有帳號？註冊';

  @override
  String get credentialsHint => '請輸入 Email，密碼至少 8 個字元。';

  @override
  String connectionFailed(String error) {
    return '無法連線：$error';
  }

  @override
  String get emailNotConfirmed => '請先到信箱點確認信，確認後才能登入。';

  @override
  String get hostedNotConfigured => '手機 Hosted 版尚未設定';

  @override
  String get hostedConfigHelp =>
      '請使用 --dart-define 提供 SUPABASE_URL 和 SUPABASE_PUBLISHABLE_KEY。RevenueCat 金鑰可在完成商店設定後加入。';

  @override
  String get startupFailed => '啟動失敗';

  @override
  String get freePoolExhausted => '今天的免費會議名額已滿，請明天再試或升級 Pro。';

  @override
  String get freeDailyLimit => '今天的免費會議額度已使用完畢。可到帳號與訂閱頁升級 Pro。';

  @override
  String get freeQuestionLimit => '今天的免費專案問答已使用 5 次。';

  @override
  String get freePlanLimit => '今天的免費計畫建議已使用 5 次。';

  @override
  String get deviceFreeAccountInUse => '這支手機今天已經使用過另一個帳號的免費額度。';

  @override
  String get deviceRequired => '無法確認這支手機，請更新 App 後再試。';

  @override
  String get meetingAllowanceRequired => '請先開始今天的會議，或升級 Pro。';

  @override
  String get allowanceReservationFailed => '無法預約會議額度。若剛才開會中斷，請等幾分鐘再試；持續失敗請回報。';

  @override
  String get duplicateClientRequest => '這次會議授權已經送出，請稍後再試。';

  @override
  String get transcriptionNotConfigured => '後端尚未設定轉寫服務。';

  @override
  String get transcriptionProviderFailed => '轉寫服務暫時無法使用，請稍後再試。';

  @override
  String get serverError => '伺服器暫時發生錯誤，請稍後再試。';

  @override
  String hostedFallback(String fallback, String code) {
    return '$fallback（$code）';
  }

  @override
  String get hostedNoAnswer => 'Hosted AI 沒有回傳專案回答';

  @override
  String get hostedNoSuggestion => 'Hosted AI 沒有回傳回答建議';

  @override
  String get hostedNoPlan => 'Hosted AI 沒有回傳 WBS';

  @override
  String hostedFeatureFailed(int status) {
    return '無法完成這個 AI 功能（$status）。';
  }

  @override
  String get hostedBadPayload => 'Hosted API 回傳格式無法解析';

  @override
  String get deviceIdUnreadable => '無法讀取這支手機的識別。';

  @override
  String get meetingAuthTimeout => '取得會議授權逾時';

  @override
  String get meetingAuthCancelled => '已取消會議授權';

  @override
  String get meetingAuthFailed => '無法取得會議授權。';

  @override
  String get noTemporaryKey => '後端沒有回傳 Soniox 短效金鑰';

  @override
  String get sessionNotDeployed => '手機版後端尚未部署 create-meeting-session。';

  @override
  String get sessionSignedOut => '登入已失效，請登出後重新登入。';

  @override
  String get freeAllowanceBlocked => '這次免費額度無法使用。';

  @override
  String get sonioxKeyRejected => 'Soniox 金鑰無效、權限不足，或轉寫服務暫時無法使用。';

  @override
  String get sonioxKeyMissingServer => '後端尚未設定 Soniox API 金鑰。';

  @override
  String meetingAuthStatus(int status) {
    return '無法取得會議授權（$status）。';
  }

  @override
  String get meetingAuthUnreadable => '無法解析會議授權';

  @override
  String get coordinatorNeedsClient =>
      'HostedSessionCoordinator 需要 Supabase 或測試用 invoker';
}
