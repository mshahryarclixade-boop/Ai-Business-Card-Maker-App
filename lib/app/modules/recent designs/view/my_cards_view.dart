import '../../../core/widgets/crown_upgrade_button.dart';
import '../../career_studio/widgets/career_widgets.dart';
import '../../../core/widgets/hide_when_pro.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/controller/card_editor_controller.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/view/card_editor_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../ai_card_generator/view/ai_card_generator_view.dart';
import '../../../routes/app_routes.dart';
import '../widgets/empty_state.dart';
import '../controller/my_cards_controller.dart';
import '../widgets/pill_tab_selector.dart';
import '../../home/widgets/recent_design_card.dart';
import 'card_detail_view.dart';
import '../../paywall/view/paywall_screen.dart';
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
                onTap: () => openPaywall(source: 'my_cards', plans: true),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Obx(
                        () => PillTabSelector(
                      selectedIndex: controller.tabIndex.value,
                      onChanged: controller.selectTab,
                      labels: ['my_cards_title'.tr, 'my_cards_tab_ai'.tr],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Obx(
                          () => controller.tabIndex.value == 0
                          ? _SavedTabView(controller: controller)
                          : _AiCardsTabView(controller: controller),
                    ),
                  ),
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

/// My Cards tab: empty state or a 2-column grid of saved designs.
class _SavedTabView extends StatelessWidget {
  final MyCardsController controller;

  const _SavedTabView({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Reads the service's list inside Obx: a card saved, edited, synced with
    // the profile or deleted changes what this shows at once.
    return Obx(() {
      final List<RecentDesign> designs = controller.savedDesigns;
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

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: designs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final design = designs[index];
        return RecentDesignCard(
          thumbnailFile: design.file,
          onTap: () => Get.to(() => CardDetailView(design: design)),
        );
      },
    );
  }
}

/// Ai Cards tab: empty state or a 2-column grid of AI-generated cards.
class _AiCardsTabView extends StatelessWidget {
  final MyCardsController controller;

  const _AiCardsTabView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<RecentDesign> designs = controller.aiDesigns;
      return _grid(designs);
    });
  }

  Widget _grid(List<RecentDesign> designs) {
    if (designs.isEmpty) {
      return EmptyStateView(
        iconAsset: 'assets/icons/mycardicon.png',
        backgroundAsset: 'assets/icons/mycardbg.png',
        title: 'my_cards_ai_empty_title'.tr,
        subtitle: 'my_cards_ai_empty_subtitle'.tr,
        buttonLabel: 'my_cards_ai_empty_button'.tr,
        onButtonTap: () {
          Get.to(() => const AiCardGeneratorView());
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: designs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final design = designs[index];
        return RecentDesignCard(
          thumbnailFile: design.file,
          onTap: () => Get.to(() => CardDetailView(design: design)),
        );
      },
    );
  }
}