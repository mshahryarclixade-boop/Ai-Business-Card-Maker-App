import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'create_first_card_section.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../custom_create/model/card_element_model.dart';
import '../../custom_create/view/card_editor_view.dart';
import '../../profile_setup/service/profile_store.dart';
import '../../qr_code_generator/view/qr_code_screen.dart';
import '../../template/widget/template_live_preview.dart';
import '../controller/home_controller.dart';
import 'share_card_sheet.dart';

/// Welcome message, the user's current card and its main actions.
class MyCardSection extends StatelessWidget {
  const MyCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<RecentDesignsService>();
    final home = Get.find<HomeController>();

    return Obx(() {
      if (service.designs.isEmpty) return const CreateFirstCardSection();
      final design = service.designs.first;
      final fullName = ProfileStore.to.profile.value.fullName.trim();
      final firstName = fullName.isEmpty ? '' : fullName.split(' ').first;
      final preview = home.previewTemplate.value;
      final liveData = home.previewData.value;
      final applying = home.applying.value;

      void editCard() => Get.to(
            () => CardEditorView(design: design),
        transition: Transition.rightToLeft,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstName.isEmpty ? 'Welcome' : 'Welcome, $firstName',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.titleDark,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: preview == null ? editCard : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: Offset(0, 4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 7 / 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (preview == null)
                        Image.file(design.file, fit: BoxFit.cover)
                      else if (liveData != null)
                        TemplateLivePreview(
                          side: liveData.front,
                          orientation: liveData.orientation,
                          repaintKey: home.frontCaptureKey,
                        )
                      else
                        Image.asset(preview.frontImagePath, fit: BoxFit.cover),
                      if (applying)
                        Container(
                          color: const Color(0x99FFFFFF),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Back side of the live preview, drawn off-screen only so it can be
          // captured when the user taps Apply Template.
          if (liveData != null)
            SizedBox(
              width: 0,
              height: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -5000,
                    top: 0,
                    width: liveData.orientation.canvasSize.width,
                    height: liveData.orientation.canvasSize.height,
                    child: IgnorePointer(
                      child: TemplateCardCanvas(
                        side: liveData.back,
                        orientation: liveData.orientation,
                        repaintKey: home.backCaptureKey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),
          if (preview == null) ...[
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Share Card',
                    filled: true,
                    onTap: () => showShareCardSheet(design.file),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'My QR Code',
                    filled: false,
                    onTap: () => Get.to(
                          () => const CustomQrCodeScreen(),
                      transition: Transition.rightToLeft,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (liveData != null)
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Edit Template',
                    filled: false,
                    onTap: applying ? null : home.editTemplate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: applying ? 'Applying...' : 'Apply Template',
                    filled: true,
                    onTap: applying ? null : home.applyTemplate,
                  ),
                ),
              ],
            )
          else
          // Template without an empty version yet: old AI flow.
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Cancel',
                    filled: false,
                    onTap: applying ? null : home.cancelPreview,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: applying ? 'Applying...' : 'Apply Template',
                    filled: true,
                    onTap: applying ? null : home.applyTemplate,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
        ],
      );
    });
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? AppColors.buttonDark : AppColors.cardWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : AppColors.titleDark,
          ),
        ),
      ),
    );
  }
}