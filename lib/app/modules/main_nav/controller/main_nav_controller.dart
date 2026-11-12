import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:get/get.dart';

import '../../../core/services/recent_designs_service.dart';
import '../../home/widgets/share_card_sheet.dart';
import '../../profile_setup/service/first_card_flow.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      switch (next) {
        case FirstCardNext.scan:
          await onScanTap(); // completes when the user comes back
        case FirstCardNext.share:
          if (Get.isRegistered<RecentDesignsService>()) {
            final service = Get.find<RecentDesignsService>();
            if (service.designs.isNotEmpty) {
              final d = service.designs.first;
              // Completes when the sheet and the option chosen in it are done.
              await showShareCardSheet(frontImage: d.file, backImage: d.backFile);
            }
          }
      }
      // Back from the action: the paywall, then the notification permission.
      await FirstCardFlow.afterAction();
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

  Future<void> onScanTap() async {
    _cancelHomeTemplatePreview();
    await Get.to(
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