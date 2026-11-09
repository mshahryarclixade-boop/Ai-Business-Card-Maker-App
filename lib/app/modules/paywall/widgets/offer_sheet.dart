import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/subscription_controller.dart';
import '../services/offer_service.dart';

/// The discount offer as a bottom sheet. The price is the store's own (the
/// separate discounted product), never typed text. Resolves to true when the
/// user bought it.
///
/// Shown once per [type] and at most once a day (see OfferService); without a
/// store product there is nothing to show and this returns false at once.
Future<bool> showOfferSheet(
  BuildContext context,
  OfferType type, {
  required String source,
}) async {
  final offers = OfferService.to;
  final id = offers.productId;
  final sub = Get.find<SubscriptionController>();
  final product = id == null ? null : sub.productFor(id);
  if (id == null || product == null) return false;

  offers.markShown(type);
  AnalyticsService.logOfferDisplayed(offerType: type.tag, source: source);

  final bought = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OfferSheet(type: type, productId: id, price: product.priceString, source: source),
  );
  if (bought != true) {
    AnalyticsService.logOfferDismissed(offerType: type.tag, source: source);
  }
  return bought == true;
}

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({
    required this.type,
    required this.productId,
    required this.price,
    required this.source,
  });

  final OfferType type;
  final String productId;
  final String price;
  final String source;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  bool _busy = false;

  Future<void> _claim() async {
    if (_busy) return;
    setState(() => _busy = true);
    AnalyticsService.logOfferAccepted(offerType: widget.type.tag, source: widget.source);
    final ok = await Get.find<SubscriptionController>().buy(
      context,
      productId: widget.productId,
      plan: 'offer_${widget.type.tag}',
      source: widget.source,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.type == OfferType.firstYear;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.profileFieldBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    (first ? 'cro_offer_first_year_title' : 'cro_offer_returning_title').tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (first ? 'cro_offer_first_year_body' : 'cro_offer_returning_body').tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      height: 1.4,
                      color: Color(0xFF737373),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // The store's own price for the discounted product.
                  Center(
                    child: Text(
                      widget.price,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _claim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : Text(
                              'cro_offer_claim'.tr,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                    child: Text(
                      'cro_offer_dismiss'.tr,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF737373),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
