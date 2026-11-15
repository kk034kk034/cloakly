import 'package:cloakly_mobile/services/hosted_plan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PlanRowPhase { loading, ready, failed, unavailable }

/// zh-Hant is the product default. English follows the device locale.
class AccountCopy {
  const AccountCopy.zh() : english = false;

  const AccountCopy.en() : english = true;

  factory AccountCopy.of(BuildContext context) {
    return AccountCopy.forLocale(Localizations.localeOf(context));
  }

  static AccountCopy forLocale(Locale locale) {
    return locale.languageCode == 'en'
        ? const AccountCopy.en()
        : const AccountCopy.zh();
  }

  final bool english;

  static const privacyUrlZh =
      'https://kk034kk034.github.io/cloakly/legal/privacy.zh-TW.html';
  static const privacyUrlEn =
      'https://kk034kk034.github.io/cloakly/legal/privacy.en.html';
  static const termsUrlZh =
      'https://kk034kk034.github.io/cloakly/legal/terms.zh-TW.html';
  static const termsUrlEn =
      'https://kk034kk034.github.io/cloakly/legal/terms.en.html';

  String get accountTitle => english ? 'Account & Subscription' : '帳號與訂閱';

  String get currentPlan => english ? 'Current plan' : '目前方案';

  String get refresh => english ? 'Refresh' : '重新整理';

  String get emailMissing => english ? 'Email not provided' : '未提供 Email';

  String get signOut => english ? 'Log out' : '登出';

  String get deleteAccount => english ? 'Delete account' : '刪除帳號';

  String get free => english ? 'Free' : '免費';

  String get planLoadFailed => english ? "Couldn't load" : '無法載入';

  String get planNotConfigured => english ? 'Not set up' : '尚未設定';

  String get billingUnavailable => english
      ? 'The RevenueCat public SDK key is not set, so subscriptions cannot be shown or purchased.'
      : '尚未設定 RevenueCat 公開 SDK key，因此目前不能顯示或購買訂閱。';

  String get proActiveHint => english
      ? 'Pro is already active. If you change devices, tap Restore Purchases below.'
      : '目前已有有效 Pro 權益。若換機，可按下方「恢復購買」。';

  String get freePlanSummary => english
      ? "Free plan: 30 minutes of meetings per day in total; 5 project questions and 5 plan suggestions. One phone can use only one account's free allowance per day."
      : '免費方案：會議每天合計 30 分鐘；專案問答 5 次、計畫建議 5 次。同一支手機每天只能使用一個帳號的免費額度。';

  String noOfferings(bool ios) {
    final store = ios ? 'App Store' : 'Google Play';
    return english
        ? 'No plans are available to purchase yet. In RevenueCat, add $store products to the Current Offering.'
        : '還沒有可購買的方案。請到 RevenueCat 的 Current Offering，加入 $store 商品。';
  }

  String get restorePurchases => english ? 'Restore Purchases' : '恢復購買';

  String get manageSubscription => english ? 'Manage Subscription' : '管理商店訂閱';

  String get restoreSuccess =>
      english ? 'Pro purchases restored.' : '已恢復 Pro 購買。';

  String get restoreEmpty =>
      english ? 'No Pro purchase was found to restore.' : '沒有找到可恢復的 Pro 購買。';

  String purchaseFailed(Object error) =>
      english ? 'Purchase did not finish: $error' : '購買未完成：$error';

  String restoreFailed(Object error) =>
      english ? 'Could not restore purchases: $error' : '無法恢復購買：$error';

  String get manageFailed => english
      ? 'Could not open the store subscription page. Cancel it in Google Play or the App Store under payments and subscriptions.'
      : '無法開啟商店訂閱頁。請到 Google Play 或 App Store 的「付款與訂閱」取消。';

  String get linkFailed => english ? 'Could not open the link.' : '無法開啟連結。';

  String get privacyLabel => english ? 'Privacy Policy' : '隱私權政策';

  String get termsLabel => english ? 'Terms of Use (EULA)' : '使用條款（EULA）';

  String get privacyUrl => english ? privacyUrlEn : privacyUrlZh;

  String get termsUrl => english ? termsUrlEn : termsUrlZh;

  String get autoRenewDisclosure => english
      ? 'Cloakly Pro is an auto-renewable subscription. Monthly: USD 19.99 per month, length 1 month. Yearly: USD 199.99 per year, length 1 year. The price and length on each plan are the subscription you are buying. Prices in US dollars are listed here; before you confirm, the store shows your region\'s price, tax, and currency. The subscription renews unless you cancel at least 24 hours before the end of the current period, and the renewal is charged within 24 hours before the period ends. On iOS, manage or cancel in Settings > Apple ID > Subscriptions. On Android, use Google Play > Payments and subscriptions. If the store offers a free trial, buying a paid subscription forfeits the unused trial where that store\'s rule applies. Deleting the Cloakly account, signing out, or uninstalling does not cancel the subscription and does not refund a charge.'
      : 'Cloakly Pro 是自動續訂訂閱。月繳：USD 19.99／月，期間 1 個月。年繳：USD 199.99／年，期間 1 年。每個方案上的價格與期間就是這次訂閱的價格與長度。這裡列出的是美元價格；確認購買前，商店會顯示你所在地區的價格、稅與幣別。除非你在目前週期結束前至少 24 小時取消，否則訂閱會自動續約，並在週期結束前 24 小時內扣款。iOS 請到「設定 > Apple ID > 訂閱」管理或取消；Android 請到 Google Play 的「付款與訂閱」。若商店提供免費試用，在該商店規則適用時，購買付費訂閱會放棄未使用的試用。刪除 Cloakly 帳號、登出或卸載 App 都不會取消訂閱，也不會自動退款。';

