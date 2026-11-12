import '../../paywall/services/paywall_triggers.dart';
import '../../../core/widgets/crown_upgrade_button.dart';
import '../../career_studio/widgets/career_widgets.dart';
import '../../../core/widgets/hide_when_pro.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/controller/card_editor_controller.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/view/card_editor_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../../routes/app_routes.dart';
import '../widgets/empty_state.dart';
import '../controller/my_cards_controller.dart';
import '../../home/widgets/recent_design_card.dart';
import 'card_detail_view.dart';
import '../../../core/translations/tr_extension.dart';

/// SETTINGS > MY CARDS > MY CARDS

class MyCardsView extends StatelessWidget {
  const MyCardsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyCardsController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
        children: [
          // The same app bar and crown as the rest of the app.
          CareerAppBar(
            title: 'my_cards_title'.tr,
            trailing: HideWhenPro(
              child: CrownUpgradeButton(
                size: 40,
                iconSize: 22,
                borderRadius: 12,
                onTap: () => PaywallTriggers.show(PaywallTrigger.crown, screen: 'my_cards'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  // Every saved card together (AI-generated and manually made).
                  Expanded(child: _SavedTabView(controller: controller)),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// All saved cards: empty state or one card per row.
class _SavedTabView extends StatelessWidget {
  final MyCardsController controller;

  const _SavedTabView({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Reads the service's list inside Obx: a card saved, edited, synced with
    // the profile or deleted changes what this shows at once.
    return Obx(() {
      final List<RecentDesign> designs = controller.allDesigns;
      return _grid(designs);
    });
  }

  Widget _grid(List<RecentDesign> designs) {
    if (designs.isEmpty) {
      return EmptyStateView(
        iconAsset: 'assets/icons/mycardicon.png',
        title: 'my_cards_empty_title'.tr,
        subtitle:
        'my_cards_empty_subtitle'.tr,
        buttonLabel: 'my_cards_empty_button'.tr,
        onButtonTap: () {
          Get.to(
                () => const CardEditorView(),
            transition: Transition.rightToLeft,
            binding: BindingsBuilder(() {
              Get.lazyPut<CardEditorController>(() => CardEditorController());
            }),
          );
        },
      );
    }

    // One card per row (no grid).
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: designs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final design = designs[index];
        return RecentDesignCard(
          thumbnailFile: design.file,
          aspectRatio: 7 / 4,
          showWatermark: true,
          onTap: () => Get.to(() => CardDetailView(design: design)),
        );
      },
    );
  }
}
