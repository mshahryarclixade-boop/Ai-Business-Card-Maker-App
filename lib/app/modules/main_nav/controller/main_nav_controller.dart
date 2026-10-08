import 'package:get/get.dart';

import '../../home/controller/home_controller.dart';
import '../../scan card and qr/view/scan_card_view.dart';

class MainNavController extends GetxController {
  /// 0=Home, 1=Template, 2=Contacts, 3=Profile
  final RxInt tabIndex = 0.obs;

  void changeTab(int index) {
    if (index != 0) _cancelHomeTemplatePreview();
    tabIndex.value = index;
  }

  /// Bottom bar order is Home (0), Scan (1), Contacts (2).
  /// Scan opens its own screen, so it never becomes the selected tab.
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