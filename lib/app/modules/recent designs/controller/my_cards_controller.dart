import 'package:get/get.dart';
import '../../../core/services/recent_designs_service.dart';

class MyCardsController extends GetxController {
  final RecentDesignsService _service = Get.find<RecentDesignsService>();

  /// 0 = My Cards tab, 1 = Ai Cards tab
  final RxInt tabIndex = 0.obs;

  List<RecentDesign> get savedDesigns => _service.savedDesigns;
  List<RecentDesign> get aiDesigns => _service.aiDesigns;

  void selectTab(int index) => tabIndex.value = index;
}