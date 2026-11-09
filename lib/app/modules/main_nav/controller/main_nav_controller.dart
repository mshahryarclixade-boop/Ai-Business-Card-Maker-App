import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:get/get.dart';

import '../../../core/services/recent_designs_service.dart';
import '../../home/widgets/share_card_sheet.dart';

import '../../home/controller/home_controller.dart';
import '../../scan card and qr/view/scan_card_view.dart';

/// What the first-card screen asked to do once Home is open.
enum FirstCardNext { scan, share }

class MainNavController extends GetxController {
  /// Set by the "first card ready" screen; run once, right after Home opens.
  static FirstCardNext? pendingFirstCardAction;

  @override
  void onReady() {
    super.onReady();
    final next = pendingFirstCardAction;
    pendingFirstCardAction = null;
    if (next == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (next) {
        case FirstCardNext.scan:
          onScanTap();
        case FirstCardNext.share:
          if (!Get.isRegistered<RecentDesignsService>()) return;
          final service = Get.find<RecentDesignsService>();
          if (service.designs.isEmpty) return;
          final d = service.designs.first;
          showShareCardSheet(frontImage: d.file, backImage: d.backFile);
      }
    });
  }

  /// 0=Home, 1=Template, 2=Contacts, 3=Clixa AI
  final RxInt tabIndex = 0.obs;

  void changeTab(int index) {
    if (index != 0) _cancelHomeTemplatePreview();
    tabIndex.value = index;
  }

  /// Bottom bar order is Home (0), Scan (1), Contacts (2), Clixa AI (3).
  /// Scan opens its own screen, so it never becomes the selected tab. Clixa AI
  /// is the fourth tab.
  void onNavTap(int index) {
    if (index == 1) {
      onScanTap();
      return;
    }
    changeTab(index);
  }

  void onScanTap() {
    _cancelHomeTemplatePreview();
    Get.to(
          () => const ScanCardView(),
      transition: Transition.rightToLeft,
    );
  }

  /// A template previewed on Home but not applied is dropped as soon as the
  /// user leaves Home, so the original card is shown again on return.
  void _cancelHomeTemplatePreview() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().cancelPreview();
    }
  }
}