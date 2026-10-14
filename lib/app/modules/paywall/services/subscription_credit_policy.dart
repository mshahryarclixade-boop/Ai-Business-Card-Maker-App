import 'package:purchases_flutter/purchases_flutter.dart';

import 'revenue_cat_service.dart';

/// The plan tier a store product maps to (`trial`, `weekly`, `monthly`,
/// `yearly`), or null for an unknown product. A free-trial period of one of
/// this app's plans gets its own `trial` tier so it isn't granted a full
/// paid pool.
String? planTierForProduct(String productId, PeriodType periodType) {
  final id = RevenueCatHelper.productIdOf(productId);
  final String tier;
  if (id == RevenueCatHelper.yearlyProductId) {
    tier = 'yearly';
  } else if (id == RevenueCatHelper.monthlyProductId) {
    tier = 'monthly';
  } else if (id == RevenueCatHelper.weeklyProductId) {
    tier = 'weekly';
  } else {
    return null;
  }
  return periodType == PeriodType.trial ? 'trial' : tier;
}

/// A genuine renewal moves the purchase date on by a whole billing period
/// (a week at the least). RevenueCat can push several CustomerInfo updates
/// for the same period whose purchase date drifts by a few minutes (receipt
/// refresh, app foregrounded, sandbox jitter); treating that drift as a
/// renewal would refill the pool and wipe what was spent. Requiring a much
/// larger gap keeps real renewals and rejects the drift.
const minimumRenewalGap = Duration(hours: 20);

/// Whether the pool should be (re)assigned: only for a known plan, and
/// when this billing period (or plan) hasn't been granted yet. Comparing
/// against the last-assigned period start keeps repeated status checks and
/// reinstalls from re-granting credits.
bool shouldReassignCredits({
  required String? lastAssignedIso,
  required String? latestPurchaseDateIso,
  required String? storedPlanTier,
  required String? newPlanTier,
}) {
  if (newPlanTier == null) return false;
  if (storedPlanTier != newPlanTier) return true;
  final latest = DateTime.tryParse(latestPurchaseDateIso ?? '');
  if (latest == null) return false;
  final last = DateTime.tryParse(lastAssignedIso ?? '');
  if (last == null) return true;
  return latest.difference(last) > minimumRenewalGap;
}
