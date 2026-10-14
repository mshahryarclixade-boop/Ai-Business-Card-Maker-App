import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

class AppReviewService {
  AppReviewService._();

  static final InAppReview _review = InAppReview.instance;

  static Future<void> requestNativeReview() async {
    try {
      final available = await _review.isAvailable();
      debugPrint('REVIEW: isAvailable = $available');

      if (available) {
        // Let the previous screen/snackbar settle first.
        await Future.delayed(const Duration(milliseconds: 800));
        await _review.requestReview();
        debugPrint('REVIEW: requestReview() called');
      }
    } catch (e, st) {
      debugPrint('REVIEW ERROR: $e');
      debugPrint('$st');
    }
  }
}