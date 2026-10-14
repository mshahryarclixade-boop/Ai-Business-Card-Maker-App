import 'package:ai_business_card_maker/app/modules/paywall/models/credit_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/revenue_cat_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/subscription_credit_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  group('planTierForProduct', () {
    test('known plans, with Play base plans', () {
      final yearly = RevenueCatHelper.yearlyProductId;
      final monthly = RevenueCatHelper.monthlyProductId;
      expect(planTierForProduct(yearly, PeriodType.normal), 'yearly');
      expect(planTierForProduct('$yearly:base', PeriodType.normal), 'yearly');
      expect(planTierForProduct(monthly, PeriodType.normal), 'monthly');
    });

    test('a trial of one of our plans gets the trial pool', () {
      expect(
        planTierForProduct(RevenueCatHelper.yearlyProductId, PeriodType.trial),
        'trial',
      );
    });

    test('unknown products get nothing, trial or not', () {
      expect(planTierForProduct('aivoice_weekly', PeriodType.normal), isNull);
      expect(planTierForProduct('other_app_pro', PeriodType.trial), isNull);
    });
  });

  group('shouldReassignCredits', () {
    final start = DateTime.utc(2026, 10, 1, 12);
    bool due(DateTime purchased, {String? stored = 'monthly'}) =>
        shouldReassignCredits(
          lastAssignedIso: start.toIso8601String(),
          latestPurchaseDateIso: purchased.toIso8601String(),
          storedPlanTier: stored,
          newPlanTier: 'monthly',
        );

    test('RevenueCat jitter on the same period does not refill', () {
      expect(due(start), isFalse);
      expect(due(start.add(const Duration(minutes: 10))), isFalse);
      expect(due(start.add(const Duration(hours: 19))), isFalse);
    });

    test('a real renewal refills', () {
      expect(due(start.add(const Duration(days: 30))), isTrue);
    });

    test('a plan change refills at once', () {
      expect(due(start, stored: 'free'), isTrue);
    });

    test('never assigned: refills', () {
      expect(
        shouldReassignCredits(
          lastAssignedIso: null,
          latestPurchaseDateIso: start.toIso8601String(),
          storedPlanTier: 'monthly',
          newPlanTier: 'monthly',
        ),
        isTrue,
      );
    });
  });

  test('Remote Config numbers given as strings are accepted', () {
    final pools = CreditPools.fromJson({'monthly': '300', 'free': 'oops'});
    expect(pools.monthly, 300);
    expect(pools.free, 5, reason: 'bad value falls back, others kept');
    expect(CreditCosts.fromJson({'ai_card': '2'}).aiCard, 2);
  });
}
