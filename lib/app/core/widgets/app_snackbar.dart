import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App-wide snackbar (title + message) shown at the bottom.
void showAppSnackbar(String title, String message) {
  if (Get.context == null) return;
  Get.closeCurrentSnackbar();
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
    backgroundColor: const Color(0xFF2E2B65),
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
  );
}
