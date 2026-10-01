import 'package:get/get.dart';

class MainNavController extends GetxController {
  /// 0=Home, 1=Template, 2=Contacts, 3=Profile
  final RxInt tabIndex = 0.obs;

  void changeTab(int index) => tabIndex.value = index;

  void onScanTap() {
    // TODO: navigate to scan screen later
  }
}