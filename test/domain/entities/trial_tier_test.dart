import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';

void main() {
  test('trial tier and its Live quota are read from entitlements', () {
    final e = EntitlementsEntity.fromJson({
      'tier': 'trial_premium',
      'entitlements': {'live': true, 'photo': true, 'chat': true},
      'live': {
        'type': 'window',
        'windows': [
          {'window': 'month', 'limit': 300, 'used': 60, 'remaining': 240},
        ],
      },
    });

    expect(e.tier, AppTier.trialPremium);
    expect(e.entitlements.live, isTrue);
    expect(e.liveQuota.limit, 300);
    expect(e.liveQuota.remaining, 240);
  });

  test('every backend tier name maps to its plan', () {
    expect(tierFromString('trial_standard'), AppTier.trialStandard);
    expect(tierFromString('trial_premium'), AppTier.trialPremium);
    expect(tierFromString('premium'), AppTier.premium);
    expect(tierFromString('unknown'), AppTier.free);
  });

  test('a used-up trial is told apart from the monthly limit', () {
    const trial = QuotaExceededException(
      'x',
      window: 'month',
      tier: 'trial_premium',
    );
    const premium = QuotaExceededException(
      'x',
      window: 'month',
      tier: 'premium',
    );

    expect(trial.isTrial, isTrue);
    expect(premium.isTrial, isFalse);
  });
}
