import 'package:purchases_flutter/purchases_flutter.dart';

import 'revenue_cat_service.dart';

/// The plan tier a store product maps to (`trial`, `weekly`, `monthly`,
/// `yearly`), or null for an unknown product. A free-trial period gets its
/// own `trial` tier so it isn't granted a full paid pool.
String? planTierForProduct(String productId, PeriodType periodType) {
  if (periodType == PeriodType.trial) return 'trial';
  final id = RevenueCatHelper.productIdOf(productId);
  if (id == RevenueCatHelper.yearlyProductId) return 'yearly';
  if (id == RevenueCatHelper.monthlyProductId) return 'monthly';
  if (id == RevenueCatHelper.weeklyProductId) return 'weekly';
  return null;
}

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
  return latest.isAfter(last);
}
