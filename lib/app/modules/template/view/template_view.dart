import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../paywall/view/paywall_view.dart';
import '../controller/template_controller.dart';
import '../model/template_item.dart';
import '../widget/orientation_and_filters.dart';
import '../widget/popular_tags_view.dart';
import '../widget/search_bar_widget.dart';
import '../widget/template_card.dart';
import '../widget/template_preview_card.dart';

class TemplateView extends GetView<TemplateController> {
  const TemplateView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(TemplateController());

    return GestureDetector(
      // tapping anywhere outside the search field dismisses the keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: AppColors.scaffoldBg,
        child: Obx(
              () => controller.selectedTemplate.value != null
              ? _TemplateDetailView(controller: controller)
              : _TemplateListing(controller: controller),
        ),
      ),
    );
  }
}

class _TemplateListing extends StatelessWidget {
  final TemplateController controller;

  const _TemplateListing({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Fixed header (never scrolls) ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: Text(
                    'Templates',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
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
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TemplateSearchBar(controller: controller),
        ),

        // Orientation tabs + filter chips — fixed, hidden while searching
        Obx(
              () => controller.isSearching.value
              ? const SizedBox.shrink()
              : Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrientationTabs(controller: controller),
                const SizedBox(height: 14),
                FilterChipsRow(controller: controller),
              ],
            ),
          ),
        ),

        // ── Scrollable body (only this part scrolls) ──────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            child: Column(
              children: [
                Obx(
                      () => controller.isSearching.value
                      ? PopularTagsView(controller: controller)
                      : _TemplatesGrid(controller: controller),
                ),
                const SizedBox(height: 90), // space for bottom nav
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Uses a `Wrap` for Horizontal/Vertical tabs (unchanged), and a true
/// Pinterest-style masonry (`MasonryGridView`) for the Saved tab only.
class _TemplatesGrid extends StatelessWidget {
  final TemplateController controller;

  const _TemplatesGrid({required this.controller});

  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Assets are still being scanned — don't flash the empty message.
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final items = controller.currentList;

      if (items.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'No templates saved yet',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: AppColors.pillLabelGrey,
              ),
            ),
          ),
        );
      }

      // Saved tab only: real masonry layout, so cards settle into
      // whichever column is currently shortest instead of a strict
      // left-right row pairing.
      if (controller.tabIndex.value == 2) {
        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Obx(
                  () => TemplateCard(
                item: item,
                isSaved: controller.savedIds.contains(item.id),
                onHeartTap: () => controller.toggleSaved(item.id),
                onTap: () => controller.openTemplate(item),
              ),
            );
          },
        );
      }

      // Horizontal / Vertical tabs — unchanged Wrap layout.
      return LayoutBuilder(
        builder: (context, constraints) {
          // 2 cards per row, so each card gets half the available
          // width minus the gap between them.
          final cardWidth = (constraints.maxWidth - _spacing) / 2;

          return Wrap(
            spacing: _spacing,
            runSpacing: _spacing,
            children: items.map((item) {
              return SizedBox(
                width: cardWidth,
                child: Obx(
                      () => TemplateCard(
                    item: item,
                    isSaved: controller.savedIds.contains(item.id),
                    onHeartTap: () => controller.toggleSaved(item.id),
                    onTap: () => controller.openTemplate(item),
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
    });
  }
}

/// Full-screen-within-the-tab preview of a tapped template.
/// Bottom nav stays visible — this is a state swap, not a new route.
class _TemplateDetailView extends StatelessWidget {
  final TemplateController controller;

  const _TemplateDetailView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final TemplateItem item = controller.selectedTemplate.value!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed header — back arrow, title, crown
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 24, 0),
          child: SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: controller.closeTemplateDetail,
                    child: const Icon(Icons.arrow_back, size: 22, color: AppColors.titleDark),
                  ),
                ),
                const Center(
                  child: Text(
                    'Templates',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
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
              ],
            ),
          ),
        ),

        // Scrollable preview + actions
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                TemplatePreviewCard(item: item),
                const SizedBox(height: 16),

                // Auto fill toggle
                Center(
                  child: SizedBox(
                    width: 195,
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 25,
                          // FittedBox scales the standard 52x32 switch down
                          // to fit the 24px-high slot.
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Obx(
                                  () => Switch(
                                value: controller.autoFillProfile.value,
                                onChanged: controller.toggleAutoFill,
                                activeColor: AppColors.primary,
                                materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 144,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Auto fill profile details',
                              maxLines: 1,
                              style: AppTextStyles.splashSubtitle.copyWith(
                                fontSize: 14,
                                color: AppColors.titleDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Edit Template button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: controller.onEditTemplateTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonDark,
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Edit Template',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ],
    );
  }
}