  String planTitle(bool isPro) {
    if (english) return isPro ? 'Current plan: Pro' : 'Current plan: Free';
    return isPro ? '目前方案：Pro' : '目前方案：免費';
  }

  String validUntil(DateTime expires) {
    final formatted = DateFormat('yyyy/MM/dd HH:mm').format(expires.toLocal());
    return english ? 'Valid until $formatted' : '有效至 $formatted';
  }

  String get lifetimePro => english ? 'Lifetime Pro access' : '永久 Pro 權益';

  String productLine(String productId) =>
      english ? 'Product: $productId' : '商品：$productId';

  String rowStatus({
    required PlanRowPhase phase,
    required bool isPro,
    HostedPlanSnapshot? plan,
  }) {
    switch (phase) {
      case PlanRowPhase.loading:
        return '';
      case PlanRowPhase.failed:
        return planLoadFailed;
      case PlanRowPhase.unavailable:
        return planNotConfigured;
      case PlanRowPhase.ready:
        if (isPro) {
          final expires = plan?.expiresAt;
          if (expires != null) {
            final date = DateFormat('yyyy/MM/dd').format(expires.toLocal());
            return english ? 'Pro · Valid until $date' : 'Pro · 有效至 $date';
          }
          if (plan != null) return english ? 'Pro · Lifetime' : 'Pro · 永久';
          return 'Pro';
        }
        if (plan == null) return free;
        return _freeWithRemaining(plan.remainingFreeSeconds);
    }
  }

  String _freeWithRemaining(int seconds) {
    final safe = seconds.clamp(0, hostedFreeDailyLimitSeconds);
    final minutes = safe ~/ 60;
    final remainder = safe % 60;
    if (english) {
      if (minutes == 0) return 'Free · $remainder sec left today';
      if (remainder == 0) return 'Free · $minutes min left today';
      return 'Free · $minutes min $remainder sec left today';
    }
    if (minutes == 0) return '免費 · 今日剩餘 $remainder 秒';
    if (remainder == 0) return '免費 · 今日剩餘 $minutes 分鐘';
    return '免費 · 今日剩餘 $minutes 分 $remainder 秒';
  }

  String get deleteNeedsEmail => english
      ? "This account has no email, so it can't be deleted here."
      : '此帳號沒有 Email，無法在這裡刪除。';

  String get deleteIntro => english
      ? 'This cannot be undone. The cloud account and subscription entitlement records are deleted. Free time this email already used today stays until the end of today, and a new sign-up continues from that usage. Meetings, transcripts, and projects on this phone stay on the device.'
      : '刪除後無法復原。雲端帳號與訂閱權益紀錄會刪除。'
            '同一個 Email 今天已使用的免費時間會保留到今天結束，重新註冊會接著計算。'
            '這台手機上的會議、逐字稿與專案會留在裝置裡。';

  String get deleteStoreWarning => english
      ? 'Cancel the Google Play or App Store subscription in the store. After the Cloakly account is deleted, the store can still renew the next period, and it does not refund the charge.'
      : 'Google Play 或 App Store 的訂閱要另外到商店取消。'
            '刪除 Cloakly 帳號後，商店仍可能在下一期續扣，也不會自動退款。';

  String get deleteAcknowledge => english
      ? 'I understand I must cancel the subscription in the store separately'
      : '我了解必須另外到商店取消訂閱';

  String get deletePasswordLabel =>
      english ? 'Enter password to confirm' : '輸入密碼以確認';

  String get cancel => english ? 'Cancel' : '取消';

  String get wrongPassword => english
      ? 'Wrong password. The account was not deleted.'
      : '密碼不正確，帳號尚未刪除。';

  String deleteFailed(Object error) =>
      english ? 'Could not delete the account: $error' : '無法刪除帳號：$error';

  String get deleteConfirmationMismatch => english
      ? 'Confirmation did not match. The account was not deleted.'
      : '確認資料不一致，帳號尚未刪除。';

  String get deleteAuthExpired => english
      ? 'Your session expired. Sign in again, then delete the account.'
      : '登入已失效，請重新登入後再刪除。';

  String get deleteIncomplete => english
      ? 'Deletion did not finish. Try again. The account may still be there.'
      : '刪除尚未完成，請再試一次。帳號可能還在。';

  String get deleteNotDeployed => english
      ? 'Account deletion is not deployed yet. The account was not deleted.'
      : '後端尚未部署刪除帳號，帳號尚未刪除。';

  String deleteFailedStatus(int status) => english
      ? 'Could not delete the account ($status). The account was not deleted.'
      : '無法刪除帳號（$status）。帳號尚未刪除。';
}
