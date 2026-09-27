import 'package:cloakly_mobile/services/hosted_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unconfirmed email auth errors use the login message', () {
    expect(
      hostedAuthErrorMessage('Email not confirmed'),
      unconfirmedEmailMessage,
    );
    expect(hostedAuthErrorMessage('Invalid login credentials'), 'Invalid login credentials');
  });

  test('quota errors explain the free limits', () {
    expect(
      hostedQuotaMessage(
        {'error': 'FREE_POOL_EXHAUSTED'},
        fallback: 'fallback',
      ),
      '今天的免費會議名額已滿，請明天再試或升級 Pro。',
    );
    expect(
      hostedQuotaMessage(
        {'error': 'FREE_QUESTION_LIMIT_REACHED'},
        fallback: 'fallback',
      ),
      '今天的免費專案問答已使用 5 次。',
    );
    expect(
      hostedQuotaMessage(
        {'error': 'DEVICE_FREE_ACCOUNT_IN_USE'},
        fallback: 'fallback',
      ),
      '這支手機今天已經使用過另一個帳號的免費額度。',
    );
    expect(
      hostedQuotaMessage('{"error":"FREE_PLAN_LIMIT_REACHED"}', fallback: 'fallback'),
      '今天的免費計畫建議已使用 5 次。',
    );
    expect(hostedQuotaMessage({'error': 'OTHER'}, fallback: 'fallback'), 'fallback');
  });
}
