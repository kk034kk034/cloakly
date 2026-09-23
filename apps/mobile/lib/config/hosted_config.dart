import 'dart:io';

class HostedConfig {
  const HostedConfig._();

  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _revenueCatAppleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_API_KEY',
  );
  static const _revenueCatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_API_KEY',
  );
  static const _entitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
    defaultValue: 'pro',
  );

  /// Strip BOM / odd whitespace that can sneak in via CI secrets.
  static String _clean(String value) {
    var s = value;
    if (s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF) {
      s = s.substring(1);
    }
    return s.trim();
  }

  static String get supabaseUrl => _clean(_supabaseUrl);
  static String get supabasePublishableKey => _clean(_supabasePublishableKey);
  static String get revenueCatAppleApiKey => _clean(_revenueCatAppleApiKey);
  static String get revenueCatGoogleApiKey => _clean(_revenueCatGoogleApiKey);
  static String get entitlementId {
    final id = _clean(_entitlementId);
    return id.isEmpty ? 'pro' : id;
  }

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static String get revenueCatApiKey {
    if (Platform.isIOS) return revenueCatAppleApiKey;
    if (Platform.isAndroid) return revenueCatGoogleApiKey;
    return '';
  }
}
