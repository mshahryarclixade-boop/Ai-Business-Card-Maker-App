import 'package:ai_business_card_maker/app/modules/paywall/models/paywall_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/revenue_cat_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/subscription_credit_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  group('PaywallConfig', () {
    test('empty or invalid JSON falls back to defaults', () {
      expect(PaywallConfig.fromJsonString('').enabled, isTrue);
      expect(PaywallConfig.fromJsonString('{oops').yearly.price, r'$29.99');
    });

    test('partial override merges over defaults', () {
      final c = PaywallConfig.fromJsonString(
        '{"enabled":false,"trial":{"days":7},"plans":{"monthly":{"visible":false}}}',
      );
      expect(c.enabled, isFalse);
      expect(c.trialButtonLabel, 'Start 7-Day Free Trial');
      expect(c.monthly.visible, isFalse);
      expect(c.yearly.visible, isTrue);
    });

    test('second paywall stays closed by default', () {
      expect(PaywallConfig.defaults.showPlansScreen, isFalse);
    });
  });

  group('plan tiers', () {
    test('monthly and yearly products map to their own tier', () {
      expect(
        planTierForProduct(
          RevenueCatHelper.monthlyProductId,
          PeriodType.normal,
        ),
        'monthly',
      );
      expect(
        planTierForProduct(
          '${RevenueCatHelper.yearlyProductId}:p1y',
          PeriodType.normal,
        ),
        'yearly',
      );
      expect(
        planTierForProduct(RevenueCatHelper.yearlyProductId, PeriodType.trial),
        'trial',
      );
      expect(planTierForProduct('unknown', PeriodType.normal), isNull);
    });
  });
}
