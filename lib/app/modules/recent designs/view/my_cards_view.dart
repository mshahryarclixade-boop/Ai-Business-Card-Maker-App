import 'package:ai_business_card_maker/app/modules/custom_create/controller/card_editor_controller.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/view/card_editor_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../ai_card_generator/view/ai_card_generator_view.dart';
import '../../paywall/view/paywall_view.dart';
import '../../../routes/app_routes.dart';
import '../widgets/empty_state.dart';
import '../controller/my_cards_controller.dart';
import '../widgets/pill_tab_selector.dart';
import '../../home/widgets/recent_design_card.dart';
import 'card_detail_view.dart';

/// SETTINGS > MY CARDS > MY CARDS

class MyCardsView extends StatelessWidget {
  const MyCardsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyCardsController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
            child: SizedBox(
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: Text(
                      'My Cards',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.titleDark,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textDark,
                        size: 20,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Get.to(
                              () => const PaywallView(),
                          transition: Transition.rightToLeft,
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const FaIcon(
                          FontAwesomeIcons.crown,
                          size: 18,
                          color: Color(0xFFF5A623),
                        ),
                      ),
                    ),
                  ),
                ],
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
                      labels: const ['My Cards', 'Ai Cards'],
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
    );
  }
}

/// My Cards tab: empty state or a 2-column grid of saved designs.
class _SavedTabView extends StatelessWidget {
  final MyCardsController controller;

  const _SavedTabView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final List<RecentDesign> designs = controller.savedDesigns;

    if (designs.isEmpty) {
      return EmptyStateView(
        iconAsset: 'assets/icons/mycardicon.png',
        title: 'No Cards Yet',
        subtitle:
        'Cards you create or save will\nappear here - ready to share\nanytime.',
        buttonLabel: 'Create Card',
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
    final List<RecentDesign> designs = controller.aiDesigns;

    if (designs.isEmpty) {
      return EmptyStateView(
        iconAsset: 'assets/icons/mycardicon.png',
        backgroundAsset: 'assets/icons/mycardbg.png',
        title: 'No Ai Cards Yet',
        subtitle: 'Cards generated with AI will\nappear here - ready to share\nanytime.',
        buttonLabel: 'Generate with AI',
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