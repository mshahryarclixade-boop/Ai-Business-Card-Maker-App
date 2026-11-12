import 'package:get/get.dart';
import '../../../core/services/recent_designs_service.dart';

class MyCardsController extends GetxController {
  final RecentDesignsService _service = Get.find<RecentDesignsService>();

  /// Every saved card, AI-generated and manually made, newest first.
  List<RecentDesign> get allDesigns => _service.designs.toList();
}
